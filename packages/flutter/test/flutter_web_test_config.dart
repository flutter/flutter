// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'flutter_test_config.dart';

/// A custom host configuration for browser tests that supports flaky golden
/// checks.
///
/// See also [processBrowserCommand].
Future<void> startWebTestHostConfiguration(String testUri) async {
  testExecutable(() async {
    final Stream<dynamic> commands = stdin
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .map<dynamic>(jsonDecode);
    await for (final dynamic command in commands) {
      await processBrowserCommand(command);
    }
  });
}
