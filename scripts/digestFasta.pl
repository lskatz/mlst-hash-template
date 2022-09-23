#!/usr/bin/env perl 

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use File::Basename qw/basename/;
use Digest::MD5 qw/md5_base64/;
use Bio::SeqIO;

use version 0.77;
our $VERSION="0.2";

local $0 = basename $0;
sub logmsg{local $0=basename $0; print STDERR "$0: @_\n";}
exit(main());

sub main{
  my $settings={};
  GetOptions($settings,qw(help force out=s)) or die $!;
  usage() if(!@ARGV || $$settings{help});
  $$settings{out} ||= die "ERROR: need an output directory with --out";

  if(-e $$settings{out} && !$$settings{force}){
    die "ERROR: output folder already exists at $$settings{out}. --force to overwrite.";
  }

  # Make the output directory
  mkdir $$settings{out};
  open(my $refFh,     ">", "$$settings{out}/ref.fasta") or die "ERROR: could not write to $$settings{out}/ref.fasta";
  open(my $allelesFh, ">", "$$settings{out}/alleles.tsv") or die "ERROR: could not write to $$settings{out}/alleles.tsv";

  # allele calling, sequencing tech, assembler
  print $allelesFh join("\t", "# locus","allele","hash-type") ."\n";
  for my $f(@ARGV){
    digestFasta($f, $refFh, $allelesFh, $settings);
  }

  close $allelesFh;
  close $refFh;

  return 0;
}

sub digestFasta{
  my($f, $refFh, $allelesFh, $settings) = @_;
  
  my $in=Bio::SeqIO->new(-file=>$f);
  my $numSeqs = 0;
  while(my $seqObj = $in->next_seq){

    my $seq = $seqObj->seq;
    my $id  = $seqObj->id;
    my $hash = md5_base64($seq);
    my ($locus, $allele) = split(/_/, $id);

    # Check if this is the first allele and if so, 
    # print out the sequence to reference alleles.
    # Increment the number of seqs
    if($numSeqs++ == 0){
      print $refFh ">$id\n$seq\n";
    }
    
    my $alleleLine = join("\t", $locus, $hash, "md5");

    print $allelesFh "$alleleLine\n";
  }

  return $numSeqs;
}


sub usage{
  print "$0: reads fasta file(s) and creates a database in the hashsum format
  The fasta file(s) must be one locus per line. The first allele is the assumed reference.
  Each sequence ID must have the format locus_allele.

  Usage: $0 [options] file1.fasta...
  --out    An output folder which will contain a reference fasta file and a TSV of alleles
  --help   This useful help menu
  \n";
  exit 0;
}

