# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This is an gyp include to use YASM for compiling assembly files.
#
# Files to be compiled with YASM should have an extension of .asm.
#
# There are three variables for this include:
# yasm_flags : Pass additional flags into YASM.
# yasm_output_path : Output directory for the compiled object files.
# yasm_includes : Includes used by .asm code.  Changes to which should force
#                 recompilation.
#
# Sample usage:
# 'sources': [
#   'ultra_optimized_awesome.asm',
# ],
# 'variables': {
#   'yasm_flags': [
#     '-I', 'assembly_include',
#   ],
#   'yasm_output_path': '<(SHARED_INTERMEDIATE_DIR)/project',
#   'yasm_includes': ['ultra_optimized_awesome.inc']
# },
# 'includes': [
#   'third_party/yasm/yasm_compile.gypi'
# ],

{
  'variables': {
    'yasm_flags': [],
    'yasm_includes': [],

    'conditions': [
      [ 'use_system_yasm==0', {
        'yasm_path': '<(PRODUCT_DIR)/yasm<(EXECUTABLE_SUFFIX)',
      }, {
        'yasm_path': '<!(which yasm)',
      }],

      # Define yasm_flags that pass into YASM.
      [ 'os_posix==1 and OS!="mac" and OS!="ios" and target_arch=="ia32"', {
        'yasm_flags': [
          '-felf32',
          '-m', 'x86',
        ],
      }],
      [ 'os_posix==1 and OS!="mac" and OS!="ios" and target_arch=="x64"', {
        'yasm_flags': [
          '-DPIC',
          '-felf64',
          '-m', 'amd64',
        ],
      }],
      [ '(OS=="mac" or OS=="ios") and target_arch=="ia32"', {
        'yasm_flags': [
          '-fmacho32',
          '-m', 'x86',
        ],
      }],
      [ '(OS=="mac" or OS=="ios") and target_arch=="x64"', {
        'yasm_flags': [
          '-fmacho64',
          '-m', 'amd64',
        ],
      }],
      [ 'OS=="win" and target_arch=="ia32"', {
        'yasm_flags': [
          '-DPREFIX',
          '-fwin32',
          '-m', 'x86',
        ],
      }],
      [ 'OS=="win" and target_arch=="x64"', {
        'yasm_flags': [
          '-fwin64',
          '-m', 'amd64',
        ],
      }],

      # Define output extension.
      ['OS=="win"', {
        'asm_obj_extension': 'obj',
      }, {
        'asm_obj_extension': 'o',
      }],
    ],
  },  # variables

  'conditions': [
    # Only depend on YASM on x86 systems, do this so that compiling
    # .asm files for ARM will fail.
    ['use_system_yasm==0 and ( target_arch=="ia32" or target_arch=="x64" )', {
      'dependencies': [
        '<(DEPTH)/third_party/yasm/yasm.gyp:yasm#host',
      ],
    }],
  ],  # conditions

  'rules': [
    {
      'rule_name': 'assemble',
      'extension': 'asm',
      'inputs': [ '<(yasm_path)', '<@(yasm_includes)'],
      'outputs': [
        '<(yasm_output_path)/<(RULE_INPUT_ROOT).<(asm_obj_extension)',
      ],
      'action': [
        '<(yasm_path)',
        '<@(yasm_flags)',
        '-o', '<(yasm_output_path)/<(RULE_INPUT_ROOT).<(asm_obj_extension)',
        '<(RULE_INPUT_PATH)',
      ],
      'process_outputs_as_sources': 1,
      'message': 'Compile assembly <(RULE_INPUT_PATH)',
    },
  ],  # rules
}
