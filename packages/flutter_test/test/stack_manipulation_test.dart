// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stack manipulation: reportExpectCall', () {
    try {
      expect(false, isTrue);
      throw 'unexpectedly did not throw';
    } catch (e, stack) {
      final FlutterErrorBuilder information = FlutterErrorBuilder();
      expect(reportExpectCallErrorBuilder(stack, information), 4);
      final TextRenderer renderer = TextRenderer();
      final List<String> lines = information.toDiagnostics().map((DiagnosticsNode node) => renderer.render(node).trimRight()).join('\n').split('\n');
      expect(lines[0], 'This was caught by the test expectation on the following line:');
      expect(lines[1], matches(r'^  .*stack_manipulation_test.dart line [0-9]+$'));
    }

    try {
      throw null;
    } catch (e, stack) {
      final FlutterErrorBuilder information = FlutterErrorBuilder();
      expect(reportExpectCallErrorBuilder(stack, information), 0);
      expect(information.toDiagnostics(), isEmpty);
    }
  });
}
