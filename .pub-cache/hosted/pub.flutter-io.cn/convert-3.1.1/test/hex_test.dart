// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:test/test.dart';

void main() {
  group('encoder', () {
    test('converts byte arrays to hex', () {
      expect(hex.encode([0x1a, 0xb2, 0x3c, 0xd4]), equals('1ab23cd4'));
      expect(hex.encode([0x00, 0x01, 0xfe, 0xff]), equals('0001feff'));
    });

    group('with chunked conversion', () {
      test('converts byte arrays to hex', () {
        var results = <String>[];
        var controller = StreamController<String>(sync: true);
        controller.stream.listen(results.add);
        var sink = hex.encoder.startChunkedConversion(controller.sink);

        sink.add([0x1a, 0xb2, 0x3c, 0xd4]);
        expect(results, equals(['1ab23cd4']));

        sink.add([0x00, 0x01, 0xfe, 0xff]);
        expect(results, equals(['1ab23cd4', '0001feff']));
      });

      test('handles empty and single-byte lists', () {
        var results = <String>[];
        var controller = StreamController<String>(sync: true);
        controller.stream.listen(results.add);
        var sink = hex.encoder.startChunkedConversion(controller.sink);

        sink.add([]);
        expect(results, equals(['']));

        sink.add([0x00]);
        expect(results, equals(['', '00']));

        sink.add([]);
        expect(results, equals(['', '00', '']));
      });
    });

    test('rejects non-bytes', () {
      expect(() => hex.encode([0x100]), throwsFormatException);

      var sink =
          hex.encoder.startChunkedConversion(StreamController(sync: true));
      expect(() => sink.add([0x100]), throwsFormatException);
    });
  });

  group('decoder', () {
    test('converts hex to byte arrays', () {
      expect(hex.decode('1ab23cd4'), equals([0x1a, 0xb2, 0x3c, 0xd4]));
      expect(hex.decode('0001feff'), equals([0x00, 0x01, 0xfe, 0xff]));
    });

    test('supports uppercase letters', () {
      expect(
          hex.decode('0123456789ABCDEFabcdef'),
          equals([
            0x01,
            0x23,
            0x45,
            0x67,
            0x89,
            0xab,
            0xcd,
            0xef,
            0xab,
            0xcd,
            0xef
          ]));
    });

    group('with chunked conversion', () {
      late List<List<int>> results;
      late StringConversionSink sink;
      setUp(() {
        results = [];
        var controller = StreamController<List<int>>(sync: true);
        controller.stream.listen(results.add);
        sink = hex.decoder.startChunkedConversion(controller.sink);
      });

      test('converts hex to byte arrays', () {
        sink.add('1ab23cd4');
        expect(
            results,
            equals([
              [0x1a, 0xb2, 0x3c, 0xd4]
            ]));

        sink.add('0001feff');
        expect(
            results,
            equals([
              [0x1a, 0xb2, 0x3c, 0xd4],
              [0x00, 0x01, 0xfe, 0xff]
            ]));
      });

      test('supports trailing digits split across chunks', () {
        sink.add('1ab23');
        expect(
            results,
            equals([
              [0x1a, 0xb2]
            ]));

        sink.add('cd');
        expect(
            results,
            equals([
              [0x1a, 0xb2],
              [0x3c]
            ]));

        sink.add('40001');
        expect(
            results,
            equals([
              [0x1a, 0xb2],
              [0x3c],
              [0xd4, 0x00, 0x01]
            ]));

        sink.add('feff');
        expect(
            results,
            equals([
              [0x1a, 0xb2],
              [0x3c],
              [0xd4, 0x00, 0x01],
              [0xfe, 0xff]
            ]));
      });

      test('supports empty strings', () {
        sink.add('');
        expect(results, isEmpty);

        sink.add('0');
        expect(results, equals([[]]));

        sink.add('');
        expect(results, equals([[]]));

        sink.add('0');
        expect(
            results,
            equals([
              [],
              [0x00]
            ]));

        sink.add('');
        expect(
            results,
            equals([
              [],
              [0x00]
            ]));
      });

      test('rejects odd length detected in close()', () {
        sink.add('1ab23');
        expect(
            results,
            equals([
              [0x1a, 0xb2]
            ]));
        expect(() => sink.close(), throwsFormatException);
      });

      test('rejects odd length detected in addSlice()', () {
        sink.addSlice('1ab23cd', 0, 5, false);
        expect(
            results,
            equals([
              [0x1a, 0xb2]
            ]));

        expect(
            () => sink.addSlice('1ab23cd', 5, 7, true), throwsFormatException);
      });
    });

    group('rejects non-hex character', () {
      for (var char in [
        'g',
        'G',
        '/',
        ':',
        '@',
        '`',
        '\x00',
        '\u0141',
        '\u{10041}'
      ]) {
        test('"$char"', () {
          expect(() => hex.decode('a$char'), throwsFormatException);
          expect(() => hex.decode('${char}a'), throwsFormatException);

          var sink =
              hex.decoder.startChunkedConversion(StreamController(sync: true));
          expect(() => sink.add(char), throwsFormatException);
        });
      }
    });

    test('rejects odd length detected in convert()', () {
      expect(() => hex.decode('1ab23cd'), throwsFormatException);
    });
  });
}
