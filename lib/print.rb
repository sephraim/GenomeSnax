# Methods for printing results
#
# @author Sean Ephraim
class Print

  # Print header
  #
  # @param source [String] Data source (e.g. hgmd, clinvar)
  # @param file [File] Output file
  # @return [Nil]
  def self.header(source, file)
    # Set ngs_ontology_num based on source
    results = CLIENT.query("
      SELECT *
      FROM ngs_feature
      WHERE ngs_ontology_no = #{ACCEPTED_SOURCES[source]}
      LIMIT 1
    ")
    results.each do |row|
      if FORMAT == 'raw'
        # Print raw output from Genome Trax
        row.each_key {|key| file.print "#{key}\t"}
      else
        # Print formatted (delimited) output from Genome Trax
        row.each_pair do |key, value|
          if key == 'feature_end'
            # Print "ref" and "alt" headers
            file.print key+DELIM+"ref"+DELIM+"alt"+DELIM
          elsif key == 'description'
            # Split the 'description' column headers into separate columns
            # TODO Don't add prefix for headers that already have prefix
            file.print value.split(';').map{ |v| v.gsub(/\|.*$/, '').prepend("#{source}_") }.join(DELIM)+DELIM
          else
            # Keep all other columns (i.e. not 'description') intact
            file.print key.to_s+DELIM
          end
        end
      end
      file.puts # end of row
    end
    return nil
  end

  # Print results
  #
  # @param results [Array] Array of hashes, each hash is one database row
  # @param file [File] Output file
  # @param opts [Hash] Options for printing results
  # @option opts [String] :ref Referenece allele
  # @option opts [String] :alt Alternate allele
  # @option opts [String] :source Data source (e.g. hgmd, clinvar)
  # @return [Nil]
  def self.results(results, file, opts = {})
    results.each do |row|
      # Get ref and alt alleles
      if FORMAT != 'raw'
        # Formatted results

        if opts[:ref].nil? || opts[:alt].nil?
          Error.fatal("You must specify a source if you don't specify ref/alt alleles") if opts[:source].nil?
          # Ref/Alt alleles aren't defined... find them
          ref,alts = Genome.get_ref_alt(row['description'], opts[:source])
          # Split up alt alleles so that 1 row is printed per allele
          # Searching for a specific variant should only return 1 row max
          alts = alts.split(',')
        else
          # Ref/Alt alleles already defined... use them
          ref = opts[:ref]
          alts = [opts[:alt]]
        end
      else
        # Raw format
        # This alt is arbitrary and is only meant to trigger the loop below
        alts = ['.']
      end
      
      # Print a row for every alt
      alts.each do |alt|
        row.each_pair do |key, value|
          if FORMAT != 'raw'
            # Formatted results
            if key == 'feature_end'
              # Print 'feature_end' value, then...
              file.print "#{value}#{DELIM}"
              # ...print ref/alt allele
              file.print "#{ref}#{DELIM}"
              file.print "#{alt}#{DELIM}"
            elsif key == 'description'
              # Split the 'description' column into separate columns
              file.print value.split(';').map{ |v| v.gsub(/^.*\|/, '') }.join(DELIM)+DELIM
            else
              # Print all other columns
              file.print "#{value}#{DELIM}"
            end
          else
            # Raw format
            file.print "#{value}\t"
          end
        end
        file.puts  # end of row
      end  # end alts.each
    end  # end results
    return nil
  end

  # Print missing
  #
  # @param term [String] Query term that returned no results
  # @param file [File] Output file
  # @return [Nil]
  def self.missing(term, file)
    file.puts term
    return nil
  end
end
