// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'package:flutter_test/flutter_test.dart';
import 'package:regular_integration_tests/treeshaking_main.dart' as app;
import 'package:flutter/material.dart';

import 'package:e2e/e2e.dart';

void main() {
  E2EWidgetsFlutterBinding.ensureInitialized() as E2EWidgetsFlutterBinding;

  testWidgets('debug+Fill+Properties for widgets is tree shaken',
          (WidgetTester tester) async {
    // About 11 instances are used by DiagnosticsNode and diagnostics
    // for flutter framework itself. Widgets have > 100. So we check for 20 to
    // so this test fails when tree-shaking is broken.
    await testOccurenceCountBelow(tester, '${debugPrefix}FillProperties', 20);
  });
}

// Used to prevent compiler optimization that will generate const string.
// Preventing counting test strings.
String get debugPrefix => <String>['d','e','b','u','g'].join('');

Future<void> testOccurenceCountBelow(WidgetTester tester, String methodName, int count) async {
  app.main();
  await tester.pumpAndSettle();

  // Make sure app loaded.
  final Finder finder = find.byKey(const Key('mainapp'));
  expect(finder, findsOneWidget);

  await _loadBundleAndCheck(methodName, count);
}

String fileContents;

Future<void> _loadBundleAndCheck(String methodName, int count) async {
  fileContents ??= await html.HttpRequest.getString('main.dart.js');
  expect(fileContents, contains('RenderObjectToWidgetElement'));
  expect(occurrenceCount(fileContents, methodName), lessThan(count));
}

int occurrenceCount(String contents, String word) {
  int count = 0;
  final int wordLength = word.length;
  int pos = contents.indexOf(word);
  final int contentLength = contents.length;
  while (pos != -1) {
    ++count;
    pos += wordLength;
    if (pos >= contentLength || count > 100) {
      break;
    }
    pos = contents.indexOf(word, pos);
  }
  return count;
}
