// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This constant is in its own library so that the test exemption bot knows
// that changing a pin does not require a new test. These pins are already
// tested as part of the analysis shard.

/// Map from package name to package version, used to artificially pin a pub
/// package version in cases when upgrading to the latest breaks Flutter.
///
/// These version pins must be pins, not ranges! Allowing these to be ranges
/// defeats the whole purpose of pinning all our dependencies, which is to
/// prevent upstream changes from causing our CI to fail randomly in ways
/// unrelated to the commits. It also, more importantly, risks breaking users
/// in ways that prevent them from ever upgrading Flutter again!
const Map<String, String> kManuallyPinnedDependencies = <String, String>{
  // Add pinned packages here. Please leave a comment explaining why.
  'flutter_gallery_assets': '1.0.2', // Tests depend on the exact version.
  'flutter_template_images': '4.2.0', // Must always exactly match flutter_tools template.
  'material_color_utilities': '0.8.0', // Keep pinned to latest until 1.0.0.
  'archive': '3.3.2', // https://github.com/flutter/flutter/issues/115660
  'leak_tracker': '10.0.4', // https://github.com/flutter/devtools/issues/3951
  'leak_tracker_testing': '3.0.1', // https://github.com/flutter/devtools/issues/3951
  'leak_tracker_flutter_testing': '3.0.4', // https://github.com/flutter/devtools/issues/3951
  'path_provider_android':
      '2.2.1', // https://github.com/flutter/flutter/issues/140796
};
