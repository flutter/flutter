#!/usr/bin/env python
#
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import base64
import os
import sys
import re

from optparse import OptionParser

"""Extracts the list of resident symbols of a library loaded in a process.

This scripts combines the extended output of memdump for a given process
(obtained through memdump -x PID) and the symbol table of a .so loaded in that
process (obtained through nm -C lib-with-symbols.so), filtering out only those
symbols that, at the time of the snapshot, were resident in memory (that are,
the symbols which start address belongs to a mapped page of the .so which was
resident at the time of the snapshot).
The aim is to perform a "code coverage"-like profiling of a binary, intersecting
run-time information (list of resident pages) and debug symbols.
"""

_PAGE_SIZE = 4096


def _TestBit(word, bit):
  assert(bit >= 0 and bit < 8)
  return not not ((word >> bit) & 1)


def _HexAddr(addr):
  return hex(addr)[2:].zfill(8)


def _GetResidentPagesSet(memdump_contents, lib_name, verbose):
  """Parses the memdump output and extracts the resident page set for lib_name.
  Args:
    memdump_contents: Array of strings (lines) of a memdump output.
    lib_name: A string containing the name of the library.so to be matched.
    verbose: Print a verbose header for each mapping matched.

  Returns:
    A set of resident pages (the key is the page index) for all the
    mappings matching .*lib_name.
  """
  resident_pages = set()
  MAP_RX = re.compile(
      r'^([0-9a-f]+)-([0-9a-f]+) ([\w-]+) ([0-9a-f]+) .* "(.*)" \[(.*)\]$')
  for line in memdump_contents:
    line = line.rstrip('\r\n')
    if line.startswith('[ PID'):
      continue

    r = MAP_RX.match(line)
    if not r:
      sys.stderr.write('Skipping %s from %s\n' % (line, memdump_file))
      continue

    map_start = int(r.group(1), 16)
    map_end = int(r.group(2), 16)
    prot = r.group(3)
    offset = int(r.group(4), 16)
    assert(offset % _PAGE_SIZE == 0)
    lib = r.group(5)
    enc_bitmap = r.group(6)

    if not lib.endswith(lib_name):
      continue

    bitmap = base64.b64decode(enc_bitmap)
    map_pages_count = (map_end - map_start + 1) / _PAGE_SIZE
    bitmap_pages_count = len(bitmap) * 8

    if verbose:
      print 'Found %s: mapped %d pages in mode %s @ offset %s.' % (
            lib, map_pages_count, prot, _HexAddr(offset))
      print ' Map range in the process VA: [%s - %s]. Len: %s' % (
          _HexAddr(map_start),
          _HexAddr(map_end),
          _HexAddr(map_pages_count * _PAGE_SIZE))
      print ' Corresponding addresses in the binary: [%s - %s]. Len: %s' % (
          _HexAddr(offset),
          _HexAddr(offset + map_end - map_start),
          _HexAddr(map_pages_count * _PAGE_SIZE))
      print ' Bitmap: %d pages' % bitmap_pages_count
      print ''

    assert(bitmap_pages_count >= map_pages_count)
    for i in xrange(map_pages_count):
      bitmap_idx = i / 8
      bitmap_off = i % 8
      if (bitmap_idx < len(bitmap) and
          _TestBit(ord(bitmap[bitmap_idx]), bitmap_off)):
        resident_pages.add(offset / _PAGE_SIZE + i)
  return resident_pages


def main(argv):
  NM_RX = re.compile(r'^([0-9a-f]+)\s+.*$')

  parser = OptionParser()
  parser.add_option("-r", "--reverse",
                    action="store_true", dest="reverse", default=False,
                    help="Print out non present symbols")
  parser.add_option("-v", "--verbose",
                    action="store_true", dest="verbose", default=False,
                    help="Print out verbose debug information.")

  (options, args) = parser.parse_args()

  if len(args) != 3:
    print 'Usage: %s [-v] memdump.file nm.file library.so' % (
        os.path.basename(argv[0]))
    return 1

  memdump_file = args[0]
  nm_file = args[1]
  lib_name = args[2]

  if memdump_file == '-':
    memdump_contents = sys.stdin.readlines()
  else:
    memdump_contents = open(memdump_file, 'r').readlines()
  resident_pages = _GetResidentPagesSet(memdump_contents,
                                        lib_name,
                                        options.verbose)

  # Process the nm symbol table, filtering out the resident symbols.
  nm_fh = open(nm_file, 'r')
  for line in nm_fh:
    line = line.rstrip('\r\n')
    # Skip undefined symbols (lines with no address).
    if line.startswith(' '):
      continue

    r = NM_RX.match(line)
    if not r:
      sys.stderr.write('Skipping %s from %s\n' % (line, nm_file))
      continue

    sym_addr = int(r.group(1), 16)
    sym_page = sym_addr / _PAGE_SIZE
    last_sym_matched = (sym_page in resident_pages)
    if (sym_page in resident_pages) != options.reverse:
      print line
  return 0

if __name__ == '__main__':
  sys.exit(main(sys.argv))
