# Nim implementation (experimental)

There are two implementations:
* _nimFastaDigest.nim_ that mimics the perl implementation (binary: `fu-digest`)
* _nimFastaDigestBuffered.nim_ that will buffer the output (binary: `fu-digest2`), with minimal performance gain

## Building

1. Install nim
2. `nimble build`

## Testing

```bash
bin/fu-digest  --out output-nim1 ../t/senterica/*tfa --verbose
bin/fu-digest2 --out output-nim2 ../t/senterica/*tfa --verbose
```

or

```bash
# Will also run the python, perl, and (if compiled) rust versions
bash run.sh
```

