# This is a template for any new hash-based MLST database

## Why?

We want to have a space to share MLST alleles with mechanisms to add/remove/curate
those alleles.
We can admit that there is no perfect solution to this and so here are the advantages/disadvantages to our approach.

### Advantages

1. Contextualize genomes with what else is out there
2. Alleles are hashed and so sequence data are not revealed
3. The hash is a fixed length, and so it is an easy check to see if an allele has been truncated.
4. Frees the database from funding sources.
5. Git repo!
   * ... can be copied and/or made decentralized easily.
   * ... can be versioned
   * ... can be forked - individuals or institutions can decide to have their own database
   * ... can be pushed - new alleles or loci can be updated
   * ... can be pulled - databases can update with the latest alleles or loci

### Disadvantages

1. Allelic sequences are lost through hashing.
2. The database creates a limited way that the database can be queried: either the query hits against an exact hashsum or it doesn't.
3. The database does not state whether any one allele conforms to any one rule. For example, it is unknown if a particular allele is bound by start and stop sites.
4. There is a lot of work ahead of us.

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
Upload to a git hosting site such as github.

