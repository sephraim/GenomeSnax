# Methods for querying and parsing data from dbNSFP
# via Genome Trax
#
# @author Sean Ephraim
class Dbnsfp
  @@ngs_ontology_no = ACCEPTED_SOURCES['dbnsfp']

  def self.query_variant(variant)
    chr,pos,ref,alt = Genome.split_variant(variant)

    # First search by position...
    results = Query.position(variant, 'dbnsfp')

    if !results.nil?
      results.each do |row|
        # ...then search by ref/alt alleles
        if row['description'].match(/;dbNSFP_ref\|#{ref};/i) && row['description'].match(/;dbNSFP_altref\|#{alt};/i)
          # Return row if found
          return [row]
        elsif row['description'].match(/;dbNSFP_ref\|#{Genome.swap_strand(ref)};/i) && row['description'].match(/;dbNSFP_altref\|#{Genome.swap_strand(alt)};/i)
          # Return row if found (opposite strand)
          return [row]
        end
      end
    end

    # Return nil if not found
    return nil
  end
end
