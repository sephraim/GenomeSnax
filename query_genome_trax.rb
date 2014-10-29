#!/usr/bin/ruby

##
# Remotely access and query the Genome Trax database
##

require_relative File.join('lib', 'bootstrap.rb')

EXT_OUT = 'hgmd.out'
EXT_MISSING = 'hgmd.missing'

opts = Trollop::options do
  opt :in, "Path to input file", :type => :string, :short => "-i"
  opt :out, "Path to annotation output file (default: [INFILE].#{EXT_OUT})", :type => :string, :short => "-o"
  opt :missing, "Path to missing log file (default: [OUTFILE].#{EXT_MISSING})", :type => :string, :short => "-m"
  opt :type, "Type of input (e.g. gene, position, variant)", :default => "gene", :short => "-t"
  opt :build, "Genomic build (e.g. hg18, hg19, hg20", :default => "hg19", :short => "-b"
  opt :progress, "Show progress", :default => false, :short => "-p"
  opt :source, "Data source (hgmd, dbsnp, clinvar)", :default => 6, :short => "-N"
  opt :noheader, "Don't include header in output file", :default => false, :short => "-n"
  opt :username, "MySQL username", :default => "hgmd", :short => "-U"
  opt :password, "MySQL password", :default => "*gaattc#", :short => "-P"
  opt :host, "MySQL host", :default => "crick.healthcare.uiowa.edu", :short => "-H"
  opt :database, "MySQL database", :default => "genometrax2014r1", :short => "-D"
end

# Type of input list
# Options are:
# - gene
# - position
# - variant
TYPE  = opts[:type]
if !['gene', 'position', 'variant'].include?(TYPE)
  Error.fatal("#{TYPE} is not a valid type")
end

# Type of genome build (e.g. hg18, hg19, etc.)
BUILD = opts[:build]
if opts[:build].match(/^hg[1-9]{1,2}$/).nil?
  Error.fatal("#{BUILD} is not a valid genome build")
end

# NGS ontology number
if opts[:source] == 'hgmd'
  NGS_ONT_NUM = 6
elsif opts[:source] == 'clinvar'
  NGS_ONT_NUM = 32
elsif opts[:source] == 'dbsnp'
  NGS_ONT_NUM = 33
elsif opts[:source] == 'evs'
  NGS_ONT_NUM = 33
elsif opts[:source] == '1kg'
  NGS_ONT_NUM = 37
  NGS_ONT_NUM = 38
  NGS_ONT_NUM = 39
else
  Error.fatal("#{opts[:source]} is not a valid source")
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
  RESULTS_FILENAME = "#{File.dirname(F_IN)}/#{File.basename(F_IN, '.*')}.#{EXT_OUT}"
end
F_RESULTS = File.open(RESULTS_FILENAME, 'w')

# Set errors file
if !opts[:missing].nil?
  MISSING_FILENAME = opts[:missing]
else
  MISSING_FILENAME = "#{File.dirname(F_IN)}/#{File.basename(F_IN, '.*')}.#{EXT_MISSING}"
end
F_MISSING = File.open(MISSING_FILENAME, 'w')

begin
  client = Mysql2::Client.new(:host     => HOST,
                              :database => DATABASE,
                              :username => USERNAME,
                              :password => PASSWORD)

  # Print column headers
  if !opts[:noheader]
    results = client.query("SELECT * FROM ngs_feature LIMIT 1")
    results.each do |row|
      row.each_key {|key| F_RESULTS.print "#{key}\t"}
      F_RESULTS.puts
    end
  end

  # Read in terms (i.e. genes, positions, or variants) list
  terms = File.read(F_IN).split("\n").collect{|line| line.strip.chomp}
  num_terms = terms.size

  # Query Genome Trax
  terms.each_with_index do |term, index|

    # Query for genes
    if TYPE == 'gene' || TYPE == 'position'
      if TYPE == 'gene'
        puts "Gene #{index+1} of #{num_terms}" if PROGRESS
        results = client.query("SELECT * FROM ngs_feature WHERE description LIKE '%;hgnc|#{term};%' AND genome='#{BUILD}' AND ngs_ontology_no=#{NGS_ONT_NUM}", :as => :hash)
      elsif TYPE == 'position'
        puts "Position #{index+1} of #{num_terms}" if PROGRESS
        chr,pos = term.split(':')
        results = client.query("SELECT * FROM ngs_feature WHERE chromosome='#{chr}' AND feature_start=#{pos} AND genome='#{BUILD}' AND ngs_ontology_no=#{NGS_ONT_NUM}", :as => :hash)
      end
      if results.to_a.empty?
        # Not found
        F_MISSING.puts term
      else
        # Found
        results.each do |row|
          row.each_value {|value| F_RESULTS.print "#{value}\t"}
          F_RESULTS.puts
        end
      end
    elsif TYPE == 'variant'
      puts "Variant #{index+1} of #{num_terms}" if PROGRESS
      chr,pos,alleles = term.split(':')
      ref,alt = alleles.split('>')

      # First search by position...
      results = client.query("SELECT * FROM ngs_feature WHERE chromosome='#{chr}' AND feature_start=#{pos} AND genome='#{BUILD}' AND ngs_ontology_no=#{NGS_ONT_NUM}", :as => :hash)

      found = false
      if !results.to_a.empty?
        results.each do |row|
          # ...then search by ref/alt alleles
          if row['description'].match(/;genomic_sequence\|[A-Z]*\(#{ref}\/#{alt}\)[A-Z]*;/i) || row['description'].match(/;genomic_sequence\|[A-Z]*\(#{swap_strand(ref)}\/#{swap_strand(alt)}\)[A-Z]*;/i)
            # found
            found = true
            row.each_value {|value| F_RESULTS.print "#{value}\t"}
            F_RESULTS.puts
            break
          end
        end # end results.each
      end # end if
      if ! found
        # not found
        F_MISSING.puts term
      end
    else
      Error.fatal("#{TYPE} is not a valid type")
    end

  end

rescue Mysql2::Error => e
  puts e.errno
  puts e.error
ensure
  client.close if client
end

F_RESULTS.close
F_MISSING.close
