# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
   'targets': [
      {
         'target_name': 'findbugs_plugin_test',
         'type': 'none',
         'variables': {
           'java_in_dir': 'test/java/',
            'run_findbugs': 0,
         },
         'includes': [ '../../../build/java.gypi' ],
      }
   ]
}
