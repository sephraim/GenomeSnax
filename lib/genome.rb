class Genome
  # Swaps the nucleotide sequence to the opposite strand
  #
  # @param seq [String] Nucleotide sequence
  # @return [String] Nucleotide sequence on opposite strand
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

  # Splits the variant string into its separate parts.
  # The parts are chromosome, position, ref allele, alt allele.
  #
  # @param variant [String] Variant as one string
  # @return [Array] Variant parts [chr, pos, ref, alt]
  def self.split_variant(variant)
    chr,pos,ref,alt = variant.split(/[^a-zA-Z\d-]/)
    # Check if the 3rd column is actually the ID column (for VCF files)
    if ref.match(/^[ACGT-]/).nil?
      chr,pos,id,ref,alt = variant.split(/[^a-zA-Z\d-]/)
    end
    return [chr, pos, ref, alt]
  end

  # Splits the chromosomal region string into its separate parts.
  # The parts are chromosome, start position, and end position.
  #
  # @param region [String] Chromosomal region as one string
  # @return [Array] Region parts [chr, start_pos, end_pos]
  def self.split_region(variant)
    chr,start_pos,end_pos = variant.split(/[^a-zA-Z\d]/)
    return [chr, start_pos, end_pos]
  end
end
