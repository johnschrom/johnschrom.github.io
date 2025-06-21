#!/usr/bin/env ruby

# Script to generate individual PDF viewer pages for each PDF in assets/pdf/
# This creates SEO-friendly URLs like /papers/paper-title/ instead of GET parameters

require 'fileutils'
require 'yaml'

# Configuration
PDF_DIR = 'assets/pdf'
PAGES_DIR = '_pages/papers'
BASE_URL = '/papers'

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

# Function to create a nice title from filename
def create_title(filename)
  basename = File.basename(filename, '.pdf')
  
  # Try to parse author-year-title format
  if basename.match(/^([a-z]+)(\d{4})(.+)$/)
    author = $1.capitalize
    year = $2
    title_part = $3.gsub(/[-_]/, ' ').split(' ').map(&:capitalize).join(' ')
    
    # Determine document type
    type = case title_part.downcase
           when /poster/
             'Poster'
           when /slides/
             'Slides'
           when /abstract/
             'Abstract'
           else
             'Paper'
           end
    
    "#{author} et al. (#{year}) - #{title_part}"
  else
    # Fallback: just clean up the filename
    basename.gsub(/[-_]/, ' ').split(' ').map(&:capitalize).join(' ')
  end
end

# Find all PDFs
pdf_files = Dir.glob("#{PDF_DIR}/**/*.pdf")

puts "Found #{pdf_files.length} PDF files"

pdf_files.each do |pdf_path|
  # Create slug and title
  relative_path = pdf_path.sub("#{PDF_DIR}/", '')
  slug = create_slug(pdf_path)
  title = create_title(pdf_path)
  
  # Determine document type and create appropriate description
  type = case relative_path.downcase
         when /poster/
           'poster'
         when /slides/
           'slides'  
         when /abstract/
           'abstract'
         else
           'publication'
         end
  
  # Create page content
  front_matter = {
    'layout' => 'pdf-viewer',
    'title' => title,
    'permalink' => "#{BASE_URL}/#{slug}/",
    'pdf_url' => "/#{pdf_path}",
    'pdf_title' => title,
    'description' => "View #{title}",
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
  end
  
  puts "Created: #{page_filename} -> #{BASE_URL}/#{slug}/"
end

puts "\nGenerated #{pdf_files.length} PDF viewer pages in #{PAGES_DIR}/"
puts "URLs will be like: #{BASE_URL}/schrom2023field/"