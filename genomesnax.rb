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
  opt :noheader, "Don't include header in output file", :default => false, :short => "-n"
  opt :username, "MySQL username", :default => CONFIG[:username], :short => "-U"
  opt :password, "MySQL password", :default => CONFIG[:password], :short => "-P"
  opt :host, "MySQL host", :default => CONFIG[:host], :short => "-H"
  opt :database, "MySQL database", :default => CONFIG[:database], :short => "-D"
end

# Type of input list
TYPE  = opts[:type]
if !ACCEPTED_TYPES.include?(TYPE)
  Error.fatal("#{TYPE} is not a valid type")
end

# Genome build version (e.g. hg18, hg19, etc.)
BUILD = opts[:build]
if opts[:build].match(/^hg[1-9]{1,2}$/).nil?
  Error.fatal("#{BUILD} is not a valid genome build")
end

# Data source
SOURCE = opts[:source]
if !ACCEPTED_SOURCES.keys.include?(SOURCE)
  Error.fatal("#{SOURCE} is not a valid source")
end

# Output format and delimiter
FORMAT = opts[:format]
if !ACCEPTED_FORMATS.include?(FORMAT)
  Error.fatal("#{FORMAT} is not a valid format")
else
  DELIM = ACCEPTED_FORMATS[FORMAT]
end

# Database credentials
HOST = opts[:host]
DATABASE = opts[:database]
USERNAME = opts[:username]
PASSWORD = opts[:password]

# Toggle progress reporting
PROGRESS = opts[:progress]

# Set input file
F_IN = opts[:in]

# Set output file
if !opts[:out].nil?
  RESULTS_FILENAME = opts[:out]
else
  RESULTS_FILENAME = "#{File.dirname(F_IN)}/#{File.basename(F_IN, '.*')}.#{SOURCE}.#{CONFIG[:ext_out]}"
end
F_RESULTS = File.open(RESULTS_FILENAME, 'w')

# Set errors file
if !opts[:missing].nil?
  MISSING_FILENAME = opts[:missing]
else
  MISSING_FILENAME = "#{File.dirname(F_IN)}/#{File.basename(F_IN, '.*')}.#{SOURCE}.#{CONFIG[:ext_missing]}"
end
F_MISSING = File.open(MISSING_FILENAME, 'w')

begin
  CLIENT = Mysql2::Client.new(:host     => HOST,
                              :database => DATABASE,
                              :username => USERNAME,
                              :password => PASSWORD)

  # Print column headers
  if !opts[:noheader]
    Print.header(SOURCE)
  end

  # Read in terms (i.e. genes, positions, or variants) list
  terms = File.read(F_IN).split("\n").collect{|line| line.strip.chomp}
  num_terms = terms.size

  # Query Genome Trax
  terms.each_with_index do |term, index|
    next if !term.match(/^#/).nil? # Skip lines that start with #

    if TYPE == 'gene'
      # Set gene regions reference file
      GENE_REFERENCE = File.join(GENES_DIR, "gene_regions_#{BUILD}.txt")
      Error.fatal("Gene region reference file does not exist at #{GENE_REFERENCE}") if !File.exist?(GENE_REFERENCE)

      # Query by gene
      puts "Gene #{index+1} of #{num_terms}" if PROGRESS
      results = Query.gene(term, SOURCE)
    elsif TYPE == 'region'
      # Query by chromosome region
      puts "Region #{index+1} of #{num_terms}" if PROGRESS
      term.prepend("chr") if term.match(/^chr/).nil? # Add 'chr' to front if missing
      results = Query.region(term, SOURCE)
    elsif TYPE == 'position'
      # Query by position
      puts "Position #{index+1} of #{num_terms}" if PROGRESS
      term.prepend("chr") if term.match(/^chr/).nil? # Add 'chr' to front if missing
      results = Query.position(term, SOURCE)
    elsif TYPE == 'variant'
      # Query by variant
      puts "Variant #{index+1} of #{num_terms}" if PROGRESS
      term.prepend("chr") if term.match(/^chr/).nil? # Add 'chr' to front if missing
      results = Query.variant(term, SOURCE)
    end

    if results.nil?
      # Not found
      Print.missing(term)
    else
      # Found
      Print.results(results)
    end
  end # end querying terms

rescue Mysql2::Error => e
  puts e.errno
  puts e.error
ensure
  CLIENT.close if CLIENT
end

F_RESULTS.close
F_MISSING.close
