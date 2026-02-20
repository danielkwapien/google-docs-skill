# Google Docs & Drive Skill

A skill for AI coding assistants (Claude Code, gemini-cli, OpenCode, Codex, Cursor) to manage Google Docs and Google Drive with comprehensive document and file operations.

## Attribution

Originally created by [Rob Taylor](https://github.com/robtaylor) — [original repo](https://github.com/robtaylor/google-docs-skill).
Maintained and extended by [Daniel Kwapien](https://github.com/danielkwapien).

## What's New in v1.3.0

- Large document insertion (`insert_markdown_to_doc.rb`) with rate limiting and batching
- Real Google Docs tables with bold headers from Markdown
- Code blocks and inline code in Consolas font
- Local image upload to Drive + inline insertion
- Template document support (preserve cover page)
- Expanded troubleshooting guide (Ruby version, token format, Drive API)

## Features

### Google Docs Operations
- Read document content and structure
- Create new documents (plain text or Markdown)
- Insert and append text with Markdown formatting
- Find and replace text
- Text formatting (bold, italic, underline)
- Insert page breaks, images, and tables
- Delete content ranges
- Large document insertion with rate limiting

### Google Drive Operations
- Upload and download files
- Search across Drive
- Create and list folders
- Share files and folders
- Move and organize files
- Export files to different formats (PDF, PNG, etc.)

## Installation

### Claude Code / OpenCode

```bash
git clone https://github.com/danielkwapien/google-docs-skill.git ~/.claude/skills/google-docs
```

### gemini-cli (as skill)

```bash
gemini skills install https://github.com/danielkwapien/google-docs-skill.git
```

### gemini-cli (as extension)

```bash
gemini extensions install https://github.com/danielkwapien/google-docs-skill.git
```

### Cross-tool standard path

```bash
git clone https://github.com/danielkwapien/google-docs-skill.git ~/.agents/skills/google-docs
```

## Setup

1. Create a Google Cloud Project and enable the Docs and Drive APIs
2. Create OAuth 2.0 credentials (Desktop application type)
3. Download credentials and save as `~/.claude/.google/client_secret.json`
4. Run any command — the script will prompt for authorization

The OAuth token is shared with other Google skills (Sheets, Calendar, Gmail, etc.).

## Usage

See [SKILL.md](SKILL.md) for complete documentation and examples.

### Quick Examples

```bash
# Read a document
scripts/docs_manager.rb read <document_id>

# Create a document from Markdown
echo '{"title": "My Doc", "markdown": "# Heading\n\nParagraph with **bold**."}' | scripts/docs_manager.rb create-from-markdown

# Insert large markdown into existing doc
scripts/insert_markdown_to_doc.rb --clear-after 1234 <document_id> ./content.md

# Upload a file to Drive
scripts/drive_manager.rb upload --file ./myfile.pdf --name "My PDF"

# Search Drive
scripts/drive_manager.rb search --query "name contains 'Report'"
```

## Requirements

- Ruby 3.0+ (Homebrew recommended on macOS: `/opt/homebrew/opt/ruby/bin/ruby`)
- Gems: `google-apis-docs_v1`, `google-apis-drive_v3`, `googleauth`

## License

MIT License — see [LICENSE](LICENSE) for details.
