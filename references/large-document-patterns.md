# Large Document Insertion Patterns

Battle-tested patterns for inserting large formatted markdown (100KB+) into Google Docs, including template documents with cover pages.

## The Core Problem

Google Docs API has a **~60 writes/minute** quota. Naive per-paragraph API calls exhaust it instantly on large documents. The `insert-from-markdown` command in `docs_manager.rb` works for small content but fails on large docs due to formatting index offset bugs when the document already has content.

## Solution: Batch Insert + Batch Format

Use `scripts/insert_markdown_to_doc.rb` for large documents.

### Strategy

1. Parse markdown into blocks: heading, paragraph, code_block, table, blank
2. Group consecutive non-table blocks into "segments"
3. Per segment: **one** `insert_text` call + **one** `batch_update` for all formatting
4. Per table: `insert_table` → sleep → refetch doc → fill cells in reverse → bold header row → append `\n`
5. Sleep between batches to stay under rate limit

### Command

```bash
scripts/insert_markdown_to_doc.rb [options] <document_id> <markdown_file>
```

**Options**:
- `--code-font FONT` — Font for code blocks/inline code (default: `Consolas`)
- `--start-index INDEX` — Insert after this index (preserves template content before it)
- `--clear-after INDEX` — Delete all content after this index before inserting
- `--insert-images` — Upload local images to Drive and insert inline
- `--image-base-dir DIR` — Base directory for resolving relative image paths
- `--chunk-size BYTES` — Max bytes per chunk (default: 20000)

### Example: Insert Into Template Doc

```bash
scripts/insert_markdown_to_doc.rb \
  --clear-after 1234 \
  --code-font Consolas \
  --insert-images \
  --image-base-dir ./docs \
  1Qz1ZsBpLQf0zcH_kFFCBYDov3IELbi8GZdbk3IVxXgM \
  ./docs/technical_doc.md
```

## Working With Template Documents

When a Google Doc has a cover page or template content you want to preserve:

1. **Find the template end index**: Use `docs_manager.rb structure <doc_id>` to identify where template content ends
2. **Clear old content**: Use `--clear-after INDEX` to delete everything after the template
3. **Insert new content**: The script appends after the cleared point

**Critical**: Never delete below the template end index or you destroy the cover page.

## Chunking Strategy

Large markdown files (100KB+) must be split into chunks to avoid quota exhaustion:

- Default chunk size: 20KB
- Each chunk gets its own set of API calls (insert + format + tables)
- 3-second sleep between chunks
- Tables require 3+ API calls each (insert → refetch → fill → bold header)
- A chunk with 20 tables = ~80 API calls minimum

**Sizing guide**:

| Content Type | Recommended Chunk Size | API Calls/Chunk |
|---|---|---|
| Text-heavy (few tables) | 30-50KB | 2-4 |
| Table-heavy | 10-15KB | 20-60 |
| Code-heavy | 20-30KB | 4-8 |
| Mixed | 20KB (default) | 10-30 |

## Rate Limiting

| Quota | Limit | Mitigation |
|---|---|---|
| Write requests/minute | ~60 | `sleep(2)` between batches |
| Batch request items | 500/batch | Slice into 150-item batches |
| Document size | ~50MB | Chunk large content |

If you hit "429 Rate Limit Exceeded":
- Increase sleep between batches (2→3 seconds)
- Decrease chunk size
- Add 10-second recovery sleep in error handler

## Table Insertion Details

Tables cannot be inserted via `insert_text`. They require:

1. `insert_table` request with row/column count at target index
2. **Wait 3 seconds** for table creation to propagate
3. Refetch document to get new table element indices
4. Fill cells **in reverse order** (to preserve indices)
5. Refetch again, then bold header row cells
6. Append `\n` after table

**Why reverse order?** Inserting text shifts all subsequent indices. Filling from last cell backward keeps earlier cell indices stable.

## Image Insertion via Drive

Google Docs `insertInlineImage` requires a **publicly accessible URL**. For local files:

1. Upload PNG to Google Drive via Drive API
2. Set permission: `anyone` with `reader` role
3. Construct URL: `https://drive.google.com/uc?export=download&id=FILE_ID`
4. Use `insertInlineImage` with that URL

**Requires**: Google Drive API enabled on the GCP project.

Use `--insert-images` flag with the script, or handle manually with `drive_manager.rb`:

```bash
scripts/drive_manager.rb upload --file ./diagram.png
scripts/drive_manager.rb share --file-id FILE_ID --type anyone --role reader
```

## Mermaid Diagram Handling

Mermaid code blocks (` ```mermaid `) cannot be rendered in Google Docs. The script replaces them with `[Diagrama - ver imagen adjunta]` placeholder text during preprocessing. Render mermaid diagrams externally and insert as images.

## Supported Markdown Features

| Feature | Rendering |
|---|---|
| `# H1` through `#### H4` | Google Docs HEADING_1 through HEADING_4 |
| `**bold**` | Bold text style |
| `*italic*` | Italic text style |
| `` `inline code` `` | Consolas font (configurable) |
| ` ``` code block ``` ` | Consolas font (configurable) |
| `- item` / `* item` | Bullet character (•) |
| `1. item` | Numbered prefix |
| `- [ ] task` / `- [x] task` | Checkbox characters (☐/☑) |
| `\| table \|` | Real Google Docs table with bold header |
| `![alt](path)` | Inline image via Drive upload |
| `---` | Blank line |

## Error Recovery

When the script errors mid-insertion (common with rate limits):

1. Check current doc state: `docs_manager.rb structure <doc_id>`
2. Identify what was successfully inserted
3. Create a "tail" markdown file with remaining content
4. Run the script again on just the tail

The script's error handler includes a 10-second recovery sleep before continuing to the next chunk.
