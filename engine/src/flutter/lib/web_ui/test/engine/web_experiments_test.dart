// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/web_experiments.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  setUp(() {
    WebExperiments.ensureInitialized();
  });

  tearDown(() {
    WebExperiments.instance!.reset();
  });

  test('js interop throws on wrong type', () {
    expect(() => jsUpdateExperiment(123, true), throwsA(anything));
    expect(() => jsUpdateExperiment('foo', 123), throwsA(anything));
    expect(() => jsUpdateExperiment('foo', 'bar'), throwsA(anything));
    expect(() => jsUpdateExperiment(false, 'foo'), throwsA(anything));
  });
}

void jsUpdateExperiment(dynamic name, dynamic enabled) {
  // ignore: implicit_dynamic_function
  js_util.callMethod(
    html.window,
    '_flutter_internal_update_experiment',
    <dynamic>[name, enabled],
  );
}
