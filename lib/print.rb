# Methods for printing results
#
# @author Sean Ephraim
class Print

  # Print header
  def self.header(source)
    # Set ngs_ontology_num based on source
    results = CLIENT.query("SELECT * FROM ngs_feature WHERE ngs_ontology_no = #{ACCEPTED_SOURCES[source]} LIMIT 1")
    results.each do |row|
      if FORMAT == 'raw'
        # Print raw output from Genome Trax
        row.each_key {|key| F_RESULTS.print "#{key}\t"}
      else
        # Print formatted (delimited) output from Genome Trax
        row.each_pair do |key, value|
          if key == 'description'
            # Split the 'description' column into separate columns
            F_RESULTS.print value.split(';').map{ |v| v.gsub(/\|.*$/, '') }.join(DELIM)+DELIM
          else
            # Keep all other columns (i.e. not 'description') intact
            F_RESULTS.print key+DELIM
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
        if key == 'description' && FORMAT != 'raw'
          # Split the 'description' column into separate columns
          F_RESULTS.print value.split(';').map{ |v| v.gsub(/^.*\|/, '') }.join(DELIM)+DELIM
        else
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
