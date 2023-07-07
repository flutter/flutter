// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/src/internal/pointer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('$Pointer', () {
    test('returns a path and components', () {
      expect(Pointer('foo/bar').path, 'foo/bar');
      expect(Pointer('foo/bar').components, ['foo', 'bar']);
    });

    test('returns a valid id', () {
      expect(Pointer('foo').id, 'foo');
      expect(Pointer('foo/bar').id, 'bar');
      expect(Pointer('foo/bar/baz').id, 'baz');
    });

    test('returns correct bool value with a collection path', () {
      expect(Pointer('foo').isCollection(), true);
      expect(Pointer('foo/bar').isCollection(), false);
      expect(Pointer('foo/bar/baz').isCollection(), true);
    });

    test('returns correct bool value with a document path', () {
      expect(Pointer('foo').isDocument(), false);
      expect(Pointer('foo/bar').isDocument(), true);
      expect(Pointer('foo/bar/baz').isDocument(), false);
    });

    test('collectionPath() fails if path is already a collection', () {
      expect(() => Pointer('foo').collectionPath('bar'), throwsAssertionError);
    });

    test('documentPath() fails if path is already a document', () {
      expect(
          () => Pointer('foo/bar').documentPath('bar'), throwsAssertionError);
    });

    test('collectionPath() returns a valid collection', () {
      var p = Pointer('foo/bar');
      expect(p.collectionPath('baz'), 'foo/bar/baz');
    });

    test('documentPath() returns a valid document', () {
      var p = Pointer('foo');
      expect(p.documentPath('bar'), 'foo/bar');
    });

    test('parentPath() reutrns null if there is no parent', () {
      expect(Pointer('foo').parentPath(), null);
    });

    test('parentPath() reutrns parent path correctly', () {
      expect(Pointer('foo/bar').parentPath(), 'foo');
      expect(Pointer('foo/bar/baz').parentPath(), 'foo/bar');
    });

    test('Pointer equality', () {
      expect(Pointer('foo') == Pointer('foo'), true);
      expect(Pointer('foo') == Pointer('foo/bar'), false);
    });

    test('Pointer equality with un-normalized paths', () {
      expect(Pointer('foo') == Pointer('/foo'), true);
      expect(Pointer('foo') == Pointer('/foo/bar'), false);
      expect(Pointer('foo') == Pointer('foo/'), true);
      expect(Pointer('foo') == Pointer('foo/bar/'), false);
    });
  });
}
