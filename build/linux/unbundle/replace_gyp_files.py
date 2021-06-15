#!/usr/bin/env python
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Replaces gyp files in tree with files from here that
make the build use system libraries.
"""


import optparse
import os.path
import shutil
import sys


REPLACEMENTS = {
  'use_system_expat': 'third_party/expat/expat.gyp',
  'use_system_ffmpeg': 'third_party/ffmpeg/ffmpeg.gyp',
  'use_system_flac': 'third_party/flac/flac.gyp',
  'use_system_harfbuzz': 'third_party/harfbuzz-ng/harfbuzz.gyp',
  'use_system_icu': 'third_party/icu/icu.gyp',
  'use_system_jsoncpp': 'third_party/jsoncpp/jsoncpp.gyp',
  'use_system_libevent': 'third_party/libevent/libevent.gyp',
  'use_system_libjpeg': 'third_party/libjpeg/libjpeg.gyp',
  'use_system_libpng': 'third_party/libpng/libpng.gyp',
  'use_system_libusb': 'third_party/libusb/libusb.gyp',
  'use_system_libvpx': 'third_party/libvpx/libvpx.gyp',
  'use_system_libwebp': 'third_party/libwebp/libwebp.gyp',
  'use_system_libxml': 'third_party/libxml/libxml.gyp',
  'use_system_libxnvctrl' : 'third_party/libXNVCtrl/libXNVCtrl.gyp',
  'use_system_libxslt': 'third_party/libxslt/libxslt.gyp',
  'use_system_opus': 'third_party/opus/opus.gyp',
  'use_system_protobuf': 'third_party/protobuf/protobuf.gyp',
  'use_system_re2': 'third_party/re2/re2.gyp',
  'use_system_snappy': 'third_party/snappy/snappy.gyp',
  'use_system_speex': 'third_party/speex/speex.gyp',
  'use_system_sqlite': 'third_party/sqlite/sqlite.gyp',
  'use_system_v8': 'v8/tools/gyp/v8.gyp',
  'use_system_zlib': 'third_party/zlib/zlib.gyp',
}


def DoMain(argv):
  my_dirname = os.path.dirname(__file__)
  source_tree_root = os.path.abspath(
    os.path.join(my_dirname, '..', '..', '..'))

  parser = optparse.OptionParser()

  # Accept arguments in gyp command-line syntax, so that the caller can re-use
  # command-line for this script and gyp.
  parser.add_option('-D', dest='defines', action='append')

  parser.add_option('--undo', action='store_true')

  options, args = parser.parse_args(argv)

  for flag, path in REPLACEMENTS.items():
    if '%s=1' % flag not in options.defines:
      continue

    if options.undo:
      # Restore original file, and also remove the backup.
      # This is meant to restore the source tree to its original state.
      os.rename(os.path.join(source_tree_root, path + '.orig'),
                os.path.join(source_tree_root, path))
    else:
      # Create a backup copy for --undo.
      shutil.copyfile(os.path.join(source_tree_root, path),
                      os.path.join(source_tree_root, path + '.orig'))

      # Copy the gyp file from directory of this script to target path.
      shutil.copyfile(os.path.join(my_dirname, os.path.basename(path)),
                      os.path.join(source_tree_root, path))

  return 0


if __name__ == '__main__':
  sys.exit(DoMain(sys.argv))
