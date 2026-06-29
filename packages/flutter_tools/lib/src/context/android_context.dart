// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../android/android_sdk.dart';
import '../android/android_studio.dart';
import '../android/android_workflow.dart';
import '../android/gradle_utils.dart';
import '../android/java.dart';

/// Holds Android-specific dependencies.
class AndroidContext {
  AndroidContext({
    required this.androidSdk,
    required this.androidStudio,
    required this.androidWorkflow,
    required this.gradleUtils,
    required this.java,
  });

  final AndroidSdk? androidSdk;
  final AndroidStudio? androidStudio;
  final GradleUtils gradleUtils;
  final AndroidWorkflow? androidWorkflow;
  final Java? java;
}
