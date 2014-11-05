# 
# 
# Input columns
#   chr, start, stop, gene_symbol, [transcript] <-- optional

F_GENES = File.open('genes.txt', 'r')
F_POSITIONS = File.open('gene_positions.unsorted.txt', 'r')

F_GENES.each_line do |gene|
  gene.chomp!
  results = F_POSITIONS.grep(/\b#{gene}\b/)

  chr = nil
  min_start = nil
  max_stop = nil
  results.each do |result|
    chr,start,stop = result.split("\t")
    min_start = start if (min_start == nil || start < min_start)
    max_stop = stop if (max_stop == nil || stop > max_stop)
  end

  puts [chr,min_start,max_stop,gene].join("\t")
  F_POSITIONS.rewind # reset file pointer
end

# Close files
F_GENES.close
F_POSITIONS.close
