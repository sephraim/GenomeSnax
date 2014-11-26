# Methods for querying and parsing data from Genome Trax
#
# @author Sean Ephraim
class Query
  
  ##
  # Query gene
  #
  # @param gene [String] Gene symbol (e.g. GJB2, USH2A)
  # @param source [String] Data source (e.g. hgmd, clinvar)
  # @return [Array/Nil] Query result or nil
  ##
  def self.gene(gene, source)
    ngs_ontology_no = VALID_SOURCES[source]

    # Find gene region
    line = ""
    open(GENE_REFERENCE) { |f| line = f.grep(/\b#{gene.strip}\b/i)[0] }

    if line.nil?
      return nil
    else
      chr,pos_start,pos_end = line.split("\t")
    end

    # Search by chromosomal region and HGNC gene name
    results = CLIENT.query("
      SELECT *
      FROM ngs_feature
      WHERE genome = '#{BUILD}'
      AND ngs_ontology_no = #{ngs_ontology_no}
      AND chromosome = '#{chr}'
      AND ((feature_start >= #{pos_start} AND feature_start <= #{pos_end})
            OR (feature_start >= #{pos_start.to_i - 1000} AND feature_start <= #{pos_end.to_i + 1000} AND description REGEXP ';hgnc[[.|.]]([^;]*,|[[.|.]]?)#{gene}[,;]'))
    ")
    results = results.to_a
    if results.empty?
      return nil
    else
      return results
    end
  end

  ##
  # Query chromosomal region
  #
  # @param region [String] Chromosomal region (e.g. chr13:20761603-20767114)
  # @param source [String] Data source (e.g. hgmd, clinvar)
  # @return [Array/Nil] Query result or nil
  ##
  def self.region(region, source)
    ngs_ontology_no = VALID_SOURCES[source]

    chr,pos_start,pos_end = Genome.split_region(region)
    return nil if chr.nil?

    # Search region
    results = CLIENT.query("
      SELECT *
      FROM ngs_feature
      WHERE genome = '#{BUILD}'
      AND ngs_ontology_no = #{ngs_ontology_no}
      AND chromosome = '#{chr}'
      AND feature_start >= #{pos_start} 
      AND feature_start <= #{pos_end} 
    ")
    results = results.to_a
    if results.empty?
      return nil
    else
      return results
    end
  end

  ##
  # Query position
  #
  # @param position [String] Chromosomal position (e.g. chr1:5643223)
  # @param source [String] Data source (e.g. hgmd, clinvar)
  # @return [Array/Nil] Query result or nil
  ##
  def self.position(position, source)
    ngs_ontology_no = VALID_SOURCES[source]
    chr,pos = Genome.split_position(position)
    return nil if chr.nil?

    results = CLIENT.query("
      SELECT *
      FROM ngs_feature
      WHERE chromosome = '#{chr}'
      AND feature_start = #{pos}
      AND genome = '#{BUILD}'
      AND ngs_ontology_no = #{ngs_ontology_no}
    ")
    results = results.to_a
    if results.empty?
      return nil
    else
      return results
    end
  end

  ##
  # Query variant
  #
  # @param variant [String] Chromosomal variant (e.g. chr1:5643223:G>A)
  # @param source [String] Data source (e.g. hgmd, clinvar)
  # @return [Array/Nil] Query result or nil
  ##
  def self.variant(variant, source)
    chr,pos,ref1,alt1 = Genome.split_variant(variant)

    # EMPTY_VALUE as input is not accepted
    if chr.nil? || ref1 == EMPTY_VALUE || alt1 == EMPTY_VALUE
      return nil
    end

    # First search by position...
    results = Query.position(variant, source)

    # ... Then check compare all ref and alt alleles
    if !results.nil?
      results.each do |row|
        ref2,alts2 = Genome.get_ref_alt(row['description'], source)
        next if ref2 == EMPTY_VALUE || alts2 == EMPTY_VALUE
        # Check all possible alt alleles
        alts2.split(',').each do |alt2|
          alt2.strip!
          if (ref1 == ref2 && alt1 == alt2) || (ref1 == Genome.swap_strand(ref2) && alt1 == Genome.swap_strand(alt2))
            return [[row],chr,pos,ref1,alt1]
          end
        end
      end
    end

    # Return nil if not found
    return nil
  end
end
