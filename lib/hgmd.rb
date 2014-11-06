# Methods for querying and parsing data from HGMD
# via Genome Trax
#
# @author Sean Ephraim
class Hgmd
  @@ngs_ontology_no = ACCEPTED_SOURCES['hgmd']

  # Query position
  def self.query_variant(variant)
    chr,pos,ref,alt = Genome.split_variant(variant)

    # First search by position...
    results = Query.position(variant, 'hgmd')

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
