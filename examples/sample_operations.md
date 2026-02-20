# Google Docs Sample Operations

Practical examples of common Google Docs operations and workflows.

## Basic Operations

### Example 1: Create a Simple Document

**Objective**: Create a new document with a title and initial content

```bash
echo '{
  "title": "Weekly Status Report",
  "content": "# Weekly Status Report\n\n## Accomplishments\n\n- Completed feature implementation\n- Resolved 3 critical bugs\n- Updated documentation\n\n## Next Week\n\n- Begin testing phase\n- Team review meeting"
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb create
```

**Expected Output**:
```json
{
  "status": "success",
  "operation": "create",
  "document_id": "1abc-xyz-new-document-123",
  "title": "Weekly Status Report",
  "revision_id": "revision_001"
}
```

**Next Steps**: Save the document_id for future operations

---

### Example 2: Read Document Content

**Objective**: Retrieve full text content of a document

```bash
~/.claude/skills/google-docs/scripts/docs_manager.rb read 1abc-xyz-document-123
```

**Expected Output**:
```json
{
  "status": "success",
  "operation": "read",
  "document_id": "1abc-xyz-document-123",
  "title": "Weekly Status Report",
  "content": "# Weekly Status Report\n\n## Accomplishments\n\n- Completed feature implementation\n- Resolved 3 critical bugs\n- Updated documentation\n\n## Next Week\n\n- Begin testing phase\n- Team review meeting",
  "revision_id": "revision_002"
}
```

---

### Example 3: Get Document Structure

**Objective**: View heading hierarchy for navigation

```bash
~/.claude/skills/google-docs/scripts/docs_manager.rb structure 1abc-xyz-document-123
```

**Expected Output**:
```json
{
  "status": "success",
  "operation": "structure",
  "document_id": "1abc-xyz-document-123",
  "title": "Weekly Status Report",
  "structure": [
    {
      "level": 1,
      "text": "Weekly Status Report",
      "start_index": 1,
      "end_index": 22
    },
    {
      "level": 2,
      "text": "Accomplishments",
      "start_index": 24,
      "end_index": 40
    },
    {
      "level": 2,
      "text": "Next Week",
      "start_index": 150,
      "end_index": 160
    }
  ]
}
```

---

## Text Manipulation

### Example 4: Insert Text at Beginning

**Objective**: Add date stamp to document start

```bash
echo '{
  "document_id": "1abc-xyz-document-123",
  "text": "Date: November 10, 2025\n\n",
  "index": 1
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb insert
```

**Result**: Date appears at very beginning, before title

---

### Example 5: Append New Section

**Objective**: Add "Challenges" section to end of document

```bash
echo '{
  "document_id": "1abc-xyz-document-123",
  "text": "\n\n## Challenges\n\n- Resource constraints during peak load\n- Integration complexity with legacy system\n\n## Mitigation Plans\n\n- Scale infrastructure proactively\n- Allocate additional developer time"
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb append
```

**Result**: New sections added to document end

---

### Example 6: Find and Replace

**Objective**: Update all instances of "Q3" to "Q4"

```bash
echo '{
  "document_id": "1abc-xyz-document-123",
  "find": "Q3 2024",
  "replace": "Q4 2024",
  "match_case": false
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb replace
```

**Expected Output**:
```json
{
  "status": "success",
  "operation": "replace",
  "document_id": "1abc-xyz-document-123",
  "find": "Q3 2024",
  "replace": "Q4 2024",
  "occurrences": 7
}
```

**Result**: All 7 occurrences updated throughout document

---

## Formatting Operations

### Example 7: Format Document Title

**Objective**: Make main heading bold

```bash
# First, get structure to find title position
~/.claude/skills/google-docs/scripts/docs_manager.rb structure 1abc-xyz-document-123

# From output: title is at index 1-22

# Apply bold formatting
echo '{
  "document_id": "1abc-xyz-document-123",
  "start_index": 1,
  "end_index": 22,
  "bold": true
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb format
```

**Result**: "Weekly Status Report" appears bold

---

### Example 8: Format Multiple Headings

**Objective**: Make all H2 headings bold and italic

```bash
# Get structure first
~/.claude/skills/google-docs/scripts/docs_manager.rb structure 1abc-xyz-document-123

# Format "Accomplishments" (index 24-40)
echo '{
  "document_id": "1abc-xyz-document-123",
  "start_index": 24,
  "end_index": 40,
  "bold": true,
  "italic": true
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb format

# Format "Next Week" (index 150-160)
echo '{
  "document_id": "1abc-xyz-document-123",
  "start_index": 150,
  "end_index": 160,
  "bold": true,
  "italic": true
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb format
```

**Result**: Both H2 headings have bold + italic styling

---

### Example 9: Emphasize Keywords

**Objective**: Bold important metrics in document

```bash
# Read document to find "3 critical bugs" position
# Assume it's at index 75-90

echo '{
  "document_id": "1abc-xyz-document-123",
  "start_index": 75,
  "end_index": 90,
  "bold": true
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb format
```

**Result**: "3 critical bugs" appears bold for emphasis

---

## Document Organization

### Example 10: Insert Page Break

**Objective**: Separate executive summary from detailed sections

```bash
# Insert page break after executive summary (assume index 500)
echo '{
  "document_id": "1abc-xyz-document-123",
  "index": 500
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb page-break
```

**Result**: Content after index 500 starts on new page

---

### Example 11: Delete Unwanted Section

**Objective**: Remove draft notes from document

```bash
# Assume draft notes are at index 1000-1500
echo '{
  "document_id": "1abc-xyz-document-123",
  "start_index": 1000,
  "end_index": 1500
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb delete
```

**Result**: 500 characters removed from document

---

## Complex Workflows

### Example 12: Generate Weekly Report

**Complete workflow**: Create, populate, and format a weekly report

```bash
# Step 1: Create document
echo '{
  "title": "Weekly Report - Nov 10, 2025"
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb create
# Returns: {"document_id": "new_doc_abc"}

# Step 2: Add structure
echo '{
  "document_id": "new_doc_abc",
  "text": "# Weekly Report - Nov 10, 2025\n\n## Summary\n\n[Summary content]\n\n## Detailed Metrics\n\n[Metrics content]\n\n## Next Steps\n\n[Action items]",
  "index": 1
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb insert

# Step 3: Replace placeholders
echo '{
  "document_id": "new_doc_abc",
  "find": "[Summary content]",
  "replace": "This week we completed 15 tasks, deployed 2 features, and resolved 8 bugs."
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb replace

echo '{
  "document_id": "new_doc_abc",
  "find": "[Metrics content]",
  "replace": "- Tasks Completed: 15\n- Features Deployed: 2\n- Bugs Resolved: 8\n- Test Coverage: 87%"
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb replace

echo '{
  "document_id": "new_doc_abc",
  "find": "[Action items]",
  "replace": "- Complete integration testing\n- Prepare for stakeholder demo\n- Update project documentation"
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb replace

# Step 4: Format headings (get structure first)
~/.claude/skills/google-docs/scripts/docs_manager.rb structure new_doc_abc

# Step 5: Format main title (bold)
echo '{
  "document_id": "new_doc_abc",
  "start_index": 1,
  "end_index": 30,
  "bold": true
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb format

# Step 6: Format section headings (bold + italic)
# Repeat for each section heading from structure output
```

**Result**: Fully formatted weekly report ready for distribution

---

### Example 13: Update Project Proposal

**Workflow**: Systematic update of an existing proposal

```bash
# Step 1: Read current state
~/.claude/skills/google-docs/scripts/docs_manager.rb read proposal_doc_123 > current_state.json

# Step 2: Update all dates
echo '{
  "document_id": "proposal_doc_123",
  "find": "2024",
  "replace": "2025"
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb replace

# Step 3: Update budget section
echo '{
  "document_id": "proposal_doc_123",
  "find": "Budget: $50,000",
  "replace": "Budget: $65,000"
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb replace

# Step 4: Add new section
echo '{
  "document_id": "proposal_doc_123",
  "text": "\n\n## Risk Assessment\n\n### Technical Risks\n\n- Infrastructure scalability\n- Third-party API dependencies\n\n### Mitigation Strategies\n\n- Load testing before launch\n- Fallback mechanisms for APIs"
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb append

# Step 5: Insert page break before appendix
# (Assume appendix starts at index 5000)
echo '{
  "document_id": "proposal_doc_123",
  "index": 5000
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb page-break

# Step 6: Format new section heading
echo '{
  "document_id": "proposal_doc_123",
  "start_index": 5010,
  "end_index": 5030,
  "bold": true
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb format
```

**Result**: Updated proposal with new content and formatting

---

### Example 14: Template-Based Document Generation

**Workflow**: Create multiple documents from template

```bash
# Create template function
create_from_template() {
  local client_name=$1
  local project_name=$2

  # Create base document
  doc_id=$(echo '{
    "title": "Project Proposal - '"$client_name"' - '"$project_name"'"
  }' | ~/.claude/skills/google-docs/scripts/docs_manager.rb create | jq -r '.document_id')

  # Add template content
  echo '{
    "document_id": "'"$doc_id"'",
    "text": "# Project Proposal\n\n**Client**: '"$client_name"'\n**Project**: '"$project_name"'\n\n## Executive Summary\n\n[To be completed]\n\n## Scope of Work\n\n[To be completed]\n\n## Timeline\n\n[To be completed]\n\n## Budget\n\n[To be completed]",
    "index": 1
  }' | ~/.claude/skills/google-docs/scripts/docs_manager.rb insert

  # Format title
  echo '{
    "document_id": "'"$doc_id"'",
    "start_index": 1,
    "end_index": 20,
    "bold": true
  }' | ~/.claude/skills/google-docs/scripts/docs_manager.rb format

  echo "Created document: $doc_id"
}

# Generate multiple proposals
create_from_template "Acme Corp" "Website Redesign"
create_from_template "Tech Startup" "Mobile App"
create_from_template "Enterprise Inc" "Data Migration"
```

**Result**: Three customized proposal documents created from template

---

## Integration with Google Drive

### Example 15: Create, Edit, and Share Document

**Workflow**: Complete document lifecycle with Drive integration

```bash
# Step 1: Create document
doc_id=$(echo '{
  "title": "Team Meeting Notes - Nov 10"
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb create | jq -r '.document_id')

# Step 2: Add meeting content
echo '{
  "document_id": "'"$doc_id"'",
  "text": "# Team Meeting Notes\n\n**Date**: November 10, 2025\n**Attendees**: Team Members\n\n## Discussion Topics\n\n1. Project status\n2. Upcoming deadlines\n3. Resource allocation\n\n## Action Items\n\n- [ ] Complete testing by Friday\n- [ ] Update documentation\n- [ ] Schedule follow-up"
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb insert

# Step 3: Format headings
echo '{
  "document_id": "'"$doc_id"'",
  "start_index": 1,
  "end_index": 20,
  "bold": true
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb format

# Step 4: Move to team folder using Drive skill
~/.claude/skills/google-drive/scripts/drive_manager.rb --operation move \
  --file-id "$doc_id" \
  --parent-id "team_folder_id_xyz"

# Step 5: Share with team
~/.claude/skills/google-drive/scripts/drive_manager.rb --operation share \
  --file-id "$doc_id" \
  --email team@company.com \
  --role writer

# Step 6: Generate PDF for archive
~/.claude/skills/google-drive/scripts/drive_manager.rb --operation export \
  --file-id "$doc_id" \
  --mime-type "application/pdf" \
  --output "meeting_notes_nov10.pdf"
```

**Result**: Document created, organized, shared, and archived

---

## Troubleshooting Examples

### Example 16: Fix Incorrect Index

**Problem**: Format operation failed with "Invalid index"

```bash
# Step 1: Read document to see current state
~/.claude/skills/google-docs/scripts/docs_manager.rb read doc_abc_123

# Step 2: Get structure for reference points
~/.claude/skills/google-docs/scripts/docs_manager.rb structure doc_abc_123

# Step 3: Manually count characters to target
# From read output: "# Title\n\nContent here"
# Index 1-7: "# Title"
# Index 8-9: "\n\n"
# Index 10+: "Content here"

# Step 4: Apply correct formatting
echo '{
  "document_id": "doc_abc_123",
  "start_index": 1,
  "end_index": 7,
  "bold": true
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb format
```

**Result**: Correct index range identified and applied

---

### Example 17: Batch Update with Verification

**Objective**: Update multiple items and verify each step

```bash
# Step 1: Backup current state
~/.claude/skills/google-docs/scripts/docs_manager.rb read doc_abc_123 > backup.json

# Step 2: First update with verification
echo '{
  "document_id": "doc_abc_123",
  "find": "Phase 1",
  "replace": "Phase 2"
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb replace
# Check output: {"occurrences": 3}

# Step 3: Second update with verification
echo '{
  "document_id": "doc_abc_123",
  "find": "January",
  "replace": "February"
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb replace
# Check output: {"occurrences": 5}

# Step 4: Verify final state
~/.claude/skills/google-docs/scripts/docs_manager.rb read doc_abc_123

# Step 5: If needed, restore from backup
# (Manual process or use delete + insert operations)
```

**Result**: Systematic updates with verification at each step

---

## Performance Optimization

### Example 18: Efficient Bulk Replacement

**Objective**: Update many instances efficiently

```bash
# Instead of multiple insert/delete operations, use replace
echo '{
  "document_id": "doc_abc_123",
  "find": "old_term",
  "replace": "new_term"
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb replace

# Single API call replaces all occurrences
# More efficient than:
# - Read document
# - Find each occurrence
# - Delete and insert at each position
```

**Result**: 10x faster than manual find/delete/insert loop

---

### Example 19: Minimize API Calls

**Objective**: Plan operations to reduce API usage

```bash
# Bad approach: Multiple reads
~/.claude/skills/google-docs/scripts/docs_manager.rb read doc_abc
# ... format operation ...
~/.claude/skills/google-docs/scripts/docs_manager.rb read doc_abc
# ... another format operation ...
~/.claude/skills/google-docs/scripts/docs_manager.rb read doc_abc

# Good approach: Single read, multiple operations
~/.claude/skills/google-docs/scripts/docs_manager.rb read doc_abc > state.json
~/.claude/skills/google-docs/scripts/docs_manager.rb structure doc_abc > structure.json

# Plan all operations from cached data
# Execute all format operations sequentially
# Read once at end to verify
```

**Result**: 3 API calls instead of 6+

---

## Common Pitfalls and Solutions

### Pitfall 1: Index Shift After Insert

**Problem**: Formatting wrong text after insertion

```bash
# Step 1: Get structure
~/.claude/skills/google-docs/scripts/docs_manager.rb structure doc_abc
# Heading at index 100-110

# Step 2: Insert text at index 50
echo '{
  "document_id": "doc_abc",
  "text": "New text (30 chars)\n\n",
  "index": 50
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb insert

# Step 3: WRONG - heading now at 130-140, not 100-110
# Must recalculate: 100 + 30 = 130

# Correct approach:
echo '{
  "document_id": "doc_abc",
  "start_index": 130,
  "end_index": 140,
  "bold": true
}' | ~/.claude/skills/google-docs/scripts/docs_manager.rb format
```

**Solution**: Recalculate indices after insertions

---

### Pitfall 2: Overlapping Format Ranges

**Problem**: Conflicting format operations

```bash
# Bad: Overlapping ranges cause confusion
echo '{"document_id":"doc","start_index":1,"end_index":50,"bold":true}' | format
echo '{"document_id":"doc","start_index":40,"end_index":60,"italic":true}' | format
# Index 40-50 has uncertain state

# Good: Clear, non-overlapping ranges
echo '{"document_id":"doc","start_index":1,"end_index":40,"bold":true}' | format
echo '{"document_id":"doc","start_index":40,"end_index":60,"italic":true}' | format
# Or combine in single call:
echo '{"document_id":"doc","start_index":40,"end_index":60,"bold":true,"italic":true}' | format
```

**Solution**: Use non-overlapping ranges or combine formatting
