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
  # @return [Array, Nil] Variant parts [chr, pos, ref, alt]; nil if invalid
  def self.split_variant(variant)
    variant_parts = variant.split(/[^a-zA-Z\d\-]/)
    if variant_parts.size == 4
      chr,pos,ref,alt = variant_parts
    elsif variant_parts.size > 4
      # More than 4 parts assumes input is a VCF file
      chr,pos,id,ref,alt = variant.split(/[^a-zA-Z\d\-]/)
    else
      # Less than 4 parts assumes something's wrong with the input
      return nil
    end

    # Assure that chr is formatted correctly, pos is an integer and that ref/alt are characters or -
    if !!(chr =~ /(^chr|^)[1-9]?[0-9XY]$/) && !!(pos =~ /^[\d]*$/) && !!(ref =~ /^[a-zA-Z\-]*$/) && !!(alt =~ /^[a-zA-Z\-]*$/)
      return [chr, pos, ref, alt]
    else
      return nil
    end
  end

  # Splits the chromosomal region string into its separate parts.
  # The parts are chromosome, start position, and end position.
  #
  # @param region [String] Chromosomal region as one string
  # @return [Array, Nil] Region parts [chr, pos_start, pos_end]; nil if invalid
  def self.split_region(variant)
    chr,pos_start,pos_end = variant.split(/[^a-zA-Z\d]/)
    # Assure that chr is formatted correctly and that pos_start/pos_end are integers
    if !!(chr =~ /(^chr|^)[1-9]?[0-9XY]$/) && !!(pos_start =~ /^[\d]*$/) && !!(pos_end =~ /^[\d]*$/)
      return [chr, pos_start, pos_end]
    else
      return nil
    end
  end

  # Get Ref Alt
  #
  # Retrieves the reference and alternate allele(s) from the description.
  #
  # @param description [String] Description column value
  # @return [Array] Ref allele, alt allele(s) (if they exist); otherwise nil
  def self.get_ref_alt(description, source)
    ref,alts = Genome.get_ref_alt_from_hgvs(description)
    if ref == EMPTY_VALUE
      # HGVS returned nothing... Search for ref and alt fields in the description column
      ref = Genome.get_ref_from_token(description, source)
      alts = Genome.get_alt_from_token(description, source)
    end
    # If 1 allele is blank, both should be blank
    if ref == EMPTY_VALUE || alts == EMPTY_VALUE
      ref = EMPTY_VALUE
      alts = EMPTY_VALUE
    end

    return [ref, alts]
  end

  # Get Ref Alt From HGVS
  #
  # Retrieves the reference and alternate allele(s) from the HGVS nomenclature.
  # If the 'hgvs' field exists in the description column, then it will parse
  # out the ref and alt allele(s). If these alleles are blank strings, they
  # will be converted to EMPTY_VALUE instead. If 'hgvs' does not exist in the description
  # column or if it just equals NATIVE_EMPTY_VALUE, then empty value placeholders will be returned.
  #
  # @param description [String] Description column value
  # @return [Array] Ref allele, alt allele(s) ([EMPTY_VALUE, EMTPY_VALUE] if they don't exist)
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
      # Convert blank strings to EMPTY_VALUE
      if ref.nil? || ref == '' || alt.nil? || alt == ''
        ref = EMPTY_VALUE
        alt = EMPTY_VALUE
      end
      return [ref, alt]
    else
      return [EMPTY_VALUE, EMPTY_VALUE]
    end
  end

  # Get the reference allele from the description string
  #
  # @param description [String] Description column value
  # @param source [String] Data source (e.g. hgmd, clinvar)
  # @return [String] Reference allele (EMPTY_VALUE if missing)
  def self.get_ref_from_token(description, source)
    match = description.match(/\b#{REF_ALLELE_TOKEN[source]}\|([a-zA-Z\-\/]*)/)
    if match.nil? || match[1] == NATIVE_EMPTY_VALUE
      return EMPTY_VALUE
    else
      return match[1]
    end
  end

  # Get the alternate allele from the description string
  #
  # @param description [String] Description column value
  # @param source [String] Data source (e.g. hgmd, clinvar)
  # @return [String] Reference allele(s) (EMPTY_VALUE if missing)
  def self.get_alt_from_token(description, source)
    match = description.match(/\b#{ALT_ALLELE_TOKEN[source]}\|([a-zA-Z\/\-,]*)/)
    if match.nil?
      return EMPTY_VALUE
    else
      alt = match[1]
    end

    # Get alternate allele from dbSNP description
    if source == 'dbsnp'
      ref_ncbi = get_ref_from_token(description, source)

      # Swap strand if none of the alleles are the NCBI ref allele
      if !alt.split('/').include?(ref_ncbi)
        alt = swap_strand(alt)
      end 

      # Set the correct alt allele
      alleles = alt.split('/')
      alleles.delete(ref_ncbi)
      alt = alleles.join(',')
    end

    if alt == NATIVE_EMPTY_VALUE || alt.nil?
      return EMPTY_VALUE
    else
      return alt
    end
  end

end
