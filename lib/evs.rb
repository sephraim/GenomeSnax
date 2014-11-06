# Methods for querying and parsing data from EVS
# via Genome Trax
#
# @author Sean Ephraim
class Evs
  @@ngs_ontology_no = ACCEPTED_SOURCES['evs']

  def self.query_variant(variant)
    chr,pos,ref,alt = Genome.split_variant(variant)

    # First search by position...
    results = Query.position(variant, 'evs')

    if !results.nil?
      results.each do |row|
        # ...then search by ref/alt alleles
        if row['description'].match(/;ref\|#{ref};/i) && row['description'].match(/;alt\|#{alt};/i)
          # Return row if found (same strand)
          return [row]
        elsif row['description'].match(/;ref\|#{Genome.swap_strand(ref)};/i) && row['description'].match(/;alt\|#{Genome.swap_strand(alt)};/i)
          # Return row if found (opposite strand)
          return [row]
        else
          # As a final attempt, search by evs_Alleles
          if row['description'].match(/;evs_Alleles\|#{ref}>#{alt};/i) || match(/;evs_Alleles\|#{Genome.swap_strand(ref)}>#{Genome.swap_strand(alt)};/i)
            return [row]
          end
        end
      end
    end

    # Return nil if not found
    return nil
  end
end
