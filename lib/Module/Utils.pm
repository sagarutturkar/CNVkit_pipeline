package Module::Utils;

use strict;
use warnings;

use Exporter;
use vars qw(@EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION @ISA);

@ISA    = qw(Exporter);
@EXPORT =
  qw(parseINI pbsHeader pbsHeader_short pbsFooter makeDir readInput readDir sendMail readAdapter make_sample_hash);


#==========================================================================================================

sub make_sample_hash {
	
	my $input = shift;
	my $split_token = shift;
	my $hash;
	
	foreach my $sample(sort keys %$input)
	{
		my @data = split $split_token, $sample;
		my $S_Name = $data[0];
		
		$hash->{$S_Name} = 1;
	}
	
	return $hash;
}

#==========================================================================================================

sub parseINI {

	my $file = shift;
	my $hash;
	
	open (IN, "$file") || die "Cannot open INI file as $file \n$!";

	while (my $buf = <IN>)
	{
		chomp($buf);
		next if ($buf =~ /^\#/);

		if ($buf =~ /\=/)
		{
			#print $buf,"\n";
			my @data = (split '=', $buf, 2);
			foreach my $data(@data)
			{
				$data =~ s/^\s+//g;
				$data =~ s/\s+$//g;
				$data =~ s/\"//g;
			}
			$hash->{$data[0]} = $data[1];
		}		
		
	}
	
	close(IN);
	return $hash;

}

#==========================================================================================================

sub readDir {

	my $path = shift;
	my $ext = shift;
	my $hash;
	my @data;
	
	chdir("$path");

	#check if input is empty
	my $input = `ls *$ext | wc -l`;
	if ($input eq 0) 
	{
		die "Error - No files found in the directory";
	}
	
	$input = `ls *$ext`;	

	@data = split /\s+/, $input;
	
	foreach my $data(@data)
	{
		
		$hash->{$data} = 1;
	}
	
	
	
	return $hash;
}


#==========================================================================================================

sub readInput {

	my $path = shift;
	my $type = shift;
	my $hash;
	my @data;
	
	chdir("$path");
	#check if input is empty
	my $input = `ls *.fastq | wc -l`;
	
	if ($input eq 0) 
	{
		die "Error - No input files found in the input directory";
	}
	
	$input = `ls *.fastq`;	

	@data = split /\s+/, $input;
	
	foreach my $data(@data)
	{
		my @sample = split /_/, $data;
		$hash->{$sample[0]}->{$data} = 1;
	}
	
	#check if input type is correct
	my $count = 0;
	my $num_of_sample = scalar(keys %$hash);
	
	foreach my $sample(keys %$hash)
	{
		$count += scalar(keys %{$hash->{$sample}});
	}
	
	if ($type == 0 && $count != $num_of_sample)
	{
		die "\n\tInput is specified as single-end reads, but multiple reads detected for same sample. \n\tPlease check input folder.\n\n";
	}
	
	if ($type == 1 && $count != 2*$num_of_sample)
	{
		die "\n\tInput is specified as paired-end reads, but read pairs absent for atleast one sample. \n\tPlease check input folder.\n\n";
	}
	
	return $hash;
}

#==========================================================================================================

sub pbsHeader {
	#This subroutine will create the header for PBS jobscript
	#Required input in order as below:
	#qname, time, node, processor, jobname, module1, module2....moduleN
	my $qname = shift;
	my $time = shift;
	my $node = shift;
	my $cpu = shift;
	my $email = shift;
	my $name = shift;
	my @modules = @_;
	
	my $module_load;
	
	
	foreach my $module(@modules)
	{
		$module_load .= 'module load '.$module."\n";
	}
	
	my $processor = '#PBS -l nodes='.$node.':ppn='.$cpu;
	my $PBS_email = '#PBS -M '.$email;
	
my $pbs_head = <<"END_MESSAGE";
#!/bin/bash
#PBS -q $qname
#PBS -l walltime=$time
$processor
#PBS -l naccesspolicy=singleuser
#PBS -N $name
#PBS -m bea
$PBS_email

starts\=\$\(date \+\"\%s\"\)
start\=\$\(date \+\"\%r, \%m\-\%d\-\%Y\"\)

$module_load
cd \$PBS_O_WORKDIR

END_MESSAGE

	return $pbs_head;
}


#==========================================================================================================

sub pbsHeader_short {
	#This subroutine will create the header for PBS jobscript
	#Required input in order as below:
	#qname, time, node, processor, jobname, module1, module2....moduleN
	my $qname = shift;
	my $time = shift;
	my $node = shift;
	my $cpu = shift;
	my $name = shift;
	my @modules = @_;
	
	my $module_load;
	
	
	foreach my $module(@modules)
	{
		$module_load .= 'module load '.$module."\n";
	}
	
	my $processor = '#PBS -l nodes='.$node.':ppn='.$cpu;
	
my $pbs_head = <<"END_MESSAGE";
#!/bin/bash
#PBS -q $qname
#PBS -l walltime=$time
$processor
#PBS -l naccesspolicy=singleuser
#PBS -N $name

starts\=\$\(date \+\"\%s\"\)
start\=\$\(date \+\"\%r, \%m\-\%d\-\%Y\"\)

$module_load
cd \$PBS_O_WORKDIR

END_MESSAGE

	return $pbs_head;
}

#==========================================================================================================

sub pbsFooter {
	
my $pbs_foot = <<'END_MESSAGE';


ends=$(date +"%s")
end=$(date +"%r, %m-%d-%Y")
diff=$(($ends-$starts))
hours=$(($diff / 3600))
dif=$(($diff % 3600))
minutes=$(($dif / 60))
seconds=$(($dif % 60))
printf "\n\t===========Time Stamp===========\n"
printf "\tStart\t:$start\n\tEnd\t:$end\n\tTime\t:%02d:%02d:%02d\n" "$hours" "$minutes" "$seconds"
printf "\t================================\n\n"

qstat -f1 $PBS_JOBID | egrep 'Job Id|Job_Name|resources_used|exec_host'

END_MESSAGE

	return $pbs_foot;

}

#==========================================================================================================

sub sendMail {

	my $path = shift;
	my $email = shift;

my $message = <<"END_MESSAGE";
Hi,

The DeconSeq pipeline is complete. Please review the following files:

Submission files and .e. and .o files are available at - $path/submission_files/
Output for each sample is available at - $path/output/
Temporary files are available at - $path/temp/

If output files are as expected, then you can choose to remove the contents of the $path/temp/ folder.

Thank you,
JobMonitor

END_MESSAGE

my $email_cmd = <<EMAIL;
mail -s "Deconseq pipeline Finished" $email << MAIL_EOF
$message
MAIL_EOF
EMAIL

`$email_cmd`;

}

1;
__END__

