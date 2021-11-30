// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

final Float32List identityTransform = Matrix4.identity().storage;
final Float32List xTranslation = (Matrix4.identity()..translate(10)).storage;
final Float32List yTranslation = (Matrix4.identity()..translate(0, 10)).storage;
final Float32List zTranslation = (Matrix4.identity()..translate(0, 0, 10)).storage;
final Float32List scaleAndTranslate2d = (Matrix4.identity()..scale(2, 3, 1)..translate(4, 5, 0)).storage;
final Float32List rotation2d = (Matrix4.identity()..rotateZ(0.2)).storage;

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  test('transformKindOf and isIdentityFloat32ListTransform identify matrix kind', () {
    expect(transformKindOf(identityTransform), TransformKind.identity);
    expect(isIdentityFloat32ListTransform(identityTransform), isTrue);

    expect(transformKindOf(zTranslation), TransformKind.complex);
    expect(isIdentityFloat32ListTransform(zTranslation), isFalse);

    expect(transformKindOf(xTranslation), TransformKind.transform2d);
    expect(isIdentityFloat32ListTransform(xTranslation), isFalse);

    expect(transformKindOf(yTranslation), TransformKind.transform2d);
    expect(isIdentityFloat32ListTransform(yTranslation), isFalse);

    expect(transformKindOf(scaleAndTranslate2d), TransformKind.transform2d);
    expect(isIdentityFloat32ListTransform(scaleAndTranslate2d), isFalse);

    expect(transformKindOf(rotation2d), TransformKind.transform2d);
    expect(isIdentityFloat32ListTransform(rotation2d), isFalse);
  });

  test('canonicalizes font families correctly on iOS', () {
    debugOperatingSystemOverride = OperatingSystem.iOs;

    expect(
      canonicalizeFontFamily('sans-serif'),
      'sans-serif',
    );
    expect(
      canonicalizeFontFamily('foo'),
      '"foo", -apple-system, BlinkMacSystemFont, sans-serif',
    );
    expect(
      canonicalizeFontFamily('.SF Pro Text'),
      '-apple-system, BlinkMacSystemFont',
    );

    debugOperatingSystemOverride = null;
  });

  test('does not use -apple-system on iOS 15', () {
    debugOperatingSystemOverride = OperatingSystem.iOs;
    debugIsIOS15 = true;

    expect(
      canonicalizeFontFamily('sans-serif'),
      'sans-serif',
    );
    expect(
      canonicalizeFontFamily('foo'),
      '"foo", BlinkMacSystemFont, sans-serif',
    );
    expect(
      canonicalizeFontFamily('.SF Pro Text'),
      'BlinkMacSystemFont',
    );

    debugOperatingSystemOverride = null;
    debugIsIOS15 = null;
  });

  test('parseFloat basic tests', () {
    // Simple integers and doubles.
    expect(parseFloat('108'), 108.0);
    expect(parseFloat('.34'), 0.34);
    expect(parseFloat('108.34'), 108.34);

    // Number followed by text.
    expect(parseFloat('108.34px'), 108.34);
    expect(parseFloat('108.34px29'), 108.34);
    expect(parseFloat('108.34px 29'), 108.34);

    // Number followed by space and text.
    expect(parseFloat('108.34 px29'), 108.34);
    expect(parseFloat('108.34 px 29'), 108.34);

    // Invalid numbers.
    expect(parseFloat('text'), isNull);
    expect(parseFloat('text108'), isNull);
    expect(parseFloat('text 108'), isNull);
    expect(parseFloat('another text 108'), isNull);
  });

  test('can set style properties on elements', () {
    final html.Element element = html.document.createElement('div');
    setElementStyle(element, 'color', 'red');
    expect(element.style.color, 'red');
  });

  test('can remove style properties from elements', () {
    final html.Element element = html.document.createElement('div');
    setElementStyle(element, 'color', 'blue');
    expect(element.style.color, 'blue');
    setElementStyle(element, 'color', null);
    expect(element.style.color, '');
  });
}
