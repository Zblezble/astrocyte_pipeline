#!/bin/bash
#PBS -N salmon_array
#PBS -l select=1:ncpus=8:mem=40gb:scratch_ssd=200gb
#PBS -l walltime=06:00:00
#PBS -J 1-72
#PBS -m abe

set -euo pipefail

# Set paths
DATADIR="/storage/zblezble/astro"
FASTP_DIR="${DATADIR}/fastq_fastp"
SALMON_INDEX="${DATADIR}/salmon_index_gencode49"
OUT_DIR="${DATADIR}/salmon_gencode"

# Add modules
module add salmon

mkdir -p "$OUT_DIR"

# Build list of all R1 fastp files (one per sample)
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

mkdir -p salmon_sample

echo "Running Salmon quant for $sample"

# Run salmon
salmon quant \
    -i "$SALMON_INDEX" \
    -l A \
    -1 "$r1_local" \
    -2 "$r2_local" \
    --validateMappings \
    --threads 8 \
    -o "salmon_sample/${sample}"

status=$?
echo "Salmon exit code: $status"
if [ $status -ne 0 ]; then
    echo "Salmon failed for $sample" >&2
    exit $status
fi

# Copy results back
mkdir -p "${OUT_DIR}/${sample}"
rsync -a "salmon_sample/${sample}/" "${OUT_DIR}/${sample}/"

echo "Finished Salmon for sample $sample"
