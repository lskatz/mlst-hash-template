# This is the file format specification for the hash allele database

Each database is a folder with these files.
The folder name is the name of the database.

## refs.fasta

These are reference alleles for each 

## alleles.tsv

Lines starting with double pound signs indicate information about the file itself.

* The first line of alleles.tsv should describe the file format and version like 
`## hash-alleles-format v0.2`

Lines starting with single pound signs are comments and can be ignored.

There is an optional line allowed which can describe the fields:

    # locus  allele  hash-type  attributes

After the headers and this optional line describing the fields, each line in the file
is an allele definition with mandatory fields. 
Attributes is the only optional field.
In a database, alleles.tsv can be seprated to multiple files with letters in between `alleles` and `.tsv`, e.g.,
`alleles.aa.tsv`, `alleles.ab.tsv`, ... , `alleles.yz.tsv`, `alleles.zz.tsv`.

The fields:

* Locus: the locus name
* Allele: the hashsum of the sequence
* hash-type: the algorithm that hashed the sequence. It should be in base64 format.
* attributes: optional fields in GFF attributes format.
   * attributes are key/values separated by `=`.
   * different attributes are separated with `;`.
   * defined attributes are allele-caller, allele-caller-version, sequencing-platform, sequencing-platform-model, assembler, assembler-version
   * Fields with `version` should have values in semver format, e.g., `3.0.0`.
   * example attributes: allele-caller=chewbbaca;allele-caller-version=2

