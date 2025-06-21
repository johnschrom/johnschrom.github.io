#!/usr/bin/env ruby

# Improved script to generate PDF viewer pages with proper bibliographic information
# Parses the .bib file to get real titles, authors, and publication info

require 'fileutils'
require 'yaml'

# Configuration
PDF_DIR = 'assets/pdf'
PAGES_DIR = '_pages/papers'
BASE_URL = '/papers'
BIB_FILE = '_bibliography/papers.bib'

# Create the papers directory if it doesn't exist
FileUtils.mkdir_p(PAGES_DIR)

# Function to create a slug from filename
def create_slug(filename)
  File.basename(filename, '.pdf')
    .gsub(/[^a-zA-Z0-9\-]/, '-')
    .gsub(/-+/, '-')
    .gsub(/^-|-$/, '')
    .downcase
end

# Function to parse BibTeX file and extract entries
def parse_bibtex(bib_file)
  return {} unless File.exist?(bib_file)
  
  content = File.read(bib_file)
  entries = {}
  
  # Find all BibTeX entries
  content.scan(/@\w+\{([^,]+),.*?\n\}/m) do |match|
    key = match[0]
    entry_text = $&
    
    # Extract fields from this entry
    entry = { 'key' => key }
    
    # Extract title
    if entry_text =~ /title\s*=\s*\{([^}]+)\}/m
      entry['title'] = $1.strip.gsub(/\s+/, ' ')
    end
    
    # Extract authors
    if entry_text =~ /author\s*=\s*\{([^}]+)\}/m
      authors_raw = $1.strip.gsub(/\s+/, ' ')
      # Clean up author formatting and convert to "First Last" format
      authors = authors_raw.gsub(/\{|\}/, '').split(/ and /)
        .map do |author|
          # Remove asterisks and clean up
          clean_author = author.strip.gsub(/\*/, '')
          
          # Handle "Last, First" format
          if clean_author.include?(',')
            parts = clean_author.split(',').map(&:strip)
            "#{parts[1]} #{parts[0]}"
          else
            clean_author
          end
        end
        .join(', ')
      
      entry['authors'] = authors
    end
    
    # Extract journal/booktitle and abbr for type detection
    if entry_text =~ /journal\s*=\s*\{([^}]+)\}/m
      entry['venue'] = $1.strip
      entry['type'] = 'article'
    elsif entry_text =~ /booktitle\s*=\s*\{([^}]+)\}/m
      entry['venue'] = $1.strip
      entry['type'] = 'conference'
    end
    
    # Extract abbr field for document type
    if entry_text =~ /abbr\s*=\s*\{([^}]+)\}/m
      entry['abbr'] = $1.strip
    end
    
    # Extract year
    if entry_text =~ /year\s*=\s*\{?(\d{4})\}?/
      entry['year'] = $1
    end
    
    # Extract PDF/poster/slides fields
    ['pdf', 'poster', 'slides'].each do |field|
      if entry_text =~ /#{field}\s*=\s*\{([^}]+)\}/
        entry[field] = $1.strip
      end
    end
    
    # Extract abstract for description
    if entry_text =~ /abstract\s*=\s*\{([^}]+)\}/m
      abstract = $1.strip.gsub(/<[^>]+>/, '').gsub(/\s+/, ' ')
      entry['abstract'] = abstract[0..200] + (abstract.length > 200 ? '...' : '')
    end
    
    entries[key] = entry
  end
  
  entries
end

# Function to find matching bib entry for PDF
def find_bib_entry(pdf_path, bib_entries)
  pdf_filename = File.basename(pdf_path, '.pdf')
  
  # Try to match by key or by PDF/poster/slides field
  bib_entries.each do |key, entry|
    # Direct key match
    return entry if key == pdf_filename
    
    # Match by PDF field
    ['pdf', 'poster', 'slides'].each do |field|
      if entry[field]
        bib_filename = File.basename(entry[field], '.pdf')
        return entry if bib_filename == pdf_filename
      end
    end
  end
  
  nil
end

# Parse bibliography file
puts "Parsing bibliography file: #{BIB_FILE}"
bib_entries = parse_bibtex(BIB_FILE)
puts "Found #{bib_entries.keys.length} bibliography entries"

# Find all PDFs
pdf_files = Dir.glob("#{PDF_DIR}/**/*.pdf")
puts "Found #{pdf_files.length} PDF files"

pdf_files.each do |pdf_path|
  # Create slug
  relative_path = pdf_path.sub("#{PDF_DIR}/", '')
  slug = create_slug(pdf_path)
  
  # Find matching bibliography entry
  bib_entry = find_bib_entry(pdf_path, bib_entries)
  
  if bib_entry
    # Use bibliographic information
    title = bib_entry['title'] || 'Untitled Document'
    authors = bib_entry['authors'] || 'Unknown Authors'
    venue = bib_entry['venue'] || ''
    year = bib_entry['year'] || ''
    abstract = bib_entry['abstract'] || "View #{title}"
    
    # Determine document type from abbr field or filename
    # Abstract files should inherit the type from their base presentation
    doc_type = if bib_entry['abbr'] == 'poster' || relative_path.downcase.include?('poster')
                 'Poster'
               elsif bib_entry['abbr'] == 'oral' || bib_entry['abbr'] == 'slides' || relative_path.downcase.include?('slides')
                 'Slides'  
               elsif relative_path.downcase.include?('abstract')
                 # For abstract files, determine if they're from oral or poster presentations
                 if relative_path.downcase.include?('poster')
                   'Poster'
                 else
                   # Default abstracts to oral presentations unless explicitly poster
                   'Slides'
                 end
               elsif bib_entry['abbr'] == 'article' || bib_entry['type'] == 'article'
                 'Publication'
               else
                 'Publication'
               end
    
    page_title = title
    description = abstract
    
  else
    # Fallback to filename-based approach
    puts "  Warning: No bibliography entry found for #{relative_path}"
    
    # Clean up filename for title
    title = File.basename(pdf_path, '.pdf').gsub(/[-_]/, ' ').split(' ').map(&:capitalize).join(' ')
    authors = ''
    venue = ''
    year = ''
    doc_type = 'Document'
    
    page_title = title
    description = "View #{title}"
  end
  
  # Create page content
  front_matter = {
    'layout' => 'pdf-viewer',
    'title' => page_title,
    'permalink' => "#{BASE_URL}/#{slug}/",
    'pdf_url' => "/#{pdf_path}",
    'pdf_title' => page_title,
    'description' => description,
    'authors' => authors,
    'venue' => venue,
    'year' => year,
    'document_type' => doc_type,
    'nav' => false,
    'sitemap' => true
  }
  
  # Write the page file
  page_filename = "#{PAGES_DIR}/#{slug}.md"
  
  File.open(page_filename, 'w') do |file|
    file.write("---\n")
    file.write(front_matter.to_yaml.sub(/^---\n/, ''))
    file.write("---\n\n")
    file.write("<!-- Auto-generated PDF viewer page for #{relative_path} -->\n")
    file.write("<!-- Bibliography key: #{bib_entry ? bib_entry['key'] : 'not found'} -->\n")
  end
  
  puts "Created: #{page_filename} -> #{BASE_URL}/#{slug}/"
  puts "  Title: #{page_title}"
  puts "  Authors: #{authors[0..50]}#{authors.length > 50 ? '...' : ''}" if authors != ''
end

puts "\nGenerated #{pdf_files.length} PDF viewer pages in #{PAGES_DIR}/"
puts "Bibliography matches: #{pdf_files.count { |pdf| find_bib_entry(pdf, bib_entries) }}/#{pdf_files.length}"