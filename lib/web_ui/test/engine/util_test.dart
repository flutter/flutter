// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/src/engine.dart';

import 'package:test/test.dart';

final Float64List identityTransform = Matrix4.identity().storage;
final Float64List xTranslation = (Matrix4.identity()..translate(10)).storage;
final Float64List yTranslation = (Matrix4.identity()..translate(0, 10)).storage;
final Float64List zTranslation = (Matrix4.identity()..translate(0, 0, 10)).storage;

void main() {
  test('transformKindOf and isIdentityFloat64ListTransform identify matrix kind', () {
    expect(transformKindOf(identityTransform), TransformKind.identity);
    expect(isIdentityFloat64ListTransform(identityTransform), isTrue);

    expect(transformKindOf(xTranslation), TransformKind.translation2d);
    expect(isIdentityFloat64ListTransform(xTranslation), isFalse);

    expect(transformKindOf(yTranslation), TransformKind.translation2d);
    expect(isIdentityFloat64ListTransform(yTranslation), isFalse);

    expect(transformKindOf(zTranslation), TransformKind.complex);
    expect(isIdentityFloat64ListTransform(zTranslation), isFalse);
  });
}
