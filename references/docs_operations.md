# Google Docs Operations Reference

Complete reference for all Google Docs operations available in the docs_manager.rb script.

## Operation Overview

| Operation | Command | Input | Output |
|-----------|---------|-------|--------|
| Read | `read <document_id>` | CLI arg | Full document content |
| Structure | `structure <document_id>` | CLI arg | Heading hierarchy |
| Insert | `insert` | JSON stdin | Insert confirmation |
| Append | `append` | JSON stdin | Append confirmation |
| Replace | `replace` | JSON stdin | Replacement count |
| Format | `format` | JSON stdin | Format confirmation |
| Page Break | `page-break` | JSON stdin | Page break confirmation |
| Create | `create` | JSON stdin | New document ID |
| Delete | `delete` | JSON stdin | Delete confirmation |

---

## Read Document

**Command**: `read <document_id>`

**Purpose**: Retrieve full document content and metadata

**Input**: Document ID as CLI argument

**Output**:
```json
{
  "status": "success",
  "operation": "read",
  "document_id": "abc123",
  "title": "Document Title",
  "content": "Full text content with paragraphs and tables...",
  "revision_id": "revision_xyz"
}
```

**Use Cases**:
- View current document state
- Calculate index positions for edits
- Backup content before modifications
- Extract text for processing

**Example**:
```bash
scripts/docs_manager.rb read 1abc-xyz-document-id-123
```

---

## Get Document Structure

**Command**: `structure <document_id>`

**Purpose**: Retrieve document heading hierarchy

**Input**: Document ID as CLI argument

**Output**:
```json
{
  "status": "success",
  "operation": "structure",
  "document_id": "abc123",
  "title": "Document Title",
  "structure": [
    {
      "level": 1,
      "text": "Main Heading",
      "start_index": 1,
      "end_index": 15
    },
    {
      "level": 2,
      "text": "Subheading",
      "start_index": 50,
      "end_index": 62
    }
  ]
}
```

**Heading Levels**:
- Level 1: Heading 1 (highest level)
- Level 2: Heading 2
- Level 3: Heading 3
- Level 4: Heading 4
- Level 5: Heading 5
- Level 6: Heading 6 (lowest level)

**Use Cases**:
- Navigate document sections
- Find insertion points for new content
- Validate document organization
- Generate table of contents

**Example**:
```bash
scripts/docs_manager.rb structure 1abc-xyz-document-id-123
```

---

## Insert Text

**Command**: `insert` (JSON via stdin)

**Purpose**: Insert text at specific index position

**Input**:
```json
{
  "document_id": "abc123",
  "text": "Text to insert with\nnewlines if needed",
  "index": 1
}
```

**Parameters**:
- `document_id` (required): Document identifier
- `text` (required): Text content to insert
- `index` (optional): Position to insert at (default: 1)

**Output**:
```json
{
  "status": "success",
  "operation": "insert",
  "document_id": "abc123",
  "inserted_at": 1,
  "text_length": 45,
  "revision_id": "revision_xyz"
}
```

**Index Guidelines**:
- Index 1: Start of document
- Existing content shifts right
- Include newlines (\n) for spacing
- Use structure command to find positions

**Examples**:
```bash
# Insert at beginning
echo '{"document_id":"abc123","text":"# Title\n\n","index":1}' | scripts/docs_manager.rb insert

# Insert at specific position
echo '{"document_id":"abc123","text":"New paragraph\n\n","index":500}' | scripts/docs_manager.rb insert
```

---

## Append Text

**Command**: `append` (JSON via stdin)

**Purpose**: Add text to end of document

**Input**:
```json
{
  "document_id": "abc123",
  "text": "\n\nAppended text at the end"
}
```

**Parameters**:
- `document_id` (required): Document identifier
- `text` (required): Text content to append

**Output**:
```json
{
  "status": "success",
  "operation": "append",
  "document_id": "abc123",
  "appended_at": 1500,
  "text_length": 25,
  "revision_id": "revision_xyz"
}
```

**Use Cases**:
- Add conclusion or summary
- Append new sections
- Add footnotes or references
- Simpler than calculating end index

**Examples**:
```bash
# Append new section
echo '{
  "document_id": "abc123",
  "text": "\n\n## Next Steps\n\n- Review document\n- Get feedback"
}' | scripts/docs_manager.rb append

# Append signature
echo '{
  "document_id": "abc123",
  "text": "\n\n---\n\nPrepared by: [Name]\nDate: [Date]"
}' | scripts/docs_manager.rb append
```

---

## Replace Text

**Command**: `replace` (JSON via stdin)

**Purpose**: Find and replace all occurrences of text

**Input**:
```json
{
  "document_id": "abc123",
  "find": "old text",
  "replace": "new text",
  "match_case": false
}
```

**Parameters**:
- `document_id` (required): Document identifier
- `find` (required): Text to search for
- `replace` (required): Replacement text
- `match_case` (optional): Case-sensitive matching (default: false)

**Output**:
```json
{
  "status": "success",
  "operation": "replace",
  "document_id": "abc123",
  "find": "old text",
  "replace": "new text",
  "occurrences": 5
}
```

**Behavior**:
- Replaces ALL occurrences
- Cannot undo (no rollback)
- Returns count of replacements
- Empty string allowed for deletion

**Use Cases**:
- Update terminology
- Fix typos throughout document
- Change dates or names
- Remove unwanted text

**Examples**:
```bash
# Case-insensitive replacement
echo '{
  "document_id": "abc123",
  "find": "q3 2024",
  "replace": "Q4 2024",
  "match_case": false
}' | scripts/docs_manager.rb replace

# Case-sensitive replacement
echo '{
  "document_id": "abc123",
  "find": "DRAFT",
  "replace": "FINAL",
  "match_case": true
}' | scripts/docs_manager.rb replace

# Delete text (replace with empty)
echo '{
  "document_id": "abc123",
  "find": "[REMOVE THIS]",
  "replace": ""
}' | scripts/docs_manager.rb replace
```

---

## Format Text

**Command**: `format` (JSON via stdin)

**Purpose**: Apply text styling to specific range

**Input**:
```json
{
  "document_id": "abc123",
  "start_index": 1,
  "end_index": 50,
  "bold": true,
  "italic": false,
  "underline": false
}
```

**Parameters**:
- `document_id` (required): Document identifier
- `start_index` (required): Start of text range
- `end_index` (required): End of text range
- `bold` (optional): Apply bold formatting
- `italic` (optional): Apply italic formatting
- `underline` (optional): Apply underline formatting

**Output**:
```json
{
  "status": "success",
  "operation": "format",
  "document_id": "abc123",
  "range": { "start": 1, "end": 50 },
  "formatting": { "bold": true }
}
```

**Formatting Options**:
- All options are independent
- Can combine multiple styles
- Applies to exact character range
- Use read/structure to find positions

**Examples**:
```bash
# Bold heading
echo '{
  "document_id": "abc123",
  "start_index": 1,
  "end_index": 20,
  "bold": true
}' | scripts/docs_manager.rb format

# Bold and italic
echo '{
  "document_id": "abc123",
  "start_index": 100,
  "end_index": 150,
  "bold": true,
  "italic": true
}' | scripts/docs_manager.rb format

# Underline only
echo '{
  "document_id": "abc123",
  "start_index": 200,
  "end_index": 225,
  "underline": true
}' | scripts/docs_manager.rb format
```

---

## Insert Page Break

**Command**: `page-break` (JSON via stdin)

**Purpose**: Insert page break at specific position

**Input**:
```json
{
  "document_id": "abc123",
  "index": 500
}
```

**Parameters**:
- `document_id` (required): Document identifier
- `index` (required): Position for page break

**Output**:
```json
{
  "status": "success",
  "operation": "page_break",
  "document_id": "abc123",
  "inserted_at": 500
}
```

**Use Cases**:
- Separate major sections
- Start new content on fresh page
- Organize long documents
- Prepare for printing

**Example**:
```bash
# Insert page break between sections
echo '{
  "document_id": "abc123",
  "index": 1000
}' | scripts/docs_manager.rb page-break
```

---

## Create Document

**Command**: `create` (JSON via stdin)

**Purpose**: Create new Google Doc

**Input**:
```json
{
  "title": "New Document Title",
  "content": "Optional initial content"
}
```

**Parameters**:
- `title` (required): Document title
- `content` (optional): Initial document content

**Output**:
```json
{
  "status": "success",
  "operation": "create",
  "document_id": "new_doc_abc123",
  "title": "New Document Title",
  "revision_id": "revision_xyz"
}
```

**Use Cases**:
- Generate reports programmatically
- Create document templates
- Batch document creation
- Automated content generation

**Examples**:
```bash
# Empty document
echo '{
  "title": "Meeting Notes"
}' | scripts/docs_manager.rb create

# Document with content
echo '{
  "title": "Project Proposal",
  "content": "# Project Proposal\n\n## Overview\n\nThis proposal outlines..."
}' | scripts/docs_manager.rb create
```

---

## Delete Content

**Command**: `delete` (JSON via stdin)

**Purpose**: Remove text from document

**Input**:
```json
{
  "document_id": "abc123",
  "start_index": 100,
  "end_index": 200
}
```

**Parameters**:
- `document_id` (required): Document identifier
- `start_index` (required): Start of deletion range
- `end_index` (required): End of deletion range

**Output**:
```json
{
  "status": "success",
  "operation": "delete",
  "document_id": "abc123",
  "deleted_range": { "start": 100, "end": 200 }
}
```

**Use Cases**:
- Remove outdated sections
- Clear template content
- Delete draft paragraphs
- Clean up document

**Examples**:
```bash
# Delete specific range
echo '{
  "document_id": "abc123",
  "start_index": 500,
  "end_index": 600
}' | scripts/docs_manager.rb delete

# Clear most of document (read first to get end index)
echo '{
  "document_id": "abc123",
  "start_index": 1,
  "end_index": 5000
}' | scripts/docs_manager.rb delete
```

---

## Error Codes

| Code | Meaning | Action |
|------|---------|--------|
| AUTH_REQUIRED | OAuth needed | Run auth flow |
| AUTH_FAILED | Auth failed | Check credentials |
| API_ERROR | Google API error | Check document ID/permissions |
| OPERATION_FAILED | Operation error | Verify parameters |
| INVALID_ARGS | Missing params | Check required fields |
| MISSING_DOCUMENT_ID | No doc ID | Provide document ID |
| MISSING_REQUIRED_FIELDS | Missing fields | Include all required fields |

---

## Exit Codes

- **0**: Success
- **1**: Operation failed
- **2**: Authentication error
- **3**: API error
- **4**: Invalid arguments

---

## Best Practices

### Index Calculation
1. Read document first to see content
2. Use structure command for heading positions
3. Count characters carefully (including spaces/newlines)
4. Remember: index 1 = start of document
5. Use append for end insertions (simpler)

### Batch Operations
1. Read document once for context
2. Plan all edits before executing
3. Execute in order: delete → insert → format
4. Consider using replace for bulk changes
5. Verify results with final read

### Error Prevention
1. Always validate document ID first
2. Check index bounds before operations
3. Test complex operations on copy first
4. Save document ID after creation
5. Use google-drive skill for backups

### Performance
1. Batch related operations together
2. Use replace instead of multiple delete/insert
3. Minimize API calls when possible
4. Cache document structure if reusing
5. Consider rate limits for bulk operations
