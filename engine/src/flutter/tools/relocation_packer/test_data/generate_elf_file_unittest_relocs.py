#!/usr/bin/env python
#
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Build relocation packer unit test data.

Uses a built relocation packer to generate 'golden' reference test data
files for elf_file_unittests.cc.
"""

import optparse
import os
import shutil
import subprocess
import sys
import tempfile

def PackArmLibraryRelocations(android_pack_relocations,
                              android_objcopy,
                              added_section,
                              input_path,
                              output_path):
  # Copy and add a 'NULL' .android.rel.dyn section for the packing tool.
  with tempfile.NamedTemporaryFile() as stream:
    stream.write('NULL')
    stream.flush()
    objcopy_command = [android_objcopy,
                       '--add-section', '%s=%s' % (added_section, stream.name),
                       input_path, output_path]
    subprocess.check_call(objcopy_command)

  # Pack relocations.
  pack_command = [android_pack_relocations, output_path]
  subprocess.check_call(pack_command)


def UnpackArmLibraryRelocations(android_pack_relocations,
                                input_path,
                                output_path):
  shutil.copy(input_path, output_path)

  # Unpack relocations.  We leave the .android.rel.dyn or .android.rela.dyn
  # in place.
  unpack_command = [android_pack_relocations, '-u', output_path]
  subprocess.check_call(unpack_command)


def main():
  parser = optparse.OptionParser()

  parser.add_option('--android-pack-relocations',
      help='Path to the ARM relocations packer binary')
  parser.add_option('--android-objcopy',
      help='Path to the toolchain\'s objcopy binary')
  parser.add_option('--added-section',
      choices=['.android.rel.dyn', '.android.rela.dyn'],
      help='Section to add, one of ".android.rel.dyn" or ".android.rela.dyn"')
  parser.add_option('--test-file',
      help='Path to the input test file, an unpacked ARM .so')
  parser.add_option('--unpacked-output',
      help='Path to the output file for reference unpacked data')
  parser.add_option('--packed-output',
      help='Path to the output file for reference packed data')

  options, _ = parser.parse_args()

  for output in [options.unpacked_output, options.packed_output]:
    directory = os.path.dirname(output)
    if not os.path.exists(directory):
      os.makedirs(directory)

  PackArmLibraryRelocations(options.android_pack_relocations,
                            options.android_objcopy,
                            options.added_section,
                            options.test_file,
                            options.packed_output)

  UnpackArmLibraryRelocations(options.android_pack_relocations,
                              options.packed_output,
                              options.unpacked_output)

  return 0


if __name__ == '__main__':
  sys.exit(main())
