import std/base64
import std/md5
import readfq
import os
import docopt
import strutils
import posix


proc stripTrailing*(s: string, c: char): string = 
  if s.len == 0: return
  var last = s.high
  while last > -1 and s[last] == c: last -= 1
  return s[0 .. last]

import sugar
proc main_helper*(main_func: var seq[string] -> int) =
  var args: seq[string] = commandLineParams()
  when defined(windows):
    try:
      let exitStatus = main_func(args)
      quit(exitStatus)
    except IOError:
      # Broken pipe
      quit(0)
    except Exception:
      stderr.writeLine( getCurrentExceptionMsg() )
      quit(2)   
  else:
    
    signal(SIG_PIPE,cast[typeof(SIG_IGN)](proc(signal:cint) =
      quit(0)
    ))
    # Handle Ctrl+C interruptions and pipe breaks
    type EKeyboardInterrupt = object of CatchableError
    proc handler() {.noconv.} =
      raise newException(EKeyboardInterrupt, "Keyboard Interrupt")
    setControlCHook(handler)
    # Handle "Ctrl+C" intterruption
    try:
      let exitStatus = main_func(args)
      quit(exitStatus)
    except EKeyboardInterrupt:
      # Ctrl+C
      quit(1)
    except IOError:
      # Broken pipe
      quit(1)
    except Exception:
      stderr.writeLine( getCurrentExceptionMsg() )
      quit(2)   

proc mlsthash(argv: var seq[string]): int =
  let args = docopt("""
Usage: mlsthash [options] -o <outdir> <FASTA>...

  <FASTA>     One or more FASTA files with alleles in the
              locus_id format

Options:
  -o, --outdir DIR           Output directory
  --no-header                Do not print alleles.tsv header
  -f, --force                Overwrite existing files
  -v, --verbose              Verbose output 
  -h, --help                 Show this help

  """, version="1.0.0", argv=argv)

  # Check if output directory exists

  let
    outdir = $args["--outdir"]
    force = bool(args["--force"])
    verbose = bool(args["--verbose"])
    no_header = bool(args["--no-header"])

  var
    refFasta = ""
    tsvAlleles = if no_header:  ""
                 else: "# locus\tallele\thash-type\n"

  if os.dirExists(outdir) and not force:
    stderr.writeLine("Output directory already exists. Use --force to overwrite.")
    return 1
  
  if not os.dirExists(outdir):
    try:
      if verbose:
        stderr.writeLine("Creating output directory: ", outdir)
      os.createDir(outdir)
    except Exception as e:
      if verbose:
        stderr.writeLine("Overwriting output directory: ", outdir)
      stderr.writeLine("Could not create output directory: ", e.msg)
      return 1

  # Open output files
  let
    fastaFilename = os.joinPath(outdir, "ref.fasta")
    allelesFilename = os.joinPath(outdir, "alleles.tsv")

  for file in args["<FASTA>"]:
    if verbose:
      stderr.writeLine("Reading FASTA file: ", file)
    if not os.fileExists(file):
      stderr.writeLine("File not found: ", file)
      return 1
    

    var
      seq_num = 0

    for record in readfq(file):
      seq_num += 1

      # Check record name format
      let
        name_bits = (record.name).split('_')
      
      if len(name_bits) != 2:
        stderr.writeLine ("ERROR: Sequence name must be in the format locus_id: ", record.name, " found")
        return 1

      let
        locus = name_bits[0]

      # Print first record
      if seq_num == 1:
        refFasta &= ">" & record.name & "\n" & record.sequence & "\n"
        if verbose:
            stderr.writeLine("Reading locus ", locus, " from file: ", file)


      let
        digest = (record.sequence).toMD5().encode().stripTrailing('=')


      tsvAlleles &= @[locus, digest, "md5"].join("\t") & "\n"

  try:
    let fastaOut = open(fastaFilename, fmWrite)
    fastaOut.write(refFasta)
    fastaOut.close()
    let tsvOut = open(allelesFilename, fmWrite)
    tsvOut.write(tsvAlleles)
    tsvOut.close()
    return 0
  except Exception as e:
    stderr.writeLine("ERROR: Unable to write to ", fastaFilename, " and ", allelesFilename, "\n  ", e.msg)
    echo refFasta
    echo "#------"
    echo tsvAlleles
    return 1
    


  


when isMainModule:
  try:
    main_helper(mlsthash)
  except IOError:
    stderr.writeLine("Quitting...")
    quit(0)
  