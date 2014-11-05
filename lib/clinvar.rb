# Methods for querying and parsing data from ClinVar
# via Genome Trax
#
# @author Sean Ephraim
class Clinvar
#  @@ngs_ontology_no = ACCEPTED_SOURCES['1kg']
@@ngs_ontology_no = 37

  # Query Gene
  # TODO Make this more DRY. It's the same as HGMD
  def self.query_gene(gene)
    results = CLIENT.query("
      SELECT *
      FROM ngs_feature
      WHERE description
      LIKE '%;hgnc|#{gene};%'
      AND genome='#{BUILD}'
      AND ngs_ontology_no=#{@@ngs_ontology_no}
    ")
    if results.to_a.empty?
      return nil
    else
      return results.to_a
    end
  end

  # Query position
  # TODO Make this more DRY. It's the same for ANY source
  def self.query_position(position)
    chr,pos = position.split(':')
    results = CLIENT.query("
      SELECT *
      FROM ngs_feature
      WHERE chromosome='#{chr}'
      AND feature_start=#{pos}
      AND genome='#{BUILD}'
      AND ngs_ontology_no=#{@@ngs_ontology_no}
    ")
    if results.to_a.empty?
      return nil
    else
      return results.to_a
    end
  end

  # TODO Query position
  def self.query_variant(variant)
    chr,pos,alleles = variant.split(':')
    ref,alt = alleles.split('>')

    # First search by position...
    results = self.query_position(variant)

    if !results.nil?
      results.each do |row|
        # ...then search by ref/alt alleles
        if row['description'].match(/;genomic_sequence\|[A-Z]*\(#{ref}\/#{alt}\)[A-Z]*;/i) || row['description'].match(/;genomic_sequence\|[A-Z]*\(#{Genome.swap_strand(ref)}\/#{Genome.swap_strand(alt)}\)[A-Z]*;/i)
          # Return row if found
          return [row]
        end
      end
    end

    # Return nil if not found
    return nil
  end
end
