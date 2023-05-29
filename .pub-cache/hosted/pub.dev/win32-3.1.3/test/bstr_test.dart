// ignore_for_file: constant_identifier_names

@TestOn('windows')

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';
import 'package:win32/win32.dart';

void main() {
  const testRuns = 500;

  test('BSTR allocation', () {
    const testString = 'Hello world';

    for (var i = 0; i < testRuns; i++) {
      final bstr = BSTR.fromString(testString);

      // A BSTR should have a DWORD-length prefix containing its length.
      final pIndex =
          Pointer<DWORD>.fromAddress(bstr.ptr.address - sizeOf<DWORD>());
      expect(pIndex.value, equals(testString.length * 2));

      expect(bstr.ptr.toDartString(), equals(testString));

      // A BSTR should end with a word-length null terminator.
      final pNull =
          Pointer<WORD>.fromAddress(bstr.ptr.address + testString.length * 2);
      expect(pNull.value, isZero, reason: 'test run $i');
      bstr.free();
    }
  });

  test('Long BSTRs', () {
    final longString = 'A very long string with padding.' * 65536;

    // Ten allocations is probably enough for an expensive test like this.
    for (var i = 0; i < 10; i++) {
      // This string is 4MB (32 chars * 2 bytes * 65536)
      final bstr = BSTR.fromString(longString);

      // A BSTR should have a DWORD-length prefix containing its length.
      final pIndex =
          Pointer<DWORD>.fromAddress(bstr.ptr.address - sizeOf<DWORD>());
      expect(pIndex.value, equals(longString.length * 2));

      expect(bstr.ptr.toDartString(), equals(longString));

      // A BSTR should end with a word-length null terminator.
      final pNull =
          Pointer<WORD>.fromAddress(bstr.ptr.address + longString.length * 2);
      expect(pNull.value, isZero);
      bstr.free();
    }
  });

  test('BSTR lengths', () {
    const testString = 'Longhorn is a bar in the village resort between the '
        'Whistler and Blackcomb mountains';

    for (var i = 0; i < testRuns; i++) {
      final bstr = BSTR.fromString(testString);

      expect(testString.length, equals(84));
      expect(bstr.byteLength, equals(84 * 2));
      expect(bstr.length, equals(84));

      expect(bstr.toString(), equals(testString));

      bstr.free();
    }
  });

  test('BSTR clone', () {
    const testString = 'This message is not unique.';

    for (var i = 0; i < testRuns; i++) {
      final original = BSTR.fromString(testString);
      final clone = original.clone();

      // Text should be equal, but pointer address should not be equal
      expect(original.ptr.toDartString(), equals(clone.ptr.toDartString()));
      expect(original.toString(), equals(clone.toString()));
      expect(original.ptr, isNot(equals(clone.ptr)));

      clone.free();
      original.free();
    }
  });

  test('BSTR concatenation', () {
    for (var i = 0; i < testRuns; i++) {
      final first = BSTR.fromString('Windows');
      final second = BSTR.fromString(' and Dart');
      final matchInHeaven = first + second;

      expect(matchInHeaven.toString(), equals('Windows and Dart'));

      [first, second, matchInHeaven].map((object) => object.free());
    }
  });
}
