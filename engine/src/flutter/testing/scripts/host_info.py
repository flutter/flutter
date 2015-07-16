#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import json
import multiprocessing
import os
import platform
import subprocess
import sys


import common


def is_linux():
  return sys.platform.startswith('linux')


def get_free_disk_space(failures):
  """Returns the amount of free space on the current disk, in GiB.

  Returns:
    The amount of free space on the current disk, measured in GiB.
  """
  if os.name == 'posix':
    # Stat the current path for info on the current disk.
    stat_result = os.statvfs('.')
    # Multiply block size by number of free blocks, express in GiB.
    return stat_result.f_frsize * stat_result.f_bavail / (
        1024.0 / 1024.0 / 1024.0)

  failures.append('get_free_disk_space: OS %s not supported.' % os.name)
  return 0


def get_num_cpus(failures):
  """Returns the number of logical CPUs on this machine.

  Returns:
    The number of logical CPUs on this machine, or 'unknown' if indeterminate.
  """
  try:
    return multiprocessing.cpu_count()
  except NotImplementedError:
    failures.append('get_num_cpus')
    return 'unknown'


def get_device_info(args, failures):
  """Parses the device info for each attached device, and returns a summary
  of the device info and any mismatches.

  Returns:
    A dict indicating the result.
  """
  if not is_linux():
    return {}

  with common.temporary_file() as tempfile_path:
    rc = common.run_command([
        sys.executable,
        os.path.join(args.paths['checkout'],
                     'build',
                     'android',
                     'buildbot',
                     'bb_device_status_check.py'),
        '--json-output', tempfile_path])

    if rc:
      failures.append('bb_device_status_check')
      return {}

    with open(tempfile_path, 'r') as src:
      device_info = json.load(src)

  results = {}
  results['devices'] = sorted(v['serial'] for v in device_info)

  details = [v['build_detail'] for v in device_info]

  def unique_build_details(index):
    return sorted(list(set([v.split(':')[index] for v in details])))

  parsed_details = {
    'device_names': unique_build_details(0),
    'build_versions': unique_build_details(1),
    'build_types': unique_build_details(2),
  }

  for k, v in parsed_details.iteritems():
    if len(v) == 1:
      results[k] = v[0]
    else:
      results[k] = 'MISMATCH'
      results['%s_list' % k] = v
      failures.append(k)

  return results


def main_run(args):
  failures = []
  host_info = {}
  host_info['os_system'] = platform.system()
  host_info['os_release'] = platform.release()

  host_info['processor'] = platform.processor()
  host_info['num_cpus'] = get_num_cpus(failures)
  host_info['free_disk_space'] = get_free_disk_space(failures)

  host_info['python_version'] = platform.python_version()
  host_info['python_path'] = sys.executable

  host_info['devices'] = get_device_info(args, failures)

  json.dump({
      'valid': True,
      'failures': failures,
      '_host_info': host_info,
  }, args.output)

  return len(failures) != 0


def main_compile_targets(args):
  json.dump([], args.output)


if __name__ == '__main__':
  funcs = {
    'run': main_run,
    'compile_targets': main_compile_targets,
  }
  sys.exit(common.run_script(sys.argv[1:], funcs))
