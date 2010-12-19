#!/usr/bin/perl -w

# this file creates an custom installer of spring "on the fly"
# run with this parameters:
# make_custom_installer.pl spring_setup.exe [file1 <existing relative path/output filename>]* >spring_customsetup.exe

use strict;
use warnings;

if ( @ARGV == 0) {
	die "Missing arguments:
make_custom_installer.pl spring_setup.exe [file1 <existing relative path/output filename>]* >spring_customsetup.exe
";
}

sub dumpFile {
	my ($filename) = @_;
	my $buf;
	printf STDERR "Reading $filename\n";
	open(FILE, "<$filename") or die "Can't open $filename";
	binmode(FILE);
	while(read(FILE,$buf, 4096)){
		print $buf;
	}
	close(FILE);
}

binmode(STDOUT);
my $i = 0;
my $setupsize = -1;
while ( $i < @ARGV ){
	my $inputfile=$ARGV[$i];
	my $outputfilename=$ARGV[$i+1];
	my $filesize= -s $inputfile;
	if ($setupsize<0){
		dumpFile($inputfile);
		$setupsize=$filesize;
	}else{
		print pack "V", length($outputfilename)+1; #(filenamesize + 0 byte)
		print $outputfilename."\0";
		print pack "V", $filesize;
		dumpFile($inputfile);
		$i++;
	}
	$i++;
}
#Write Signature
print pack "V", 0; # end mark
print "SPRING";
print pack "V", $setupsize;

