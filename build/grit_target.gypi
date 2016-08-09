# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into a target that will have one or more
# uses of grit_action.gypi. To use this the following variables need to be
# defined:
#   grit_out_dir: string: the output directory path

# DO NOT USE THIS FILE. Instead, use qualified includes.
# TODO: Convert everything to qualified includes, and delete this file,
# http://crbug.com/401588
{
  'conditions': [
    # If the target is a direct binary, it needs to be able to find the header,
    # otherwise it probably a supporting target just for grit so the include
    # dir needs to be set on anything that depends on this action.
    ['_type=="executable" or _type=="shared_library" or \
      _type=="loadable_module" or _type=="static_library"', {
      'include_dirs': [
        '<(grit_out_dir)',
      ],
    }, {
      'direct_dependent_settings': {
        'include_dirs': [
          '<(grit_out_dir)',
        ],
      },
    }],
  ],
}
