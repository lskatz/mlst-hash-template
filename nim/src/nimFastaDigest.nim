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
proc main_helper*(main_func: seq[string] -> int) =
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

proc mlsthash(argv: seq[string]): int =
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
  let fastaOut = open(fastaFilename, fmWrite)
  defer: fastaOut.close()
  let tsvOut = open(allelesFilename, fmWrite)
  defer: tsvOut.close()

  if not no_header:
    tsvOut.writeLine("# locus\tallele\thash-type")

  for file in args["<FASTA>"]:
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
        allele = name_bits[1]

      # Print first record
      if seq_num == 1:
        fastaOut.writeLine(">", record.name, "\n", record.sequence)
        if verbose:
            stderr.writeLine("Reading locus ", locus, " from file: ", file)

      let
        digest = (record.sequence).toMD5().encode().stripTrailing('=')
        fields   = @[locus, digest, "md5"]
        line   = fields.join("\t")

      tsvOut.writeLine(line)
  return 0
      
    


    


  


when isMainModule:
  try:
    #quit(mlsthash(commandLineParams()))
    main_helper(mlsthash)
  except IOError:
    stderr.writeLine("Quitting...")
    quit(0)
  except Exception as e:
    stderr.writeLine(e.msg)
    quit(1)
  
