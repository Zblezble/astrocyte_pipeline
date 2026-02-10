#!/bin/bash
#PBS -N salmon_index
#PBS -l select=1:ncpus=24:mem=300gb:scratch_local=300gb
#PBS -l walltime=04:00:00
#PBS -m abe

# Set paths
DATADIR="/storage/zblezble/astro"

# Add modules
module add salmon

cd $SCRATCHDIR

# Download data
wget https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_49/gencode.v49.transcripts.fa.gz
wget https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_49/GRCh38.primary_assembly.genome.fa.gz

# Prep decoy file
grep "^>" <(gunzip -c GRCh38.primary_assembly.genome.fa.gz) | cut -d " " -f 1 > decoys.txt
sed -i.bak -e 's/>//g' decoys.txt

# Merge transcripts and genome
cat gencode.v49.transcripts.fa.gz GRCm38.primary_assembly.genome.fa.gz > gentrome.fa.gz

# Run indexing
salmon index -t gentrome.fa.gz -d decoys.txt -p 24 -i salmon_index_gencode49 --gencode

# Copy results back
rsync -r $SCRATCHDIR/salmon_index_gencode49 $DATADIR/