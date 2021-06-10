// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/web_experiments.dart';

const bool _defaultUseCanvasText = true;
const bool _defaultUseCanvasRichText = true;

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

  test('default web experiment values', () {
    expect(WebExperiments.instance!.useCanvasText, _defaultUseCanvasText);
    expect(WebExperiments.instance!.useCanvasRichText, _defaultUseCanvasRichText);
  });

  test('can turn on/off web experiments', () {
    WebExperiments.instance!.updateExperiment('useCanvasText', true);
    WebExperiments.instance!.updateExperiment('useCanvasRichText', true);
    expect(WebExperiments.instance!.useCanvasText, isTrue);
    expect(WebExperiments.instance!.useCanvasRichText, isTrue);

    WebExperiments.instance!.updateExperiment('useCanvasText', false);
    WebExperiments.instance!.updateExperiment('useCanvasRichText', false);
    expect(WebExperiments.instance!.useCanvasText, isFalse);
    expect(WebExperiments.instance!.useCanvasRichText, isFalse);

    WebExperiments.instance!.updateExperiment('useCanvasText', null);
    WebExperiments.instance!.updateExperiment('useCanvasRichText', null);
    // Goes back to default value.
    expect(WebExperiments.instance!.useCanvasText, _defaultUseCanvasText);
    expect(WebExperiments.instance!.useCanvasRichText, _defaultUseCanvasRichText);
  });

  test('ignores unknown experiments', () {
    expect(WebExperiments.instance!.useCanvasText, _defaultUseCanvasText);
    expect(WebExperiments.instance!.useCanvasRichText, _defaultUseCanvasRichText);
    WebExperiments.instance!.updateExperiment('foobarbazqux', true);
    expect(WebExperiments.instance!.useCanvasText, _defaultUseCanvasText);
    expect(WebExperiments.instance!.useCanvasRichText, _defaultUseCanvasRichText);
    WebExperiments.instance!.updateExperiment('foobarbazqux', false);
    expect(WebExperiments.instance!.useCanvasText, _defaultUseCanvasText);
    expect(WebExperiments.instance!.useCanvasRichText, _defaultUseCanvasRichText);
  });

  test('can reset web experiments', () {
    WebExperiments.instance!.updateExperiment('useCanvasText', false);
    WebExperiments.instance!.updateExperiment('useCanvasRichText', false);
    WebExperiments.instance!.reset();
    expect(WebExperiments.instance!.useCanvasText, _defaultUseCanvasText);
    expect(WebExperiments.instance!.useCanvasRichText, _defaultUseCanvasRichText);

    WebExperiments.instance!.updateExperiment('useCanvasText', false);
    WebExperiments.instance!.updateExperiment('useCanvasRichText', false);
    WebExperiments.instance!.updateExperiment('foobarbazqux', true);
    WebExperiments.instance!.reset();
    expect(WebExperiments.instance!.useCanvasText, _defaultUseCanvasText);
    expect(WebExperiments.instance!.useCanvasRichText, _defaultUseCanvasRichText);
  });

  test('js interop also works', () {
    expect(WebExperiments.instance!.useCanvasText, _defaultUseCanvasText);
    expect(WebExperiments.instance!.useCanvasRichText, _defaultUseCanvasRichText);

    expect(() => jsUpdateExperiment('useCanvasText', true), returnsNormally);
    expect(() => jsUpdateExperiment('useCanvasRichText', true), returnsNormally);
    expect(WebExperiments.instance!.useCanvasText, isTrue);
    expect(WebExperiments.instance!.useCanvasRichText, isTrue);

    expect(() => jsUpdateExperiment('useCanvasText', null), returnsNormally);
    expect(() => jsUpdateExperiment('useCanvasRichText', null), returnsNormally);
    expect(WebExperiments.instance!.useCanvasText, _defaultUseCanvasText);
    expect(WebExperiments.instance!.useCanvasRichText, _defaultUseCanvasRichText);
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
