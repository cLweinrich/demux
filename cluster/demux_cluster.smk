# Demultiplexing Snakefile - clustering

### Setup ###
configfile: "config.yaml"
workdir: config["workdir"]

import pandas
samples = [s for s in pandas.read_csv(config["minibar_barcodes_file"], header=None, delimiter="\t").loc[:,0].tolist()]
#### # ###

### Output ###
rule all:
    input:
        [f"output/6_sorted/{sample}.fasta" for sample in samples]
### # ###

### Workflow ###
rule minibar:
    input:
        config["basecalled_fastq"]
    output:
        expand("output/1_minibar/sample_{sample}.fastq", sample=samples)
    params:
        mamba_env=config["mamba_env"],
        minibar_e=config["minibar_barcode_e"],
        minibar_E=config["minibar_primer_E"],
        barcodes_file=config["minibar_barcodes_file"],
        minibar_cols=config["minibar_cols"]
    threads:
        1
    shell:
        "mamba run -n {params.mamba_env} python "
        "minibar.py "
        "-e {params.minibar_e} "
        "-E {params.minibar_E} "
        "{params.barcodes_file} "
        "{input} "
        "-F "
        "-T "
        "-cols {params.minibar_cols}; "
        "for f in sample_*.fastq; do mv $f output/1_minibar; done"

rule derep:
    input:
        "output/1_minibar/sample_{sample}.fastq"
    output:
        "output/2_derep/{sample}.fastq"
    params:
        mamba_env=config["mamba_env"],
        q_max=config["q_max"],
        fasta_width=config["fasta_width"]
    threads:
        1
    shell:        
        "mamba run -n {params.mamba_env} vsearch "
        "--fastx_uniques {input} "
        "--fastqout {output} "
        "--fastq_qout_max "
        "--fastq_qmaxout {params.q_max} "
        "--sizeout "
        "--fasta_width {params.fasta_width}"

rule fastq_filter:
    input:
        "output/2_derep/{sample}.fastq"
    output: 
        "output/3_filter/{sample}.fasta"
    params:
        mamba_env=config["mamba_env"],
        max_ee=config["max_expected_error"],
        min_len=config["min_len"],
        max_len=config["max_len"],
        max_ns=config["max_ns"],
        q_max=config["q_max"],
        fasta_width=config["fasta_width"]
    threads:
        1
    shell:
        "mamba run -n {params.mamba_env} vsearch "
        "--fastq_filter {input} "
        "--fastq_maxee {params.max_ee} "
        "--fastq_minlen {params.min_len} "
        "--fastq_maxlen {params.max_len} "
        "--fastq_maxns {params.max_ns} "
        "--fastq_qmax {params.q_max} "
        "--fastaout {output} "
        "--fasta_width {params.fasta_width}"

rule cluster:
    input:
        "output/3_filter/{sample}.fasta"
    output:
        "output/4_cluster/{sample}.fasta"
    params:
        mamba_env=config["mamba_env"],
        alpha=config["denoise_alpha"],
        minsize=config["denoise_minsize"],
        fasta_width=config["fasta_width"]
    threads:
        1
    shell:
        "mamba run -n {params.mamba_env} vsearch " 
        "--cluster_unoise {input} "
        "--unoise_alpha {params.alpha} "
        "--minsize {params.minsize} "
        "--sizein "
        "--sizeout "
        "--fasta_width {params.fasta_width} "
        "--consout {output}"

rule uchime3_denovo:
    input:
        "output/4_cluster/{sample}.fasta"
    output:
        "output/5_nonchimeras/{sample}.fasta"
    params:
        mamba_env=config["mamba_env"],
        fasta_width=config["fasta_width"]
    threads:
        1
    shell:
        "mamba run -n {params.mamba_env} vsearch " 
        "--uchime3_denovo {input} "
        "--sizein "
        "--sizeout "
        "--fasta_width {params.fasta_width} "
        "--qmask none "
        "--nonchimeras {output}"

rule size_sort:
    input:
        "output/5_nonchimeras/{sample}.fasta"
    output:
        "output/6_sorted/{sample}.fasta"
    params:
        mamba_env=config["mamba_env"],
        fasta_width=config["fasta_width"],
        minsize=config["size_sort_minsize"]
    shell:
        "mamba run -n {params.mamba_env} vsearch " 
        "--sortbysize {input} "
        "--sizein "
        "--sizeout "
        "--fasta_width {params.fasta_width} "
        "--minsize {params.minsize} "
        "--output {output}"
