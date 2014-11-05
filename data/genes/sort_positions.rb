# Sorts a file by chromosomal position
# 
# Input file must be tab-separated and have the following format:
#   - Column 1: chromosome (e.g. chr1, chr10, chrX)
#   - Column 2: start position (e.g. 4325484)
#   - All other columns can be ordered in any way

F_IN = 'output.txt' # <-- EDIT THIS
F_OUT = 'sorted_positions.txt' # <-- EDIT THIS

F_TMP = ".#{F_OUT}.tmp"

`rm -f #{F_TMP}`
`rm -f #{F_OUT}`
puts "Sorting chromosomal positions..."
`sort -k2,2n #{F_IN} > #{F_TMP}`
('1'..'22').to_a.push('X').push('Y').each do |chr|
  `grep '^chr#{chr}\t' #{F_TMP} >> #{F_OUT}`
end
`rm -f #{F_TMP}`
puts "Sorted file written to #{F_OUT}"
