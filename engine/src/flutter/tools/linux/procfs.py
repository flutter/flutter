#!/usr/bin/env python
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# A Python library to read and store procfs (/proc) information on Linux.
#
# Each information storage class in this file stores original data as original
# as reasonablly possible. Translation is done when requested. It is to make it
# always possible to probe the original data.


import collections
import logging
import os
import re
import struct
import sys


class _NullHandler(logging.Handler):
  def emit(self, record):
    pass


_LOGGER = logging.getLogger('procfs')
_LOGGER.addHandler(_NullHandler())


class ProcStat(object):
  """Reads and stores information in /proc/pid/stat."""
  _PATTERN = re.compile(r'^'
                        '(?P<PID>-?[0-9]+) '
                        '\((?P<COMM>.+)\) '
                        '(?P<STATE>[RSDZTW]) '
                        '(?P<PPID>-?[0-9]+) '
                        '(?P<PGRP>-?[0-9]+) '
                        '(?P<SESSION>-?[0-9]+) '
                        '(?P<TTY_NR>-?[0-9]+) '
                        '(?P<TPGID>-?[0-9]+) '
                        '(?P<FLAGS>[0-9]+) '
                        '(?P<MINFIT>[0-9]+) '
                        '(?P<CMINFIT>[0-9]+) '
                        '(?P<MAJFIT>[0-9]+) '
                        '(?P<CMAJFIT>[0-9]+) '
                        '(?P<UTIME>[0-9]+) '
                        '(?P<STIME>[0-9]+) '
                        '(?P<CUTIME>[0-9]+) '
                        '(?P<CSTIME>[0-9]+) '
                        '(?P<PRIORITY>[0-9]+) '
                        '(?P<NICE>[0-9]+) '
                        '(?P<NUM_THREADS>[0-9]+) '
                        '(?P<ITREALVALUE>[0-9]+) '
                        '(?P<STARTTIME>[0-9]+) '
                        '(?P<VSIZE>[0-9]+) '
                        '(?P<RSS>[0-9]+) '
                        '(?P<RSSLIM>[0-9]+) '
                        '(?P<STARTCODE>[0-9]+) '
                        '(?P<ENDCODE>[0-9]+) '
                        '(?P<STARTSTACK>[0-9]+) '
                        '(?P<KSTKESP>[0-9]+) '
                        '(?P<KSTKEIP>[0-9]+) '
                        '(?P<SIGNAL>[0-9]+) '
                        '(?P<BLOCKED>[0-9]+) '
                        '(?P<SIGIGNORE>[0-9]+) '
                        '(?P<SIGCATCH>[0-9]+) '
                        '(?P<WCHAN>[0-9]+) '
                        '(?P<NSWAP>[0-9]+) '
                        '(?P<CNSWAP>[0-9]+) '
                        '(?P<EXIT_SIGNAL>[0-9]+) '
                        '(?P<PROCESSOR>[0-9]+) '
                        '(?P<RT_PRIORITY>[0-9]+) '
                        '(?P<POLICY>[0-9]+) '
                        '(?P<DELAYACCT_BLKIO_TICKS>[0-9]+) '
                        '(?P<GUEST_TIME>[0-9]+) '
                        '(?P<CGUEST_TIME>[0-9]+)', re.IGNORECASE)

  def __init__(self, raw, pid, vsize, rss):
    self._raw = raw
    self._pid = pid
    self._vsize = vsize
    self._rss = rss

  @staticmethod
  def load_file(stat_f):
    raw = stat_f.readlines()
    stat = ProcStat._PATTERN.match(raw[0])
    return ProcStat(raw,
                    stat.groupdict().get('PID'),
                    stat.groupdict().get('VSIZE'),
                    stat.groupdict().get('RSS'))

  @staticmethod
  def load(pid):
    try:
      with open(os.path.join('/proc', str(pid), 'stat'), 'r') as stat_f:
        return ProcStat.load_file(stat_f)
    except IOError:
      return None

  @property
  def raw(self):
    return self._raw

  @property
  def pid(self):
    return int(self._pid)

  @property
  def vsize(self):
    return int(self._vsize)

  @property
  def rss(self):
    return int(self._rss)


class ProcStatm(object):
  """Reads and stores information in /proc/pid/statm."""
  _PATTERN = re.compile(r'^'
                        '(?P<SIZE>[0-9]+) '
                        '(?P<RESIDENT>[0-9]+) '
                        '(?P<SHARE>[0-9]+) '
                        '(?P<TEXT>[0-9]+) '
                        '(?P<LIB>[0-9]+) '
                        '(?P<DATA>[0-9]+) '
                        '(?P<DT>[0-9]+)', re.IGNORECASE)

  def __init__(self, raw, size, resident, share, text, lib, data, dt):
    self._raw = raw
    self._size = size
    self._resident = resident
    self._share = share
    self._text = text
    self._lib = lib
    self._data = data
    self._dt = dt

  @staticmethod
  def load_file(statm_f):
    try:
      raw = statm_f.readlines()
    except (IOError, OSError):
      return None
    statm = ProcStatm._PATTERN.match(raw[0])
    return ProcStatm(raw,
                     statm.groupdict().get('SIZE'),
                     statm.groupdict().get('RESIDENT'),
                     statm.groupdict().get('SHARE'),
                     statm.groupdict().get('TEXT'),
                     statm.groupdict().get('LIB'),
                     statm.groupdict().get('DATA'),
                     statm.groupdict().get('DT'))

  @staticmethod
  def load(pid):
    try:
      with open(os.path.join('/proc', str(pid), 'statm'), 'r') as statm_f:
        return ProcStatm.load_file(statm_f)
    except (IOError, OSError):
      return None

  @property
  def raw(self):
    return self._raw

  @property
  def size(self):
    return int(self._size)

  @property
  def resident(self):
    return int(self._resident)

  @property
  def share(self):
    return int(self._share)

  @property
  def text(self):
    return int(self._text)

  @property
  def lib(self):
    return int(self._lib)

  @property
  def data(self):
    return int(self._data)

  @property
  def dt(self):
    return int(self._dt)


class ProcStatus(object):
  """Reads and stores information in /proc/pid/status."""
  _PATTERN = re.compile(r'^(?P<NAME>[A-Za-z0-9_]+):\s+(?P<VALUE>.*)')

  def __init__(self, raw, dct):
    self._raw = raw
    self._pid = dct.get('Pid')
    self._name = dct.get('Name')
    self._vm_peak = dct.get('VmPeak')
    self._vm_size = dct.get('VmSize')
    self._vm_lck = dct.get('VmLck')
    self._vm_pin = dct.get('VmPin')
    self._vm_hwm = dct.get('VmHWM')
    self._vm_rss = dct.get('VmRSS')
    self._vm_data = dct.get('VmData')
    self._vm_stack = dct.get('VmStk')
    self._vm_exe = dct.get('VmExe')
    self._vm_lib = dct.get('VmLib')
    self._vm_pte = dct.get('VmPTE')
    self._vm_swap = dct.get('VmSwap')

  @staticmethod
  def load_file(status_f):
    raw = status_f.readlines()
    dct = {}
    for line in raw:
      status_match = ProcStatus._PATTERN.match(line)
      if status_match:
        match_dict = status_match.groupdict()
        dct[match_dict['NAME']] = match_dict['VALUE']
      else:
        raise SyntaxError('Unknown /proc/pid/status format.')
    return ProcStatus(raw, dct)

  @staticmethod
  def load(pid):
    with open(os.path.join('/proc', str(pid), 'status'), 'r') as status_f:
      return ProcStatus.load_file(status_f)

  @property
  def raw(self):
    return self._raw

  @property
  def pid(self):
    return int(self._pid)

  @property
  def vm_peak(self):
    """Returns a high-water (peak) virtual memory size in kilo-bytes."""
    if self._vm_peak.endswith('kB'):
      return int(self._vm_peak.split()[0])
    raise ValueError('VmPeak is not in kB.')

  @property
  def vm_size(self):
    """Returns a virtual memory size in kilo-bytes."""
    if self._vm_size.endswith('kB'):
      return int(self._vm_size.split()[0])
    raise ValueError('VmSize is not in kB.')

  @property
  def vm_hwm(self):
    """Returns a high-water (peak) resident set size (RSS) in kilo-bytes."""
    if self._vm_hwm.endswith('kB'):
      return int(self._vm_hwm.split()[0])
    raise ValueError('VmHWM is not in kB.')

  @property
  def vm_rss(self):
    """Returns a resident set size (RSS) in kilo-bytes."""
    if self._vm_rss.endswith('kB'):
      return int(self._vm_rss.split()[0])
    raise ValueError('VmRSS is not in kB.')


class ProcMapsEntry(object):
  """A class representing one line in /proc/pid/maps."""

  def __init__(
      self, begin, end, readable, writable, executable, private, offset,
      major, minor, inode, name):
    self.begin = begin
    self.end = end
    self.readable = readable
    self.writable = writable
    self.executable = executable
    self.private = private
    self.offset = offset
    self.major = major
    self.minor = minor
    self.inode = inode
    self.name = name

  def as_dict(self):
    return {
        'begin': self.begin,
        'end': self.end,
        'readable': self.readable,
        'writable': self.writable,
        'executable': self.executable,
        'private': self.private,
        'offset': self.offset,
        'major': self.major,
        'minor': self.minor,
        'inode': self.inode,
        'name': self.name,
    }


class ProcMaps(object):
  """Reads and stores information in /proc/pid/maps."""

  MAPS_PATTERN = re.compile(
      r'^([a-f0-9]+)-([a-f0-9]+)\s+(.)(.)(.)(.)\s+([a-f0-9]+)\s+(\S+):(\S+)\s+'
      r'(\d+)\s*(.*)$', re.IGNORECASE)

  EXECUTABLE_PATTERN = re.compile(
      r'\S+\.(so|dll|dylib|bundle)((\.\d+)+\w*(\.\d+){0,3})?')

  def __init__(self):
    self._sorted_indexes = []
    self._dictionary = {}
    self._sorted = True

  def iter(self, condition):
    if not self._sorted:
      self._sorted_indexes.sort()
      self._sorted = True
    for index in self._sorted_indexes:
      if not condition or condition(self._dictionary[index]):
        yield self._dictionary[index]

  def __iter__(self):
    if not self._sorted:
      self._sorted_indexes.sort()
      self._sorted = True
    for index in self._sorted_indexes:
      yield self._dictionary[index]

  @staticmethod
  def load_file(maps_f):
    table = ProcMaps()
    for line in maps_f:
      table.append_line(line)
    return table

  @staticmethod
  def load(pid):
    try:
      with open(os.path.join('/proc', str(pid), 'maps'), 'r') as maps_f:
        return ProcMaps.load_file(maps_f)
    except (IOError, OSError):
      return None

  def append_line(self, line):
    entry = self.parse_line(line)
    if entry:
      self._append_entry(entry)
    return entry

  @staticmethod
  def parse_line(line):
    matched = ProcMaps.MAPS_PATTERN.match(line)
    if matched:
      return ProcMapsEntry(  # pylint: disable=W0212
          int(matched.group(1), 16),  # begin
          int(matched.group(2), 16),  # end
          matched.group(3),           # readable
          matched.group(4),           # writable
          matched.group(5),           # executable
          matched.group(6),           # private
          int(matched.group(7), 16),  # offset
          matched.group(8),           # major
          matched.group(9),           # minor
          int(matched.group(10), 10), # inode
          matched.group(11)           # name
          )
    else:
      return None

  @staticmethod
  def constants(entry):
    return entry.writable == '-' and entry.executable == '-'

  @staticmethod
  def executable(entry):
    return entry.executable == 'x'

  @staticmethod
  def executable_and_constants(entry):
    return ((entry.writable == '-' and entry.executable == '-') or
            entry.executable == 'x')

  def _append_entry(self, entry):
    if self._sorted_indexes and self._sorted_indexes[-1] > entry.begin:
      self._sorted = False
    self._sorted_indexes.append(entry.begin)
    self._dictionary[entry.begin] = entry


class ProcSmaps(object):
  """Reads and stores information in /proc/pid/smaps."""
  _SMAPS_PATTERN = re.compile(r'^(?P<NAME>[A-Za-z0-9_]+):\s+(?P<VALUE>.*)')

  class VMA(object):
    def __init__(self):
      self._size = 0
      self._rss = 0
      self._pss = 0

    def append(self, name, value):
      dct = {
        'Size': '_size',
        'Rss': '_rss',
        'Pss': '_pss',
        'Referenced': '_referenced',
        'Private_Clean': '_private_clean',
        'Shared_Clean': '_shared_clean',
        'KernelPageSize': '_kernel_page_size',
        'MMUPageSize': '_mmu_page_size',
        }
      if name in dct:
        self.__setattr__(dct[name], value)

    @property
    def size(self):
      if self._size.endswith('kB'):
        return int(self._size.split()[0])
      return int(self._size)

    @property
    def rss(self):
      if self._rss.endswith('kB'):
        return int(self._rss.split()[0])
      return int(self._rss)

    @property
    def pss(self):
      if self._pss.endswith('kB'):
        return int(self._pss.split()[0])
      return int(self._pss)

  def __init__(self, raw, total_dct, maps, vma_internals):
    self._raw = raw
    self._size = total_dct['Size']
    self._rss = total_dct['Rss']
    self._pss = total_dct['Pss']
    self._referenced = total_dct['Referenced']
    self._shared_clean = total_dct['Shared_Clean']
    self._private_clean = total_dct['Private_Clean']
    self._kernel_page_size = total_dct['KernelPageSize']
    self._mmu_page_size = total_dct['MMUPageSize']
    self._maps = maps
    self._vma_internals = vma_internals

  @staticmethod
  def load(pid):
    with open(os.path.join('/proc', str(pid), 'smaps'), 'r') as smaps_f:
      raw = smaps_f.readlines()

    vma = None
    vma_internals = collections.OrderedDict()
    total_dct = collections.defaultdict(int)
    maps = ProcMaps()
    for line in raw:
      maps_match = ProcMaps.MAPS_PATTERN.match(line)
      if maps_match:
        vma = maps.append_line(line.strip())
        vma_internals[vma] = ProcSmaps.VMA()
      else:
        smaps_match = ProcSmaps._SMAPS_PATTERN.match(line)
        if smaps_match:
          match_dict = smaps_match.groupdict()
          vma_internals[vma].append(match_dict['NAME'], match_dict['VALUE'])
          total_dct[match_dict['NAME']] += int(match_dict['VALUE'].split()[0])

    return ProcSmaps(raw, total_dct, maps, vma_internals)

  @property
  def size(self):
    return self._size

  @property
  def rss(self):
    return self._rss

  @property
  def referenced(self):
    return self._referenced

  @property
  def pss(self):
    return self._pss

  @property
  def private_clean(self):
    return self._private_clean

  @property
  def shared_clean(self):
    return self._shared_clean

  @property
  def kernel_page_size(self):
    return self._kernel_page_size

  @property
  def mmu_page_size(self):
    return self._mmu_page_size

  @property
  def vma_internals(self):
    return self._vma_internals


class ProcPagemap(object):
  """Reads and stores partial information in /proc/pid/pagemap.

  It picks up virtual addresses to read based on ProcMaps (/proc/pid/maps).
  See https://www.kernel.org/doc/Documentation/vm/pagemap.txt for details.
  """
  _BYTES_PER_PAGEMAP_VALUE = 8
  _BYTES_PER_OS_PAGE = 4096
  _VIRTUAL_TO_PAGEMAP_OFFSET = _BYTES_PER_OS_PAGE / _BYTES_PER_PAGEMAP_VALUE

  _MASK_PRESENT = 1 << 63
  _MASK_SWAPPED = 1 << 62
  _MASK_FILEPAGE_OR_SHAREDANON = 1 << 61
  _MASK_SOFTDIRTY = 1 << 55
  _MASK_PFN = (1 << 55) - 1

  class VMA(object):
    def __init__(self, vsize, present, swapped, pageframes):
      self._vsize = vsize
      self._present = present
      self._swapped = swapped
      self._pageframes = pageframes

    @property
    def vsize(self):
      return int(self._vsize)

    @property
    def present(self):
      return int(self._present)

    @property
    def swapped(self):
      return int(self._swapped)

    @property
    def pageframes(self):
      return self._pageframes

  def __init__(self, vsize, present, swapped, vma_internals, in_process_dup):
    self._vsize = vsize
    self._present = present
    self._swapped = swapped
    self._vma_internals = vma_internals
    self._in_process_dup = in_process_dup

  @staticmethod
  def load(pid, maps):
    total_present = 0
    total_swapped = 0
    total_vsize = 0
    in_process_dup = 0
    vma_internals = collections.OrderedDict()
    process_pageframe_set = set()

    try:
      pagemap_fd = os.open(
          os.path.join('/proc', str(pid), 'pagemap'), os.O_RDONLY)
    except (IOError, OSError):
      return None
    for vma in maps:
      present = 0
      swapped = 0
      vsize = 0
      pageframes = collections.defaultdict(int)
      begin_offset = ProcPagemap._offset(vma.begin)
      chunk_size = ProcPagemap._offset(vma.end) - begin_offset
      try:
        os.lseek(pagemap_fd, begin_offset, os.SEEK_SET)
        buf = os.read(pagemap_fd, chunk_size)
      except (IOError, OSError):
        return None
      if len(buf) < chunk_size:
        _LOGGER.warn('Failed to read pagemap at 0x%x in %d.' % (vma.begin, pid))
      pagemap_values = struct.unpack(
          '=%dQ' % (len(buf) / ProcPagemap._BYTES_PER_PAGEMAP_VALUE), buf)
      for pagemap_value in pagemap_values:
        vsize += ProcPagemap._BYTES_PER_OS_PAGE
        if pagemap_value & ProcPagemap._MASK_PRESENT:
          if (pagemap_value & ProcPagemap._MASK_PFN) in process_pageframe_set:
            in_process_dup += ProcPagemap._BYTES_PER_OS_PAGE
          else:
            process_pageframe_set.add(pagemap_value & ProcPagemap._MASK_PFN)
          if (pagemap_value & ProcPagemap._MASK_PFN) not in pageframes:
            present += ProcPagemap._BYTES_PER_OS_PAGE
          pageframes[pagemap_value & ProcPagemap._MASK_PFN] += 1
        if pagemap_value & ProcPagemap._MASK_SWAPPED:
          swapped += ProcPagemap._BYTES_PER_OS_PAGE
      vma_internals[vma] = ProcPagemap.VMA(vsize, present, swapped, pageframes)
      total_present += present
      total_swapped += swapped
      total_vsize += vsize
    try:
      os.close(pagemap_fd)
    except OSError:
      return None

    return ProcPagemap(total_vsize, total_present, total_swapped,
                       vma_internals, in_process_dup)

  @staticmethod
  def _offset(virtual_address):
    return virtual_address / ProcPagemap._VIRTUAL_TO_PAGEMAP_OFFSET

  @property
  def vsize(self):
    return int(self._vsize)

  @property
  def present(self):
    return int(self._present)

  @property
  def swapped(self):
    return int(self._swapped)

  @property
  def vma_internals(self):
    return self._vma_internals


class _ProcessMemory(object):
  """Aggregates process memory information from /proc for manual testing."""
  def __init__(self, pid):
    self._pid = pid
    self._maps = None
    self._pagemap = None
    self._stat = None
    self._status = None
    self._statm = None
    self._smaps = []

  def _read(self, proc_file):
    lines = []
    with open(os.path.join('/proc', str(self._pid), proc_file), 'r') as proc_f:
      lines = proc_f.readlines()
    return lines

  def read_all(self):
    self.read_stat()
    self.read_statm()
    self.read_status()
    self.read_smaps()
    self.read_maps()
    self.read_pagemap(self._maps)

  def read_maps(self):
    self._maps = ProcMaps.load(self._pid)

  def read_pagemap(self, maps):
    self._pagemap = ProcPagemap.load(self._pid, maps)

  def read_smaps(self):
    self._smaps = ProcSmaps.load(self._pid)

  def read_stat(self):
    self._stat = ProcStat.load(self._pid)

  def read_statm(self):
    self._statm = ProcStatm.load(self._pid)

  def read_status(self):
    self._status = ProcStatus.load(self._pid)

  @property
  def pid(self):
    return self._pid

  @property
  def maps(self):
    return self._maps

  @property
  def pagemap(self):
    return self._pagemap

  @property
  def smaps(self):
    return self._smaps

  @property
  def stat(self):
    return self._stat

  @property
  def statm(self):
    return self._statm

  @property
  def status(self):
    return self._status


def main(argv):
  """The main function for manual testing."""
  _LOGGER.setLevel(logging.WARNING)
  handler = logging.StreamHandler()
  handler.setLevel(logging.WARNING)
  handler.setFormatter(logging.Formatter(
      '%(asctime)s:%(name)s:%(levelname)s:%(message)s'))
  _LOGGER.addHandler(handler)

  pids = []
  for arg in argv[1:]:
    try:
      pid = int(arg)
    except ValueError:
      raise SyntaxError("%s is not an integer." % arg)
    else:
      pids.append(pid)

  procs = {}
  for pid in pids:
    procs[pid] = _ProcessMemory(pid)
    procs[pid].read_all()

    print '=== PID: %d ===' % pid

    print '   stat: %d' % procs[pid].stat.vsize
    print '  statm: %d' % (procs[pid].statm.size * 4096)
    print ' status: %d (Peak:%d)' % (procs[pid].status.vm_size * 1024,
                                     procs[pid].status.vm_peak * 1024)
    print '  smaps: %d' % (procs[pid].smaps.size * 1024)
    print 'pagemap: %d' % procs[pid].pagemap.vsize
    print '   stat: %d' % (procs[pid].stat.rss * 4096)
    print '  statm: %d' % (procs[pid].statm.resident * 4096)
    print ' status: %d (Peak:%d)' % (procs[pid].status.vm_rss * 1024,
                                     procs[pid].status.vm_hwm * 1024)
    print '  smaps: %d' % (procs[pid].smaps.rss * 1024)
    print 'pagemap: %d' % procs[pid].pagemap.present

  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))
