class Query
  
  ##
  # Query gene
  ##
  def self.gene(gene, source)
    ngs_ontology_no = ACCEPTED_SOURCES[source]
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
  ##
  def self.position(position, source)
    ngs_ontology_no = ACCEPTED_SOURCES[source]
    chr,pos = position.split(':')
    results = CLIENT.query("
      SELECT *
      FROM ngs_feature
      WHERE chromosome = '#{chr}'
      AND feature_start = #{pos}
      AND genome = '#{BUILD}'
      AND ngs_ontology_no = #{ngs_ontology_no}
    ")
    if results.to_a.empty?
      return nil
    else
      return results.to_a
    end
  end

  ##
  # Query variant
  ##
  # TODO Make this work for ClinVar
  def self.variant(variant, source)
    if source == 'hgmd'
      return Hgmd.query_variant(variant)
    elsif source == 'clinvar'
      return Clinvar.query_variant(variant)
    end
    return nil
  end
end
