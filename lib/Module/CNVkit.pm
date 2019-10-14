package Module::CNVkit;

use strict;
use warnings;
use Exporter;
use Data::Dumper;
use Module::Utils;

use vars qw(@EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION @ISA);

@ISA    = qw(Exporter);
@EXPORT =
  qw(cnvkit cnvkit_by_sample);

#==========================================================================================================

sub cnvkit {
	
	my $path = shift;
	my $ini = shift;
	my $input = shift;
	
	my $cmd_before;		
	my $CNV;
	my $cmd_after;

	#prepare shell script for submission
	open (SC, ">$path/submission_files/step_1.sh") || die	"Cannot open file $path/submission_files/step_1.sh for writing $! \n";
	
	$cmd_before .= "# Running CNVkit together for all samples \n\n";
	$cmd_before .= "mkdir $path/output/CNVkit \n";
	$cmd_before .= "cd $path/output/CNVkit  \n\n";
	
	$CNV = "cnvkit.py batch ";
	
	if ($ini->{'experiment_type'} eq 'WGS')
	{
		$CNV .= "-m wgs \\\n";
	}

	$CNV .= "--drop-low-coverage -p $ini->{'num_cpus'} \\\n";
	
	my $tumor;
	my $normal = "-n \\\n";

	foreach my $sample(sort keys %$input)
	{
		
		if ($sample =~ /tumor/s)
		{
			$tumor .= "$path/input/$sample \\\n";
		}
		
		if ($sample =~ /normal/s)
		{
			$normal .= "$path/input/$sample \\\n";
		}
		
	}
	
	$CNV .= $tumor;
	$CNV .= $normal;
	$CNV .= "-f  $ini->{'ref_fasta'} \\\n";
	$CNV .= "--annotate $ini->{'annotation'} \\\n";	
	$CNV .= "--output-reference reference.cnn \n\n";
	
	$cmd_after .= "cnvkit.py heatmap *.cns -d -o heatmap.pdf  \n";
	$cmd_after .= "convert -density 300 -depth 8 -quality 100 -background white -alpha remove heatmap.pdf heatmap.png  \n";
	
	open (MF, ">$path/submission_files/CNVkit.sub") || die "Cannot open file $path/submission_files/CNVkit.sub for writing $! \n";	
	print MF pbsHeader($ini->{'cluster'},  $ini->{'time_needed'},  $ini->{'num_nodes'},  $ini->{'num_cpus'}, $ini->{'email'}, "CNVkit_All" ,"bioinfo", "CNVkit");
	print MF $cmd_before;
	print MF $CNV;
	print MF $cmd_after;
	print MF pbsFooter();
	close(MF);

	print SC "qsub -W umask=022 CNVkit.sub \n";
	print SC "sleep 2s \n\n";

	close(SC);
}

sub cnvkit_by_sample {
	
	my $path = shift;
	my $ini = shift;
	my $input = shift;
	
	#prepare shell script for submission
	open (SC, ">$path/submission_files/step_2.sh") || die	"Cannot open file $path/submission_files/step_1.sh for writing $! \n";
	
	foreach my $sample(sort keys %$input)
	{
		
		my $cmd_before;		
		my $CNV;
		my $cmd_after;
		
		next if ($sample =~ /_normal/);
		
		$sample =~ s/_.*//s;
		
		my $tumor = $sample."_tumor";
		
		$cmd_before .= "mkdir $path/output/$sample \n";
		$cmd_before .= "cd $path/output/$sample  \n\n";
		
		#scatter plot commands
		$CNV .= "#generate scatter plot \n";
		$CNV .= "cnvkit.py scatter $path/output/CNVkit/$sample"
		."_tumor.cnr  -s $path/output/CNVkit/$sample"
		."_tumor.cns -o $sample"
		."_scatter.pdf \n";
		
		$CNV .= "convert -density 300 -depth 8 -quality 100 -background white -alpha remove $sample"
		."_scatter.pdf $sample"
		."_scatter.png \n\n\n";
		
		#diagram plot commands
		$CNV .= "#generate diagram plot \n";
		$CNV .= "cnvkit.py diagram -t 2 -s $path/output/CNVkit/$sample"
		."_tumor.cns -o $sample"
		."_diagram.pdf \n";
		
		$CNV .= "convert -density 300 -depth 8 -quality 100 -background white -alpha remove $sample"
		."_diagram.pdf $sample"
		."_diagram.png \n\n\n";
		
		$CNV .= "# List the targeted genes in which a segmentation breakpoint occurs \n";
		$CNV .= "cnvkit.py breaks $path/output/CNVkit/$sample"
		."_tumor.cnr $path/output/CNVkit/$sample"
		."_tumor.cns -o $sample"
		."_genebreaks.txt  \n\n";
		
		
		$CNV .= "# Calling copy number gains and losses \n";
		$CNV .= "# The --filter option is used to reduce the number of false-positive segments returned. \n";
		$CNV .= "cnvkit.py segmetrics --drop-low-coverage --ci --sem \\\n";
		$CNV .= "$path/output/CNVkit/$tumor.cnr -s $path/output/CNVkit/$tumor.cns \\\n";
		$CNV .= "-o $tumor.segmetrics.cns \n\n";
		$CNV .= "cnvkit.py call --drop-low-coverage --filter ci  \\\n";
		$CNV .= "$tumor.segmetrics.cns -o $tumor.call.filtered.cns \n\n";

		$CNV .= "# genemetrics with ratio \n";
		$CNV .= "cnvkit.py genemetrics  $path/output/CNVkit/$sample"
		."_tumor.cnr > $sample"
		."_genemetrics_with_ratio.txt  \n";
		
		$CNV .= "tail -n+2  $sample"
		."_genemetrics_with_ratio.txt   | cut -f1 | sort > $sample"
		."_ratio-genes.txt  \n\n";
		
		$CNV .= "# genemetrics with segment \n";
		$CNV .= "cnvkit.py genemetrics  $path/output/CNVkit/$sample"
		."_tumor.cnr -s $path/output/$sample/$sample"
		."_tumor.call.filtered.cns > $sample"
		."_genemetrics_with_segment.txt  \n";
		
		$CNV .= "tail -n+2  $sample"
		."_genemetrics_with_segment.txt   | cut -f 1,8 | sort > $sample"
		."_segment-genes.txt  \n\n";
		
		$CNV .= "python $path/lib/scripts/cnv_parser.py  -ratio_genes  $sample"
		."_ratio-genes.txt -seg_genes $sample"
		."_segment-genes.txt -prefix $sample \n\n";
		
#		$CNV .= "comm -12 $sample"
#		."_ratio-genes.txt $sample"
#		."_segment-genes.txt > $sample"
#		."_trusted-genes.txt \n\n\n";
				
		
		$cmd_after .= "perl /depot/pccr/data/Utils/GitHub/General-Purpose-Scripts/tab2xlsx_mul.pl \\\n";
		$cmd_after .= "$path/lib/data/columns.txt,$sample"."_tumor.call.filtered.cns,$sample"."_genemetrics_with_ratio.txt,$sample"."_genemetrics_with_segment.txt,$sample"."_genebreaks.txt,$sample"."_trusted_genes.txt \\\n";
		$cmd_after .= "Column_Description,Gainloss,genemetrics_with_ratio,genemetrics_with_segment,genebreaks,Trusted_genes $sample"."_Results.xlsx \n\n";
		
		#$cmd_after .= "sed \-i \-e \'s\/\$\/\\t$sample\/\'  $sample".'_trusted-genes.txt'."\n";
		$cmd_after .= "rm \*\.pdf\n";
		
		
		open (MF, ">$path/submission_files/$sample.sub") || die "Cannot open file $path/submission_files/$sample.sub for writing $! \n";
		
		#write to shell script
		print SC "qsub -W umask=022 $sample.sub \n";
                print SC "sleep 2s \n\n";
                
                print MF pbsHeader($ini->{'cluster'},  $ini->{'time_needed'},  $ini->{'num_nodes'},  $ini->{'num_cpus'}, $ini->{'email'}, $sample,  "bioinfo", "CNVkit", "biopython");
		
                print MF $cmd_before;
                print MF $CNV;
                print MF $cmd_after;
                print MF pbsFooter();
                
                close(MF);
	}
	
	close(SC);
	
}


1;
__END__

