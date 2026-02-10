#!/bin/bash
#PBS -N fastp_array
#PBS -l select=1:ncpus=8:mem=40gb:scratch_ssd=200gb
#PBS -l walltime=04:00:00
#PBS -J 1-72
#PBS -m abe

set -euo pipefail

# Set paths
DATADIR="/storage/zblezble/astro"
TABLE="${DATADIR}/fastq/samples.tsv"

# Add modules
module add fastp

if [ ! -f "$TABLE" ]; then
    echo "samples.tsv not found at $TABLE" >&2
    exit 1
fi

# Pick the line corresponding to this array index
line_number=$((PBS_ARRAY_INDEX + 1))
line=$(sed -n "${line_number}p" "$TABLE" || true)

if [ -z "$line" ]; then
    echo "No line for PBS_ARRAY_INDEX=$PBS_ARRAY_INDEX (line ${line_number})" >&2
    exit 1
fi

# Parse: sample_id  fq1  fq2
read -r sample fq1 fq2 <<< "$line"

if [ -z "$sample" ]; then
    echo "Malformed line in samples.tsv: '$line'" >&2
    exit 1
fi

echo "PBS_ARRAY_INDEX=$PBS_ARRAY_INDEX"
echo "Sample: $sample"

# Define clumpified input paths
in1="${DATADIR}/fastq_clump/${sample}_clump_R1.fastq.gz"
in2="${DATADIR}/fastq_clump/${sample}_clump_R2.fastq.gz"

if [ ! -f "$in1" ] || [ ! -f "$in2" ]; then
    echo "Missing clumped FASTQs for sample $sample" >&2
    echo "Expected:"
    echo "  $in1"
    echo "  $in2"
    exit 1
fi

cd "$SCRATCHDIR" || { echo "Cannot cd to \$SCRATCHDIR" >&2; exit 1; }

mkdir -p fastp_out fastp_reports

# Copy to scratch
rsync "$in1" "$SCRATCHDIR/"
rsync "$in2" "$SCRATCHDIR/"

r1_local=$(basename "$in1")
r2_local=$(basename "$in2")

# Define outputs
out1="fastp_out/${sample}_fastp_R1.fastq.gz"
out2="fastp_out/${sample}_fastp_R2.fastq.gz"
html="fastp_reports/${sample}_fastp.html"
json="fastp_reports/${sample}_fastp.json"

echo "Running fastp for $sample"
echo "  in1: $r1_local"
echo "  in2: $r2_local"
echo "  out1: $out1"
echo "  out2: $out2"

# Run fastp
fastp \
    --in1 "$r1_local" \
    --in2 "$r2_local" \
    --out1 "$out1" \
    --out2 "$out2" \
    --detect_adapter_for_pe \
    --overrepresentation_analysis \
    --html "$html" \
    --json "$json" \
    --thread 8

status=$?
echo "fastp exit code: $status"
if [ $status -ne 0 ]; then
    echo "fastp failed for $sample" >&2
    exit $status
fi

# Copy results back
mkdir -p "${DATADIR}/fastq_fastp" "${DATADIR}/fastp_reports"

rsync fastp_out/${sample}_fastp_R1.fastq.gz "${DATADIR}/fastq_fastp/"
rsync fastp_out/${sample}_fastp_R2.fastq.gz "${DATADIR}/fastq_fastp/"
rsync fastp_reports/${sample}_fastp.html    "${DATADIR}/fastp_reports/"
rsync fastp_reports/${sample}_fastp.json    "${DATADIR}/fastp_reports/"

echo "Finished fastp for $sample"
