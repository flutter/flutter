// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';

Pointer<Uint8> _bytesFromList(List<int> ints) {
  final Pointer<Uint8> ptr = calloc(ints.length);
  final Uint8List list = ptr.asTypedList(ints.length);
  list.setAll(0, ints);
  return ptr;
}

void main() {
  test('toUtf8 ASCII', () {
    final String start = 'Hello World!\n';
    final Pointer<Uint8> converted = start.toNativeUtf8().cast();
    final Uint8List end = converted.asTypedList(start.length + 1);
    final matcher =
        equals([72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100, 33, 10, 0]);
    expect(end, matcher);
    calloc.free(converted);
  });

  test('fromUtf8 ASCII', () {
    final Pointer<Utf8> utf8 = _bytesFromList(
        [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100, 33, 10, 0]).cast();
    final String end = utf8.toDartString();
    expect(end, 'Hello World!\n');
  });

  test('toUtf8 emoji', () {
    final String start = '😎👿💬';
    final Pointer<Utf8> converted = start.toNativeUtf8().cast();
    final int length = converted.length;
    final Uint8List end = converted.cast<Uint8>().asTypedList(length + 1);
    final matcher =
        equals([240, 159, 152, 142, 240, 159, 145, 191, 240, 159, 146, 172, 0]);
    expect(end, matcher);
    calloc.free(converted);
  });

  test('formUtf8 emoji', () {
    final Pointer<Utf8> utf8 = _bytesFromList(
        [240, 159, 152, 142, 240, 159, 145, 191, 240, 159, 146, 172, 0]).cast();
    final String end = utf8.toDartString();
    expect(end, '😎👿💬');
  });

  test('fromUtf8 invalid', () {
    final Pointer<Utf8> utf8 = _bytesFromList([0x80, 0x00]).cast();
    expect(() => utf8.toDartString(), throwsA(isFormatException));
  });

  test('fromUtf8 ASCII with length', () {
    final Pointer<Utf8> utf8 = _bytesFromList(
        [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100, 33, 10, 0]).cast();
    final String end = utf8.toDartString(length: 5);
    expect(end, 'Hello');
  });

  test('fromUtf8 emoji with length', () {
    final Pointer<Utf8> utf8 = _bytesFromList(
        [240, 159, 152, 142, 240, 159, 145, 191, 240, 159, 146, 172, 0]).cast();
    final String end = utf8.toDartString(length: 4);
    expect(end, '😎');
  });

  test('fromUtf8 with zero length', () {
    final Pointer<Utf8> utf8 = _bytesFromList(
        [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100, 33, 10, 0]).cast();
    final String end = utf8.toDartString(length: 0);
    expect(end, '');
  });

  test('fromUtf8 with negative length', () {
    final Pointer<Utf8> utf8 = _bytesFromList(
        [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100, 33, 10, 0]).cast();
    expect(() => utf8.toDartString(length: -1), throwsRangeError);
  });

  test('fromUtf8 with length and containing a zero byte', () {
    final Pointer<Utf8> utf8 = _bytesFromList(
        [72, 101, 108, 108, 111, 0, 87, 111, 114, 108, 100, 33, 10]).cast();
    final String end = utf8.toDartString(length: 13);
    expect(end, 'Hello\x00World!\n');
  });

  test('length', () {
    final string = 'Hello';
    final utf8Pointer = string.toNativeUtf8();
    expect(utf8Pointer.length, 5);
    calloc.free(utf8Pointer);
  });

  test('nullptr.toDartString()', () {
    final Pointer<Utf8> utf8 = nullptr;
    try {
      utf8.toDartString();
    } on UnsupportedError {
      return;
    }
    fail('Expected an error.');
  });

  test('nullptr.length', () {
    final Pointer<Utf8> utf8 = nullptr;
    try {
      utf8.length;
    } on UnsupportedError {
      return;
    }
    fail('Expected an error.');
  });
}
