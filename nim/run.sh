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