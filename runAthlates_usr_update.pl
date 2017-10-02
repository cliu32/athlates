#Author: Xiao Yang (with modification by Chang Liu, cliu32@wustl.edu)
#!/usr/bin/perl

use strict;
use Getopt::Long;

my %option = (
	h      		=> '',
	silent 	=> '',
	p 			=> 16,
	# I/O setting 
	ibam		=> '',
	bed		=> '',
	odir		=> '',
	oprf 		=> '',
	msa		=> '',
);

GetOptions(
	"h"				=> \$option{h},
	"p=i"				=> \$option{p},
	"bed=s"			=> \$option{bed},
	"nbed=s"		=> \$option{nbed},
	"ibam=s"		=> \$option{ibam},
	"odir=s"		=> \$option{odir},
	"oprf=s"    	=> \$option{oprf},
	"msa=s"		=> \$option{msa},
) || printHelp (); 

if ($option{h}) { printHelp();}

my $ref = $option{ref};
my $ibam = $option{ibam};
my $bed = $option{bed};
my $nbed = $option{nbed};
my $odir = $option{odir};
my $oprf = $option{oprf};
my $msa = $option{msa};

 
unless ($option{silent}) { 
	print "[CMD] ./$0";
	if ($ibam) { print " -ibam $ibam"; }
		print " -bed $bed -nbed $nbed -odir $odir -oprf $oprf\n\n"; 
}

# -----------------update path in this section-----------------
my $samtool_cmd = "samtools";
my $athlates = "/path/to/athlates/bin/typing";
# -----------------update path in this section-----------------

unless ($bed && $nbed && $odir && $oprf && $msa) {
	print "-ibam, -bed, -nbed, -odir, -oprf, -msa should be specified\n";
	print "Type -h for usage\n";
	exit;
}

# Extract alignment to bed 		
unless ($option{silent}) { "\tExtract alignment to $bed\n"; }
my $tmpbam = "$odir/$oprf.t.bam";
my $tmpsam = "$odir/$oprf.t.sam";
my $tbam = "$odir/$oprf.target.bam";
my $tsam = "$odir/$oprf.target.sam";

system ("$samtool_cmd view -b -L $bed $ibam > $tmpbam");
system ("$samtool_cmd view -h -o $tmpsam $tmpbam");
system ("LC_ALL=C sort -k 1,1 -k 3,3 $tmpsam > $tsam");
system ("$samtool_cmd  view -bS $tsam > $tbam");

`rm $tmpbam`;
`rm $tmpsam`;
`rm $tsam`;

# Extract alignment to non-target bed 		
unless ($option{silent}) { "\tExtract alignment to $nbed\n"; }
my $ntbam = "$odir/$oprf.non-target.bam";
my $ntsam = "$odir/$oprf.non-target.sam";

system ("$samtool_cmd view -b -L $nbed $ibam > $tmpbam");
system ("$samtool_cmd view -h -o $tmpsam $tmpbam");
system ("LC_ALL=C sort -k 1,1 -k 3,3 $tmpsam > $ntsam");
system ("$samtool_cmd  view -bS $ntsam > $ntbam");

`rm $tmpbam`;
`rm $tmpsam`;
`rm $ntsam`;

# athlates
unless ($option{silent}) { "\tRun athlates\n"; }
my $athlate_out = "$odir/$oprf.athlate";
system ("$athlates -bam $tbam -exlbam $ntbam -msa $msa -o $athlate_out");

################################################################################################################################
# sub-functions 
#################################################################################################################################
sub printHelp {
		print "\n----------------------------------------------------------------------------\n";
		print "usage: ./$0 -ibam [input.sorted.bam] -bed [.bed] -nbed [non-target.bed] -msa [msa] -odir [odir] -oprf [oprefix]\n\n";
		print "-silent: no screen output for programs called\n\n";
		print "I/O setting\n";
		print "-ibam: input bam file that stores reads aligned to HLA references\n";
		print "-bed: target bed file\n";
		print "-nbed: non-target bed file\n";
		print "-msa: multiple sequencea alignement of target alleles\n";
		print "-odir: output dir\n";
		print "-oprf: output prefix\n";
		print "\n----------------------------------------------------------------------------\n";
		exit;
}
 
 
