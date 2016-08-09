# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    'target_define%': 'TARGET_UNSUPPORTED',
    'conditions': [
      [ 'target_arch == "arm"', {
        'target_define': 'TARGET_ARM',
      }],
      [ 'target_arch == "arm64"', {
        'target_define': 'TARGET_ARM64',
      }],
    ],
  },
  'targets': [
    {
      # GN: //tools/relocation_packer:lib_relocation_packer
      'target_name': 'lib_relocation_packer',
      'toolsets': ['host'],
      'type': 'static_library',
      'defines': [
        '<(target_define)',
      ],
      'dependencies': [
        '../../third_party/elfutils/elfutils.gyp:libelf',
      ],
      'sources': [
        'src/debug.cc',
        'src/delta_encoder.cc',
        'src/elf_file.cc',
        'src/leb128.cc',
        'src/packer.cc',
        'src/sleb128.cc',
        'src/run_length_encoder.cc',
      ],
    },
    {
      # GN: //tools/relocation_packer:relocation_packer
      'target_name': 'relocation_packer',
      'toolsets': ['host'],
      'type': 'executable',
      'defines': [
        '<(target_define)',
      ],
      'dependencies': [
        '../../third_party/elfutils/elfutils.gyp:libelf',
        'lib_relocation_packer',
      ],
      'sources': [
        'src/main.cc',
      ],
    },
    {
      # GN: //tools/relocation_packer:relocation_packer_unittests
      'target_name': 'relocation_packer_unittests',
      'toolsets': ['host'],
      'type': 'executable',
      'defines': [
        '<(target_define)',
      ],
      'cflags': [
        '-DINTERMEDIATE_DIR="<(INTERMEDIATE_DIR)"',
      ],
      'dependencies': [
        '../../testing/gtest.gyp:gtest',
        'lib_relocation_packer',
      ],
      'include_dirs': [
        '../..',
      ],
      'sources': [
        'src/debug_unittest.cc',
        'src/delta_encoder_unittest.cc',
        'src/elf_file_unittest.cc',
        'src/leb128_unittest.cc',
        'src/packer_unittest.cc',
        'src/sleb128_unittest.cc',
        'src/run_length_encoder_unittest.cc',
        'src/run_all_unittests.cc',
      ],
      'copies': [
        {
          'destination': '<(INTERMEDIATE_DIR)',
          'files': [
            'test_data/elf_file_unittest_relocs_arm32.so',
            'test_data/elf_file_unittest_relocs_arm32_packed.so',
            'test_data/elf_file_unittest_relocs_arm64.so',
            'test_data/elf_file_unittest_relocs_arm64_packed.so',
          ],
        },
      ],
    },

    # Targets to build test data.  These participate only in building test
    # data for use with elf_file_unittest.cc, and are not part of the main
    # relocation packer build.  Unit test data files are checked in to the
    # source tree as 'golden' data, and are not generated 'on the fly' by
    # the build.
    #
    # See test_data/generate_elf_file_unittest_relocs.sh for instructions.
    {
      # GN: //tools/relocation_packer:relocation_packer_test_data
      'target_name': 'relocation_packer_test_data',
      'toolsets': ['target'],
      'type': 'shared_library',
      'cflags': [
        '-O0',
        '-g0',
      ],
      'sources': [
        'test_data/elf_file_unittest_relocs.cc',
      ],
    },
    {
      # GN: //tools/relocation_packer:relocation_packer_unittests_test_data
      'target_name': 'relocation_packer_unittests_test_data',
      'toolsets': ['target'],
      'type': 'none',
      'actions': [
        {
          'variables': {
            'test_file': '<(SHARED_LIB_DIR)/librelocation_packer_test_data.so',
            'conditions': [
              [ 'target_arch == "arm"', {
                'added_section': '.android.rel.dyn',
                'unpacked_output': 'elf_file_unittest_relocs_arm32.so',
                'packed_output': 'elf_file_unittest_relocs_arm32_packed.so',
              }],
              [ 'target_arch == "arm64"', {
                'added_section': '.android.rela.dyn',
                'unpacked_output': 'elf_file_unittest_relocs_arm64.so',
                'packed_output': 'elf_file_unittest_relocs_arm64_packed.so',
              }],
            ],
          },
          'action_name': 'generate_relocation_packer_test_data',
          'inputs': [
            'test_data/generate_elf_file_unittest_relocs.py',
            '<(PRODUCT_DIR)/relocation_packer',
            '<(test_file)',
          ],
          'outputs': [
            '<(INTERMEDIATE_DIR)/<(unpacked_output)',
            '<(INTERMEDIATE_DIR)/<(packed_output)',
          ],
          'action': [
              'python', 'test_data/generate_elf_file_unittest_relocs.py',
              '--android-pack-relocations=<(PRODUCT_DIR)/relocation_packer',
              '--android-objcopy=<(android_objcopy)',
              '--added-section=<(added_section)',
              '--test-file=<(test_file)',
              '--unpacked-output=<(INTERMEDIATE_DIR)/<(unpacked_output)',
              '--packed-output=<(INTERMEDIATE_DIR)/<(packed_output)',
          ],
        },
      ],
    },
  ],
}
