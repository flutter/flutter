# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is a helper to java_apk.gypi. It should be used to create an
# action that runs ApkBuilder via ANT.
#
# Required variables:
#  apk_name - File name (minus path & extension) of the output apk.
#  android_manifest_path - Path to AndroidManifest.xml.
#  app_manifest_version_name - set the apps 'human readable' version number.
#  app_manifest_version_code - set the apps version number.
# Optional variables:
#  asset_location - The directory where assets are located (if any).
#  create_density_splits - Whether to create density-based apk splits. Splits
#    are supported only for minSdkVersion >= 21.
#  language_splits - List of languages to create apk splits for.
#  resource_zips - List of paths to resource zip files.
#  shared_resources - Make a resource package that can be loaded by a different
#    application at runtime to access the package's resources.
#  extensions_to_not_compress - E.g.: 'pak,dat,bin'
#  extra_inputs - List of extra action inputs.
{
  'variables': {
    'asset_location%': '',
    'create_density_splits%': 0,
    'resource_zips%': [],
    'shared_resources%': 0,
    'extensions_to_not_compress%': '',
    'extra_inputs%': [],
    'resource_packaged_apk_name': '<(apk_name)-resources.ap_',
    'resource_packaged_apk_path': '<(intermediate_dir)/<(resource_packaged_apk_name)',
  },
  'action_name': 'package_resources_<(apk_name)',
  'message': 'packaging resources for <(apk_name)',
  'inputs': [
    # TODO: This isn't always rerun correctly, http://crbug.com/351928
    '<(DEPTH)/build/android/gyp/util/build_utils.py',
    '<(DEPTH)/build/android/gyp/package_resources.py',
    '<(android_manifest_path)',
    '<@(extra_inputs)',
  ],
  'outputs': [
    '<(resource_packaged_apk_path)',
  ],
  'action': [
    'python', '<(DEPTH)/build/android/gyp/package_resources.py',
    '--android-sdk', '<(android_sdk)',
    '--aapt-path', '<(android_aapt_path)',
    '--configuration-name', '<(CONFIGURATION_NAME)',
    '--android-manifest', '<(android_manifest_path)',
    '--version-code', '<(app_manifest_version_code)',
    '--version-name', '<(app_manifest_version_name)',
    '--no-compress', '<(extensions_to_not_compress)',
    '--apk-path', '<(resource_packaged_apk_path)',
  ],
  'conditions': [
    ['shared_resources == 1', {
      'action': [
        '--shared-resources',
      ],
    }],
    ['asset_location != ""', {
      'action': [
        '--asset-dir', '<(asset_location)',
      ],
    }],
    ['create_density_splits == 1', {
      'action': [
        '--create-density-splits',
      ],
      'outputs': [
        '<(resource_packaged_apk_path)_hdpi',
        '<(resource_packaged_apk_path)_xhdpi',
        '<(resource_packaged_apk_path)_xxhdpi',
        '<(resource_packaged_apk_path)_xxxhdpi',
        '<(resource_packaged_apk_path)_tvdpi',
      ],
    }],
    ['language_splits != []', {
      'action': [
        '--language-splits=<(language_splits)',
      ],
      'outputs': [
        "<!@(python <(DEPTH)/build/apply_locales.py '<(resource_packaged_apk_path)_ZZLOCALE' <(language_splits))",
      ],
    }],
    ['resource_zips != []', {
      'action': [
        '--resource-zips', '>(resource_zips)',
      ],
      'inputs': [
        '>@(resource_zips)',
      ],
    }],
  ],
}
