// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/src/dart/analysis/file_byte_store.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileByteStoreValidatorTest);
  });
}

@reflectiveTest
class FileByteStoreValidatorTest {
  final validator = FileByteStoreValidator();

  test_get_bad_notEnoughBytes() {
    var bytes = Uint8List.fromList([1, 2, 3]);
    var data = validator.getData(bytes);
    expect(data, isNull);
  }

  test_get_bad_notEnoughBytes_zero() {
    var bytes = Uint8List.fromList([]);
    var data = validator.getData(bytes);
    expect(data, isNull);
  }

  test_get_bad_wrongChecksum() {
    var data = Uint8List.fromList([1, 2, 3]);
    var bytes = validator.wrapData(data);

    // Damage the checksum.
    expect(bytes[bytes.length - 1], isNot(42));
    bytes[bytes.length - 1] = 42;

    var data2 = validator.getData(bytes);
    expect(data2, isNull);
  }

  test_get_bad_wrongVersion() {
    var bytes = Uint8List.fromList(
      [0xBA, 0xDA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
    );
    var data = validator.getData(bytes);
    expect(data, isNull);
  }

  test_get_good() {
    var data = Uint8List.fromList([1, 2, 3]);
    var bytes = validator.wrapData(data);
    var data2 = validator.getData(bytes);
    expect(data2, hasLength(3));
    expect(data2, data);
  }

  test_get_good_zeroBytesData() {
    var data = Uint8List.fromList([]);
    var bytes = validator.wrapData(data);
    var data2 = validator.getData(bytes);
    expect(data2, hasLength(0));
    expect(data2, data);
  }
}
