# Methods for querying and parsing data from ClinVar
# via Genome Trax
#
# @author Sean Ephraim
class Clinvar
  @@ngs_ontology_no = ACCEPTED_SOURCES['clinvar']

  def self.query_variant(variant)
    chr,pos,alleles = variant.split(':')
    ref,alt = alleles.split('>')

    # First search by position...
    results = Query.position(variant, 'clinvar')

    if !results.nil?
      results.each do |row|
        # ...then search by ref/alt alleles
        if row['description'].match(/;ref\|#{ref};/i) && row['description'].match(/;alt\|#{alt};/i)
          # Return row if found
          return [row]
        elsif row['description'].match(/;ref\|#{Genome.swap_strand(ref)};/i) && row['description'].match(/;alt\|#{Genome.swap_strand(alt)};/i)
          # Return row if found (opposite strand)
          return [row]
        end
      end
    end

    # Return nil if not found
    return nil
  end
end
