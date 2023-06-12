// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('vm') // Uses dart:io

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

final String pathPrefix =
    Directory.current.path.endsWith('test') ? './assets/' : './test/assets/';
final String path = '${pathPrefix}hello.txt';
const String expectedStringContents = 'Hello, world!';
final Uint8List bytes = Uint8List.fromList(utf8.encode(expectedStringContents));
final File textFile = File(path);
final String textFilePath = textFile.path;

void main() {
  group('Create with an objectUrl', () {
    final PickedFile pickedFile = PickedFile(textFilePath);

    test('Can be read as a string', () async {
      expect(await pickedFile.readAsString(), equals(expectedStringContents));
    });
    test('Can be read as bytes', () async {
      expect(await pickedFile.readAsBytes(), equals(bytes));
    });

    test('Can be read as a stream', () async {
      expect(await pickedFile.openRead().first, equals(bytes));
    });

    test('Stream can be sliced', () async {
      expect(
          await pickedFile.openRead(2, 5).first, equals(bytes.sublist(2, 5)));
    });
  });
}
