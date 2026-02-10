#!/bin/bash
#PBS -N multiqc_fastqc_fastp
#PBS -l select=1:ncpus=4:mem=10gb:scratch_ssd=50gb
#PBS -l walltime=01:00:00
#PBS -m abe

set -euo pipefail

# Set paths
DATADIR="/storage/zblezble/astro"

# Add modules
module add python27-modules-gcc

cd "$SCRATCHDIR" || { echo "Cannot cd to \$SCRATCHDIR" >&2; exit 1; }

# Copy to scratch
rsync -a "${DATADIR}/fastqc_fastp/" fastqc_fastp/

mkdir -p multiqc_fastqc_fastp

# Run MultiQC
multiqc fastqc_fastp -o multiqc_fastqc_fastp

# Copy results back
rsync -a multiqc_fastqc_fastp "${DATADIR}/"

echo "MultiQC (FastQC on fastp outputs) finished."
