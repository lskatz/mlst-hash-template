#!/bin/bash
set -euxo pipefail
INPUT="../t/senterica/*.tfa"
if [[ ! -e "bin/fu-digest" ]]; then
  nimble build
fi

bin/fu-digest $INPUT --force --out output-nim/
bin/fu-digest2 $INPUT --force --out output-nim-buf/
../scripts/digestFasta.py --force --out output-py/ $INPUT
../scripts/digestFasta.pl --force --out output-pl/ $INPUT

if [[ -e ../rust/target/release/mlst-hash-template-rust ]]; then
  ../rust/target/release/mlst-hash-template-rust $INPUT
  mkdir -p output-rust
  mv alleles.tsv ref.fasta output-rust
fi

echo "CHECK OUTPUT"
md5sum output-*/alleles* |sort
md5sum output-*/ref* |sort

hyperfine --version && \
 mkdir -p benchmark && \
 hyperfine --export-csv benchmark/speed.csv --export-markdown benchmark/speed.md \
    --warmup 1 --min-runs 20 --cleanup "rm -rf output*" -n perl -n python -n nim -n nim-buf -n rust \
    "../scripts/digestFasta.pl --force --out output-pl/ $INPUT" \
    "../scripts/digestFasta.py --force --out output-py/ $INPUT" \
    "bin/fu-digest $INPUT --force --out output-nim/" \
    "bin/fu-digest2 $INPUT --force --out output-nim-buf/" \
    "../rust/target/release/mlst-hash-template-rust $INPUT"
rm alleles.tsv ref.fasta 
