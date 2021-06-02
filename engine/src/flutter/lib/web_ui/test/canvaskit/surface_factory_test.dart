// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import '../matchers.dart';
import 'common.dart';

const MethodCodec codec = StandardMethodCodec();

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('$SurfaceFactory', () {
    setUpCanvasKitTest();

    test('cannot be created with size less than 2', () {
      expect(() => SurfaceFactory(-1), throwsAssertionError);
      expect(() => SurfaceFactory(0), throwsAssertionError);
      expect(() => SurfaceFactory(1), throwsAssertionError);
      expect(SurfaceFactory(2), isNotNull);
    });

    test('getSurface', () {
      final SurfaceFactory factory = SurfaceFactory(3);
      expect(factory.baseSurface, isNotNull);
      expect(factory.backupSurface, isNotNull);
      expect(factory.baseSurface, isNot(equals(factory.backupSurface)));

      expect(factory.debugSurfaceCount, equals(2));

      // Get a surface from the factory, it should be unique.
      final Surface newSurface = factory.getSurface();
      expect(newSurface, isNot(equals(factory.baseSurface)));
      expect(newSurface, isNot(equals(factory.backupSurface)));

      expect(factory.debugSurfaceCount, equals(3));

      // Get another surface from the factory. Now we are at maximum capacity,
      // so it should return the backup surface.
      final Surface anotherSurface = factory.getSurface();
      expect(anotherSurface, isNot(equals(factory.baseSurface)));
      expect(anotherSurface, equals(factory.backupSurface));

      expect(factory.debugSurfaceCount, equals(3));
    });

    test('releaseSurface', () {
      final SurfaceFactory factory = SurfaceFactory(3);

      // Create a new surface and immediately release it.
      final Surface surface = factory.getSurface();
      factory.releaseSurface(surface);

      // If we create a new surface, it should be the same as the one we
      // just created.
      final Surface newSurface = factory.getSurface();
      expect(newSurface, equals(surface));
    });

    test('isLive', () {
      final SurfaceFactory factory = SurfaceFactory(3);

      expect(factory.isLive(factory.baseSurface), isTrue);
      expect(factory.isLive(factory.backupSurface), isTrue);

      final Surface surface = factory.getSurface();
      expect(factory.isLive(surface), isTrue);

      factory.releaseSurface(surface);
      expect(factory.isLive(surface), isFalse);
    });

    // TODO: https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}
