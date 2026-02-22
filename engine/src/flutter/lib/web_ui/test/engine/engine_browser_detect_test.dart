// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/browser_detection.dart';
import 'package:ui/src/engine/safe_browser_api.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('browserSupportsCanvasKitChromium', () {
    JSAny? oldV8BreakIterator = v8BreakIterator;
    JSAny? oldIntlSegmenter = intlSegmenter;

    setUp(() {
      oldV8BreakIterator = v8BreakIterator;
      oldIntlSegmenter = intlSegmenter;
    });
    tearDown(() {
      v8BreakIterator = oldV8BreakIterator;
      intlSegmenter = oldIntlSegmenter;
      debugResetBrowserSupportsImageDecoder();
    });

    test('Detect browsers that support CanvasKit Chromium', () {
      v8BreakIterator = Object().toJSBox; // Any non-null value.
      intlSegmenter = Object().toJSBox; // Any non-null value.
      browserSupportsImageDecoder = true;

      expect(browserSupportsCanvaskitChromium, isTrue);
    });

    test('Detect browsers that do not support image codecs', () {
      v8BreakIterator = Object().toJSBox; // Any non-null value.
      intlSegmenter = Object().toJSBox; // Any non-null value.
      browserSupportsImageDecoder = false;

      // TODO(mdebbar): we don't check image codecs for now.
      // https://github.com/flutter/flutter/issues/122331
      expect(browserSupportsCanvaskitChromium, isTrue);
    });

    test('Detect browsers that do not support v8BreakIterator', () {
      v8BreakIterator = null;
      intlSegmenter = Object().toJSBox; // Any non-null value.
      browserSupportsImageDecoder = true;

      expect(browserSupportsCanvaskitChromium, isFalse);
    });

    test('Detect browsers that support neither', () {
      v8BreakIterator = null;
      intlSegmenter = Object().toJSBox; // Any non-null value.
      browserSupportsImageDecoder = false;

      expect(browserSupportsCanvaskitChromium, isFalse);
    });

    test('Detect browsers that support v8BreakIterator but no Intl.Segmenter', () {
      v8BreakIterator = Object().toJSBox; // Any non-null value.
      intlSegmenter = null;

      expect(browserSupportsCanvaskitChromium, isFalse);
    });
  });

  group('browserMayOverrideAntialiasHint', () {
    tearDown(() {
      debugBrowserMayOverrideAntialiasHint = null;
    });

    // Regression test for https://github.com/flutter/flutter/issues/182722
    test('can be overridden for testing', () {
      debugBrowserMayOverrideAntialiasHint = true;
      expect(browserMayOverrideAntialiasHint, isTrue);

      debugBrowserMayOverrideAntialiasHint = false;
      expect(browserMayOverrideAntialiasHint, isFalse);
    });

    test('defaults to browser detection when debug override is null', () {
      debugBrowserMayOverrideAntialiasHint = null;
      // The actual value depends on the browser running the test.
      // On Firefox, it should be true; on other browsers, false.
      expect(browserMayOverrideAntialiasHint, equals(isFirefox));
    });
  });
}

@JS('window.Intl.v8BreakIterator')
external JSAny? get v8BreakIterator;

@JS('window.Intl.v8BreakIterator')
external set v8BreakIterator(JSAny? x);

@JS('window.Intl.Segmenter')
external JSAny? get intlSegmenter;

@JS('window.Intl.Segmenter')
external set intlSegmenter(JSAny? x);
