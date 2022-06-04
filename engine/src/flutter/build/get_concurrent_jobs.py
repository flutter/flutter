#!/usr/bin/env python3
# Copyright 2019 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script computes the number of concurrent jobs that can run in the
# build as a function of the machine. It accepts a set of key value pairs
# given by repeated --memory-per-job arguments. For example:
#
# $ get_concurrent_jobs.py --memory-per-job dart=1GB
#
# The result is a json map printed to stdout that gives the number of
# concurrent jobs allowed of each kind. For example:
#
# {"dart": 8}
#
# Some memory can be held out of the calculation with the --reserve-memory flag.

import argparse
import ctypes
import json
import multiprocessing
import os
import re
import subprocess
import sys

UNITS = {'B': 1, 'KB': 2**10, 'MB': 2**20, 'GB': 2**30, 'TB': 2**40}


# pylint: disable=line-too-long
# See https://docs.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-globalmemorystatusex
# and https://docs.microsoft.com/en-us/windows/win32/api/sysinfoapi/ns-sysinfoapi-memorystatusex
# pylint: enable=line-too-long
class MEMORYSTATUSEX(ctypes.Structure):
  _fields_ = [
      ('dwLength', ctypes.c_ulong),
      ('dwMemoryLoad', ctypes.c_ulong),
      ('ullTotalPhys', ctypes.c_ulonglong),
      ('ullAvailPhys', ctypes.c_ulonglong),
      ('ullTotalPageFile', ctypes.c_ulonglong),
      ('ullAvailPageFile', ctypes.c_ulonglong),
      ('ullTotalVirtual', ctypes.c_ulonglong),
      ('ullAvailVirtual', ctypes.c_ulonglong),
      ('sullAvailExtendedVirtual', ctypes.c_ulonglong),
  ]


def get_total_memory():
  if sys.platform in ('win32', 'cygwin'):
    stat = MEMORYSTATUSEX(dwLength=ctypes.sizeof(MEMORYSTATUSEX))
    success = ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(stat))
    return stat.ullTotalPhys if success else 0
  if sys.platform.startswith('linux'):
    if os.path.exists('/proc/meminfo'):
      with open('/proc/meminfo') as meminfo:
        memtotal_re = re.compile(r'^MemTotal:\s*(\d*)\s*kB')
        for line in meminfo:
          match = memtotal_re.match(line)
          if match:
            return float(match.group(1)) * 2**10
  if sys.platform == 'darwin':
    try:
      return int(subprocess.check_output(['sysctl', '-n', 'hw.memsize']))
    except:  # pylint: disable=bare-except
      return 0
  return 0


def parse_size(string):
  i = next(i for (i, c) in enumerate(string) if not c.isdigit())
  number = string[:i].strip()
  unit = string[i:].strip()
  return int(float(number) * UNITS[unit])


class ParseSizeAction(argparse.Action):

  def __call__(self, parser, args, values, option_string=None):
    sizes = getattr(args, self.dest, [])
    for value in values:
      (k, val) = value.split('=', 1)
      sizes.append((k, parse_size(val)))
    setattr(args, self.dest, sizes)


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument(
      '--memory-per-job',
      action=ParseSizeAction,
      default=[],
      nargs='*',
      help='Key value pairings (dart=1GB) giving an estimate of the amount of '
      'memory needed for the class of job.'
  )
  parser.add_argument(
      '--reserve-memory',
      type=parse_size,
      default=0,
      help='The amount of memory to be held out of the amount for jobs to use.'
  )
  args = parser.parse_args()

  total_memory = get_total_memory()

  # Ensure the total memory used in the calculation below is at least 0
  mem_total_bytes = max(0, total_memory - args.reserve_memory)

  # Ensure the number of cpus used in the calculation below is at least 1
  try:
    cpu_cap = multiprocessing.cpu_count()
  except:  # pylint: disable=bare-except
    cpu_cap = 1

  concurrent_jobs = {}
  for job, memory_per_job in args.memory_per_job:
    # Calculate the number of jobs that will fit in memory. Ensure the
    # value is at least 1.
    num_concurrent_jobs = int(max(1, mem_total_bytes / memory_per_job))
    # Cap the number of jobs by the number of cpus available.
    concurrent_jobs[job] = min(num_concurrent_jobs, cpu_cap)

  print(json.dumps(concurrent_jobs))

  return 0


if __name__ == '__main__':
  sys.exit(main())
