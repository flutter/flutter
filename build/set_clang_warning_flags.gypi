# Copyright (c) 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included to set clang-specific compiler flags.
# To use this the following variable can be defined:
#   clang_warning_flags:       list: Compiler flags to pass to clang.
#   clang_warning_flags_unset: list: Compiler flags to not pass to clang.
#
# Only use this in third-party code. In chromium_code, fix your code to not
# warn instead!
#
# Note that the gypi file is included in target_defaults, so it does not need
# to be explicitly included.
#
# Warning flags set by this will be used on all platforms. If you want to set
# warning flags on only some platforms, you have to do so manually.
#
# To use this, create a gyp target with the following form:
# {
#   'target_name': 'my_target',
#   'variables': {
#     'clang_warning_flags': ['-Wno-awesome-warning'],
#     'clang_warning_flags_unset': ['-Wpreviously-set-flag'],
#   }
# }

{
  'variables': {
    'clang_warning_flags_unset%': [],  # Provide a default value.
  },
  'conditions': [
    ['clang==1', {
      # This uses >@ instead of @< to also see clang_warning_flags set in
      # targets directly, not just the clang_warning_flags in target_defaults.
      'cflags': [ '>@(clang_warning_flags)' ],
      'cflags!': [ '>@(clang_warning_flags_unset)' ],
      'xcode_settings': {
        'WARNING_CFLAGS': ['>@(clang_warning_flags)'],
        'WARNING_CFLAGS!': ['>@(clang_warning_flags_unset)'],
      },
      'msvs_settings': {
        'VCCLCompilerTool': {
          'AdditionalOptions': [ '>@(clang_warning_flags)' ],
          'AdditionalOptions!': [ '>@(clang_warning_flags_unset)' ],
        },
      },
    }],
    ['clang==0 and host_clang==1', {
      'target_conditions': [
        ['_toolset=="host"', {
          'cflags': [ '>@(clang_warning_flags)' ],
          'cflags!': [ '>@(clang_warning_flags_unset)' ],
        }],
      ],
    }],
  ],
}
