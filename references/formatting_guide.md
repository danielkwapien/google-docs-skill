# Google Docs Formatting Guide

Comprehensive guide to text formatting and document structure in Google Docs.

## Text Formatting Options

### Available Formatting Styles

**Bold**:
- Apply to emphasize important text
- Use for headings, keywords, warnings
- Makes text stand out in document

**Italic**:
- Apply for emphasis or titles
- Use for book/movie names, foreign words
- Softer emphasis than bold

**Underline**:
- Apply for additional emphasis
- Use sparingly (can conflict with links)
- Traditional emphasis style

### Combining Formatting

All formatting options are independent and can be combined:

```bash
# Bold only
echo '{"document_id":"abc","start_index":1,"end_index":10,"bold":true}' | format

# Bold + Italic
echo '{"document_id":"abc","start_index":1,"end_index":10,"bold":true,"italic":true}' | format

# Bold + Italic + Underline
echo '{"document_id":"abc","start_index":1,"end_index":10,"bold":true,"italic":true,"underline":true}' | format

# Remove formatting (set to false)
echo '{"document_id":"abc","start_index":1,"end_index":10,"bold":false}' | format
```

---

## Document Structure Best Practices

### Heading Hierarchy

**Level 1 (Heading 1)**:
- Document title or main sections
- Largest font size
- Use sparingly (typically 1-3 per document)
- Example: "Project Proposal", "Annual Report"

**Level 2 (Heading 2)**:
- Major sections within document
- Second largest font
- Primary organizational structure
- Example: "Introduction", "Methodology", "Results"

**Level 3 (Heading 3)**:
- Subsections within major sections
- Third level of hierarchy
- Supporting organization
- Example: "Background Research", "Data Collection Methods"

**Levels 4-6**:
- Additional nesting as needed
- Use for detailed breakdowns
- Maintain logical hierarchy
- Don't skip levels (H1 → H3 is poor structure)

### Heading Best Practices

1. **Consistent Numbering**:
   - Use numbered headings for formal documents
   - Example: "1. Introduction", "1.1 Background", "1.2 Objectives"

2. **Parallel Structure**:
   - Keep similar-level headings in same format
   - Example: All verbs or all nouns

3. **Descriptive Titles**:
   - Make headings self-explanatory
   - Avoid vague titles like "Other" or "Miscellaneous"

4. **Logical Flow**:
   - Order sections chronologically or by importance
   - Maintain clear progression of ideas

---

## Document Organization Patterns

### Report Structure
```
# Annual Report (H1)
## Executive Summary (H2)
## Financial Performance (H2)
### Revenue Analysis (H3)
### Expense Breakdown (H3)
## Future Outlook (H2)
### Q1 Projections (H3)
### Strategic Initiatives (H3)
```

### Proposal Structure
```
# Project Proposal (H1)
## Problem Statement (H2)
## Proposed Solution (H2)
### Technical Approach (H3)
### Timeline (H3)
### Budget (H3)
## Expected Outcomes (H2)
## Next Steps (H2)
```

### Meeting Notes Structure
```
# Meeting Notes - [Date] (H1)
## Attendees (H2)
## Agenda Items (H2)
### Budget Review (H3)
### Timeline Discussion (H3)
## Action Items (H2)
## Next Meeting (H2)
```

---

## Index Position Guidelines

### Understanding Indices

**Index System**:
- Google Docs uses character-based indices
- Index 1 = first character of document
- Each character (letters, spaces, newlines) has an index
- Formatting doesn't affect indices
- Indices shift when text is inserted or deleted

**Example Document**:
```
Hello World
Second line
```

Index positions:
- 1-5: "Hello"
- 6: " " (space)
- 7-11: "World"
- 12: "\n" (newline)
- 13-18: "Second"
- 19: " " (space)
- 20-23: "line"
- 24: "\n" (newline, if present)

### Calculating Indices

**Method 1: Character Count**
```python
# Manual counting
text = "Hello World\nSecond line"
# H=1, e=2, l=3, l=4, o=5, space=6, W=7, o=8, r=9, l=10, d=11, newline=12
# S=13, e=14, c=15, o=16, n=17, d=18, space=19, l=20, i=21, n=22, e=23
```

**Method 2: Use Structure Command**
```bash
# Get heading positions
scripts/docs_manager.rb structure abc123

# Output shows start_index and end_index for each heading
# Use these as reference points for nearby text
```

**Method 3: Read Document**
```bash
# Read document to see current content
scripts/docs_manager.rb read abc123

# Count characters to desired position
# Or use returned content for reference
```

### Common Index Scenarios

**Insert at Beginning**:
```bash
# Index 1 = very start of document
echo '{"document_id":"abc","text":"New start","index":1}' | insert
```

**Insert After Heading**:
```bash
# First get structure to find heading end
scripts/docs_manager.rb structure abc

# If heading ends at 50, insert at 51
echo '{"document_id":"abc","text":"Content","index":51}' | insert
```

**Format Title**:
```bash
# First 20 characters typically title
echo '{"document_id":"abc","start_index":1,"end_index":20,"bold":true}' | format
```

**Append to End**:
```bash
# No index calculation needed - use append
echo '{"document_id":"abc","text":"End content"}' | append
```

---

## Formatting Workflows

### Workflow 1: Format Document Title

```bash
# Step 1: Read to see title
scripts/docs_manager.rb read abc123

# Step 2: Calculate title length (assume "Project Proposal" = 16 chars)
# Index 1-16 for title

# Step 3: Apply bold formatting
echo '{
  "document_id": "abc123",
  "start_index": 1,
  "end_index": 16,
  "bold": true
}' | scripts/docs_manager.rb format
```

### Workflow 2: Format Multiple Headings

```bash
# Step 1: Get structure
scripts/docs_manager.rb structure abc123

# Output shows all headings with positions
# Example: {"level":1,"text":"Introduction","start_index":1,"end_index":13}

# Step 2: Format each heading
echo '{
  "document_id": "abc123",
  "start_index": 1,
  "end_index": 13,
  "bold": true
}' | scripts/docs_manager.rb format

# Repeat for other headings
```

### Workflow 3: Emphasize Keywords

```bash
# Step 1: Read document
scripts/docs_manager.rb read abc123

# Step 2: Find keyword positions manually or use replace
# Option A: Manual formatting
echo '{
  "document_id": "abc123",
  "start_index": 100,
  "end_index": 110,
  "bold": true
}' | scripts/docs_manager.rb format

# Option B: Replace with formatted text (not directly supported)
# Better to identify positions first, then format
```

---

## Style Guidelines

### Professional Documents

**Title Page**:
- Bold, large heading for title
- Regular text for subtitle/author
- Consider page break after title page

**Body Text**:
- Regular weight for main content
- Bold for section headings
- Italic for emphasis within paragraphs
- Underline sparingly (mainly for links)

**Emphasis Hierarchy**:
1. Bold = Strong emphasis
2. Italic = Moderate emphasis
3. Underline = Subtle emphasis

### Academic Documents

**Headings**:
- All headings bold
- Numbered sections (1, 1.1, 1.1.1)
- Consistent capitalization

**Citations**:
- Italic for book/journal titles
- Regular for article titles in quotes
- Use superscript for footnote references (not directly supported)

**Figures/Tables**:
- Bold for "Figure 1:" or "Table 1:"
- Regular for caption text

### Business Documents

**Executive Summary**:
- Bold heading
- Regular paragraphs
- Bold for key metrics or findings

**Action Items**:
- Bold for "Action Items" heading
- Regular bullet points
- Underline for deadlines/owners

**Emphasis**:
- Bold for critical information
- Italic for notes or asides
- Avoid underline (looks like links)

---

## Document Templates

### Meeting Minutes Template
```
# Meeting Minutes - [Date]
**Attendees**: [Names]
**Duration**: [Time]

## Agenda
1. [Topic 1]
2. [Topic 2]

## Discussion
*Notes here*

## Action Items
- [ ] **Owner**: Task description
```

### Project Proposal Template
```
# Project Proposal: [Title]

## Executive Summary
*Brief overview*

## Background
Regular text here

## Proposed Solution
**Key Feature 1**: Description
**Key Feature 2**: Description

## Timeline
*Detailed schedule*

## Budget
Regular text with **bold** for totals
```

### Report Template
```
# [Report Title]

## Summary
*Executive summary in italics*

## Section 1
Regular paragraphs

### Subsection 1.1
More detailed content

## Conclusions
**Key Finding 1**: Description
**Key Finding 2**: Description
```

---

## Advanced Formatting Techniques

### Creating Visual Hierarchy

**Method 1: Size through Headings**
```
Use heading styles (H1-H6) for size differentiation
Cannot set font size directly via API
Headings provide consistent sizing
```

**Method 2: Weight through Bold**
```bash
# Make important text bold
echo '{"document_id":"abc","start_index":1,"end_index":20,"bold":true}' | format
```

**Method 3: Style through Italic**
```bash
# Add emphasis with italic
echo '{"document_id":"abc","start_index":50,"end_index":70,"italic":true}' | format
```

### Formatting Patterns

**Pattern: Emphasis Stack**
```
Bold > Italic > Underline
Use bold for highest emphasis
Use italic for medium emphasis
Use underline sparingly
```

**Pattern: Information Hierarchy**
```
Heading 1 = Document title
Heading 2 = Major sections
Bold = Important within section
Italic = Emphasis within paragraph
Regular = Standard content
```

---

## Limitations and Workarounds

### Current Limitations

**Not Supported**:
- Font size changes (use headings instead)
- Font family changes (use Drive for templates)
- Text color changes
- Background color/highlighting
- Superscript/subscript
- Strikethrough
- Alignment (left/center/right)
- Line spacing
- Bulleted/numbered lists formatting

**Workarounds**:
- Use heading styles for size variation
- Pre-format template documents
- Use Drive API for advanced formatting
- Apply formatting in Google Docs UI manually

### Best Practices with Limitations

1. **Use What's Available**:
   - Maximize use of bold, italic, underline
   - Leverage heading hierarchy
   - Use page breaks for organization

2. **Template Approach**:
   - Create formatted template in Google Docs
   - Copy and modify via API
   - Preserve complex formatting

3. **Hybrid Workflow**:
   - Generate content via API
   - Apply advanced formatting in UI
   - Balance automation with manual touch

---

## Formatting Checklist

### Before Formatting
- [ ] Read document to understand current state
- [ ] Get structure to identify heading positions
- [ ] Plan formatting strategy
- [ ] Calculate index positions accurately

### During Formatting
- [ ] Apply bold to headings
- [ ] Emphasize key terms with bold/italic
- [ ] Check index calculations
- [ ] Verify no overlapping format requests

### After Formatting
- [ ] Read formatted document to verify
- [ ] Check heading hierarchy makes sense
- [ ] Ensure consistency throughout
- [ ] Consider additional organization (page breaks)

---

## Troubleshooting

### Issue: Formatting Wrong Text

**Cause**: Incorrect index calculation

**Solution**:
1. Read document to see current content
2. Manually count characters to target
3. Use structure command for reference points
4. Test with small range first

### Issue: Formatting Doesn't Apply

**Cause**: API error or index out of bounds

**Solution**:
1. Verify document ID is correct
2. Check start_index < end_index
3. Ensure indices within document length
4. Check for API error messages

### Issue: Lost Track of Positions

**Cause**: Multiple edits changed indices

**Solution**:
1. Read document again for fresh state
2. Recalculate from current content
3. Consider using replace for bulk changes
4. Apply all edits in single batch when possible
