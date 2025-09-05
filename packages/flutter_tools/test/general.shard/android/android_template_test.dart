// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('Android settings.gradle.kts template', () {
    test('template includes Properties import', () {
      // Read the actual template file directly
      final File templateFile = File('packages/flutter_tools/templates/app/android.tmpl/settings.gradle.kts.tmpl');

      expect(templateFile.existsSync(), isTrue, reason: 'Template file should exist');

      final String content = templateFile.readAsStringSync();

      // Verify the template contains the expected import and usage
      expect(content, contains('import java.util.Properties'),
        reason: 'Template should include Properties import');
      expect(content, contains('val properties = Properties()'),
        reason: 'Template should use Properties correctly');
    });
  });
}
