# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file contains settings for ../chrome/chrome.gyp that other gyp files
# also use.
{
  'variables': {
    # TODO: remove this helper when we have loops in GYP
    'apply_locales_cmd': ['python', '<(DEPTH)/build/apply_locales.py'],

    'conditions': [
      ['OS=="mac"', {
        'conditions': [
          ['branding=="Chrome"', {
            'mac_bundle_id': 'com.google.Chrome',
            'mac_creator': 'rimZ',
            # The policy .grd file also needs the bundle id.
            'grit_defines': ['-D', 'mac_bundle_id=com.google.Chrome'],
          }, {  # else: branding!="Chrome"
            'mac_bundle_id': 'org.chromium.Chromium',
            'mac_creator': 'Cr24',
            # The policy .grd file also needs the bundle id.
            'grit_defines': ['-D', 'mac_bundle_id=org.chromium.Chromium'],
          }],  # branding
        ],  # conditions
      }],  # OS=="mac"
    ],  # conditions
  },  # variables
}
