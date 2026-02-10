## 🌟 RNAseq pipeline for iPSC-derived astrocytes

Code used for processing and analyzing RNAseq data generated from iPSC-derived astrocytes. Based on standard operating procedures of the tools used.

Salmon decoy-aware index built according to https://combine-lab.github.io/alevin-tutorial/2019/selective-alignment/


---

## 📂 Contents

This repository contains the full preprocessing and quantification workflow, organized by sequentially numbered directories:

- **00_salmon_index.sh** – generation of the Salmon transcriptome index (decoy-aware)
- **00_sample_table.sh** – table listing all samples pairing forward and reverse reads for array jobs
- **01_clumpify.sh** – fastq file compression (BBMap Clumpify)
- **02_fastqc_multiqc.sh** – Initial QC using FastQC + MultiQC
- **03_fastp.sh** – Adapter trimming and read filtering
- **04_fastqc.sh** – Post-trim FastQC
- **05_multiqc.sh** – Aggregated QC reporting
- **06_salmon.sh** – Transcript quantification with Salmon
- **07_tximport_limma.R** – Import to R (tximport), normalization, and differential expression using limma
- LICENSE – Licensing information
- README.md – This file

---

## 🔍 Features and usage

- Complete, reproducible RNAseq processing chain from raw fastq reads to DEGs.
- Designed for **Metacentrum** featuring PBS batch and PBS batch array jobs.
- Each file contains code used for that pipeline step.
- Steps were executed in numerical order.
- **Note:** Running FastQC as a PBS array job (04) and MultiQC as a separate job (05) is more efficient than the original combined approach (02).


---

## 🧩 Tools Used

- FastQC – https://github.com/s-andrews/FastQC
- MultiQC – https://github.com/MultiQC/MultiQC
- Salmon – https://github.com/COMBINE-lab/salmon
- BBMap / Clumpify – https://github.com/BioInfoTools/BBMap
- fastp – https://github.com/OpenGene/fastp
- tximport – https://github.com/mikelove/tximport
- limma – https://github.com/Bioconductor-mirror/limma

---

## 📜 License

This repository is released under the BSD-3-Clause license. See LICENSE for details.
