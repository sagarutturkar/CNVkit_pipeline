# CNVkit Pipeline
This pipeline prepares [CNVkit](https://cnvkit.readthedocs.io/en/stable/quickstart.html) steps for mapped WGS/WES data (BAM) that can be run on a cluster.

## Prerequisites:
Pipeline assumes that you have the CNVkit installed and user has knowledge of CNVkit steps.

## Expected Input:
1. Indexed BAM files for tumor and normal samples. BAM files generated through GATK best practises works.
2. Tumor and Normal samples should be named with suffix `_tumor` and `_normal`, respectively.

Example input files for the two samples `T1` and `T2`.
```
T1_normal.bai  T1_normal.bam
T1_tumor.bai   T1_tumor.bam

T2_normal.bai  T2_normal.bam
T2_tumor.bai   T2_tumor.bam
```
## Pipeline steps:

### Step 1:
1. Create empty directory and clone the repository.
2. Set the parameters in the file `parameters.ini`.
3. Prpeare the pipeline with command `sh prepare_CNVkit.sh`.
4. Link or copy the BAM files to `input` directory. 
5. Follow the above naming convension for input BAMs.

