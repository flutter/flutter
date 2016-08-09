# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'libwebp',
      'type': 'none',
      'direct_dependent_settings': {
        'defines': [
          'ENABLE_WEBP',
        ],
      },
      'link_settings': {
        'libraries': [
          # Check for presence of webpdemux library, use it if present.
          '<!(python <(DEPTH)/tools/compile_test/compile_test.py '
          '--code "int main() { return 0; }" '
          '--run-linker '
          '--on-success "-lwebp -lwebpdemux" '
          '--on-failure "-lwebp" '
          '-- -lwebpdemux)',
        ],
      },
    }
  ],
}
