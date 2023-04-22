// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/project.dart';

class ThrowingPub implements Pub {
  @override
  Future<void> batch(final List<String> arguments, {
    final PubContext? context,
    final String? directory,
    final MessageFilter? filter,
    final String? failureMessage = 'pub failed',
  }) {
    throw UnsupportedError('Attempted to invoke pub during test.');
  }

  @override
  Future<void> get({
    final PubContext? context,
    required final FlutterProject project,
    final bool upgrade = false,
    final bool offline = false,
    final bool checkLastModified = true,
    final bool skipPubspecYamlCheck = false,
    final bool generateSyntheticPackage = false,
    final bool generateSyntheticPackageForExample = false,
    final String? flutterRootOverride,
    final bool checkUpToDate = false,
    final bool shouldSkipThirdPartyGenerator = true,
    final PubOutputMode outputMode = PubOutputMode.all,
  }) {
    throw UnsupportedError('Attempted to invoke pub during test.');
  }

  @override
  Future<void> interactively(
    final List<String> arguments, {
    final FlutterProject? project,
    required final PubContext context,
    required final String command,
    final bool touchesPackageConfig = false,
    final bool generateSyntheticPackage = false,
    final PubOutputMode outputMode = PubOutputMode.all,
  }) {
    throw UnsupportedError('Attempted to invoke pub during test.');
  }
}
