# Methods for querying and parsing data from dbSNP
# via Genome Trax
#
# @author Sean Ephraim
class Dbsnp
  @@ngs_ontology_no = ACCEPTED_SOURCES['dbsnp']

  def self.query_variant(variant)
    chr,pos,ref,alt = Genome.split_variant(variant)

    # First search by position...
    results = Query.position(variant, 'dbsnp')

    if !results.nil?
      results.each do |row|
        # ... then match your ref allele with DbSNP_refNCBI...
        if row['description'].match(/;DbSNP_refNCBI\|#{ref};/i) || row['description'].match(/;DbSNP_refNCBI\|#{Genome.swap_strand(ref)};/i)
          # ... then try every combiniation of variation using your ref/alt alleles
          if row['description'].match(/;variation\|#{ref}\/#{alt};/i) || row['description'].match(/;variation\|#{alt}\/#{ref};/i)
            # Return row if found (same strand)
            return [row]
          elsif row['description'].match(/;variation\|#{Genome.swap_strand(ref)}\/#{Genome.swap_strand(alt)};/i) || row['description'].match(/;variation\|#{Genome.swap_strand(alt)}\/#{Genome.swap_strand(ref)};/i)
            # Return row if found (opposite strand)
            return [row]
          end
        end
      end
    end

    # Return nil if not found
    return nil
  end
end
