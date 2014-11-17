##
# *** Genome Snax ***
# An easier way to query Genome Trax by
#   - genes
#   - chromosomal regions
#   - chromosomal positions
#   - variants
#
# @author Sean Ephraim
##

require_relative File.join('lib', 'bootstrap.rb')

opts = Trollop::options do
  opt :in, "Path to input file", :type => :string, :required => true, :short => "-i"
  opt :out, "Path to annotation output file (default: [INFILE].[SOURCE].#{CONFIG[:ext_missing]})", :type => :string, :short => "-o"
  opt :missing, "Path to missing log file (default: [OUTFILE].[SOURCE].#{CONFIG[:ext_out]})", :type => :string, :short => "-m"
  opt :type, "Type of input (e.g. gene, region, position, variant)", :type => :string, :required => true, :short => "-t"
  opt :format, "Output format (e.g. tab, raw)", :default => CONFIG[:format], :short => "-f"
  opt :build, "Genomic build (e.g. hg19)", :default => CONFIG[:build], :short => "-b"
  opt :progress, "Show progress", :default => false, :short => "-p"
  opt :source, "Data source (e.g. hgmd, clinvar, dbsnp)", :type => :string, :required => true, :short => "-s"
  opt :username, "MySQL username", :default => CONFIG[:username], :short => "-U"
  opt :password, "MySQL password", :default => CONFIG[:password], :short => "-P"
  opt :host, "MySQL host", :default => CONFIG[:host], :short => "-H"
  opt :database, "MySQL database", :default => CONFIG[:database], :short => "-D"
end

# Type of input list
TYPE = opts[:type]
if !ACCEPTED_TYPES.include?(TYPE)
  Error.fatal("#{TYPE} is not a valid type")
end

# Genome build version (e.g. hg18, hg19, etc.)
BUILD = opts[:build]
if opts[:build].match(/^hg[0-9]{1,2}$/).nil?
  Error.fatal("#{BUILD} is not a valid genome build")
end

# Data source
SOURCES = opts[:source].split(',')
SOURCES.each do |source|
  if !ACCEPTED_SOURCES.keys.include?(source)
    Error.fatal("#{source} is not a valid source")
  end
end

# Output format and delimiter
FORMAT = opts[:format]
if !ACCEPTED_FORMATS.include?(FORMAT)
  Error.fatal("#{FORMAT} is not a valid format")
else
  DELIM = ACCEPTED_FORMATS[FORMAT]
end

# Database credentials
HOST     = opts[:host]
DATABASE = opts[:database]
USERNAME = opts[:username]
PASSWORD = opts[:password]

# Toggle progress reporting
PROGRESS = opts[:progress]

# Set input file
F_IN = opts[:in]

# Read in terms (i.e. genes, positions, regions, or variants) list
TERMS = File.read(F_IN).split("\n").collect{|line| line.strip.chomp}
NUM_TERMS = TERMS.size
  
# Set merged output file
if !opts[:out].nil?
  MERGED_RESULTS_FILENAME = opts[:out]
else
  MERGED_RESULTS_FILENAME = "#{File.dirname(F_IN)}/#{File.basename(F_IN, '.*')}.#{CONFIG[:ext_out]}"
end
#F_MERGED_RESULTS = File.open(MERGED_RESULTS_FILENAME, 'w')

# Temporary index file used for merging results
MERGED_INDEX_FILENAME = MERGED_RESULTS_FILENAME + ".temp_index"


# Keep track of all opened files
source_results_filenames = []
source_missing_filenames = []

begin
  CLIENT = Mysql2::Client.new(:host     => HOST,
                              :database => DATABASE,
                              :username => USERNAME,
                              :password => PASSWORD)

  SOURCES.each_with_index do |source, source_num|
    # Set source output file
    source_results_filename = "#{File.dirname(F_IN)}/#{File.basename(F_IN, '.*')}.#{source}.#{CONFIG[:ext_out]}"
    source_results_filenames << source_results_filename
    f_source_results = File.open(source_results_filename, 'w')
    
    # Set source errors file
    source_missing_filename = "#{File.dirname(F_IN)}/#{File.basename(F_IN, '.*')}.#{source}.#{CONFIG[:ext_missing]}"
    source_missing_filenames << source_missing_filename
    f_source_missing = File.open(source_missing_filename, 'w')

    # Print column headers
    if source_num < 1 || FORMAT != 'raw'
      Print.header(source, f_source_results)
    end 
  
    # Query Genome Trax
    TERMS.each_with_index do |term, term_num|
      next if !term.strip.match(/^(#|$)/).nil? # Skip lines that start with # and empty lines
  
      if TYPE == 'gene'
        # Set gene regions reference file
        GENE_REFERENCE = File.join(GENES_DIR, "gene_regions_#{BUILD}.txt")
        Error.fatal("Gene region reference file does not exist at #{GENE_REFERENCE}") if !File.exist?(GENE_REFERENCE)
  
        # Query by gene
        puts "Searching #{source}; Gene #{term_num+1} of #{NUM_TERMS}" if PROGRESS
        results = Query.gene(term, source)
      elsif TYPE == 'region'
        # Query by chromosome region
        puts "Searching #{source}; Region #{term_num+1} of #{NUM_TERMS}" if PROGRESS
        term.prepend("chr") if term.match(/^chr/).nil? # Add 'chr' to front if missing
        results = Query.region(term, source)
      elsif TYPE == 'position'
        # Query by position
        puts "Searching #{source}; Position #{term_num+1} of #{NUM_TERMS}" if PROGRESS
        term.prepend("chr") if term.match(/^chr/).nil? # Add 'chr' to front if missing
        results = Query.position(term, source)
      elsif TYPE == 'variant'
        # Query by variant
        puts "Searching #{source}; Variant #{term_num+1} of #{NUM_TERMS}" if PROGRESS
        term.prepend("chr") if term.match(/^chr/).nil? # Add 'chr' to front if missing
        results,chr,pos,ref,alt = Query.variant(term, source)
      end
  
      if results.nil?
        # Not found
        Print.missing(term, f_source_missing)
      else
        # Found
        if TYPE == 'variant'
          Print.results(results, f_source_results, :ref => ref, :alt => alt)
        else
          Print.results(results, f_source_results, :source => source)
        end
      end
    end # end querying terms
    f_source_results.close
    f_source_missing.close
  end # end SOURCES.each

rescue Mysql2::Error => e
  puts e.errno
  puts e.error
ensure
  CLIENT.close if CLIENT
end

# Merge results
puts "Finalize results..." if PROGRESS
if FORMAT == 'raw'
  source_results_filenames.each_with_index do |filename, file_num|
    if file_num < 1
      # Copy all source results (including header) into merged file
      `cp -f #{filename} #{MERGED_RESULTS_FILENAME}`
    else
      # Copy all source results (excluding header) into merged file
      `tail -n +2 #{filename} >> #{MERGED_RESULTS_FILENAME}`
    end
  end
else
  # Create temporary index file of all variants
  puts "Creating index file to merge results..." if PROGRESS
  `tail -q -n +2 #{source_results_filenames.join(' ')} | cut -f2-6 | sort -u > #{MERGED_INDEX_FILENAME}`

  # Merge headers
  header = ""
  num_description_fields = {}
  source_results_filenames.each_with_index do |filename, file_num|
    result = `head -1 #{filename}`.chomp.split(DELIM)

    # Delete last element (ngs_ontology_no)
    result.pop

    # Delete unnecessary columns and find out how many description columns there are
    if file_num < 1
      num_description_fields[filename] = result.drop(DESCRIPTION_COLUMN_NUM-1).length
      # Delete first column (Genome Trax unique ID)
      result.shift
      result.slice!(5..8)
    else
      # Delete all columns that have already been printed
      result.shift(DESCRIPTION_COLUMN_NUM-1)
      num_description_fields[filename] = result.length
    end

    header += result.join(DELIM) + DELIM
  end
  header.strip!
  F_MERGED_RESULTS = File.open(MERGED_RESULTS_FILENAME, 'w')
  F_MERGED_RESULTS.puts header

  # Merge results
  File.open(MERGED_INDEX_FILENAME).each_line do |variant|
    variant.strip!
    row = variant+DELIM
    source_results_filenames.each do |filename|
      result = `grep '#{DELIM+variant+DELIM}' #{filename} | cut -f#{DESCRIPTION_COLUMN_NUM}-#{DESCRIPTION_COLUMN_NUM+num_description_fields[filename]-1}`.strip
      if result.empty?
        # Add N-number of EMPTY_VALUE placholders
        num_description_fields[filename].times { row += (EMPTY_VALUE+DELIM) }
      else
        if result.include?("\n")
          # Combine multiple results
          combined_values = []
          result.each_line do |line|
            line.strip!
            i = 0
            line.split(DELIM).each do |value|
              if combined_values[i].nil?
                combined_values[i] = value
              else
                combined_values[i] += ";#{value}"
              end
              i += 1
            end
          end
          row += combined_values.join(DELIM)+DELIM
        else
          # Handle singe result
          row += result+DELIM
        end
      end
    end
    row.strip!
    F_MERGED_RESULTS.puts row
  end
end
F_MERGED_RESULTS.close

# Cleanup temp files
puts "Cleaning up temporary files..." if PROGRESS
File.delete(MERGED_INDEX_FILENAME)
source_results_filenames.each do |filename|
  File.delete(filename)
end

puts "Final results written to #{MERGED_RESULTS_FILENAME}" if PROGRESS
puts "***** Done! *****" if PROGRESS
