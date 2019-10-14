# CNVkit Pipeline
This pipeline prepares [CNVkit](https://cnvkit.readthedocs.io/en/stable/quickstart.html) steps for somatic CNV calling with WGS/WES data (BAM) to run on a cluster.

## Prerequisites:
1. Pipeline assumes that you have the CNVkit installed and user is well-versed with CNVkit steps and documentation.
2. Pipeline is currently set to run on the Purdue University RCAC Clusters and may need updates to run on other clusters.

## Expected Input:
1. Indexed BAM files for tumor and normal samples. BAM files generated through GATK best practices works.
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
3. Prepare the pipeline with command `sh prepare_CNVkit.sh`.
4. Link or copy the BAM files to `input` directory. 
5. Follow the above naming convention for input BAMs. 

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
cd CNVkit_pipeline
perl 1_CNV.pl

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

## Output files:
A short description for each output file is provided. Please check [this link](https://cnvkit.readthedocs.io/en/stable/fileformats.html#) for detailed information.  

### Result files in the **/output/CNVkit** directory:

| File Name 	| File Description 	|
|---------------------------------	|----------------------------------------------------------	|
| *_normal.antitargetcoverage.cnn 	| bin-level anticoverage file Normal sample 	|
| *_normal.targetcoverage.cnn 	| bin-level covarge file for normal sample 	|
| *_tumor.antitargetcoverage.cnn 	| bin-level anticoverage file Tumor sample 	|
| *_tumor.targetcoverage.cnn 	| bin-level covarge file for Tumor sample 	|
| *_tumor.cnr 	| Bin-level log2 ratios by Sample 	|
| *_tumor.cns 	| Segmented log2 ratios by Sample 	|
| reference.cnn 	| Copy number reference profile (All Normal Samples) 	|
| heatmap.png 	| Chromosme level copy number heatmap for multiple samples 	|


#### Example Heatmap:
![**Figure A**](/lib/data/heatmap.png) 

### Result files in the **/output/\<SAMPLE\>** directory:

| File Name 	| File Description 	|
|--------------------------------	|----------------------------------------------------------------------	|
| *_Results.xlsx 	| Combined result files in excel format 	|
| *_diagram.png 	| Copy number shown on each chromosome as an ideogram 	|
| *_scatter.png 	| bin-level log2 coverages and segmentation calls plotted by chromosme 	|
| *_genebreaks.txt 	| List the targeted genes in which a segmentation breakpoint occurs. 	|
| *_genemetrics_with_ratio.txt 	| targeted genes with copy number gain or loss (by ratio) 	|
| *_genemetrics_with_segment.txt 	| targeted genes with copy number gain or loss (by segment) 	|
| *_ratio-genes.txt 	| genelist (by ratio) - 	|
| *_segment-genes.txt 	| genelist (by segment) 	|
| *_trusted_genes.txt 	| genelist and cn (affected by both ratio and segment) 	|
| *_tumor.call.filtered.cns 	| Estimated absolute integer copy number for each segment 	|
| *_tumor.segmetrics.cns 	| summary statistics of the residual bin-level log2 ratio estimates 	|

#### Example Diagram plot:
![**Figure B**](/lib/data/T1_diagram.png) 

#### Example Scatter plot:
![**Figure C**](/lib/data/T1_scatter.png) 

#### Estimated absolute integer copy number for each segment available in the file *_tumor.call.filtered.cns:

| Copy Number Call 	| Interpretation 	|
|------------------	|-------------------------------------	|
| 0 	| homozygous deletion (2-copy loss) 	|
| 1 	| heterozygous deletion (1-copy loss) 	|
| 2 	| normal diploid state 	|
| 3 	| one copy gain 	|
| 4 	| amplification (>= 2-copy gain) 	|

#### Preview of contingency table of affected genes by sample in file Ctable.txt:
1. The number in each column denotes the copy-number associated with specific sample 
2. BLANK value denotes NO gain/loss detected.
3. `Altered in Samples` denotes the total number of samples with gain/loss.

| Gene_ID 	| T1 	| T10 	| T2 	| T3 	| T4 	| T6 	| T7 	| T8 	| T9 	| Altered in Samples 	|
|--------------------	|----	|-----	|----	|----	|----	|----	|----	|----	|----	|--------------------	|
| CSMD3 	|  	| 3 	| 3 	| 3 	|  	| 4 	|  	| 3 	| 3 	| 6 	|
| ENSCAFG00000038475 	|  	| 3 	| 3 	| 3 	|  	| 4 	|  	| 3 	| 3 	| 6 	|
| ENSCAFG00000036360 	|  	| 3 	| 3 	| 3 	|  	| 4 	|  	| 3 	| 3 	| 6 	|
| SLC30A8 	|  	| 3 	| 3 	| 3 	|  	| 4 	|  	| 3 	| 3 	| 6 	|
| ENSCAFG00000032793 	|  	| 3 	| 3 	| 3 	|  	| 4 	|  	| 3 	| 3 	| 6 	|
| ENSCAFG00000038488 	|  	| 3 	| 3 	| 3 	|  	| 4 	|  	| 3 	| 3 	| 6 	|
| KCTD8 	|  	|  	| 3 	| 3 	| 0 	| 4 	|  	| 3 	| 3 	| 6 	|





