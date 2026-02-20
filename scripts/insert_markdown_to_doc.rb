#!/usr/bin/env ruby
# frozen_string_literal: true

require 'google/apis/docs_v1'
require 'google/apis/drive_v3'
require 'googleauth'
require 'json'
require 'yaml'
require 'optparse'

TOKEN_PATH = File.expand_path('~/.claude/.google/token.json')
CLIENT_SECRET_PATH = File.expand_path('~/.claude/.google/client_secret.json')
RATE_LIMIT_SLEEP = 2.0
BATCH_SLICE_SIZE = 150

def build_credentials
  yaml_data = YAML.safe_load(File.read(TOKEN_PATH))
  token_data = JSON.parse(yaml_data['default'])
  secret_data = JSON.parse(File.read(CLIENT_SECRET_PATH))
  installed = secret_data['installed']

  Google::Auth::UserRefreshCredentials.new(
    client_id: installed['client_id'],
    client_secret: installed['client_secret'],
    scope: [
      'https://www.googleapis.com/auth/documents',
      'https://www.googleapis.com/auth/drive'
    ],
    access_token: token_data['access_token'],
    refresh_token: token_data['refresh_token'],
    expires_at: Time.at(token_data['expiration_time_millis'] / 1000)
  )
end

def init_services(creds)
  docs = Google::Apis::DocsV1::DocsService.new
  docs.authorization = creds
  drive = Google::Apis::DriveV3::DriveService.new
  drive.authorization = creds
  [docs, drive]
end

def get_end_index(docs, doc_id)
  doc = docs.get_document(doc_id)
  doc.body.content.last.end_index - 1
end

def batch_update(docs, doc_id, requests)
  return if requests.empty?
  requests.each_slice(BATCH_SLICE_SIZE) do |batch|
    docs.batch_update_document(
      doc_id,
      Google::Apis::DocsV1::BatchUpdateDocumentRequest.new(requests: batch)
    )
    sleep(RATE_LIMIT_SLEEP) if batch.length > 10
  end
end

def process_inline(line)
  result = ''
  formats = []
  pos = 0
  while pos < line.length
    if line[pos, 2] == '**'
      end_pos = line.index('**', pos + 2)
      if end_pos
        t = line[pos + 2...end_pos]
        s = result.length
        result += t
        formats << { type: :bold, start: s, end: s + t.length }
        pos = end_pos + 2
      else; result += line[pos]; pos += 1; end
    elsif line[pos] == '`' && line[pos + 1] != '`'
      end_pos = line.index('`', pos + 1)
      if end_pos
        t = line[pos + 1...end_pos]
        s = result.length
        result += t
        formats << { type: :code, start: s, end: s + t.length }
        pos = end_pos + 1
      else; result += line[pos]; pos += 1; end
    elsif line[pos] == '*' && line[pos + 1] != '*'
      end_pos = line.index('*', pos + 1)
      if end_pos && (end_pos + 1 >= line.length || line[end_pos + 1] != '*')
        t = line[pos + 1...end_pos]
        s = result.length
        result += t
        formats << { type: :italic, start: s, end: s + t.length }
        pos = end_pos + 1
      else; result += line[pos]; pos += 1; end
    else; result += line[pos]; pos += 1; end
  end
  [result, formats]
end

def parse_markdown(markdown)
  blocks = []
  lines = markdown.lines.map(&:rstrip)
  i = 0
  while i < lines.length
    line = lines[i]
    if    line.start_with?('#### '); blocks << { type: :heading, level: 4, text: line[5..] }
    elsif line.start_with?('### ');  blocks << { type: :heading, level: 3, text: line[4..] }
    elsif line.start_with?('## ');   blocks << { type: :heading, level: 2, text: line[3..] }
    elsif line.start_with?('# ');    blocks << { type: :heading, level: 1, text: line[2..] }
    elsif line.start_with?('```')
      lang = line[3..].strip
      i += 1
      code_lines = []
      while i < lines.length && !lines[i].start_with?('```')
        code_lines << lines[i]; i += 1
      end
      blocks << { type: :code_block, text: code_lines.join("\n"), lang: lang }
    elsif line.start_with?('|') && line.end_with?('|')
      rows = []
      while i < lines.length && lines[i].start_with?('|') && lines[i].end_with?('|')
        cells = lines[i][1..-2].split('|').map(&:strip)
        unless cells.all? { |c| c.match?(/^[-: ]+$/) }
          rows << cells.map { |c| process_inline(c)[0] }
        end
        i += 1
      end
      blocks << { type: :table, rows: rows } unless rows.empty?
      next
    elsif line == '---'; blocks << { type: :blank }
    elsif line.empty?;   blocks << { type: :blank }
    elsif line.match?(/^[-*] \[[ xX]\] /)
      plain, fmts = process_inline(line.sub(/^[-*] \[[ xX]\] /, ''))
      prefix = line.include?('[x]') || line.include?('[X]') ? '☑ ' : '☐ '
      blocks << { type: :paragraph, text: prefix + plain, formats: fmts.map { |f| { type: f[:type], start: f[:start] + prefix.length, end: f[:end] + prefix.length } } }
    elsif line.match?(/^[-*] /)
      plain, fmts = process_inline(line[2..])
      blocks << { type: :paragraph, text: '• ' + plain, formats: fmts.map { |f| { type: f[:type], start: f[:start] + 2, end: f[:end] + 2 } } }
    elsif line.match?(/^\d+\. /)
      m = line.match(/^(\d+\. )(.*)$/)
      prefix = m[1]; plain, fmts = process_inline(m[2])
      blocks << { type: :paragraph, text: prefix + plain, formats: fmts.map { |f| { type: f[:type], start: f[:start] + prefix.length, end: f[:end] + prefix.length } } }
    else
      plain, fmts = process_inline(line)
      blocks << { type: :paragraph, text: plain, formats: fmts }
    end
    i += 1
  end
  blocks
end

def preprocess_markdown(markdown, image_placeholder: '[Diagrama - ver imagen adjunta]')
  lines = markdown.lines
  result = []
  i = 0
  images = []
  while i < lines.length
    line = lines[i]
    if line.strip.start_with?('```mermaid')
      while i < lines.length && !lines[i].strip.start_with?('```') || i == lines.index { |l| l.strip.start_with?('```mermaid') }
        i += 1
      end
      i += 1 if i < lines.length
      result << "#{image_placeholder}\n"
      next
    elsif line.strip.match?(/^!\[.*\]\(.*\)$/)
      m = line.strip.match(/^!\[(.*)\]\((.*)\)$/)
      images << { alt: m[1], path: m[2], line: result.length }
      result << "#{image_placeholder}\n"
    else
      result << line
    end
    i += 1
  end
  { text: result.join, images: images }
end

def insert_text_segment(docs, doc_id, blocks_segment, insert_at, code_font: 'Consolas')
  text = ''
  headings = []
  bolds = []
  italics = []
  codes = []
  pos = 0

  blocks_segment.each do |block|
    case block[:type]
    when :heading
      t = block[:text] + "\n"
      level = case block[:level]
              when 1 then 'HEADING_1'; when 2 then 'HEADING_2'
              when 3 then 'HEADING_3'; else 'HEADING_4'; end
      headings << { style: level, start: pos, end: pos + t.length - 1 }
      text += t; pos += t.length
    when :paragraph
      t = block[:text] + "\n"
      (block[:formats] || []).each do |f|
        case f[:type]
        when :bold;   bolds   << { start: pos + f[:start], end: pos + f[:end] }
        when :italic; italics << { start: pos + f[:start], end: pos + f[:end] }
        when :code;   codes   << { start: pos + f[:start], end: pos + f[:end] }
        end
      end
      text += t; pos += t.length
    when :code_block
      t = block[:text] + "\n"
      codes << { start: pos, end: pos + t.length }
      text += t; pos += t.length
    when :blank
      text += "\n"; pos += 1
    end
  end

  return 0 if text.empty?

  batch_update(docs, doc_id, [{ insert_text: { location: { index: insert_at }, text: text } }])
  sleep(RATE_LIMIT_SLEEP)

  fmt_reqs = []
  headings.reverse.each do |h|
    fmt_reqs << { update_paragraph_style: {
      range: { start_index: insert_at + h[:start], end_index: insert_at + h[:end] },
      paragraph_style: { named_style_type: h[:style] }, fields: 'namedStyleType'
    } }
  end
  bolds.each do |b|
    next if b[:start] >= b[:end]
    fmt_reqs << { update_text_style: {
      range: { start_index: insert_at + b[:start], end_index: insert_at + b[:end] },
      text_style: { bold: true }, fields: 'bold'
    } }
  end
  italics.each do |it|
    next if it[:start] >= it[:end]
    fmt_reqs << { update_text_style: {
      range: { start_index: insert_at + it[:start], end_index: insert_at + it[:end] },
      text_style: { italic: true }, fields: 'italic'
    } }
  end
  codes.each do |c|
    next if c[:start] >= c[:end]
    fmt_reqs << { update_text_style: {
      range: { start_index: insert_at + c[:start], end_index: insert_at + c[:end] },
      text_style: { weighted_font_family: { font_family: code_font } },
      fields: 'weightedFontFamily'
    } }
  end
  batch_update(docs, doc_id, fmt_reqs) unless fmt_reqs.empty?
  sleep(RATE_LIMIT_SLEEP)

  text.length
end

def insert_table_at_end(docs, doc_id, rows, bold_header: true)
  return if rows.empty?
  num_rows = rows.length
  num_cols = rows.map(&:length).max
  insert_at = get_end_index(docs, doc_id)

  batch_update(docs, doc_id, [{ insert_table: {
    rows: num_rows, columns: num_cols, location: { index: insert_at }
  } }])
  sleep(3)

  doc = docs.get_document(doc_id)
  table_el = doc.body.content.find { |el| el.table && el.start_index >= insert_at }
  return unless table_el

  text_reqs = []
  rows.each_with_index do |row, ri|
    tr = table_el.table.table_rows[ri]; next unless tr
    row.each_with_index do |cell_text, ci|
      cell = tr.table_cells[ci]; next unless cell
      clean = cell_text.to_s.strip; next if clean.empty?
      text_reqs << { insert_text: { location: { index: cell.start_index + 1 }, text: clean } }
    end
  end
  batch_update(docs, doc_id, text_reqs.reverse)
  sleep(2)

  if bold_header
    doc2 = docs.get_document(doc_id)
    table2 = doc2.body.content.find { |el| el.table && el.start_index >= insert_at }
    if table2&.table&.table_rows&.first
      bold_reqs = table2.table.table_rows[0].table_cells.map do |cell|
        { update_text_style: {
          range: { start_index: cell.start_index + 1, end_index: cell.end_index - 1 },
          text_style: { bold: true }, fields: 'bold'
        } }
      end
      batch_update(docs, doc_id, bold_reqs)
    end
  end

  after_idx = get_end_index(docs, doc_id)
  batch_update(docs, doc_id, [{ insert_text: { location: { index: after_idx }, text: "\n" } }])
  sleep(1)
end

def insert_blocks(docs, doc_id, blocks, code_font: 'Consolas')
  segment = []
  blocks.each do |block|
    if block[:type] == :table
      unless segment.empty?
        insert_at = get_end_index(docs, doc_id)
        insert_text_segment(docs, doc_id, segment, insert_at, code_font: code_font)
        segment = []
        sleep(1)
      end
      $stderr.print "  [TABLE #{block[:rows].length}r] "
      insert_table_at_end(docs, doc_id, block[:rows])
    else
      segment << block
    end
  end
  unless segment.empty?
    insert_at = get_end_index(docs, doc_id)
    insert_text_segment(docs, doc_id, segment, insert_at, code_font: code_font)
  end
end

def upload_and_share(drive, local_path, filename)
  metadata = Google::Apis::DriveV3::File.new(name: filename)
  result = drive.create_file(metadata, upload_source: local_path, content_type: 'image/png', fields: 'id')
  drive.create_permission(result.id, Google::Apis::DriveV3::Permission.new(type: 'anyone', role: 'reader'), fields: 'id')
  "https://drive.google.com/uc?export=download&id=#{result.id}"
end

def insert_local_images(docs, drive, doc_id, images, base_dir)
  placeholder = '[Diagrama - ver imagen adjunta]'
  doc = docs.get_document(doc_id)
  placeholder_paras = []
  doc.body.content.each do |el|
    next unless el.paragraph
    text = el.paragraph.elements&.map { |pe| pe.text_run&.content.to_s }.join
    placeholder_paras << { start: el.start_index, end: el.end_index } if text.include?(placeholder)
  end

  images.each_with_index do |img, idx|
    next if idx >= placeholder_paras.length
    local_path = File.join(base_dir, img[:path])
    next unless File.exist?(local_path)

    $stderr.puts "  Uploading #{img[:path]}..."
    url = upload_and_share(drive, local_path, File.basename(img[:path]))
    sleep(1)
  end

  uploaded_urls = images.filter_map.with_index do |img, idx|
    local_path = File.join(base_dir, img[:path])
    next unless File.exist?(local_path)
    upload_and_share(drive, local_path, File.basename(img[:path]))
  end

  pairs = placeholder_paras.first(uploaded_urls.length).zip(uploaded_urls)
  pairs.reverse.each do |para, url|
    docs.batch_update_document(doc_id,
      Google::Apis::DocsV1::BatchUpdateDocumentRequest.new(requests: [
        { delete_content_range: { range: { start_index: para[:start], end_index: para[:end] } } }
      ]))
    sleep(1.5)
    docs.batch_update_document(doc_id,
      Google::Apis::DocsV1::BatchUpdateDocumentRequest.new(requests: [
        { insert_inline_image: {
          location: { index: para[:start] }, uri: url,
          object_size: { height: { magnitude: 280, unit: 'PT' }, width: { magnitude: 440, unit: 'PT' } }
        } }
      ]))
    sleep(2)
  end
end

def split_into_chunks(text, max_bytes: 20_000)
  lines = text.lines
  chunks = []
  current = ''
  lines.each do |line|
    if current.bytesize + line.bytesize > max_bytes && !current.empty?
      chunks << current
      current = ''
    end
    current += line
  end
  chunks << current unless current.empty?
  chunks
end

if __FILE__ == $PROGRAM_NAME
  options = { code_font: 'Consolas', insert_images: false, start_index: nil, chunk_size: 20_000 }

  OptionParser.new do |opts|
    opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options] <document_id> <markdown_file>"
    opts.on('--code-font FONT', "Font for code blocks/inline code (default: Consolas)") { |v| options[:code_font] = v }
    opts.on('--start-index INDEX', Integer, "Insert after this index (preserves content before it)") { |v| options[:start_index] = v }
    opts.on('--insert-images', "Upload local images to Drive and insert them") { options[:insert_images] = true }
    opts.on('--image-base-dir DIR', "Base directory for resolving image paths") { |v| options[:image_base_dir] = v }
    opts.on('--chunk-size BYTES', Integer, "Max bytes per chunk (default: 20000)") { |v| options[:chunk_size] = v }
    opts.on('--clear-after INDEX', Integer, "Delete all content after this index before inserting") { |v| options[:clear_after] = v }
    opts.on('-h', '--help', 'Show help') { puts opts; exit }
  end.parse!

  if ARGV.length < 2
    $stderr.puts "Usage: #{File.basename($PROGRAM_NAME)} [options] <document_id> <markdown_file>"
    $stderr.puts "Run with --help for options"
    exit 1
  end

  doc_id = ARGV[0]
  markdown_file = ARGV[1]
  markdown = File.read(markdown_file)

  creds = build_credentials
  docs, drive = init_services(creds)

  preprocessed = preprocess_markdown(markdown)
  $stderr.puts "Preprocessed: #{preprocessed[:images].length} images found"

  if options[:clear_after]
    end_idx = get_end_index(docs, doc_id)
    if end_idx > options[:clear_after]
      $stderr.puts "Clearing content from index #{options[:clear_after]} to #{end_idx}..."
      batch_update(docs, doc_id, [{ delete_content_range: {
        range: { start_index: options[:clear_after], end_index: end_idx }
      } }])
      sleep(2)
    end
  end

  chunks = split_into_chunks(preprocessed[:text], max_bytes: options[:chunk_size])
  $stderr.puts "Split into #{chunks.length} chunks"

  chunks.each_with_index do |chunk, idx|
    blocks = parse_markdown(chunk)
    tc = blocks.count { |b| b[:type] == :table }
    cc = blocks.count { |b| b[:type] == :code_block }
    $stderr.puts "\nChunk #{idx + 1}/#{chunks.length} (#{blocks.length} blocks, #{tc} tables, #{cc} code)"

    begin
      insert_blocks(docs, doc_id, blocks, code_font: options[:code_font])
      $stderr.puts "  Done."
      sleep(3)
    rescue Google::Apis::ClientError => e
      $stderr.puts "  API ERROR: #{e.message}"
      sleep(10)
    rescue StandardError => e
      $stderr.puts "  ERROR: #{e.message}"
      sleep(10)
    end
  end

  if options[:insert_images] && preprocessed[:images].any?
    base_dir = options[:image_base_dir] || File.dirname(markdown_file)
    $stderr.puts "\nInserting #{preprocessed[:images].length} images..."
    insert_local_images(docs, drive, doc_id, preprocessed[:images], base_dir)
  end

  final_idx = get_end_index(docs, doc_id)
  puts JSON.pretty_generate({
    status: 'success',
    operation: 'insert_markdown_to_doc',
    document_id: doc_id,
    chunks_processed: chunks.length,
    images_found: preprocessed[:images].length,
    end_index: final_idx
  })
end
