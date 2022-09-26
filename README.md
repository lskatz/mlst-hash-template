# This is a template for any new hash-based MLST database

## Database format

In the db folder, each scheme has two files.

* `refs.fasta` - reference alleles for each locus
* `alleles.tsv` - information on each allele

The specification is at [docs/specification.md](docs/specification.md)

## Example

### python

    mkdir -v db
    python3 scripts/digestFasta.py t/senterica/*.tfa --out db/senterica.dbhpy --force

### perl

    mkdir -v db
    perl scripts/digestFasta.pl t/senterica/*.tfa --out db/senterica.dbhpl --force

## Installation

1. Clone the repo
2. Put `scripts` into your PATH

## Usage

To add your own database, use this repo as a template and then add your database using the scripts.
Make a new repo with it.

