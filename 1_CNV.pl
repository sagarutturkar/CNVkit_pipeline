#use 5.10.0;
use strict;
use warnings;

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use Data::Dumper;
use Module::Utils;
use Module::CNVkit;

#Get the path for the current directory
my $base_path = $FindBin::Bin;

#Read the input INI file
my $ini_file = "$base_path/parameters.ini";
my $ini = parseINI($ini_file);

#Access the INI file information in variable
my $input = readDir("$base_path/input/", "bam");
my $sample_hash = make_sample_hash($input, "_");

#print Dumper $input;

cnvkit($base_path,$ini, $input);
cnvkit_by_sample($base_path,$ini,$input)


