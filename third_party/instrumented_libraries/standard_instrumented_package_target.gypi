# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into a target for instrumented dynamic
# packages and describes standard build action for most of the packages.

{
  'target_name': '<(_sanitizer_type)-<(_package_name)',
  'type': 'none',
  'actions': [
    {
      'action_name': '<(_package_name)',
      'inputs': [
        # TODO(earthdok): reintroduce some sort of dependency
        # See http://crbug.com/343515
        #'download_build_install.py',
      ],
      'outputs': [
        '<(PRODUCT_DIR)/instrumented_libraries/<(_sanitizer_type)/<(_package_name).txt',
      ],
      'action': ['scripts/download_build_install.py',
        '--build-method=>(_build_method)',
        '--cc=<(_cc)',
        '--cflags=>(_package_cflags)',
        '--cxx=<(_cxx)',
        '--extra-configure-flags=>(_extra_configure_flags)',
        '--intermediate-dir=<(INTERMEDIATE_DIR)',
        '--jobs=>(_jobs)',
        '--ldflags=>(_package_ldflags)',
        '--libdir=<(_libdir)',
        '--package=<(_package_name)',
        '--product-dir=<(PRODUCT_DIR)',
        '--sanitizer=<(_sanitizer_type)',
      ],
      'conditions': [
        ['verbose_libraries_build==1', {
          'action+': [
            '--verbose',
          ],
        }],
      ],
      'target_conditions': [
        ['">(_patch)"!=""', {
          'action+': [
            '--patch=>(_patch)',
          ],
          'inputs+': [
            '>(_patch)',
          ],
        }],
        ['">(_pre_build)"!=""', {
          'action+': [
            '--pre-build=>(_pre_build)',
          ],
          'inputs+': [
            '>(_pre_build)',
          ],
        }],
        ['">(_<(_sanitizer_type)_blacklist)"!=""', {
          'action+': [
            '--sanitizer-blacklist=>(_<(_sanitizer_type)_blacklist)',
          ],
          'inputs+': [
            '>(_<(_sanitizer_type)_blacklist)',
          ],
        }],
      ],
    },
  ],
}
