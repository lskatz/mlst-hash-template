# Package
version       = "0.1.0"
author        = "Andrea Telatin"
description   = "MLST hash"
license       = "MIT"

# Dependencies
requires "nim >= 1.2", "docopt", "readfq"

srcDir = "src"
binDir = "bin" 
namedBin = {
    "nimFastaDigest": "fu-digest",
    "nimFastaDigestBuffered": "fu-digest2"
}.toTable()

 
