# CNVkit Pipeline
This pipeline prepares [CNVkit](https://cnvkit.readthedocs.io/en/stable/quickstart.html) steps for somatic CNV calling with WGS/WES data (BAM) to run on a cluster.

## Prerequisites:
1. Pipeline assumes that you have the CNVkit installed and user is well-versed with CNVkit steps and documentation.
2. Pipeline is currently set to run on the Purdue University RCAC Clusters and may need updates to run on other clusters.

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

### Step 1: (Prepare pipeline and inputs)
In this step, we will prepare the pipeline, set the parameters and copy the input files using the below substeps.

1. Create empty directory and clone the repository.
2. Set the appropriate parameters in the file `parameters.ini`.
3. Prpeare the pipeline with command `sh prepare_CNVkit.sh`.
4. Link or copy the BAM files to `input` directory. 
5. Follow the above naming convension for input BAMs. 

```
# Clone repository
git clone https://github.com/sagarutturkar/CNVkit_pipeline.git

# Prepare Pipeline
cd CNVkit_pipeline
dos2unix prepare_CNVkit.sh.txt
sh prepare_CNVkit.sh.txt


# Copy or link input BAM
cd input
scp <PATH>/T1_normal* ./
scp <PATH>/T1_tumor* ./
```
#### Note:
> Matched normal for every sample is not required but make sure to include sufficient number of normal samples. See CNVkit documentation for details.

### Step 2: (Prepare Submission files)
In this step we will prepare the submission files for batch and individual sample processing and submit the jobs to the cluster using the below substeps.

1. Run the perl script as `perl 1_CNV.pl` to achieve following. 
      -  Submission files will be generated in the directory `submission_files` according to `parameters.ini`.
      -  File `CNVkit.sub` has commands to process data in batch mode for all samples.
      -  Remaining submission files has commands to process individual sample data.
      -  Easy submit jobs with `sh step_1.sh`.
      
2. Run the individual sample commands **only after successful completion of job** `CNVkit.sub`.
      -  Easy submit multiple jobs with `sh step_2.sh`.

```
cd submission_files
sh step_1.sh

#After successful completion of job CNVkit.sub
sh step_2.sh
```
#### Note:
> This step completes all the steps for CNVkit and generates separate CNV calls for each individual samples.

### Step 3: (Run Custom python scripts):
1. [cnv_parser.py](https://github.com/sagarutturkar/CNVkit_pipeline/blob/master/lib/scripts/cnv_parser.py): It is useful to generate the list of **Trusted genes** [(more information here)](https://cnvkit.readthedocs.io/en/stable/reports.html#genemetrics) that are affected at both ratio and segment levels. 
2. [make_ctable.py](https://github.com/sagarutturkar/CNVkit_pipeline/blob/master/lib/scripts/make_ctable.py): It is useful to have the contingency table of cn-gain (copy number > 2) and cn-loss (copy number < 2) across all samples.

#### [cnv_parser.py](https://github.com/sagarutturkar/CNVkit_pipeline/blob/master/lib/scripts/cnv_parser.py):
> This script will determine the intersection of ratio and segment affected genes and then only selects the subset of genes having copy number gain or loss by both methods.

```
# This step has already been incarporated in the previous submission file.
# Resulting file - *_trusted_* is available for each sample.
```
#### [make_ctable.py](https://github.com/sagarutturkar/CNVkit_pipeline/blob/master/lib/scripts/make_ctable.py):
> This table will read the combined list of Trusted genes from all samples and prepare the contingency table of genes by samples. The table is sorted by the gene that is altered in most number of samples.

```
cd output

find `pwd` -name "*trusted*" | xargs -I {} sh -c " tail -n+2 {} | cat" > All_sample_cn.txt

python ../lib/scripts/make_ctable.py -infile  All_sample_cn.txt  -outfile  Ctable.txt
```








