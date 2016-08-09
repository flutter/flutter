#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
from collections import defaultdict
import json
import os
import re
import subprocess
import sys

import suppressions


def ReadReportsFromFile(filename):
  """ Returns a list of (report_hash, report) and the URL of the report on the
  waterfall.
  """
  input_file = file(filename, 'r')
  # reports is a list of (error hash, report) pairs.
  reports = []
  in_suppression = False
  cur_supp = []
  # This stores the last error hash found while reading the file.
  last_hash = ""
  for line in input_file:
    line = line.strip()
    line = line.replace("</span><span class=\"stdout\">", "")
    line = line.replace("</span><span class=\"stderr\">", "")
    line = line.replace("&lt;", "<")
    line = line.replace("&gt;", ">")
    if in_suppression:
      if line == "}":
        cur_supp += ["}"]
        reports += [[last_hash, "\n".join(cur_supp)]]
        in_suppression = False
        cur_supp = []
        last_hash = ""
      else:
        cur_supp += [" "*3 + line]
    elif line == "{":
      in_suppression = True
      cur_supp = ["{"]
    elif line.find("Suppression (error hash=#") == 0:
      last_hash = line[25:41]
  # The line at the end of the file is assumed to store the URL of the report.
  return reports,line

def Demangle(names):
  """ Demangle a list of C++ symbols, return a list of human-readable symbols.
  """
  # -n is not the default on Mac.
  args = ['c++filt', '-n']
  pipe = subprocess.Popen(args, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
  stdout, _ = pipe.communicate(input='\n'.join(names))
  demangled = stdout.split("\n")
  # Each line ends with a newline, so the final entry of the split output
  # will always be ''.
  assert len(demangled) == len(names)
  return demangled

def GetSymbolsFromReport(report):
  """Extract all symbols from a suppression report."""
  symbols = []
  prefix = "fun:"
  prefix_len = len(prefix)
  for line in report.splitlines():
    index = line.find(prefix)
    if index != -1:
      symbols.append(line[index + prefix_len:])
  return symbols

def PrintTopSymbols(symbol_reports, top_count):
  """Print the |top_count| symbols with the most occurrences."""
  boring_symbols=['malloc', '_Znw*', 'TestBody']
  sorted_reports = sorted(filter(lambda x:x[0] not in boring_symbols,
                                 symbol_reports.iteritems()),
                          key=lambda x:len(x[1]), reverse=True)
  symbols = symbol_reports.keys()
  demangled = Demangle(symbols)
  assert len(demangled) == len(symbols)
  symboltable = dict(zip(symbols, demangled))

  print "\n"
  print "Top %d symbols" % top_count
  for (symbol, suppressions) in sorted_reports[:top_count]:
    print "%4d occurrences : %s" % (len(suppressions), symboltable[symbol])

def ReadHashExclusions(exclusions):
  input_file = file(exclusions, 'r')
  contents = json.load(input_file)
  return contents['hashes']


def main(argv):
  supp = suppressions.GetSuppressions()

  # all_reports is a map {report: list of urls containing this report}
  all_reports = defaultdict(list)
  report_hashes = {}
  symbol_reports = defaultdict(list)

  # Create argument parser.
  parser = argparse.ArgumentParser()
  parser.add_argument('--top-symbols', type=int, default=0,
    help='Print a list of the top <n> symbols')
  parser.add_argument('--symbol-filter', action='append',
    help='Filter out all suppressions not containing the specified symbol(s). '
         'Matches against the mangled names.')
  parser.add_argument('--exclude-symbol', action='append',
    help='Filter out all suppressions containing the specified symbol(s). '
         'Matches against the mangled names.')
  parser.add_argument('--exclude-hashes', action='append',
    help='Specify a .json file with a list of hashes to exclude.')

  parser.add_argument('reports', metavar='report file', nargs='+',
    help='List of report files')
  args = parser.parse_args(argv)

  # exclude_hashes is a list of strings, each string an error hash.
  exclude_hashes = []

  exclude_hashes = []
  if args.exclude_hashes:
    for excl in args.exclude_hashes:
      print "reading exclusion", excl
      exclude_hashes += ReadHashExclusions(excl)

  for f in args.reports:
    f_reports, url = ReadReportsFromFile(f)
    for (hash, report) in f_reports:
      if hash in exclude_hashes:
        continue
      all_reports[report] += [url]
      report_hashes[report] = hash

  reports_count = 0
  for r in all_reports:
    cur_supp = supp['common_suppressions']
    if all([re.search("%20Mac%20|mac_valgrind", url)
            for url in all_reports[r]]):
      # Include mac suppressions if the report is only present on Mac
      cur_supp += supp['mac_suppressions']
    elif all([re.search("Linux%20", url) for url in all_reports[r]]):
      cur_supp += supp['linux_suppressions']
    if all(["DrMemory" in url for url in all_reports[r]]):
      cur_supp += supp['drmem_suppressions']
    if all(["DrMemory%20full" in url for url in all_reports[r]]):
      cur_supp += supp['drmem_full_suppressions']

    # Test if this report is already suppressed
    skip = False
    for s in cur_supp:
      if s.Match(r.split("\n")):
        skip = True
        break

    # Skip reports if none of the symbols are in the report.
    if args.symbol_filter and all(not s in r for s in args.symbol_filter):
        skip = True
    if args.exclude_symbol and any(s in r for s in args.exclude_symbol):
        skip = True

    if not skip:
      reports_count += 1
      print "==================================="
      print "This report observed at"
      for url in all_reports[r]:
        print "  %s" % url
      print "didn't match any suppressions:"
      print "Suppression (error hash=#%s#):" % (report_hashes[r])
      print r
      print "==================================="

      if args.top_symbols > 0:
        symbols = GetSymbolsFromReport(r)
        for symbol in symbols:
          symbol_reports[symbol].append(report_hashes[r])

  if reports_count > 0:
    print ("%d unique reports don't match any of the suppressions" %
           reports_count)
    if args.top_symbols > 0:
      PrintTopSymbols(symbol_reports, args.top_symbols)

  else:
    print "Congratulations! All reports are suppressed!"
    # TODO(timurrrr): also make sure none of the old suppressions
    # were narrowed too much.


if __name__ == "__main__":
  main(sys.argv[1:])
