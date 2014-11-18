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
  opt :type, "Type of input (e.g. #{VALID_TYPES.join(', ')})", :type => :string, :required => true, :short => "-t"
  opt :format, "Output format (e.g. tab, raw)", :default => CONFIG[:format], :short => "-f"
  opt :build, "Genomic build (e.g. hg19)", :default => CONFIG[:build], :short => "-b"
  opt :progress, "Show progress", :default => false, :short => "-p"
  opt :source, "Data source (e.g. hgmd, clinvar, dbsnp) (default: all sources)", :type => :string, :short => "-s"
  opt :preserve, "Preserve individual source files in addition to merged output file", :default => false, :short => "-r"
  opt :username, "MySQL username", :default => CONFIG[:username], :short => "-U"
  opt :password, "MySQL password", :default => CONFIG[:password], :short => "-P"
  opt :host, "MySQL host", :default => CONFIG[:host], :short => "-H"
  opt :database, "MySQL database", :default => CONFIG[:database], :short => "-D"
end

# Type of input list
TYPE = opts[:type]
if !VALID_TYPES.include?(TYPE)
  Error.fatal("#{TYPE} is not a valid type")
end

# Genome build version (e.g. hg18, hg19, etc.)
BUILD = opts[:build]
if opts[:build].match(/^hg[0-9]{1,2}$/).nil?
  Error.fatal("#{BUILD} is not a valid genome build")
end

# Data sources
if opts[:source].nil?
  SOURCES = VALID_SOURCES.keys
else
  SOURCES = opts[:source].split(',')
  SOURCES.each do |source|
    if !VALID_SOURCES.keys.include?(source)
      Error.fatal("#{source} is not a valid source")
    end
  end
end

# Output format and delimiter
FORMAT = opts[:format]
if !VALID_FORMATS.include?(FORMAT)
  Error.fatal("#{FORMAT} is not a valid format")
else
  DELIM = VALID_FORMATS[FORMAT]
end

# Database credentials
HOST     = opts[:host]
DATABASE = opts[:database]
USERNAME = opts[:username]
PASSWORD = opts[:password]

# Toggle progress reporting
PROGRESS = opts[:progress]

# Toggle preservation of temp files
PRESERVE_TEMP_FILES = opts[:preserve]

# Set input file
F_IN = opts[:in]

# Read in terms (i.e. genes, positions, regions, or variants) list
# This will remove empty lines and lines that start with #
TERMS = File.read(F_IN).split("\n").collect{|line| line.strip}.reject {|line| line =~ /^(#|$)/}
NUM_TERMS = TERMS.size
  
# Set merged output file
if !opts[:out].nil?
  MERGED_RESULTS_FILENAME = opts[:out]
else
  MERGED_RESULTS_FILENAME = File.join(File.dirname(F_IN), "#{File.basename(F_IN, '.*')}.#{CONFIG[:ext_out]}")
end

# Set merged output file
if !opts[:missing].nil?
  MISSING_FILENAME = opts[:missing]
else
  MISSING_FILENAME = File.join(File.dirname(F_IN), "#{File.basename(F_IN, '.*')}.#{CONFIG[:ext_missing]}")
end

# Keep track of all opened files
source_results_filenames = []

begin
  CLIENT = Mysql2::Client.new(:host     => HOST,
                              :database => DATABASE,
                              :username => USERNAME,
                              :password => PASSWORD)

  # Terms with no results
  F_MISSING = File.open(MISSING_FILENAME, 'w')

  puts "SEARCHING" if PROGRESS
  SOURCES.each_with_index do |source, source_num|
    # Set source output file
    source_results_filename = File.join(File.dirname(MERGED_RESULTS_FILENAME), "#{File.basename(MERGED_RESULTS_FILENAME, '.*')}.#{source}.#{CONFIG[:ext_out]}")
    source_results_filenames << source_results_filename
    f_source_results = File.open(source_results_filename, 'w')
    
    # Print column headers
    if source_num < 1 || FORMAT != 'raw'
      Print.source_header(source, f_source_results)
    end 
  
    # Query Genome Trax
    term_num = 1
    TERMS.each do |term|
      print "- Searching #{source.upcase} ".ljust(30, '.') + " #{TYPE.capitalize} #{term_num} of #{NUM_TERMS}\n" if PROGRESS
      if TYPE == 'gene'
        # Set gene regions reference file
        GENE_REFERENCE = File.join(GENES_DIR, "gene_regions_#{BUILD}.txt")
        Error.fatal("Gene region reference file does not exist at #{GENE_REFERENCE}") if !File.exist?(GENE_REFERENCE)
  
        # Query by gene
        results = Query.gene(term, source)
      elsif TYPE == 'region'
        # Query by chromosomal region
        term.prepend("chr") if term.match(/^chr/).nil? # Add 'chr' to front if missing
        results = Query.region(term, source)
      elsif TYPE == 'position'
        # Query by chromosomal position
        term.prepend("chr") if term.match(/^chr/).nil? # Add 'chr' to front if missing
        results = Query.position(term, source)
      elsif TYPE == 'variant'
        # Query by variant
        term.prepend("chr") if term.match(/^chr/).nil? # Add 'chr' to front if missing
        results,chr,pos,ref,alt = Query.variant(term, source)
      end
  
      if results.nil?
        # Not found
        Print.missing(term, F_MISSING, :source => source)
      else
        # Found
        if TYPE == 'variant'
          Print.source_results(results, f_source_results, :ref => ref, :alt => alt)
        else
          Print.source_results(results, f_source_results, :source => source)
        end
      end
      term_num += 1
    end # end querying terms
    f_source_results.close
  end # end SOURCES.each

rescue Mysql2::Error => e
  puts e.errno
  puts e.error
ensure
  CLIENT.close if CLIENT
  F_MISSING.close if F_MISSING
end

puts "FINALIZING RESULTS" if PROGRESS
Print.merged_results(source_results_filenames, MERGED_RESULTS_FILENAME)

# Cleanup temp files
if PRESERVE_TEMP_FILES
  if PROGRESS
    puts "- Individual source results written to:"
    source_results_filenames.each { |f| puts "\t#{f}" }
  end
else
  puts "- Cleaning up temporary files..." if PROGRESS
  source_results_filenames.each { |f| File.delete(f) }
end

# Cleanup empty missing files
if File.zero?(MISSING_FILENAME)
  File.delete(f)
  puts "- All input terms returned results" if PROGRESS
else
  puts "- Input terms with no results written to:\n\t#{MISSING_FILENAME.sub(/^\.\//, '')}" if PROGRESS
end

puts "- Final results written to:\n\t#{MERGED_RESULTS_FILENAME.sub(/^\.\//, '')}" if PROGRESS
puts " Done! ".center(20, '*') if PROGRESS
