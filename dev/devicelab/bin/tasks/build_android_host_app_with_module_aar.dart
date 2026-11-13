// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/tasks/build_android_host_app_with_module_aar.dart';
import 'package:pub_semver/pub_semver.dart';

/// Runs the module AAR test with the Gradle/AGP versions that work on CI's
/// default JDK.
///
/// Older Gradle/AGP versions that cannot run on the default JDK are covered by
/// `android_java17_build_android_host_app_with_module_aar.dart`.
Future<void> main() async {
  await task(
    buildAndroidHostAppWithModuleAarTest(
      gradleVersion: '9.5.0',
      agpVersion: Version.parse('9.3.1'),
    ),
  );
}
