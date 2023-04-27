#!/usr/bin/env perl 

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use File::Basename qw/basename/;
use Digest::MD5 qw/md5_base64 md5_hex/;
use File::Temp qw/tempdir/;
use File::Copy qw/mv/;

use MIME::Base64 qw/decode_base64/;

use version 0.77;

local $0 = basename $0;
sub logmsg{local $0=basename $0; print STDERR "$0: @_\n";}
exit(main());

sub main{
  my $settings={};
  GetOptions($settings,qw(help force tempdir=s db=s out=s)) or die $!;
  usage() if(!@ARGV || $$settings{help});
  $$settings{db}  ||= die "ERROR: need an input directory with --in";
  $$settings{tempdir} ||= tempdir("$0.XXXXXX", CLEANUP=>1, TMPDIR=>1);
  $$settings{out} ||= die "ERROR: need an output directory with --out";

  if(-e $$settings{out} && !$$settings{force}){
    die "ERROR: output folder already exists at $$settings{out}. --force to overwrite.";
  }
  mkdir $$settings{out};
  mkdir $$settings{tempdir} if(!-e $$settings{tempdir});

  my $hashDb = readHashDb($$settings{db}, $settings);
  logmsg "Converted $$settings{db} into $hashDb";

  mlstype(\@ARGV, $hashDb, $$settings{out}, $settings);

  return 0;
}

sub mlstype{
  my($queries, $hashDb, $outdir, $settings) = @_;

  for my $inFasta(@$queries){
    my $sample = basename($inFasta);
    $sample =~ s/\.(fa|fasta|fna)$//;
    logmsg "Querying $sample against $hashDb";
    
    my $outFasta = "$outdir/".basename($inFasta);
    print "EToKi.py MLSType -i $inFasta -r $hashDb/ref.fasta -d $hashDb/etoki.csv -k $sample -o $outFasta.tmp"."\n";
    system("EToKi.py MLSType -i $inFasta -r $hashDb/ref.fasta -d $hashDb/etoki.csv -k $sample -o $outFasta.tmp");
    die "ERROR running EToKi.py MLSType: $!" if $?;

    mv("$outFasta.tmp", $outFasta) or die "ERROR: could not rename $outFasta.tmp to $outFasta: $!";
  }
}

sub readHashDb{
  my($dbDir, $settings) = @_;

  my $alleles = readAlleles("$dbDir/alleles.tsv", $settings);
  my $ref = readRef("$dbDir/ref.fasta", $settings);

  my $dir = saveDb($ref, $alleles, $settings);

  return $dir;
}

# Save a hash of alleles and ref into an EToKi database
sub saveDb{
  my($ref, $alleles, $settings) = @_;

  my $dir = "$$settings{tempdir}/etoki_db";
  mkdir $dir;

  my %alleleInt;
  open(my $allelesFh, ">", "$dir/etoki.csv") or die "ERROR: could not open $dir/etoki.csv for writing: $!";
  for my $alleleInfo(@$alleles){
    my $hex = join("-",
      substr($$alleleInfo{hex},0,8),
      substr($$alleleInfo{hex},8,4),
      substr($$alleleInfo{hex},12,4),
      substr($$alleleInfo{hex},16,4),
      substr($$alleleInfo{hex},20,12),
    );

    print $allelesFh join(",", $hex, $$alleleInfo{locus}, ++$alleleInt{$$alleleInfo{locus}})."\n";
  }
  close $allelesFh;

  open(my $refFh, ">", "$dir/ref.fasta") or die "ERROR: could not write to $dir/ref.fasta: $!";
  print $refFh $ref;
  close $refFh;

  return $dir;
}


sub readRef{
  my($fasta, $settings) = @_;

  local $/ = undef;
  open(my $fh, $fasta) or die "ERROR: could not read $fasta: $!";
  my $content = <$fh>;
  close $fh;
  return $content;
}

sub readAlleles{
  my($tsv, $settings) = @_;

  my @allele;

  open(my $fh, $tsv) or die "ERROR: could not read $tsv: $!";
  while(<$fh>){
    chomp;
    if(/^#/){
      next;
    }

    my($locus, $base64, $algo) = split(/\t/, $_);
    if(lc($algo) ne "md5"){
      logmsg "Warning: skipping line without md5sum algorithm: $_";
      next;
    }

    my $hex = unpack("H*", decode_base64($base64));

    push(@allele, {hex=>$hex, locus=>$locus});
  }
  return \@allele;
}

sub usage{
  print "$0: query an MLST hash database with EToKi
  Usage: $0 [options] file1.fasta...
  --db     The MLST hash database folder [required]
  --out    An output folder which will contain a reference fasta file and a TSV of alleles [required]
  --force  Override the output folder in --out
  --help   This useful help menu
  \n";
  exit 0;
}

