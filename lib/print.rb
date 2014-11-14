# Methods for printing results
#
# @author Sean Ephraim
class Print

  # Print header
  def self.header(source)
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
        row.each_key {|key| F_RESULTS.print "#{key}\t"}
      else
        # Print formatted (delimited) output from Genome Trax
        row.each_pair do |key, value|
          if key == 'feature_end'
            # Print "ref" and "alt" headers
            F_RESULTS.print key+DELIM+"ref"+DELIM+"alt"+DELIM
          elsif key == 'description'
            # Split the 'description' column headers into separate columns
            F_RESULTS.print value.split(';').map{ |v| v.gsub(/\|.*$/, '').prepend("#{source}_") }.join(DELIM)+DELIM
          else
            # Keep all other columns (i.e. not 'description') intact
            F_RESULTS.print key.to_s+DELIM
          end
        end
      end
      F_RESULTS.puts # end of row
    end
  end

  # Print results
  def self.results(results, opts = {})
    results.each do |row|
      # Get ref and alt alleles
      if FORMAT != 'raw'
        # Formatted results

        if opts[:ref].nil? || opts[:alt].nil?
          # Ref/Alt alleles aren't defined... find them
          ref,alts = Genome.get_ref_alt(row['description'], SOURCE)
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
              F_RESULTS.print "#{value}#{DELIM}"
              # ...print ref/alt allele
              F_RESULTS.print "#{ref}#{DELIM}"
              F_RESULTS.print "#{alt}#{DELIM}"
            elsif key == 'description'
              # Split the 'description' column into separate columns
              F_RESULTS.print value.split(';').map{ |v| v.gsub(/^.*\|/, '') }.join(DELIM)+DELIM
            else
              # Print all other columns
              F_RESULTS.print "#{value}#{DELIM}"
            end
          else
            # Raw format
            F_RESULTS.print "#{value}\t"
          end
        end
        F_RESULTS.puts  # end of row
      end  # end alts.each
    end  # end results
  end

  # Print missing
  def self.missing(term)
    F_MISSING.puts term
  end
end
