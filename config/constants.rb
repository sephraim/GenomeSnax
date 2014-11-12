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
  'hgmd' => 6,
  'clinvar' => 32,
  'dbsnp' => 33,
  'dbnsfp' => 26,
  'evs' => 25,
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
  'hgmd' => 'ref',
  'clinvar' => 'ref',
#  'dbsnp' => 'ref_ncbi', # 2014.3
  'dbsnp' => 'DbSNP_refNCBI', # 2014.1
  'dbnsfp' => 'ref',
  'evs' => 'evs_RefBaseNCBI37',
}

# Token for the alternative allele in the description column
ALT_ALLELE_TOKEN = {
  'hgmd' => 'alt',
  'clinvar' => 'alt',
#  'dbsnp' => 'variant', # 2014.3
  'dbsnp' => 'variation', # 2014.1
  'dbnsfp' => 'altref',
  'evs' => 'alt',
}
