# Application root directory
APP_ROOT = File.expand_path(File.dirname(File.dirname(__FILE__)))

# Data directory
DATA_DIR = File.join(APP_ROOT, 'data')

# Genes directory
GENES_DIR = File.join(DATA_DIR, 'genes')

# Accepted input types
ACCEPTED_TYPES = [
  'gene',
  'region',
  'position',
  'variant',
]

# Accepted data sources
ACCEPTED_SOURCES = {
  'clinvar' => 32,
  'dbnsfp'  => 26,
  'dbsnp'   => 33,
  'evs'     => 25,
  'gwas'    => 17,
  'hgmd'    => 6,
#  NOTE 1000 Genomes is not supported at this time (no records in Genome Trax)
#  '1kg' => {
#    'yri' => 37,
#    'ceu' => 38,
#    'jpt_chb' => 39,
#  }
}

# Accepted output formats
ACCEPTED_FORMATS = {
  'tab' => "\t",
  'raw' => nil,
}

# Token for the reference allele in the description column
REF_ALLELE_TOKEN = {
  'clinvar' => 'ref',
  'dbnsfp'  => 'ref',
  'dbsnp'   => 'DbSNP_refNCBI',
  'evs'     => 'evs_RefBaseNCBI37',
  'hgmd'    => 'ref',
}

# Token for the alternative allele in the description column
ALT_ALLELE_TOKEN = {
  'clinvar' => 'alt',
  'dbnsfp'  => 'altref',
  'dbsnp'   => 'variation', # NOTE: Additional parsing needed
  'evs'     => 'alt',
  'hgmd'    => 'alt',
}
