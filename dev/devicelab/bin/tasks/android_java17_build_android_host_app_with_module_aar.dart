// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/tasks/build_android_host_app_with_module_aar.dart';
import 'package:pub_semver/pub_semver.dart';

/// Runs the module AAR test with older Gradle/AGP versions.
///
/// Gradle 8.4 cannot run on newer JDKs (Java 25 requires Gradle 9.1.0+, see
/// https://docs.gradle.org/current/userguide/compatibility.html), so this task
/// runs on a CI target pinned to Java 17 to keep coverage of pre-AGP 8.3
/// projects.
Future<void> main() async {
  await task(
    buildAndroidHostAppWithModuleAarTest(gradleVersion: '8.4', agpVersion: Version.parse('8.2.1')),
  );
}
