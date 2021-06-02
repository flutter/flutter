// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:zircon/zircon.dart';

/// Helper method to turn a [String] into a [ByteData] containing the
/// text of the string encoded as UTF-8.
ByteData utf8Bytes(final String text) {
  return ByteData.view(Uint8List.fromList(utf8.encode(text)).buffer);
}

void main() {
  group('duplicated handle', () {
    test('create and duplicate handles', () {
      final HandlePairResult pair = System.eventpairCreate();
      expect(pair.status, equals(ZX.OK));
      expect(pair.first.isValid, isTrue);
      expect(pair.second.isValid, isTrue);

      final Handle duplicate = pair.first.duplicate(ZX.RIGHT_SAME_RIGHTS);
      expect(duplicate.isValid, isTrue);

      final Handle failedDuplicate = pair.first.duplicate(-1);
      expect(failedDuplicate.isValid, isFalse);
    });

    test('failure invalid rights', () {
      final HandleResult vmo = System.vmoCreate(0);
      expect(vmo.status, equals(ZX.OK));
      final Handle failedDuplicate = vmo.handle.duplicate(-1);
      expect(failedDuplicate.isValid, isFalse);
      expect(vmo.handle.isValid, isTrue);
    });

    test('failure invalid handle', () {
      final Handle handle = Handle.invalid();
      final Handle duplicate = handle.duplicate(ZX.RIGHT_SAME_RIGHTS);
      expect(duplicate.isValid, isFalse);
    });

    test('duplicated handle should have same koid', () {
      final HandlePairResult pair = System.eventpairCreate();
      expect(pair.status, equals(ZX.OK));
      expect(pair.first.isValid, isTrue);
      expect(pair.second.isValid, isTrue);

      final Handle duplicate = pair.first.duplicate(ZX.RIGHT_SAME_RIGHTS);
      expect(duplicate.isValid, isTrue);

      expect(pair.first.koid, duplicate.koid);
    });

    // TODO(fxbug.dev/77599): Simplify once zx_object_get_info is available.
    test('reduced rights', () {
      // Set up handle.
      final HandleResult vmo = System.vmoCreate(2);
      expect(vmo.status, equals(ZX.OK));

      // Duplicate the first handle.
      final Handle duplicate = vmo.handle.duplicate(ZX.RIGHTS_BASIC);
      expect(duplicate.isValid, isTrue);

      // Write bytes to the original handle.
      final ByteData data1 = utf8Bytes('a');
      final int status1 = System.vmoWrite(vmo.handle, 0, data1);
      expect(status1, equals(ZX.OK));

      // Write bytes to the duplicated handle.
      final ByteData data2 = utf8Bytes('b');
      final int status2 = System.vmoWrite(duplicate, 1, data2);
      expect(status2, equals(ZX.ERR_ACCESS_DENIED));

      // Read bytes.
      final ReadResult readResult = System.vmoRead(vmo.handle, 0, 2);
      expect(readResult.status, equals(ZX.OK));
      expect(readResult.numBytes, equals(2));
      expect(readResult.bytes.lengthInBytes, equals(2));
      expect(readResult.bytesAsUTF8String(), equals('a\x00'));
    });
  });

  group('replaced handle', () {
    test('create and replace handles', () {
      final HandlePairResult pair = System.eventpairCreate();
      expect(pair.status, equals(ZX.OK));
      expect(pair.first.isValid, isTrue);
      expect(pair.second.isValid, isTrue);

      final Handle replaced = pair.first.replace(ZX.RIGHT_SAME_RIGHTS);
      expect(replaced.isValid, isTrue);
      expect(pair.first.isValid, isFalse);
    });

    test('failure invalid rights', () {
      final HandleResult vmo = System.vmoCreate(0);
      expect(vmo.status, equals(ZX.OK));
      final Handle failedDuplicate = vmo.handle.replace(-1);
      expect(failedDuplicate.isValid, isFalse);
      expect(vmo.handle.isValid, isFalse);
    });

    test('failure invalid handle', () {
      final Handle handle = Handle.invalid();
      final Handle replaced = handle.replace(ZX.RIGHT_SAME_RIGHTS);
      expect(handle.isValid, isFalse);
      expect(replaced.isValid, isFalse);
    });

    test('transferred handle should have same koid', () {
      final HandlePairResult pair = System.eventpairCreate();
      expect(pair.status, equals(ZX.OK));
      expect(pair.first.isValid, isTrue);
      expect(pair.second.isValid, isTrue);

      final int koid = pair.first.koid;
      final Handle replaced = pair.first.replace(ZX.RIGHT_SAME_RIGHTS);
      expect(replaced.isValid, isTrue);

      expect(koid, replaced.koid);
    });

    // TODO(fxbug.dev/77599): Simplify once zx_object_get_info is available.
    test('reduced rights', () {
      // Set up handle.
      final HandleResult vmo = System.vmoCreate(2);
      expect(vmo.status, equals(ZX.OK));

      // Replace the first handle.
      final Handle duplicate =
          vmo.handle.replace(ZX.RIGHTS_BASIC | ZX.RIGHT_READ);
      expect(duplicate.isValid, isTrue);

      // Write bytes to the original handle.
      final ByteData data1 = utf8Bytes('a');
      final int status1 = System.vmoWrite(vmo.handle, 0, data1);
      expect(status1, equals(ZX.ERR_BAD_HANDLE));

      // Write bytes to the duplicated handle.
      final ByteData data2 = utf8Bytes('b');
      final int status2 = System.vmoWrite(duplicate, 1, data2);
      expect(status2, equals(ZX.ERR_ACCESS_DENIED));

      // Read bytes.
      final ReadResult readResult = System.vmoRead(duplicate, 0, 2);
      expect(readResult.status, equals(ZX.OK));
      expect(readResult.numBytes, equals(2));
      expect(readResult.bytes.lengthInBytes, equals(2));
      expect(readResult.bytesAsUTF8String(), equals('\x00\x00'));
    });
  });

  test('cache koid and invalidate', () {
    final HandleResult vmo = System.vmoCreate(0);
    expect(vmo.status, equals(ZX.OK));
    int originalKoid = vmo.handle.koid;
    expect(originalKoid, isNot(equals(ZX.KOID_INVALID)));
    // Cached koid should be same value.
    expect(originalKoid, equals(vmo.handle.koid));
    vmo.handle.close();
    // koid should be invalidated.
    expect(vmo.handle.koid, equals(ZX.KOID_INVALID));
  });
}
