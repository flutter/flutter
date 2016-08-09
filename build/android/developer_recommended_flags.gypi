# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This is the set of recommended gyp variable settings for Chrome for Android development.
#
# These can be used by copying this file to $CHROME_SRC/chrome/supplement.gypi.
#
# Even better, create chrome/supplement.gypi containing the following:
#   {
#     'includes': [ '../build/android/developer_recommended_flags.gypi' ]
#   }
# and you'll get new settings automatically.
# When using this method, you can override individual settings by setting them unconditionally (with
# no %) in chrome/supplement.gypi.
# I.e. to disable gyp_managed_install but use everything else:
#   {
#     'variables': {
#       'gyp_managed_install': 0,
#     },
#     'includes': [ '../build/android/developer_recommended_flags.gypi' ]
#   }

{
  'variables': {
    'variables': {
      # Set component to 'shared_library' to enable the component build. This builds native code as
      # many small shared libraries instead of one monolithic library. This slightly reduces the time
      # required for incremental builds.
      'component%': 'shared_library',
    },
    'component%': '<(component)',

    # When gyp_managed_install is set to 1, building an APK will install that APK on the connected
    # device(/emulator). To install on multiple devices (or onto a new device), build the APK once
    # with each device attached. This greatly reduces the time required for incremental builds.
    #
    # This comes with some caveats:
    #   Only works with a single device connected (it will print a warning if
    #     zero or multiple devices are attached).
    #   Device must be flashed with a user-debug unsigned Android build.
    #   Some actions are always run (i.e. ninja will never say "no work to do").
    'gyp_managed_install%': 1,

    # With gyp_managed_install, we do not necessarily need a standalone APK.
    # When create_standalone_apk is set to 1, we will build a standalone APK
    # anyway. For even faster builds, you can set create_standalone_apk to 0.
    'create_standalone_apk%': 1,

    # Set clang to 1 to use the clang compiler. Clang has much (much, much) better warning/error
    # messages than gcc.
    # TODO(cjhopman): Enable this when http://crbug.com/156420 is addressed. Until then, users can
    # set clang to 1, but Android stack traces will sometimes be incomplete.
    #'clang%': 1,

    # Set fastbuild to 1 to build with less debugging information. This can greatly decrease linking
    # time. The downside is that stack traces will be missing useful information (like line
    # numbers).
    #'fastbuild%': 1,
  },
}
