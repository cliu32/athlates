#!/usr/bin/perl

# brief	Given the collective HLA cDNA and genomic sequences, remove redundant sequences
#	and create {target}.bed {non-target}.bed files for each type of HLA-gene.

use strict;
use Getopt::Long;
 


my %option = (
	h      	=> '',
	ref		  => '',
	oprefix	=> '',
);

GetOptions(
	"h"			=> \$option{h},
	"ref=s"   => \$option{ref},
  "oprefix=s"	=> \$option{oprefix}
) || printHelp (); 

if ($option{h}) { printHelp();}
unless($option{ref} && $option{oprefix}) { printHelp(); }
printCmd ();


#------------------------------------------------------------------------------------------------------------------------
# Step 1, read reference input, remove redundancy write to a cleaned ref file, meanwhile create .bed file for each gene
#------------------------------------------------------------------------------------------------------------------------
my %geneNames;  # gene_name -> bed file 
my %refNames;   # ref_name -> 1

open (REF, "<$option{ref}") or die "unable to open file $option{ref} to read\n";
my $cleanedfile = $option{oprefix}.".clean.fasta";
open (CLEAN, ">>$cleanedfile") or die "unable to open file $cleanedfile to write\n";

my $header;
my $seq;
my $gene_name;
my $file_id = 0;
my $gene_len;
my $total_ref = 0;
while (<REF>){
	
	if (/>/) {
		if ($seq) {
			if(!$refNames{$header}) { # not previously written 
				print CLEAN ">".$header."\n".$seq."\n";  # cleaned file
				open (BED, ">>$geneNames{$gene_name}") or die "can't open $geneNames{$gene_name}\n";
				print BED $header."\t1\t$gene_len\n";   # bed file
				close (BED);
				$refNames{$header} = 1;
			  $total_ref ++;
			}
		}
		
		my $name = $_;
		$name =~ s/^>//; # remove >
	  $name =~ s/\s+$//; # remove trailing whitespace

		my @elem = split (/\s/, $name); # four fields e.g. "HLA:HLA00001 A*01:01:01:01 3503 bp"
		my $size = $#elem + 1;
		if ($size != 4) {
			print "Error: The header\n$name\nwhen split by space, the number of elems !=4 \n"; 
			exit(1);
		}
		
		# split the second field
		my @split2nd = split(/\*/, $elem[1]);
		$size = $#split2nd + 1;
		if ($size != 2) {
			print "$elem[1] has no * symbol\n";
			exit(1);
		}
		
		$header = $elem[0]."_".$split2nd[0]."_".$split2nd[1]."_".$elem[2];
		$gene_len = $elem[2];
		$gene_name = $split2nd[0];
		
		if (! $geneNames{$gene_name}) { # create a new .bed file
			my $bedfile = $option{oprefix}.".$gene_name.bed";
			$geneNames{$gene_name} = $bedfile;
		}
			
		$seq = ""; # clear out old sequence
		
	} else {
		s/\s+//g; # remove whitespace
    $seq .= $_; # add sequence
	}
}
# the last sequence
if ($seq) {
		print CLEAN ">".$header."\n".$seq."\n";  # cleaned file
		open (BED, ">>$geneNames{$gene_name}") or die "can't open $geneNames{$gene_name}\n";
		print BED $header."\t1\t$gene_len\n";   # bed file
		close (BED);
    $total_ref ++;
}
 
close(REF);

print "\nTotal Reference in $cleanedfile is $total_ref\n\n";

#------------------------------------------------------------------------------------------------------------------------
# Step 2, for each gene create non-{gene}.bed file
#------------------------------------------------------------------------------------------------------------------------

print "Number of genes: " . keys( %geneNames) . ".\n";
my %duplicate = %geneNames;
while(my ($target_gene, $target_bedfile) = each(%geneNames)) {

		print $target_gene."\t";
		
		# create the non-.bed file
		my $non_bed = $option{oprefix}.".non-$target_gene.bed";
		
		system ("touch $non_bed");
		
		while(my($cur_gene, $cur_bedfile) = each(%duplicate)) {
		
			if ($target_gene ne $cur_gene) {
			
				system ("cat $cur_bedfile >> $non_bed");
				
			}
			
		}
}

print "\n\n";

sub printHelp {
	print "\n--------------------------------------------------------------------\n";
	print "usage: ./hla_ref_clean.pl -ref [HLA_ref_db.fa] -oprefix [OutPrefix]\n\n";
	print "\t-ref: Input HLA references collected from IMGT/HLA database\n";
	print "--------------------------------------------------------------------\n\n";
	exit(1);
}

sub printCmd {
	print "\nRunning cmd:\n\t perl hla_ref_clean.pl"; 
	print " -ref $option{hla_prf} -oprefix $option{oprefix}\n\n";	
}
