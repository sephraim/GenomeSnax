#!/bin/bash

# Get new refFlat file
#wget http://hgdownload.cse.ucsc.edu/goldenPath/hg19/database/refFlat.txt.gz
echo "Downloading refFlat.txt..."
curl -O http://hgdownload.cse.ucsc.edu/goldenPath/hg19/database/refFlat.txt.gz

#Unzip it
echo "Unzipping refFlat.txt.gz..."
gunzip refFlat.txt.gz

# Get the fields you want (chr, starting pos, ending position, gene symbol, transcript)
echo "Retrieving necessary fields from refFlat.txt..."
cut -f1,2,3,5,6 refFlat.txt | awk '{print $3"\t"$4"\t"$5"\t"$1"\t"$2}' | grep 'chr[1-9XYxy][0-9XYxy]\?\t' | sort -u > gene_transcripts_hg19.txt

# Make a sorted list of genes
echo "Retrieving list of gene symbols..."
cut -f4 gene_transcripts_hg19.txt | sort -u > genes_hg19.txt

# Get the full gene regions from the gene transcripts
echo "Finding gene regions from gene transcripts. This may take a little while..."
ruby get_gene_regions.rb genes_hg19.txt gene_transcripts_hg19.txt > gene_regions_hg19.unsorted.txt

# Sort the gene regions by chromosomal position
ruby sort_positions.rb gene_regions_hg19.unsorted.txt gene_regions_hg19.txt

rm refFlat.txt
rm gene_transcripts_hg19.txt
rm genes_hg19.txt
rm gene_regions_hg19.unsorted.txt

echo "Your file has been written to gene_regions_hg19.txt"
