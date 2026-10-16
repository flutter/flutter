// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:meta/meta.dart';

import 'capture.dart';

/// Standalone `flutter screenshot` command, kept for backward compatibility.
///
/// Delegates to [CaptureScreenshotCommand].
class ScreenshotCommand extends CaptureScreenshotCommand {
  ScreenshotCommand({required super.toolContext, super.vmServiceConnector});

  @override
  String get name => 'screenshot';

  @override
  String get description => 'Take a screenshot from a connected device.';

  @override
  bool get hidden => true;

  @override
  final List<String> aliases = const <String>['pic'];

  @visibleForTesting
  static void checkOutput(File outputFile, FileSystem fs) =>
      CaptureScreenshotCommand.checkOutput(outputFile, fs);
}
