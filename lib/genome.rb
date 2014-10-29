class Genome
  # Swaps the nucleotide sequence to the opposite strand
  #
  # @param seq [String] Nucleotide sequence
  def self.swap_strand(seq)
    seq = seq.upcase.split("")
    seq.each_with_index do |base, i|
      seq[i] = 'A' if base == 'T' 
      seq[i] = 'T' if base == 'A' 
      seq[i] = 'G' if base == 'C' 
      seq[i] = 'C' if base == 'G' 
    end 
    return seq.join("")
  end
end
