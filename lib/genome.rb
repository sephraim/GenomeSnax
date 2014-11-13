class Genome
  # Swaps the nucleotide sequence to the opposite strand
  #
  # For example:
  #   Original: TCCAGACAC
  #   Swapped:  GTGTCTGGA
  #
  # @param seq [String] Nucleotide sequence
  # @return [String] Nucleotide sequence on opposite strand
  def self.swap_strand(seq)
    seq = seq.reverse.upcase.split("")
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

  # Get Ref Alt From HGVS
  #
  # Retrieves the reference and alternate allele(s) from the HGVS nomenclature.
  # If the 'hgvs' field exists in the description column, then it will parse
  # out the ref and alt allele(s). If these alleles are blank strings, they
  # will be converted to '.' instead. If 'hgvs' does not exist in the description
  # column or if it just equals 'N/A', then nil will be returned.
  #
  # @param description [String] Description column value
  # @return [Array|Nil] Ref allele, alt allele (if they exist); otherwise nil
  def self.get_ref_alt_from_hgvs(description)
    # Parse out just the HGVS nucleotide change (if it exists)
    if (match = description.match(/;hgvs\|NM_.*[:\s]c\.([^,;\s%]*)/))

      hgvs_nchange = match[1]
      # Retrieve the ref and alt allele(s)
      if hgvs_nchange.include?("=") || hgvs_nchange.include?("?") # i.e. 117188566C=
        # Do nothing... what'd you expect?
      elsif hgvs_nchange.include?("del") && hgvs_nchange.include?("ins")
        # DELETION/INSERTION
        # e.g. 608_609delTCinsAA
        ref,alt = hgvs_nchange.match(/[0-9\*]del([actgACTG\-]*)ins([actgACTG\-]*)/)[1..2]
      elsif hgvs_nchange.include?("ins")
        # INSERTION
        # e.g. 512_513insAACG
        ref = '-'
        alt = hgvs_nchange.match(/[0-9\*]ins([actgACTG\-]*)/)[1]
      elsif hgvs_nchange.include?("del")
        # DELETION
        # e.g. 431_450delTCATCTTCGAAGCCGCCTTC
        ref = hgvs_nchange.match(/[0-9\*]del([actgACTG\-]*)/)[1]
        alt = '-'
      elsif hgvs_nchange.include?("dup")
        # DUPLICATION
        ref = '-'
        alt = hgvs_nchange.match(/[0-9\*]dup([actgACTG\-]*)/)[1]
      else
        # SUBSTITUTION
        # e.g. *111CCC>TAGGG
        # e.g. *CCC>TAGGG
        ref,alt = hgvs_nchange.match(/[0-9\*]([actgACTG\-]*)>([actgACTG\-]*)/)[1..2]
      end
      # Convert blank strings to '.'
      ref = '.' if ref.nil? || ref == ''
      alt = '.' if alt.nil? || alt == ''
      return [ref, alt]
    else
      return nil
    end
  end

  # Get the reference allele from the description string
  #
  # @param description [String] Description column value
  # @param source [String] Data source (e.g. hgmd, clinvar)
  # @param strand [String] Chromosome strand (+ or -)
  # @return [String] Reference allele(s)
  def self.get_ref(description, source, strand = '+')
    ref = description.match(/\b#{REF_ALLELE_TOKEN[source]}\|([a-zA-Z\-\/]*)/)[1]
    if ref == "N/A"
      return "."
    else
      return ref
    end
  end

  # Get the alternate allele from the description string
  #
  # @param description [String] Description column value
  # @param source [String] Data source (e.g. hgmd, clinvar)
  # @param strand [String] Chromosome strand (+ or -)
  # @return [String] Reference allele(s)
  def self.get_alt(description, source, strand = '+')
    alt = description.match(/\b#{ALT_ALLELE_TOKEN[source]}\|([a-zA-Z\/\-,]*)/)[1]

    # Get alternate allele from dbSNP description
    if source == 'dbsnp'
      ref_ncbi = get_ref(description, source)

      # Swap strand if none of the alleles are the NCBI ref allele
      if !alt.split('/').include?(ref_ncbi)
        alt = swap_strand(alt)
      end 

      # Set the correct alt allele
      alleles = alt.split('/')
      alleles.delete(ref_ncbi)
      alt = alleles.join(',')
    end

    if alt == 'N/A' || alt.nil?
      return "."
    else
      return alt
    end
  end

end
