// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library uri.spec_tests;

import 'dart:convert' show json;
import 'dart:io';

import 'package:test/test.dart';
import 'package:uri/uri.dart';

void runSpecTests(String testname, {String? solo}) {
  final testFile = File('test/uritemplate-test/$testname.json');
  final testJson = json.decode(testFile.readAsStringSync());

  for (var specGroup in testJson.keys) {
    group(specGroup, () {
      final data = testJson[specGroup];
      final variables = data['variables'] as Map<String, Object?>;
      final testCases = data['testcases'] as List;

      for (var testCase in testCases.cast<List>()) {
        final templateString = testCase[0] as String;
        if (solo != null && templateString == solo) continue;
        test(templateString, () {
          final expectation = testCase[1];
          if (expectation == false) {
            expect(
              () {
                UriTemplate(templateString).expand(variables);
              },
              throwsA(isA<ParseException>()),
              reason: templateString,
            );
          } else {
            final template = UriTemplate(templateString);
            final r = template.expand(variables);
            if (expectation is List) {
              expect(r, isIn(expectation), reason: templateString);
            } else {
              expect(
                r,
                expectation,
                reason: 'template: $templateString variables: $variables',
              );
            }
          }
        });
      }
    });
  }
}

void main() {
  if (!File('test/uritemplate-test/spec-examples.json').existsSync()) {
    throw StateError(
      'spec examples not found. Make sure you run tests from the project'
      ' directory, or try running `git submodule update`.',
    );
  }

  runSpecTests('spec-examples');
  runSpecTests('spec-examples-by-section');
  runSpecTests('extended-tests');
  runSpecTests('negative-tests');
}
