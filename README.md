# Demultiplexing Workflows
This repo contains two [Snakemake](https://snakemake.readthedocs.io/en/stable/index.html) workflows for demultiplexing and clustering nucleotide sequences.
First, reads are demultiplexed by [minibar](https://github.com/calacademy-research/minibar/blob/master/minibar.py).
Reads are then dereplicated, quality filtered, and clustered by [VSEARCH](https://github.com/torognes/vsearch).
After clustering, chimeric reads are removed (vsearch --uchime3_denovo) and the final reads are sorted in order of decreasing cluster size in the final output .fastas.

![alt text](https://github.com/cLweinrich/demux/blob/main/workflow.svg)

## Workflows 
The two versions of the workflow are identical except for the clustering step:
* The "cluster" version implements a single-pass, greedy centroid-based algorithm (vsearch --cluster_size). This version is more likely to combine similar species/sequences into the same cluster.

* The "denoise" version implements the [UNOISE2](https://drive5.com/usearch/manual/unoise_algo.html) amplicon correction/denoising algorithm. This version is more likely to split a single species into multiple clusters.

## Setup
### Dependencies
Both workflows require Snakemake, VSEARCH, and [Edlib](https://github.com/Martinsos/edlib) (required for minibar).

My recommendation is to create two separate [Mamba](https://mamba.readthedocs.io/en/latest/index.html) environments, one for Snakemake and one for VSEARCH and Edlib.

The Snakemake env will be used to execute the workflow, and the other env will be specified in the config.yaml and will be called within the workflow for execution.

### File Requirements
Both workflows have the file same requirements:
  1. .fastq file containing sequences to be demultiplexed and clustered
  2. minibar.py
  3. Barcode/primer specification file for minibar
  4. demux_denoise.smk / demux_cluster.smk
  5. denoise_config.yaml / cluster_config.yaml
  6. (Optional) .job file for running the workflow on Argon

Neither minibar.py nor the .smk file need to be altered between runs. 

All configuration options are in the .yaml configuration file.
