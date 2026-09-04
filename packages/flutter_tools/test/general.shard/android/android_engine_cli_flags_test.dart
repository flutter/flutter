// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:flutter_tools/src/android/android_engine_cli_flags.dart';

import '../../src/common.dart';

void main() {
  testWithoutContext(
    'AndroidEngineCliFlags.allFlags contains all defined static const String variables',
    () {
      final String flutterRoot = getFlutterRoot();
      final filePath = io.Platform.pathSeparator == r'\'
          ? '$flutterRoot\\packages\\flutter_tools\\lib\\src\\android\\android_engine_cli_flags.dart'
          : '$flutterRoot/packages/flutter_tools/lib/src/android/android_engine_cli_flags.dart';

      final file = io.File(filePath);
      final String content = file.readAsStringSync();

      final regex = RegExp(r"static const String (\w+) = '([^']+)';");
      final Iterable<Match> matches = regex.allMatches(content);

      final parsedFlags = <String>[];
      for (final match in matches) {
        final String constantName = match.group(1)!;
        final String flagName = match.group(2)!;

        // Exclude the aliases that are deliberately mapped from other flags
        if (constantName == 'enableHcppAndSurfaceControl' || constantName == 'verboseLogging') {
          continue;
        }
        parsedFlags.add(flagName);
      }

      expect(parsedFlags, isNotEmpty);

      for (final parsedFlag in parsedFlags) {
        expect(
          AndroidEngineCliFlags.allFlags,
          contains(parsedFlag),
          reason:
              'Flag "$parsedFlag" is defined in AndroidEngineCliFlags but not included in allFlags',
        );
      }

      // Also verify no extra flags were hardcoded.
      expect(
        AndroidEngineCliFlags.allFlags.length,
        parsedFlags.length,
        reason:
            'AndroidEngineCliFlags.allFlags contains a different number of items than the constants defined in the file',
      );
    },
  );
}
