// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/project.dart';

class ThrowingPub implements Pub {
  @override
  Future<void> batch(List<String> arguments, {
    PubContext? context,
    String? directory,
    MessageFilter? filter,
    String? failureMessage = 'pub failed',
  }) {
    throw UnsupportedError('Attempted to invoke pub during test.');
  }

  @override
  Future<void> get({
    PubContext? context,
    required FlutterProject project,
    bool skipIfAbsent = false,
    bool upgrade = false,
    bool offline = false,
    bool checkLastModified = true,
    bool skipPubspecYamlCheck = false,
    bool generateSyntheticPackage = false,
    bool generateSyntheticPackageForExample = false,
    String? flutterRootOverride,
    bool checkUpToDate = false,
    bool shouldSkipThirdPartyGenerator = true,
    bool printProgress = true,
  }) {
    throw UnsupportedError('Attempted to invoke pub during test.');
  }

  @override
  Future<void> interactively(
    List<String> arguments, {
    String? directory,
    required Stdio stdio,
    bool touchesPackageConfig = false,
    bool generateSyntheticPackage = false,
  }) {
    throw UnsupportedError('Attempted to invoke pub during test.');
  }
}
