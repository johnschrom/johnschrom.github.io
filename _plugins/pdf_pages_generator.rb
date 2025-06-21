# Jekyll plugin to automatically generate PDF viewer pages
# Runs during site generation and creates pages for any PDFs in assets/pdf/

require 'fileutils'
require 'yaml'
require 'digest'

module Jekyll
  class PdfPagesGenerator < Generator
    safe true
    priority :high

    # Configuration
    PDF_DIR = 'assets/pdf'
    PAGES_DIR = '_pages/papers'
    BASE_URL = '/papers'
    BIB_FILE = '_bibliography/papers.bib'
    CACHE_FILE = '.pdf_pages_cache'

    def generate(site)
      Jekyll.logger.info "PDF Pages:", "Plugin starting..."
      
      unless File.directory?(PDF_DIR)
        Jekyll.logger.warn "PDF Pages:", "PDF directory '#{PDF_DIR}' not found"
        return
      end
      
      Jekyll.logger.info "PDF Pages:", "PDF directory found"
      
      # For GitHub Actions, always regenerate (no cache file access)
      if ENV['GITHUB_ACTIONS']
        Jekyll.logger.info "PDF Pages:", "Running in GitHub Actions, forcing regeneration"
      elsif needs_regeneration?
        Jekyll.logger.info "PDF Pages:", "Regeneration needed (cache miss)"
      else
        Jekyll.logger.info "PDF Pages:", "No regeneration needed, skipping"
        return
      end
      
      Jekyll.logger.info "PDF Pages:", "Generating PDF viewer pages..."
      
      # Create the papers directory if it doesn't exist
      FileUtils.mkdir_p(PAGES_DIR)
      
      # Parse bibliography file
      bib_entries = parse_bibtex(BIB_FILE)
      Jekyll.logger.info "PDF Pages:", "Found #{bib_entries.keys.length} bibliography entries"
      
      # Find all PDFs
      pdf_files = Dir.glob("#{PDF_DIR}/**/*.pdf")
      Jekyll.logger.info "PDF Pages:", "Found #{pdf_files.length} PDF files"
      
      generated_files = []
      
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
          doc_type = determine_document_type(bib_entry, relative_path)
          
          page_title = title
          description = abstract
          
        else
          # Fallback to filename-based approach
          Jekyll.logger.warn "PDF Pages:", "No bibliography entry found for #{relative_path}"
          
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
        generated_files << page_filename
        
        File.open(page_filename, 'w') do |file|
          file.write("---\n")
          file.write(front_matter.to_yaml.sub(/^---\n/, ''))
          file.write("---\n\n")
          file.write("<!-- Auto-generated PDF viewer page for #{relative_path} -->\n")
          file.write("<!-- Bibliography key: #{bib_entry ? bib_entry['key'] : 'not found'} -->\n")
        end
      end
      
      # Clean up old generated files
      cleanup_old_files(generated_files)
      
      # Update cache (skip in GitHub Actions)
      update_cache unless ENV['GITHUB_ACTIONS']
      
      Jekyll.logger.info "PDF Pages:", "Successfully generated #{pdf_files.length} PDF viewer pages"
      Jekyll.logger.info "PDF Pages:", "Bibliography matches: #{pdf_files.count { |pdf| find_bib_entry(pdf, bib_entries) }}/#{pdf_files.length}"
      Jekyll.logger.info "PDF Pages:", "Files created in: #{PAGES_DIR}"
    end

    private

    def needs_regeneration?
      return true unless File.exist?(CACHE_FILE)
      
      cache_data = YAML.load_file(CACHE_FILE) rescue {}
      
      # Check if PDF directory or bib file changed
      current_hash = generate_content_hash
      cache_data['content_hash'] != current_hash
    end

    def generate_content_hash
      content = ""
      
      # Hash PDF files
      if Dir.exist?(PDF_DIR)
        Dir.glob("#{PDF_DIR}/**/*.pdf").sort.each do |file|
          content += "#{file}:#{File.mtime(file).to_i}"
        end
      end
      
      # Hash bib file
      if File.exist?(BIB_FILE)
        content += "#{BIB_FILE}:#{File.mtime(BIB_FILE).to_i}"
      end
      
      Digest::MD5.hexdigest(content)
    end

    def update_cache
      cache_data = {
        'content_hash' => generate_content_hash,
        'last_updated' => Time.now.to_s
      }
      
      File.write(CACHE_FILE, cache_data.to_yaml)
    end

    def cleanup_old_files(current_files)
      return unless Dir.exist?(PAGES_DIR)
      
      # Find all existing generated files
      existing_files = Dir.glob("#{PAGES_DIR}/*.md").select do |file|
        content = File.read(file)
        content.include?("<!-- Auto-generated PDF viewer page")
      end
      
      # Remove files that are no longer needed
      (existing_files - current_files).each do |file|
        File.delete(file)
        Jekyll.logger.info "PDF Pages:", "Removed obsolete file: #{file}"
      end
    end

    def create_slug(filename)
      File.basename(filename, '.pdf')
        .gsub(/[^a-zA-Z0-9\-]/, '-')
        .gsub(/-+/, '-')
        .gsub(/^-|-$/, '')
        .downcase
    end

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
        
        # Extract authors and convert to "First Last" format
        if entry_text =~ /author\s*=\s*\{([^}]+)\}/m
          authors_raw = $1.strip.gsub(/\s+/, ' ')
          authors = authors_raw.gsub(/\{|\}/, '').split(/ and /)
            .map do |author|
              clean_author = author.strip.gsub(/\*/, '')
              
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

    def determine_document_type(bib_entry, relative_path)
      # Abstract files should inherit the type from their base presentation
      if bib_entry['abbr'] == 'poster' || relative_path.downcase.include?('poster')
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
    end
  end
end