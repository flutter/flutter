// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:zircon/zircon.dart';

void main() {
  group('test vmo', () {
    test('fromFile', () {
      const String fuchsia = 'Fuchsia';
      File f = File('tmp/testdata')
        ..createSync()
        ..writeAsStringSync(fuchsia);
      String readFuchsia = f.readAsStringSync();
      expect(readFuchsia, equals(fuchsia));

      SizedVmo fileVmo = SizedVmo.fromFile('tmp/testdata');
      Uint8List fileData = fileVmo.map();
      String fileString = utf8.decode(fileData.sublist(0, fileVmo.size));
      expect(fileString, equals(fuchsia));
    });

    test('duplicate', () {
      const String fuchsia = 'Fuchsia';
      Uint8List data = Uint8List.fromList(fuchsia.codeUnits);
      SizedVmo vmo = SizedVmo.fromUint8List(data);
      final Vmo duplicate =
          vmo.duplicate(ZX.RIGHTS_BASIC | ZX.RIGHT_READ | ZX.RIGHT_MAP);
      expect(duplicate.isValid, isTrue);

      // Read from the duplicate.
      final duplicatedVmo = SizedVmo(duplicate.handle, fuchsia.length);
      Uint8List vmoData = duplicatedVmo.map();
      String vmoString = utf8.decode(vmoData.sublist(0, vmo.size));
      expect(vmoString, equals(fuchsia));
    });
  });
}
