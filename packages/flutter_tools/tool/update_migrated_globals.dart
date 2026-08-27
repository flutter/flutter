// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

/// Convenience runner for `dev/flutter_analyzer_plugin/tool/update_migrated_files.dart`.
///
/// Updates the list of migrated `flutter_tools` files enforced by the
/// `no_globals_in_flutter_tools` analyzer plugin rule.
Future<void> main(List<String> args) async {
  final scriptFile = File(Platform.script.toFilePath());
  final String scriptDir = scriptFile.parent.path;
  final targetScript =
      '$scriptDir/../../../dev/flutter_analyzer_plugin/tool/update_migrated_files.dart';

  final Process process = await Process.start(Platform.resolvedExecutable, <String>[
    targetScript,
    ...args,
  ], mode: ProcessStartMode.inheritStdio);
  exitCode = await process.exitCode;
}
