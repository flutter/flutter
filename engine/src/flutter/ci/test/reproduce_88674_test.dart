// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:engine_repo_tools/engine_repo_tools.dart';
import 'package:test/test.dart';

void main() {
  final io.Directory repoDir = Engine.findWithin().flutterDir;

  test('gen_javadoc.py contains io.flutter in packages list', () {
    final genJavadocFile = io.File('${repoDir.path}/tools/javadoc/gen_javadoc.py');
    expect(genJavadocFile.existsSync(), isTrue);

    final String content = genJavadocFile.readAsStringSync();
    // Verify that 'io.flutter' is in the packages list
    expect(content, contains("'io.flutter'"));
  });

  group('FlutterInjector Javadocs completeness', () {
    late io.File sourceFile;
    late List<String> lines;

    setUpAll(() {
      sourceFile = io.File(
        '${repoDir.path}/shell/platform/android/io/flutter/FlutterInjector.java',
      );
      expect(sourceFile.existsSync(), isTrue);
      lines = sourceFile.readAsLinesSync();
    });

    // List of public API signatures to verify
    final publicAPIs = <String>[
      'public final class FlutterInjector',
      'public static void setInstance(',
      'public static FlutterInjector instance(',
      'public FlutterLoader flutterLoader(',
      'public DeferredComponentManager deferredComponentManager(',
      'public ExecutorService executorService(',
      'public FlutterJNI.Factory getFlutterJNIFactory(',
      'public static final class Builder',
      'public Builder setFlutterLoader(',
      'public Builder setDeferredComponentManager(',
      'public Builder setFlutterJNIFactory(',
      'public Builder setExecutorService(',
      'public FlutterInjector build(',
    ];

    for (final api in publicAPIs) {
      test('API "$api" has Javadoc', () {
        final int index = lines.indexWhere((String line) {
          final String trimmed = line.trim();
          return !trimmed.startsWith('//') && !trimmed.startsWith('*') && trimmed.contains(api);
        });
        expect(index, isNot(-1), reason: 'Could not find API signature: $api');

        // Look backwards for a Javadoc block ending with '*/'
        int checkIndex = index - 1;
        var hasJavadoc = false;
        while (checkIndex >= 0) {
          final String trimmedLine = lines[checkIndex].trim();
          if (trimmedLine.isEmpty || trimmedLine.startsWith('@')) {
            // Skip empty lines and annotations
            checkIndex--;
            continue;
          }
          if (trimmedLine.endsWith('*/')) {
            hasJavadoc = true;
          }
          break;
        }

        expect(hasJavadoc, isTrue, reason: 'API "$api" at line ${index + 1} is missing Javadoc');
      });
    }
  });
}
