# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'memconsumer',
      'type': 'none',
      'dependencies': [
        'memconsumer_apk',
      ],
    },
    {
      'target_name': 'memconsumer_apk',
      'type': 'none',
      'variables': {
        'apk_name': 'MemConsumer',
        'java_in_dir': 'java',
        'resource_dir': 'java/res',
        'native_lib_target': 'libmemconsumer',
      },
      'dependencies': [
        'libmemconsumer',
      ],
      'includes': [ '../../../build/java_apk.gypi' ],
    },
    {
      'target_name': 'libmemconsumer',
      'type': 'shared_library',
      'variables': {
        # This library uses native JNI exports; tell gyp so that the required
        # symbols will be kept.
        'use_native_jni_exports': 1,
      },
      'sources': [
        'memconsumer_hook.cc',
      ],
      'libraries': [
        '-llog',
      ],
    },
  ],
}
