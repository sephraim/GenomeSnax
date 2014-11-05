# Application root directory
APP_ROOT = File.expand_path(File.dirname(File.dirname(__FILE__)))

# Data directory
DATA_DIR = File.join(APP_ROOT, 'data')

# Genes directory
GENES_DIR = File.join(DATA_DIR, 'genes')

# Accepted input types
ACCEPTED_TYPES = [
  'gene',
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
