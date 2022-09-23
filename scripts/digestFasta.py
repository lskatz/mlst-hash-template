#!/usr/bin/env python3
"""
reads fasta file(s) and creates a database in the hashsum format
The fasta file(s) must be one locus per line. The first allele is the assumed reference.
Each sequence ID must have the format locus_allele.

Input:
Fasta file

Output:
- A reference fasta file
- A TSV file with all the alleles
"""

import sys
import os
import argparse

import hashlib
import base64
def read_fasta(path):
        if path.endswith('.gz'):
            import gzip
            fasta = gzip.open(path, 'rt')
        else:
            fasta = open(path, 'rt')

        name = None
        
        for line in fasta:
            if line.startswith('>'):
                if name is not None:
                    yield name, seq
                name = line[1:].rstrip()
                seq = ''
            else:
                seq += line.rstrip()
        yield name, seq

def seq_digest(string, method="md5"):
    if method == "md5":
        return string.digest().encode('base64').strip()
    elif method == "md5_base64":
        return base64.b64encode(hashlib.md5(string.encode()).digest()).decode('utf-8').rstrip("=")
        
    else:
        raise ValueError("Unknown method %s" % method)

def main():
    args = argparse.ArgumentParser()
    args.add_argument("FASTA", help="Fasta file(s) with alleles having name as locus_id", nargs="+")
    args.add_argument("-o", "--out", "--outdir", help="Output directory, will be created")
    args.add_argument("--force", help="Proceed if output directory is found", action="store_true")
    args.add_argument("--verbose", help="Print verbose information", action="store_true")
    args = args.parse_args()

    locus_file = {}
    parsed_files = {}

    # TODO Check if output exists (force option)
    if os.path.isdir(args.out):
        if not args.force:
            print("Output directory exists, use --force to proceed", file=sys.stderr)
            return 1

    # Create output directory
    if not os.path.exists(args.out):
        os.makedirs(args.out)

    outputFastaRefs = open(os.path.join(args.out, "ref.fasta"), 'w')
    outputTsvAlleles = open(os.path.join(args.out, "alleles.tsv"), 'w')

    print("# locus", "allele", "hash-type", sep="\t", file=outputTsvAlleles)
    for fasta_path in args.FASTA:
        seq_num = 0
        if args.verbose:
            print("Processing %s" % fasta_path, file=sys.stderr)

        if not os.path.exists(fasta_path):
            print("File %s not found" % fasta_path, file=sys.stderr)
            return 1
        
        for name, seq in read_fasta(fasta_path):
            try:
                locus, allele = name.split("_")
            except ValueError:
                print("Error: %s is not a valid sequence name (should be locus_allele)" % name, file=sys.stderr)
                sys.exit(1)
            
            if locus not in locus_file:
                if args.verbose:
                    print(" + Locus %s from %s" % (locus, fasta_path), file=sys.stderr)
                locus_file[locus] = fasta_path
            elif locus_file[locus] != fasta_path:
                print("Locus %s is found in multiple files (%s and %s) as %s" % (locus, locus_file[locus], fasta_path, name), file=sys.stderr)
                return 1
            
            if seq_num == 0:
                print(">%s\n%s" % (name, seq), file=outputFastaRefs)
            
            # Encode MD5 base64 of seq
            base64_md5 = seq_digest(seq, method="md5_base64")
            print(locus, base64_md5, "md5",  sep="\t", file=outputTsvAlleles)
            seq_num += 1

if __name__ == "__main__":
    quit(main())
