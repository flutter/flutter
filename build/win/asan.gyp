# Copyright (c) 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
   'targets': [
     {
       'target_name': 'asan_dynamic_runtime',
       'type': 'none',
       'variables': {
         # Every target is going to depend on asan_dynamic_runtime, so allow
         # this one to depend on itself.
         'prune_self_dependency': 1,
       },
       'conditions': [
         ['OS=="win"', {
           'copies': [
             {
               'destination': '<(PRODUCT_DIR)',
               'files': [
                 # Path is relative to this GYP file.
                 '<(DEPTH)/<(make_clang_dir)/lib/clang/<!(python <(DEPTH)/tools/clang/scripts/update.py --print-clang-version)/lib/windows/clang_rt.asan_dynamic-i386.dll',
               ],
             },
           ],
         }],
       ],
     },
   ],
}
