#!/bin/bash
#PBS -N fastqc_clumped
#PBS -l select=1:ncpus=12:mem=40gb:scratch_ssd=200gb
#PBS -l walltime=04:00:00
#PBS -m abe

set -euo pipefail

# Set paths
DATADIR="/storage/zblezble/astro"

# Add modules
module add fastqc
module add python27-modules-gcc

cd "$SCRATCHDIR" || { echo "Cannot cd to \$SCRATCHDIR" >&2; exit 1; }

# Copy clumped reads to scratch
mkdir -p fastq_clump
rsync -a "${DATADIR}/fastq_clump/" fastq_clump/

# Sanity check
ls fastq_clump/*.fastq.gz | head

# Run FastQC
mkdir -p fastqc_clump
fastqc fastq_clump/*.fastq.gz -t 12 -o fastqc_clump

# Run MultiQC
mkdir -p multiqc_fastqc_clump
multiqc fastqc_clump -o multiqc_fastqc_clump

# Copy results back
rsync -a fastqc_clump "${DATADIR}/"
rsync -a multiqc_fastqc_clump "${DATADIR}/"

echo "FastQC + MultiQC on clumped reads finished."

