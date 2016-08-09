# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

''' A bunch of helper functions for querying gdb.'''

import logging
import os
import re
import tempfile

GDB_LINE_RE = re.compile(r'Line ([0-9]*) of "([^"]*)".*')

def _GdbOutputToFileLine(output_line):
  ''' Parse the gdb output line, return a pair (file, line num) '''
  match =  GDB_LINE_RE.match(output_line)
  if match:
    return match.groups()[1], match.groups()[0]
  else:
    return None

def ResolveAddressesWithinABinary(binary_name, load_address, address_list):
  ''' For each address, return a pair (file, line num) '''
  commands = tempfile.NamedTemporaryFile()
  commands.write('add-symbol-file "%s" %s\n' % (binary_name, load_address))
  for addr in address_list:
    commands.write('info line *%s\n' % addr)
  commands.write('quit\n')
  commands.flush()
  gdb_commandline = 'gdb -batch -x %s 2>/dev/null' % commands.name
  gdb_pipe = os.popen(gdb_commandline)
  result = gdb_pipe.readlines()

  address_count = 0
  ret = {}
  for line in result:
    if line.startswith('Line'):
      ret[address_list[address_count]] = _GdbOutputToFileLine(line)
      address_count += 1
    if line.startswith('No line'):
      ret[address_list[address_count]] = (None, None)
      address_count += 1
  gdb_pipe.close()
  commands.close()
  return ret

class AddressTable(object):
  ''' Object to do batched line number lookup. '''
  def __init__(self):
    self._load_addresses = {}
    self._binaries = {}
    self._all_resolved = False

  def AddBinaryAt(self, binary, load_address):
    ''' Register a new shared library or executable. '''
    self._load_addresses[binary] = load_address

  def Add(self, binary, address):
    ''' Register a lookup request. '''
    if binary == '':
      logging.warn('adding address %s in empty binary?' % address)
    if binary in self._binaries:
      self._binaries[binary].append(address)
    else:
      self._binaries[binary] = [address]
    self._all_resolved = False

  def ResolveAll(self):
    ''' Carry out all lookup requests. '''
    self._translation = {}
    for binary in self._binaries.keys():
      if binary != '' and binary in self._load_addresses:
        load_address = self._load_addresses[binary]
        addr = ResolveAddressesWithinABinary(
            binary, load_address, self._binaries[binary])
        self._translation[binary] = addr
    self._all_resolved = True

  def GetFileLine(self, binary, addr):
    ''' Get the (filename, linenum) result of a previously-registered lookup
    request.
    '''
    if self._all_resolved:
      if binary in self._translation:
        if addr in self._translation[binary]:
          return self._translation[binary][addr]
    return (None, None)
