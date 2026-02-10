#!/bin/bash
#PBS -N fastqc_fastp_array
#PBS -l select=1:ncpus=4:mem=16gb:scratch_ssd=100gb
#PBS -l walltime=04:00:00
#PBS -J 1-72
#PBS -m abe

set -euo pipefail

# Set paths
DATADIR="/storage/zblezble/astro"
FASTP_DIR="${DATADIR}/fastq_fastp"

# Add modules
module add fastqc

# Build a bash array of all R1 fastp files
mapfile -t r1_list < <(ls "${FASTP_DIR}"/*_fastp_R1.fastq.gz | sort)

count=${#r1_list[@]}
if [ "$count" -eq 0 ]; then
    echo "No *_fastp_R1.fastq.gz files found in ${FASTP_DIR}" >&2
    exit 1
fi

idx=$((PBS_ARRAY_INDEX - 1))

if [ "$idx" -lt 0 ] || [ "$idx" -ge "$count" ]; then
    echo "PBS_ARRAY_INDEX=${PBS_ARRAY_INDEX} out of range (0..$((count-1)))" >&2
    exit 1
fi

r1="${r1_list[$idx]}"
sample=$(basename "$r1" | sed 's/_fastp_R1\.fastq\.gz//')
r2="${FASTP_DIR}/${sample}_fastp_R2.fastq.gz"

echo "PBS_ARRAY_INDEX=$PBS_ARRAY_INDEX"
echo "Sample: $sample"
echo "R1: $r1"
echo "R2: $r2"

if [ ! -f "$r2" ]; then
    echo "Missing R2 for sample $sample" >&2
    exit 1
fi

cd "$SCRATCHDIR" || { echo "Cannot cd to \$SCRATCHDIR" >&2; exit 1; }

# Copy to scratch
rsync "$r1" "$SCRATCHDIR/"
rsync "$r2" "$SCRATCHDIR/"

r1_local=$(basename "$r1")
r2_local=$(basename "$r2")

mkdir -p fastqc_fastp

echo "Running FastQC for $sample"

# Run FastQC
fastqc \
    "$r1_local" \
    "$r2_local" \
    -t 4 \
    -o fastqc_fastp

echo "FastQC finished for $sample"

# Copy results back
mkdir -p "${DATADIR}/fastqc_fastp"
rsync -a fastqc_fastp/ "${DATADIR}/fastqc_fastp/"

echo "Copied FastQC results for $sample back to ${DATADIR}/fastqc_fastp"
