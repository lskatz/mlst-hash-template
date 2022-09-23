#!/usr/bin/env python3

import unittest
import sys
import os

RealBin = os.path.dirname(os.path.realpath(__file__))

# Make sure this repo is prioritized on PATH
#sys.path.insert(0,RealBin + "/../scripts")
#os.environ["PATH"] = RealBin+"/../scripts" + os.environ["PATH"]
#print(sys.path)

refs    = RealBin+"/../t/senterica.dbhpy/ref.fasta"
alleles = RealBin+"/../t/senterica.dbhpy/alleles.tsv"

class CreateDB(unittest.TestCase):

  def test_upper(self):
    self.assertEqual('foo'.upper(), 'FOO')

  def test_runScript(self):
    sys.path.insert(0,RealBin + "/../scripts")
    cmd = RealBin+"/../scripts/digestFasta.py "+RealBin+"/../t/senterica/*.tfa --out "+RealBin+"/../t/senterica.dbhpy --force"
    exit_code = os.system(cmd)
    self.assertEqual(exit_code >> 8, 0)

  def test_validDb(self):

    obsCount = {}
    with open(alleles) as alleleFh:
      for line in alleleFh:
        if line[0:1] == '#':
          continue

        F = line.split('\t')
        locus = F[0]
        if(locus not in obsCount):
          obsCount[locus]=0
        obsCount[locus] += 1


    expCount = {
        "aroC":984,
        "dnaN":975,
        "hemD":916,
        "hisD":1380,
        "purE":1075,
        "sucA":1002,
        "thrA":1156
    }
    for locus in obsCount:
      self.assertEqual(obsCount[locus], expCount[locus])


if __name__ == '__main__':
  unittest.main()

