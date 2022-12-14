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
This file would normally have one allele per locus but it can have more than one allele per locus.

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

* Locus: the locus name. Must match the regex `/[A-Z0-9_-]+/i`.
* Allele: the hashsum of the sequence in base64.
* hash-type: the algorithm that hashed the sequence. It should be in base64 format. There is only one valid value at this time `md5`. This field is case insensitive.
* attributes: optional fields in GFF attributes format.

### Attributes field

The attributes are in the fourth column and are in the GFF attributes format.

* attributes are key/values separated by `=`.
* different attributes are separated with `;`.
* keys and values are case insensitive.  ChewBBACA should be interpreted the same as chewbbaca.
* defined attributes are allele-caller, allele-caller-version, sequencing-platform, sequencing-platform-model, assembler, assembler-version
* Fields with `version` should have values in semver format, e.g., `3.0.0`.
* Values should be quoted. Values cannot have the `"` character because it is reserved. Values are allowed to have single quotes `'` however.
* example attributes: allele-caller="chewbbaca";allele-caller-version="2";sequencing-platform="A fake 'SNP' platform"

**Defined attributes**

| Attribute | Data type | Description | Example |
|-----------|-----------|-------------|---------|
| allele-caller | String | The software used to call the allele | ChewBBACA |
| allele-caller-version | Version | The version of the allele-caller | 2.1.0 |
| allele-caller-options | String | Any non-default options used in the allele caller | --size-threshold 0.3 |
| sequencing-platform | String | The sequencing platform used to sequence the this allele | Illumina |
| sequencing-platform-model | String | The model name of the sequencing platform | MiSeq |
| assembler | String | The software used to assemble the raw reads from the sequencer | SPAdes |
| assembler-version | Version | The version of the assembler software | 3.13 |
| assembler-options | String | Any non-default options used in the assembler | --careful |
| start-sequence | String | The first nucleotides of the allele, usually the start codon | ATG |
| stop-sequence | String | The last nucleotides of the allele, usually the stop codon, in the forward direction | TGA | 
| length | Integer | The number of nucleotides in the allele | 947 |
| CIGAR _experimental_ | String | A CIGAR string describing the match to the reference sequence. Specification for the CIGAR string is described in the SAM specification. This field requires another field `ref`. | 30M5I30M |
| SNP _experimental_ | String | A SNP notation describing what was the reference nucleotide and what is the new nucleotide. The format is concatenated and has three fields: reference base(s), position, allele base(s). Coordinates are 1-based. Can describe indels too. Multiple SNP values can be separated by semicolons. This field requires another field `ref`. | SNP in the 5th position, insertion in the 10th position from A to two Gs, and deletion of ATG in the 30th position: `A5G;A10GG;ATG30` |
| ref | String | The identifier of the reference allele that this allele was compared against. Do not include extra information after the whitespace in an identifier, if it exists. The allele must exist in `refs.fasta`. | aroC_1 |

### Examples for alleles.tsv

#### Only required fields

```text
## hash-alleles-format v0.3
# locus allele  hash-type
aroC    6GUMqxkMYXpIDEPWB7GXJg  md5
aroC    YaT2ElkUSm8IvbW6g/hxSg  md5
aroC    PO9EWkqaMIxKj7kRtQUt5A  md5
dnaN    1AF2Py325f6H4eB9PBcP5g  md5
dnaN    8khwhE2lNGi1ARavWpiPnw  md5
dnaN    D9pt/Lk/D8BOMO0ZmkGSlA  md5
hemD    /kXf/b7JIRAdxKQR2OWB2A  md5
hemD    Z1wFdsONZPsiBY0We8badg  md5
hemD    Xqa0fIqryOcOG390D1HfNQ  md5
hisD    n3YsJGxULFLJTFAiymIxHA  md5
hisD    PDnj+IrIcQ0hqksnlaInLA  md5
hisD    rJG6kUykD7QR+6kVB+3uag  md5
purE    3+0cJja2LgafXtLwFWlSRg  md5
purE    /58bj78QhjGigSl9bPtV/A  md5
purE    8iP6DvzzYcjFiBOmOVWydg  md5
sucA    SBtkVPM/rnh1tJeMFAlOww  md5
sucA    PcnmEBZq9wOow/WyVMFHZg  md5
sucA    VLbw66gQl3nDdppBRX5R/Q  md5
thrA    6uxkS0Eb0LOrHghvur0pyQ  md5
thrA    3Iobq+fag08oHdKCJ9b5tQ  md5
thrA    dhqKwb2BFpPAvDaWt3+9yA  md5
```

#### With attributes field

The third entry has no attributes field, to help illustrate that alleles with and without an attribute field can be in the same file.

```text
## hash-alleles-format v0.3
# locus allele  hash-type
aroC    6GUMqxkMYXpIDEPWB7GXJg  md5  allele-caller="chewbbaca";allele-caller-version="2";sequencing-platform="Illumina";sequencing-platform-model="MiSeq";start-sequence="GTT";stop-sequence="GGT"
aroC    YaT2ElkUSm8IvbW6g/hxSg  md5  allele-caller="stringmlst";allele-caller-version="0.6.3";sequencing-platform="Illumina";sequencing-platform-model="NovaSeq"
aroC    PO9EWkqaMIxKj7kRtQUt5A  md5  
```
