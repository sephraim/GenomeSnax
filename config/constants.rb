# Application root directory
APP_ROOT = File.expand_path(File.dirname(File.dirname(__FILE__)))

# Data directory
DATA_DIR = File.join(APP_ROOT, 'data')

# Genes directory
GENES_DIR = File.join(DATA_DIR, 'genes')

# Temp file directory
TMP_DIR = File.join(APP_ROOT, 'tmp')

# Preferred empty output value
EMPTY_VALUE = '.'

# Native empty value seen in original data
NATIVE_EMPTY_VALUE = 'N/A'

# 'description' column number in the MySQL database (1-based)
DESCRIPTION_COLUMN_NUM = 11

# Accepted input types
VALID_TYPES = [
  'gene',
  'region',
  'position',
  'variant',
]

# Accepted data sources
VALID_SOURCES = {
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
VALID_FORMATS = {
  'tab' => "\t",
  'raw' => nil,
}

# Token for the reference allele in the description column
REF_ALLELE_TOKEN = {
  'clinvar' => 'ref',
  'dbnsfp'  => 'dbNSFP_ref',
  'dbsnp'   => 'DbSNP_refNCBI',
  'evs'     => 'evs_RefBaseNCBI37',
  'gwas'    => 'ref',
  'hgmd'    => 'ref',
}

# Token for the alternative allele in the description column
ALT_ALLELE_TOKEN = {
  'clinvar' => 'alt',
  'dbnsfp'  => 'dbNSFP_altref',
  'dbsnp'   => 'variation', # NOTE: Additional parsing needed
  'evs'     => 'alt',
  'gwas'    => 'alt',
  'hgmd'    => 'alt',
}
