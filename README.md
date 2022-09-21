# This is a template for any new hash-based MLST database

## Database format

In the db folder, each scheme has two files.

* `refs.fasta` - reference alleles for each locus
* `alleles.tsv`
   * tab separated values: md5sum (base64) of the sequence, locus name, attributes
      * attributes are key/values separated by `=`.
      * different attributes are separated with `;`.
      * defined attributes are allele-caller, allele-caller-version, sequencing-platform, sequencing-platform-model, assembler, assembler-version
      * example: allele-caller=chewbbaca;allele-caller-version=2
   * `alleles.tsv` can be chunked into files of at most 500k lines to avoid having huge files
      * These need to be concatenated later at time of use

