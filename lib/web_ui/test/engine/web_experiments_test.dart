// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

void main() {
  setUp(() {
    WebExperiments.ensureInitialized();
  });

  tearDown(() {
    WebExperiments.instance.reset();
  });

  test('default web experiment values', () {
    expect(WebExperiments.instance.useCanvasText, false);
  });

  test('can turn on/off web experiments', () {
    WebExperiments.instance.updateExperiment('useCanvasText', true);
    expect(WebExperiments.instance.useCanvasText, true);

    WebExperiments.instance.updateExperiment('useCanvasText', false);
    expect(WebExperiments.instance.useCanvasText, false);

    WebExperiments.instance.updateExperiment('useCanvasText', null);
    // Goes back to default value.
    expect(WebExperiments.instance.useCanvasText, false);
  });

  test('ignores unknown experiments', () {
    expect(WebExperiments.instance.useCanvasText, false);
    WebExperiments.instance.updateExperiment('foobarbazqux', true);
    expect(WebExperiments.instance.useCanvasText, false);
    WebExperiments.instance.updateExperiment('foobarbazqux', false);
    expect(WebExperiments.instance.useCanvasText, false);
  });

  test('can reset web experiments', () {
    WebExperiments.instance.updateExperiment('useCanvasText', true);
    WebExperiments.instance.reset();
    expect(WebExperiments.instance.useCanvasText, false);

    WebExperiments.instance.updateExperiment('useCanvasText', true);
    WebExperiments.instance.updateExperiment('foobarbazqux', true);
    WebExperiments.instance.reset();
    expect(WebExperiments.instance.useCanvasText, false);
  });

  test('js interop also works', () {
    expect(WebExperiments.instance.useCanvasText, false);

    expect(() => jsUpdateExperiment('useCanvasText', true), returnsNormally);
    expect(WebExperiments.instance.useCanvasText, true);

    expect(() => jsUpdateExperiment('useCanvasText', null), returnsNormally);
    expect(WebExperiments.instance.useCanvasText, false);
  });

  test('js interop throws on wrong type', () {
    expect(() => jsUpdateExperiment(123, true), throwsA(anything));
    expect(() => jsUpdateExperiment('foo', 123), throwsA(anything));
    expect(() => jsUpdateExperiment('foo', 'bar'), throwsA(anything));
    expect(() => jsUpdateExperiment(false, 'foo'), throwsA(anything));
  });
}

void jsUpdateExperiment(dynamic name, dynamic enabled) {
  js_util.callMethod(
    html.window,
    '_flutter_internal_update_experiment',
    <dynamic>[name, enabled],
  );
}
