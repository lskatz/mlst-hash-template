# File format specification for the hash allele database

The hash allele database format describes an MLST database where each locus
has many alleles.
The locus has a reference allele that can be used to match query sequences against.
The other alleles are hashed such that only exact matches can be found in a query.

In many other allele databases, the loci have alleles with integer identifiers.
Here, we use hashsum identifiers. Therefore, databases will be able to be merged
and compared universally. 
"Allele number 1 of locus 1" is unfortunately ambugiuous in a decentralized database or across multiple databases of the same type.
However, allele `FF..FF` is unambiguous between schemes of the same hashsum algorithm.
Therefore, merging alleles from different hash allele databases should be trivial and unambiguous.

The basic structure is that the folder name is the name of the database.
Each database is a folder with these files.

* refs.fasta
* alleles.tsv

## refs.fasta

These are reference alleles for each locus. 
The defline must be in the format of `>locus` or `>locus_allele`.
Locus must match the regex `/[A-Z0-9-]+/i`, i.e., only letters, numbers, and dashes.
refs.fasta must be compatible with bioinformatics software such as `makeblastdb` and `blastn`.

## alleles.tsv

This file has two sections: a header and a body.
The header lines start with `##` and indicate information about the file itself.

* The first line of alleles.tsv should describe the file format and version like 
`## hash-alleles-format v0.2`

Lines starting with single pound signs are comments and can be ignored.

There is an optional comment line allowed between the header and body which can describe the fields:

    # locus  allele  hash-type  attributes

After the headers and this optional line describing the fields, each line in the file
is an allele definition with mandatory fields. 
Attributes is the only optional field.
In a database folder, alleles.tsv can be seprated to multiple files with letters in between `alleles` and `.tsv`, e.g.,
`alleles.aa.tsv`, `alleles.ab.tsv`, ... , `alleles.yz.tsv`, `alleles.zz.tsv`.

The fields:

* Locus: the locus name. Must match the regex `/[A-Z0-9-]+/i`.
* Allele: the hashsum of the sequence in base64.
* hash-type: the algorithm that hashed the sequence. It should be in base64 format. There is only one valid value at this time `md5`. This field is case insensitive.
* attributes: optional fields in GFF attributes format.
   * attributes are key/values separated by `=`.
   * different attributes are separated with `;`.
   * defined attributes are allele-caller, allele-caller-version, sequencing-platform, sequencing-platform-model, assembler, assembler-version
   * Fields with `version` should have values in semver format, e.g., `3.0.0`.
   * Values should be quoted. Values cannot have the `"` character because it is reserved. Values are allowed to have single quotes `'` however.
   * example attributes: allele-caller="chewbbaca";allele-caller-version="2";sequencing-platform="A fake 'SNP' platform"

