# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This GYP file should be included for every target in Chromium that is built
# using the NaCl toolchain.
{
  'includes': [
    '../native_client/build/untrusted.gypi',
  ],
  'target_defaults': {
    'conditions': [
      # TODO(bradnelson): Drop this once the nacl side does the same.
      ['target_arch=="x64"', {
        'variables': {
          'enable_x86_32': 0,
        },
      }],
      ['target_arch=="ia32" and OS!="win"', {
        'variables': {
          'enable_x86_64': 0,
        },
      }],
      ['target_arch=="arm"', {
        'variables': {
          'clang': 1,
        },
        'defines': [
          # Needed by build/build_config.h processor architecture detection.
          '__ARMEL__',
          # Needed by base/third_party/nspr/prtime.cc.
          '__arm__',
          # Disable ValGrind. The assembly code it generates causes the build
          # to fail.
          'NVALGRIND',
        ],
      }],
    ],
  },
}
