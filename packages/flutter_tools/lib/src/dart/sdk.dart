// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import '../artifacts.dart';

/// Locate the Dart SDK.
String get dartSdkPath {
  return path.join(ArtifactStore.flutterRoot, 'bin', 'cache', 'dart-sdk');
}
