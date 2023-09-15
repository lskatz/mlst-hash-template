#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Test::More;
use FindBin qw/$RealBin/;
use File::Basename qw/basename/;
use Digest::MD5 qw/md5_base64/;

plan tests => 1;

$ENV{PATH} = "$RealBin/../scripts:$ENV{PATH}";

my $db = "$RealBin/senterica";
my $hashdb = "$RealBin/senterica.dbh";
my $etokiout = "$RealBin/senterica.dbh.etoki";
my $hashdbMore = "$RealBin/senterica.dbh.etoki.out";

my $asmdir = "$RealBin/salm-genomes";

subtest 'build senterica' => sub{
  system("perl scripts/queryMLST.etoki.pl --force --db $hashdb --out $etokiout $asmdir/*.fasta > $etokiout.log 2>&1");
  if($?){
    BAIL_OUT("Could not run queryMLST.etoki.pl:\n".`cat $etokiout.log`);
  }
  system("perl scripts/addAlleles.etoki.pl --force --out $hashdbMore --scheme senterica --db-dir $db $etokiout/*.fasta > $hashdbMore.log 2>&1");
  if($?){
    BAIL_OUT("Could not run addAlleles.etoki.pl:\n".`cat $hashdbMore.log`);
  }

  my %expST = (
    tNNIBToTUwzQHhjQEkAe1g => {
      aroC => 'YaT2ElkUSm8IvbW6g/hxSg',
      dnaN => 'Pz+ZC/zlP13IqpaLikN0yQ',
      hemD => 'oUZdMdamT4BWpcC5JQWLhA',
      hisD => 'iplJmn3q7Sg015maXvCv8A',
      purE => 'AEFydnKCuEVyiBRT+9aYsw',
      sucA => 'QAwvmHu6g34ZE6bqRDD6gQ',
      thrA => 'tGtePJWoIEwX76f9RTH1Kw',
      scheme => 'senterica',
      'hash-type' => 'md5',
      ST   => 'tNNIBToTUwzQHhjQEkAe1g',
    },
    'b6go19zEE2kJlKVk+oWRQg' => {
      aroC => 'Flxv3JboE18TPgHxPxr6Yw',
      dnaN => 'aME1V/22w9uMW35qI2FGbw',
      hemD => 'TyCpECvKHUjPyRCeFJwVEg',
      hisD => 'stH9GZhaQRXzhbu5ZjM7lw',
      purE => '4r5IdowZkWB0e6iDAg6fOA',
      sucA => 'iMpgedPsbT7ayQQaaV6+RQ',
      thrA => 'dvxTIwu8hlig1V7pI56wgw',
      scheme => 'senterica',
      'hash-type' => 'md5',
      ST   => 'b6go19zEE2kJlKVk+oWRQg',
    },


  );

  my %obsST;
  open(my $fh, "<", "$hashdbMore/profiles.tsv") or die "ERROR: could not read $hashdbMore/profiles.tsv: !";
  my $header = <$fh>;
  # whitespace and comment trim
  $header =~ s/^#?\s+|\s+$//g;
  my @header = split(/\t/, $header);
  while(<$fh>){
    next if(/^#/);
    chomp;
    my @F = split(/\t/);
    my %F;
    @F{@header} = @F;

    $obsST{$F{ST}} = \%F;
  }
  is_deeply(\%obsST, \%expST, "profiles.tsv");
};


