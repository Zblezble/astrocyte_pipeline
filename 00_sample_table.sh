#!/usr/bin/env bash

set -euo pipefail

# Set paths
DATADIR="/storage/zblezble/astro"

# Find R1 files and pair them with R2 by filename convention
printf "sample_id\tfq1\tfq2\n" > samples.tsv
while IFS= read -r r1; do
  r2="${r1/_R1/_R2}"
  [ -f "$r2" ] || { echo "WARNING: Missing R2 for $r1" >&2; continue; }
  base=$(basename "$r1")
  sample="${base%%_R1*}"        # everything before _R1
  printf "%s\t%s\t%s\n" "$sample" "$r1" "$r2" >> samples.tsv
done < <(find "$DATADIR" -type f -name "*_R1*.fastq.gz" | sort)
echo "Wrote $(($(wc -l < samples.tsv)-1)) samples to samples.tsv"