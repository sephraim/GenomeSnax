# Methods for querying and parsing data from Genome Trax
#
# @author Sean Ephraim
class Query
  
  ##
  # Query gene
  #
  # @param gene [String] Gene symbol (e.g. GJB2, USH2A)
  # @param source [String] Data source (e.g. hgmd, clinvar)
  # @retrun [Array/Nil] Query result or nil
  ##
  def self.gene(gene, source)
    ngs_ontology_no = ACCEPTED_SOURCES[source]

    # Find gene region
    line = ""
    open(GENE_REFERENCE) { |f| line = f.grep(/\b#{gene}\b/i)[0] }
    chr,pos_start,pos_end = line.split("\t")

    results = nil
    # Search by chromosomal position and HGNC gene name
    if ['hgmd', 'clinvar', 'dbnsfp', 'evs'].include?(source)
      results = CLIENT.query("
        SELECT *
        FROM ngs_feature
        WHERE genome = '#{BUILD}'
        AND ngs_ontology_no = #{ngs_ontology_no}
        AND ((chromosome = '#{chr}' AND feature_start >= #{pos_start} AND feature_end <= #{pos_end})
        OR description LIKE '%;hgnc|#{gene};%')
      ")
    elsif ['dbsnp'].include?(source)
      # Search by chromosomal position only
      results = CLIENT.query("
        SELECT *
        FROM ngs_feature
        WHERE genome = '#{BUILD}'
        AND ngs_ontology_no = #{ngs_ontology_no}
        AND chromosome = '#{chr}'
        AND feature_start >= #{pos_start} 
        AND feature_end <= #{pos_end} 
      ")
    else
      Error.fatal("Gene query for #{source} has not been specified")
    end
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
  # @retrun [Array/Nil] Query result or nil
  ##
  def self.position(position, source)
    ngs_ontology_no = ACCEPTED_SOURCES[source]
    chr,pos = Genome.split_variant(position)
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
  # @retrun [Array/Nil] Query result or nil
  ##
  def self.variant(variant, source)
    if source == 'hgmd'
      return Hgmd.query_variant(variant)
    elsif source == 'clinvar'
      return Clinvar.query_variant(variant)
    elsif source == 'dbsnp'
      return Dbsnp.query_variant(variant)
    elsif source == 'dbnsfp'
      return Dbnsfp.query_variant(variant)
    elsif source == 'evs'
      return Evs.query_variant(variant)
    else
      Error.fatal("Variant query for #{source} has not been specified")
    end
    return nil
  end
end
