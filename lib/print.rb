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
            # Split the 'description' column into separate columns
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
  def self.results(results)
    results.each do |row|
      row.each_pair do |key, value|
        if FORMAT != 'raw'
          # Print formatted results
          if key == 'feature_end'
            # Print 'feature_end' value, then...
            F_RESULTS.print "#{value}#{DELIM}"
            # ...print "ref" and "alt" allele
            alleles = Genome.get_ref_alt_from_hgvs(row['description'])
            if !alleles.nil?
              ref,alt = alleles[0..1]
            else
              ref = Genome.get_ref(row['description'], SOURCE)
              alt = Genome.get_alt(row['description'], SOURCE)
            end
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
          # Print raw results
          F_RESULTS.print "#{value}\t"
        end
      end
      F_RESULTS.puts # end of row
    end
  end

  # Print missing
  def self.missing(term)
    F_MISSING.puts term
  end
end
