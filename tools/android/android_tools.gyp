# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    # Intermediate target grouping the android tools needed to run native
    # unittests and instrumentation test apks.
    {
      'target_name': 'android_tools',
      'type': 'none',
      'dependencies': [
        'adb_reboot/adb_reboot.gyp:adb_reboot',
        'file_poller/file_poller.gyp:file_poller',
        'forwarder2/forwarder.gyp:forwarder2',
        'md5sum/md5sum.gyp:md5sum',
        'purge_ashmem/purge_ashmem.gyp:purge_ashmem',
        'run_pie/run_pie.gyp:run_pie',
        '../../tools/telemetry/telemetry.gyp:*#host',
      ],
    },
    {
      'target_name': 'heap_profiler',
      'type': 'none',
      'dependencies': [
        'heap_profiler/heap_profiler.gyp:heap_dump',
        'heap_profiler/heap_profiler.gyp:heap_profiler',
      ],
    },
    {
      'target_name': 'memdump',
      'type': 'none',
      'dependencies': [
        'memdump/memdump.gyp:memdump',
      ],
    },
    {
      'target_name': 'memconsumer',
      'type': 'none',
      'dependencies': [
        'memconsumer/memconsumer.gyp:memconsumer',
      ],
    },
    {
      'target_name': 'ps_ext',
      'type': 'none',
      'dependencies': [
        'ps_ext/ps_ext.gyp:ps_ext',
      ],
    },
  ],
}
