# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    # These files lists are shared with the GN build.
    'relocation_packer_sources': [
      'bionic/tools/relocation_packer/src/debug.cc',
      'bionic/tools/relocation_packer/src/delta_encoder.cc',
      'bionic/tools/relocation_packer/src/elf_file.cc',
      'bionic/tools/relocation_packer/src/packer.cc',
      'bionic/tools/relocation_packer/src/sleb128.cc',
    ],
    'relocation_packer_main_source': [
      'bionic/tools/relocation_packer/src/main.cc',
    ],
    'relocation_packer_test_sources': [
      'bionic/tools/relocation_packer/src/debug_unittest.cc',
      'bionic/tools/relocation_packer/src/delta_encoder_unittest.cc',
      'bionic/tools/relocation_packer/src/elf_file_unittest.cc',
      'bionic/tools/relocation_packer/src/packer_unittest.cc',
      'bionic/tools/relocation_packer/src/sleb128_unittest.cc',
      'bionic/tools/relocation_packer/src/run_all_unittests.cc',
    ],
  },
  'targets': [
    {
      # GN: //third_party/android_platform:android_lib_relocation_packer
      'target_name': 'android_lib_relocation_packer',
      'toolsets': ['host'],
      'type': 'static_library',
      'dependencies': [
        '../../third_party/elfutils/elfutils.gyp:libelf',
      ],
      'sources': [
        '<@(relocation_packer_sources)'
      ],
    },
    {
      # GN: //third_party/android_platform:android_relocation_packer
      'target_name': 'android_relocation_packer',
      'toolsets': ['host'],
      'type': 'executable',
      'dependencies': [
        '../../third_party/elfutils/elfutils.gyp:libelf',
        'android_lib_relocation_packer',
      ],
      'sources': [
        '<@(relocation_packer_main_source)'
      ],
    },
    {
      # TODO(GN)
      'target_name': 'android_relocation_packer_unittests',
      'toolsets': ['host'],
      'type': 'executable',
      'dependencies': [
        '../../testing/gtest.gyp:gtest',
        'android_lib_relocation_packer',
      ],
      'include_dirs': [
        '../..',
      ],
      'sources': [
        '<@(relocation_packer_test_sources)'
      ],
      'copies': [
        {
          'destination': '<(PRODUCT_DIR)',
          'files': [
            'bionic/tools/relocation_packer/test_data/elf_file_unittest_relocs_arm32.so',
            'bionic/tools/relocation_packer/test_data/elf_file_unittest_relocs_arm32_packed.so',
            'bionic/tools/relocation_packer/test_data/elf_file_unittest_relocs_arm64.so',
            'bionic/tools/relocation_packer/test_data/elf_file_unittest_relocs_arm64_packed.so',
            'bionic/tools/relocation_packer/test_data/elf_file_unittest_relocs_ia32.so',
            'bionic/tools/relocation_packer/test_data/elf_file_unittest_relocs_ia32_packed.so',
            'bionic/tools/relocation_packer/test_data/elf_file_unittest_relocs_x64.so',
            'bionic/tools/relocation_packer/test_data/elf_file_unittest_relocs_x64_packed.so',
            'bionic/tools/relocation_packer/test_data/elf_file_unittest_relocs_mips32.so',
            'bionic/tools/relocation_packer/test_data/elf_file_unittest_relocs_mips32_packed.so',
          ],
        },
      ],
    },
  ],
}
