#!/usr/bin/env perl 

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use File::Basename qw/basename/;
use Digest::MD5 qw/md5_base64/;
use Digest::SHA qw/sha1_base64 sha256_base64/;

use version 0.77;
our $VERSION="0.3";

# Make a hashing function that is global. It will reference
# a hashing algorithm.
my $hash_function;

local $0 = basename $0;
sub logmsg{local $0=basename $0; print STDERR "$0: @_\n";}
exit(main());

sub main{
  my $settings={};
  GetOptions($settings,qw(help hash=s force out=s)) or die $!;
  usage() if(!@ARGV || $$settings{help});
  $$settings{out} ||= die "ERROR: need an output directory with --out";
  $$settings{hash}||= "md5";

  # Decide on a hashing algorithm
  if(lc($$settings{hash}) eq "md5"){
    $hash_function = \&md5_base64;
  }
  elsif(lc($$settings{hash}) eq "sha1"){
    $hash_function = \&sha1_base64;
  }
  elsif(lc($$settings{hash}) eq "sha256"){
    $hash_function = \&sha256_base64;
  }
  elsif(lc($$settings{hash}) eq "plaintext"){
    $hash_function = \&uc;
  }
  else{
    die "ERROR: I do not understand --hash $$settings{hash}";
  }

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
 
    my $hash = &$hash_function($seq);
    # try for a right split so that only the last _ is used to split locus/allele
    #my ($locus, $allele) = split(/_/, $id);
    # https://stackoverflow.com/a/25173358
    my ($locus, $allele) = split(/_([^_]+)$/, $id);
 
    # Check if this is the first allele and if so, 
    # print out the sequence to reference alleles.
    # Increment the number of seqs
    if($numSeqs++ == 0){
      print $refFh ">$id\n$seq\n";
    }
    
    my $alleleLine = join("\t", $locus, $hash, $$settings{hash});

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

sub uc{
  return(uc($_[0]));
}

sub usage{
  print "$0: reads fasta file(s) and creates a database in the hashsum format
  The fasta file(s) must be one locus per line. The first allele is the assumed reference.
  Each sequence ID must have the format locus_allele.
  Usage: $0 [options] file1.fasta...
  --out    An output folder which will contain a reference fasta file and a TSV of alleles
  --hash   Which algorithm to use? md5 (default), sha256, sha1, plaintext
  --help   This useful help menu
  \n";
  exit 0;
}

