#!/bin/bash
#PBS -N clumpify_array
#PBS -l select=1:ncpus=4:mem=50gb:scratch_ssd=200gb
#PBS -l walltime=04:00:00
#PBS -J 1-77
#PBS -m abe


# Set paths
DATADIR="/storage/zblezble/astro"
TABLE="${DATADIR}/fastq/samples.tsv"

# Add modules
module add bbmap

# Sanity check
if [ ! -f "$TABLE" ]; then
    echo "samples.tsv not found at $TABLE" >&2
    exit 1
fi

# Pick the line corresponding to this array index
line_number=$((PBS_ARRAY_INDEX + 1))

line=$(sed -n "${line_number}p" "$TABLE")

if [ -z "$line" ]; then
    echo "No line for PBS_ARRAY_INDEX=$PBS_ARRAY_INDEX (line ${line_number})" >&2
    exit 1
fi

# Parse fields: sample_id  fq1  fq2
read -r sample fq1 fq2 <<< "$line"

if [ -z "$sample" ] || [ -z "$fq1" ] || [ -z "$fq2" ]; then
    echo "Malformed line in samples.tsv: '$line'" >&2
    exit 1
fi

echo "PBS_ARRAY_INDEX=$PBS_ARRAY_INDEX"
echo "Sample: $sample"
echo "R1: $fq1"
echo "R2: $fq2"

# Copy to scratch
mkdir -p "$SCRATCHDIR"/fastq_clump
cd "$SCRATCHDIR" || { echo "Cannot cd to \$SCRATCHDIR" >&2; exit 1; }

rsync "$fq1" "$SCRATCHDIR/"
rsync "$fq2" "$SCRATCHDIR/"

r1_local=$(basename "$fq1")
r2_local=$(basename "$fq2")

# Run clumpify
clumpify.sh \
    in1="$r1_local" \
    in2="$r2_local" \
    out1="fastq_clump/${sample}_clump_R1.fastq.gz" \
    out2="fastq_clump/${sample}_clump_R2.fastq.gz" \
    reorder t=4 -Xmx40g

status=$?
echo "clumpify exit code: $status"
if [ $status -ne 0 ]; then
    echo "clumpify failed for $sample" >&2
    exit $status
fi

# Copy results back
mkdir -p "${DATADIR}/fastq_clump"
rsync "fastq_clump/${sample}_clump_R1.fastq.gz" "${DATADIR}/fastq_clump/"
rsync "fastq_clump/${sample}_clump_R2.fastq.gz" "${DATADIR}/fastq_clump/"

echo "Finished sample $sample"

