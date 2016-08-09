# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    # Check for presence of harfbuzz-icu library, use it if present.
    'harfbuzz_libraries':
        '<!(python <(DEPTH)/tools/compile_test/compile_test.py '
        '--code "int main() { return 0; }" '
        '--run-linker '
        '--on-success "harfbuzz harfbuzz-icu" '
        '--on-failure "harfbuzz" '
        '-- -lharfbuzz-icu)',
  },
  'targets': [
    {
      'target_name': 'harfbuzz-ng',
      'type': 'none',
      'cflags': [
        '<!@(pkg-config --cflags <(harfbuzz_libraries))',
      ],
      'direct_dependent_settings': {
        'cflags': [
          '<!@(pkg-config --cflags <(harfbuzz_libraries))',
        ],
      },
      'link_settings': {
        'ldflags': [
          '<!@(pkg-config --libs-only-L --libs-only-other <(harfbuzz_libraries))',
        ],
        'libraries': [
          '<!@(pkg-config --libs-only-l <(harfbuzz_libraries))',
        ],
      },
      'variables': {
        'headers_root_path': 'src',
        'header_filenames': [
          'hb.h',
        ],
      },
      'includes': [
        '../../build/shim_headers.gypi',
      ],
    },
  ],
}
