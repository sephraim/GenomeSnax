# Sorts a file by chromosomal position
# 
# Input file must be tab-separated and have the following format:
#   - Column 1: chromosome (e.g. chr1, chr10, chrX)
#   - Column 2: start position (e.g. 4325484)
#   - All other columns can be ordered in any way
#
# Example usage:
#   ruby sort_positions.rb input.txt output.txt

F_IN = ARGV[0]
F_OUT = ARGV[1]

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
