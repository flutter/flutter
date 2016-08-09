# Copyright (c) 2009 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'gmock',
      'type': 'static_library',
      'dependencies': [
        'gtest.gyp:gtest',
      ],
      'sources': [
        # Sources based on files in r173 of gmock.
        'gmock/include/gmock/gmock-actions.h',
        'gmock/include/gmock/gmock-cardinalities.h',
        'gmock/include/gmock/gmock-generated-actions.h',
        'gmock/include/gmock/gmock-generated-function-mockers.h',
        'gmock/include/gmock/gmock-generated-matchers.h',
        'gmock/include/gmock/gmock-generated-nice-strict.h',
        'gmock/include/gmock/gmock-matchers.h',
        'gmock/include/gmock/gmock-spec-builders.h',
        'gmock/include/gmock/gmock.h',
        'gmock/include/gmock/internal/gmock-generated-internal-utils.h',
        'gmock/include/gmock/internal/gmock-internal-utils.h',
        'gmock/include/gmock/internal/gmock-port.h',
        'gmock/src/gmock-all.cc',
        'gmock/src/gmock-cardinalities.cc',
        'gmock/src/gmock-internal-utils.cc',
        'gmock/src/gmock-matchers.cc',
        'gmock/src/gmock-spec-builders.cc',
        'gmock/src/gmock.cc',
        'gmock_mutant.h',  # gMock helpers
      ],
      'sources!': [
        'gmock/src/gmock-all.cc',  # Not needed by our build.
      ],
      'include_dirs': [
        'gmock',
        'gmock/include',
      ],
      'direct_dependent_settings': {
        'include_dirs': [
          'gmock/include',  # So that gmock headers can find themselves.
        ],
      },
      'export_dependent_settings': [
        'gtest.gyp:gtest',
      ],
      'conditions': [
        ['OS == "ios"', {
          'toolsets': ['host', 'target'],
        }],
      ],
    },
    {
      'target_name': 'gmock_main',
      'type': 'static_library',
      'dependencies': [
        'gmock',
      ],
      'sources': [
        'gmock/src/gmock_main.cc',
      ],
    },
  ],
}
