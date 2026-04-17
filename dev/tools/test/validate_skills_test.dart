// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:dart_skills_lint/dart_skills_lint.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  test('Validate Flutter Skills', () async {
    final Level oldLevel = Logger.root.level;
    Logger.root.level = Level.ALL;
    final StreamSubscription<LogRecord> subscription = Logger.root.onRecord.listen((record) {
      print(record.message);
    });

    try {
      final bool isValid = await validateSkills(
        skillDirPaths: ['../../.agents/skills'],
        resolvedRules: {
          'check-relative-paths': AnalysisSeverity.error,
          'check-absolute-paths': AnalysisSeverity.error,
          'check-trailing-whitespace': AnalysisSeverity.error,
        },
      );
      expect(isValid, isTrue, reason: 'Skills validation failed. See above for details.');
    } finally {
      Logger.root.level = oldLevel;
      await subscription.cancel();
    }
  });
}
