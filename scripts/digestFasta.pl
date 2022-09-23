#!/usr/bin/env perl 

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use File::Basename qw/basename/;
use Digest::MD5 qw/md5_base64/;

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
    logmsg "Processing $f";
    digestFasta($f, $refFh, $allelesFh, $settings);
  }

  close $allelesFh;
  close $refFh;

  return 0;
}

sub digestFasta{
  my($f, $refFh, $allelesFh, $settings) = @_;
  

  my $numSeqs = 0;
  open(my $seqFh, "<", "$f") or die "ERROR: could not open $f for reading";
  my @aux = undef;
  my ($id, $seq);
  my ($n, $slen, $comment, $qlen) = (0, 0, 0);
  while ( ($id, $seq, undef) = readfq($seqFh, \@aux)) {
 
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

# Read fq subroutine from Andrea which was inspired by lh3
sub readfq {
    my ($fh, $aux) = @_;
    @$aux = [undef, 0] if (!(@$aux));	# remove deprecated 'defined'
    return if ($aux->[1]);
    if (!defined($aux->[0])) {
        while (<$fh>) {
            chomp;
            if (substr($_, 0, 1) eq '>' || substr($_, 0, 1) eq '@') {
                $aux->[0] = $_;
                last;
            }
        }
        if (!defined($aux->[0])) {
            $aux->[1] = 1;
            return;
        }
    }
    my $name = /^.(\S+)/? $1 : '';
    my $comm = /^.\S+\s+(.*)/? $1 : ''; # retain "comment"
    my $seq = '';
    my $c;
    $aux->[0] = undef;
    while (<$fh>) {
        chomp;
        $c = substr($_, 0, 1);
        last if ($c eq '>' || $c eq '@' || $c eq '+');
        $seq .= $_;
    }
    $aux->[0] = $_;
    $aux->[1] = 1 if (!defined($aux->[0]));
    return ($name, $seq) if ($c ne '+');
    my $qual = '';
    while (<$fh>) {
        chomp;
        $qual .= $_;
        if (length($qual) >= length($seq)) {
            $aux->[0] = undef;
            return ($name, $seq, $comm, $qual);
        }
    }
    $aux->[1] = 1;
    return ($name, $seq, $comm);
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

