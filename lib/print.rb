# Methods for printing results
#
# @author Sean Ephraim
class Print

  # Print header
  #
  # @param source [String] Data source (e.g. hgmd, clinvar)
  # @param file [File] Output file
  # @return [Nil]
  def self.source_header(source, file)
    # Set ngs_ontology_num based on source
    results = CLIENT.query("
      SELECT *
      FROM ngs_feature
      WHERE ngs_ontology_no = #{VALID_SOURCES[source]}
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
            fields = value.split(';')
            fields.each do |f|
              f.gsub!(/\|.*$/, '')
              if !f.match(/^#{source}_/i)
                # Add prefix for headers that don't already have a prefix
                f = f.prepend("#{source}_")
              end
            end
            file.print fields.join(DELIM)+DELIM
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
  def self.source_results(results, file, opts = {})
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
          value = EMPTY_VALUE if value == NATIVE_EMPTY_VALUE
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
              # Values that are NATIVE_EMPTY_VALUE will be mapped to EMPTY_VALUE instead
              file.print value.split(';').map{ |v| v.gsub(/^.*\|/, '') }.map{ |v| (v == NATIVE_EMPTY_VALUE) ? EMPTY_VALUE : v }.join(DELIM)+DELIM
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
  # @param opts [Hash] Options for printing results
  # @option opts [String] :source Data source that returned no results
  # @return [Nil]
  def self.missing(term, file, opts = {})
    if opts[:source].nil?
      file.puts "Missing ".ljust(30, '.') + " #{term}"
    else
      file.puts "Missing from #{opts[:source].upcase} ".ljust(30, '.') + " #{term}"
    end

    return nil
  end

  # Print merged results
  #
  # @param source_results_filenames [Array] List of files to merge
  # @param merged_filename [String] Output file name
  # @return [Nil]
  def self.merged_results(source_results_filenames, merged_filename)
    # Temporary index file used for merging results
    merged_index_filename = File.join(TMP_DIR, merged_filename + ".index.tmp")

    # Merge results
    if FORMAT == 'raw'
      source_results_filenames.each_with_index do |filename, file_num|
        if file_num < 1
          # Copy all source results (including header) into merged file
          `cp -f #{filename} #{merged_filename}`
        else
          # Copy all source results (excluding header) into merged file
          `tail -n +2 #{filename} >> #{merged_filename}`
        end
      end
    else
      # Create temporary index file of all variants
      puts "- Creating index file to merge results..." if PROGRESS
      presorted_index_filename = merged_index_filename + '.presorted'
      sorted_index_filename = merged_index_filename + '.sorted'
      File.delete(presorted_index_filename) if File.exist?(presorted_index_filename)
      File.delete(sorted_index_filename) if File.exist?(sorted_index_filename)
      File.delete(merged_index_filename) if File.exist?(merged_index_filename)
      # Step 1 of sorting by chromosomal position (sort by position only)
      `tail -q -n +2 #{source_results_filenames.join(' ')} | cut -f2-6 | sort -k2,2n | uniq > #{presorted_index_filename}`
      # Step 2 of sorting by chromosomal position (sort by chr+position)
      ('1'..'22').to_a.push('X').push('Y').each do |chr|
        `grep '^chr#{chr}\t' #{presorted_index_filename} >> #{sorted_index_filename}`
      end

      File.delete(presorted_index_filename) if File.exist?(presorted_index_filename)

#      # TODO Merge duplicated records of 1 variant on opposite strands
#      # NOTE: This may have to happen below instead
#      File.open(sorted_index_filename).each_line do |variant|
#        line.strip!
#        chr,pos_start,pos_end = variant.strip.split(DELIM)
#        results = `grep '#{chr+DELIM+pos_start+DELIM+pos_end+DELIM}' #{sorted_index_filename}`.split("\n")
#        if results.size == 1
#          # Print single result
#          `echo #{results} >> #{merged_index_filename}`
#        elsif true # <-- TODO Change this!
#          # TODO Merge multiple results, then print
#          `echo #{results} >> #{merged_index_filename}` # <-- TODO Change this!
#        end
#      end
merged_index_filename = sorted_index_filename # TODO <-- remove this line later
      
#      File.delete(sorted_index_filename) if File.exist?(sorted_index_filename) # TODO <-- put this back!
    
      puts "- Merging all results..." if PROGRESS
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
      f_merged = File.open(merged_filename, 'w')
      f_merged.puts header

      # Merge results
      File.open(merged_index_filename).each_line do |variant|
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
        f_merged.puts row
      end
      f_merged.close if f_merged
    end
    File.delete(merged_index_filename) if File.exist?(merged_index_filename)
    return nil
  end
end
