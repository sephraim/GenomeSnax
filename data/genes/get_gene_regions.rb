# Gets the full regions of a gene based on the given transcripts
# 
# Input columns:
#   chr, start, stop, gene_symbol, [transcript] <-- optional
#
# Example usage:
#   ruby get_gene_regions.rb genes_list.txt gene_transcripts.txt > gene_regions.unsorted.txt

F_GENES = File.open(ARGV[0], 'r')
F_TRANSCRIPTS = File.open(ARGV[1], 'r')

F_GENES.each_line do |gene|
  gene.chomp!
  results = F_TRANSCRIPTS.grep(/\b#{gene}\b/)

  chr = nil
  min_start = nil
  max_stop = nil
  results.each do |result|
    chr,start,stop = result.split("\t")
    min_start = start if (min_start == nil || start < min_start)
    max_stop = stop if (max_stop == nil || stop > max_stop)
  end

  puts [chr,min_start,max_stop,gene].join("\t")
  F_TRANSCRIPTS.rewind # reset file pointer
end

# Close files
F_GENES.close
F_TRANSCRIPTS.close
