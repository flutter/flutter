// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('vm') // Uses dart:io

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:test/test.dart';

final String pathPrefix =
    Directory.current.path.endsWith('test') ? './assets/' : './test/assets/';
final String path = '${pathPrefix}hello.txt';
const String expectedStringContents = 'Hello, world!';
final Uint8List bytes = Uint8List.fromList(utf8.encode(expectedStringContents));
final File textFile = File(path);
final String textFilePath = textFile.path;

void main() {
  group('Create with a path', () {
    test('Can be read as a string', () async {
      final XFile file = XFile(textFilePath);
      expect(await file.readAsString(), equals(expectedStringContents));
    });
    test('Can be read as bytes', () async {
      final XFile file = XFile(textFilePath);
      expect(await file.readAsBytes(), equals(bytes));
    });

    test('Can be read as a stream', () async {
      final XFile file = XFile(textFilePath);
      expect(await file.openRead().first, equals(bytes));
    });

    test('Stream can be sliced', () async {
      final XFile file = XFile(textFilePath);
      expect(await file.openRead(2, 5).first, equals(bytes.sublist(2, 5)));
    });

    test('saveTo(..) creates file', () async {
      final XFile file = XFile(textFilePath);
      final Directory tempDir = Directory.systemTemp.createTempSync();
      final File targetFile = File('${tempDir.path}/newFilePath.txt');
      if (targetFile.existsSync()) {
        await targetFile.delete();
      }

      await file.saveTo(targetFile.path);

      expect(targetFile.existsSync(), isTrue);
      expect(targetFile.readAsStringSync(), 'Hello, world!');

      await tempDir.delete(recursive: true);
    });

    test('saveTo(..) does not load the file into memory', () async {
      final TestXFile file = TestXFile(textFilePath);
      final Directory tempDir = Directory.systemTemp.createTempSync();
      final File targetFile = File('${tempDir.path}/newFilePath.txt');
      if (targetFile.existsSync()) {
        await targetFile.delete();
      }

      await file.saveTo(targetFile.path);

      expect(file.hasBeenRead, isFalse);

      await tempDir.delete(recursive: true);
    });
  });

  group('Create with data', () {
    final XFile file = XFile.fromData(bytes);

    test('Can be read as a string', () async {
      expect(await file.readAsString(), equals(expectedStringContents));
    });
    test('Can be read as bytes', () async {
      expect(await file.readAsBytes(), equals(bytes));
    });

    test('Can be read as a stream', () async {
      expect(await file.openRead().first, equals(bytes));
    });

    test('Stream can be sliced', () async {
      expect(await file.openRead(2, 5).first, equals(bytes.sublist(2, 5)));
    });

    test('Function saveTo(..) creates file', () async {
      final Directory tempDir = Directory.systemTemp.createTempSync();
      final File targetFile = File('${tempDir.path}/newFilePath.txt');
      if (targetFile.existsSync()) {
        await targetFile.delete();
      }

      await file.saveTo(targetFile.path);

      expect(targetFile.existsSync(), isTrue);
      expect(targetFile.readAsStringSync(), 'Hello, world!');

      await tempDir.delete(recursive: true);
    });
  });
}

/// An XFile subclass that tracks reads, for testing purposes.
class TestXFile extends XFile {
  TestXFile(String path) : super(path);

  bool hasBeenRead = false;

  @override
  Future<Uint8List> readAsBytes() {
    hasBeenRead = true;
    return super.readAsBytes();
  }
}
