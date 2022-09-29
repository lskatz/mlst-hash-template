#!/bin/bash
set -euo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BINDIR="$DIR"/../bin
INPUT_DIR="$DIR"/../../t/senterica/

if [[ ! -e "$BINDIR"/fu-digest ]]; then
  nimble build
fi

# CHECK INTEGRITY OF INPUT FILES
if [[ $(cat "$INPUT_DIR"/*.tfa | md5sum | cut -f 1 -d " ") != "f32235cb2a59f64df0ab8c4892a34040" ]]; then
  echo "ERROR: input files have changed ($INPUT_DIR/*.tfa)"
  exit 1
else
    echo "PASS: input files have not changed"
fi

COUNT_PASS=0
COUNT_FAIL=0
for BIN in fu-digest fu-digest2;
do
  echo "==== TESTING: $BIN ===="
  OUTDIR="$DIR"/output-$BIN/
  "$BINDIR"/$BIN "$INPUT_DIR"/*.tfa --force --out "$OUTDIR"
  
  SEQ_COUNT=$(grep -c ">" "$OUTDIR"/ref.fasta)
  FASTA_LINE_COUNT=$(cat "$OUTDIR"/ref.fasta | wc -l)
  ALLELES_LINES=$(cat "$OUTDIR"/alleles.tsv | wc -l)
  HEADER_LINES=$(grep "# locus.allele.hash-type" "$OUTDIR"/alleles.tsv | wc -l)
  FIRST_HASH=$(head -n 2 "$OUTDIR"/alleles.tsv | tail -n 1 | cut -f 2)
  LAST_HASH=$(tail -n 1 "$OUTDIR"/alleles.tsv | cut -f 2)
  LAST_LOCUS=$(tail -n 1 "$OUTDIR"/alleles.tsv | cut -f 1)

  # Check number of ref sequences
  MSG="Number of ref sequences in fasta file"
  EXP=7
  if [[ $SEQ_COUNT -ne $EXP ]]; then
    echo "ERROR: $MSG (exp=$EXP got=$SEQ_COUNT)"
    COUNT_FAIL=$((COUNT_FAIL+1))
  else
    echo "PASS:  $MSG (exp=$EXP got=$SEQ_COUNT)"
    COUNT_PASS=$((COUNT_PASS+1))
  fi

    # Check number of ref sequences
  MSG="Number of lines in fasta file"
  EXP=14
  if [[ $FASTA_LINE_COUNT -ne $EXP ]]; then
    echo "ERROR: $MSG (exp=$EXP got=$FASTA_LINE_COUNT)"
    COUNT_FAIL=$((COUNT_FAIL+1))
  else
    echo "PASS:  $MSG (exp=$EXP got=$FASTA_LINE_COUNT)"
    COUNT_PASS=$((COUNT_PASS+1))
  fi

  MSG="Counting alleles lines"
  EXP=7489

  if [[ $ALLELES_LINES -ne $EXP ]]; then
    echo "ERROR: $MSG (exp=$EXP got=$ALLELES_LINES)"
    COUNT_FAIL=$((COUNT_FAIL+1))
  else
    echo "PASS:  $MSG (exp=$EXP got=$ALLELES_LINES)"
    COUNT_PASS=$((COUNT_PASS+1))
  fi

  # Checking header
  MSG="Checking header in alleles"
  EXP=1
  if [[ $HEADER_LINES -ne $EXP ]]; then
    echo "ERROR: $MSG (exp=$EXP got=$HEADER_LINES)"
    COUNT_FAIL=$((COUNT_FAIL+1))
  else
    echo "PASS:  $MSG (exp=$EXP got=$HEADER_LINES)"
    COUNT_PASS=$((COUNT_PASS+1))
  fi

  # Check first hash
  EXP="6GUMqxkMYXpIDEPWB7GXJg"
  if [[ "$FIRST_HASH" != "$EXP" ]]; then
    echo "ERROR: $MSG (exp=$EXP got=$FIRST_HASH)"
    COUNT_FAIL=$((COUNT_FAIL+1))
  else
    echo "PASS:  $MSG (exp=$EXP got=$FIRST_HASH)"
    COUNT_PASS=$((COUNT_PASS+1))
  fi

  # Check last hash
  EXP="NjlXOr6OjUczQJLNrYhRhA"
  if [[ "$LAST_HASH" != "$EXP" ]]; then
    echo "ERROR: $MSG (exp=$EXP got=$LAST_HASH)"
    COUNT_FAIL=$((COUNT_FAIL+1))
  else
    echo "PASS:  $MSG (exp=$EXP got=$LAST_HASH)"
    COUNT_PASS=$((COUNT_PASS+1))
  fi

  # Check last locus
  EXP="thrA"
  if [[ "$LAST_LOCUS" != "$EXP" ]]; then
    echo "ERROR: $MSG (exp=$EXP got=$LAST_LOCUS)"
    COUNT_FAIL=$((COUNT_FAIL+1))
  else
    echo "PASS:  $MSG (exp=$EXP got=$LAST_LOCUS)"
    COUNT_PASS=$((COUNT_PASS+1))
  fi

  # Check output file MD5   
  MSG="Checking output file MD5 of alleles"
  EXP="f843e7575ee39118ece85202226d5afa"
  GOT=$(cat "$OUTDIR"/alleles.tsv | md5sum | cut -f 1 -d " ")
  if [[ "$GOT" != "$EXP" ]]; then
    echo "ERROR: $MSG (exp=$EXP got=$GOT)"
    COUNT_FAIL=$((COUNT_FAIL+1))
  else
    echo "PASS:  $MSG (exp=$EXP got=$GOT)"
    COUNT_PASS=$((COUNT_PASS+1))
  fi
  
  MSG="Checking output file MD5 of ref.fasta"
  EXP="fb09d346e80d4f3e48a9203d73fe9d1f"
  GOT=$(cat "$OUTDIR"/ref.fasta | md5sum | cut -f 1 -d " ")
    if [[ "$GOT" != "$EXP" ]]; then
        echo "ERROR: $MSG (exp=$EXP got=$GOT)"
        COUNT_FAIL=$((COUNT_FAIL+1))
    else
        echo "PASS:  $MSG (exp=$EXP got=$GOT)"
        COUNT_PASS=$((COUNT_PASS+1))
    fi
done

