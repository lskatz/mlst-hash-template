#!/usr/bin/env perl 

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use File::Basename qw/basename/;
use Digest::MD5 qw/md5_base64 md5_hex/;
use File::Temp qw/tempdir/;
use File::Copy qw/mv/;

use version 0.77;

# https://lskatz.github.io/mlst/wgmlst/cgmlst/etoki/chewbbaca/colorid/wgMLST/#etoki-results
# a good allele
use constant GOOD                   => 1;
# an allele that has no major problem in its sequences, but may be low quality (still acceptable). 2 is used by default when there is no quality scores such as a fasta file input.
use constant GOOD_NO_QUAL           => 2;
# the allele is fine, but we are not the central database, so will not be able to assign a formal ID
use constant GOOD_BUT_NOT_AUTHORITY => 8;
# the gene is duplicated (two or more hits in the genome)
use constant GENE_DUPLICATION       => 32;
# the gene is fragmented
use constant GENE_FRAGMENTED        => 64;
# the identity to the reference is too low
use constant GENE_LOW_IDENTITY      => 256;

my %etokiFlag = (
  1   => GOOD,
  2   => GOOD_NO_QUAL,
  8   => GOOD_BUT_NOT_AUTHORITY,
  32  => GENE_DUPLICATION,
  64  => GENE_FRAGMENTED,
  256 => GENE_LOW_IDENTITY,
);

local $0 = basename $0;
sub logmsg{local $0=basename $0; print STDERR "$0: @_\n";}
exit(main());

sub main{
  my $settings={};
  GetOptions($settings,qw(help force tempdir=s scheme=s db-dir=s out=s)) or die $!;
  usage() if(!@ARGV || $$settings{help});
  $$settings{tempdir} ||= tempdir("$0.XXXXXX", CLEANUP=>1, TMPDIR=>1);
  $$settings{out} ||= die "ERROR: need an output directory with --out";
  $$settings{scheme} ||= die "ERROR: need the name of a scheme with --scheme";
  $$settings{'db-dir'}||= die "ERROR: need the directory of the MLST database scheme with --db-dir";

  if(-e $$settings{out} && !$$settings{force}){
    die "ERROR: output folder already exists at $$settings{out}. --force to overwrite.";
  }
  mkdir $$settings{out};
  mkdir $$settings{tempdir} if(!-e $$settings{tempdir});

  for my $f(@ARGV){
    logmsg "Reading $f";
    my $alleles = readEtokiFasta($f, $settings);
    logmsg "Writing results from $f to $$settings{out}";
    writeEtokiToHashDb($alleles, $$settings{out}, $$settings{'db-dir'}, $settings);
  }

  return 0;
}

sub readEtokiFasta{
  my($fasta, $settings) = @_;

  my @allele;

  my $numSeqs = 0;
  open(my $seqFh, "<", "$fasta") or die "ERROR: could not open $fasta for reading";
  my @aux = undef;
  my ($id, $seq);
  my ($n, $slen, $comment, $qlen) = (0, 0, 0);
  while ( ($id, $seq, $comment) = readfq($seqFh, \@aux)) {

    my %property;
    my @kvPair = split(/\s+/, $comment);
    for my $kv(@kvPair){
      my($key, $value) = split(/=/, $kv);
      $property{$key} = $value;
    }

    push(@allele, {
        properties => \%property,
        locus      => $id,
        seq        => $seq,
    });

  }
  close $seqFh;

  return \@allele;

}

# Use the properties of the alleles from Etoki to generate new HashDB files
sub writeEtokiToHashDb{
  my($alleles, $outdir, $dbDir, $settings) = @_;

  my %profile;

  my $allelesFile = "$outdir/alleles.new.tsv";
  open(my $allelesFh, ">>", $allelesFile) or die "ERROR: could not append to $allelesFile: $!";
  print $allelesFh "## hash-alleles-format v0.5\n";
  print $allelesFh "# ".join("\t", qw(locus allele hash-type attributes))."\n";

  for my $allele(@$alleles){

    # Extract some properties to make this block readable
    my %property = %{ $$allele{properties} };
    my $seq = $$allele{seq};
    my $locus = $$allele{locus};

    my $hash = md5_base64($seq);

    if($property{accepted} == GOOD || $property{accepted} == GOOD_NO_QUAL){
      my $attributes = "allele-caller=EToKi";
      $attributes.=";length=".length($seq);
      $attributes.=";start-sequence=".substr($seq,0,3);
      $attributes.=";stop-sequence=".substr($seq,-3,3);
      #TODO figure out how to get the reference allele
      #Currently looks like: aroC_1:501M. Maybe I should update the spec to just this?
      #$attributes.=";ref=$property{reference}";
      #$attributes.=";CIGAR=$property{CIGAR}";
      print $allelesFh join("\t",
        $locus,
        $hash,
        "md5",
        $attributes,
      ) . "\n";

      $profile{$locus} = $hash;
    }
  }
  close $allelesFh;

  my @sortedLoci = sort{$a cmp $b} keys(%profile);

  my $allelesStr = "";
  for my $locus(@sortedLoci){
    $allelesStr .= "$profile{$locus}\t";
  }
  $allelesStr =~ s/\s+$//; # remove trailing tab
  my $ST = md5_base64($allelesStr);

  open(my $profileFh, ">>", "$outdir/profiles.tsv") or die "ERROR: could not append to $outdir/profiles.tsv: $!";
  print $profileFh "# ".join("\t", qw(scheme ST hash-type), @sortedLoci)."\n";
  print $profileFh join("\t",
    $$settings{scheme}, $ST, "md5", $allelesStr
  );
  close $profileFh;
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
    return ($name, $seq, $comm) if ($c ne '+');
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
  print "$0: Read EToKi MLST results in fasta format and turn them into new alleles for the MLST hash spec database
  Usage: $0 [options] file1.fasta...
  --out    An output folder for alleles.tsv and any other files
  --scheme The name of the scheme, e.g., Salmonella_enterica_cgMLST
  --db-dir The directory of the MLST hash database
  --force  Override the output folder in --out
  --help   This useful help menu
  \n";
  exit 0;
}

