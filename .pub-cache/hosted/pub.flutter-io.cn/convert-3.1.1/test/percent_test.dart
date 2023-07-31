// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:test/test.dart';

void main() {
  group('encoder', () {
    test("doesn't percent-encode unreserved characters", () {
      var safeChars = 'abcdefghijklmnopqrstuvwxyz'
          'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
          '0123456789-._~';
      expect(percent.encode([...safeChars.codeUnits]), equals(safeChars));
    });

    test('percent-encodes reserved ASCII characters', () {
      expect(percent.encode([...' `{@[,/^}\x7f\x00%'.codeUnits]),
          equals('%20%60%7B%40%5B%2C%2F%5E%7D%7F%00%25'));
    });

    test('percent-encodes non-ASCII characters', () {
      expect(percent.encode([0x80, 0xFF]), equals('%80%FF'));
    });

    test('mixes encoded and unencoded characters', () {
      expect(percent.encode([...'a+b=\x80'.codeUnits]), equals('a%2Bb%3D%80'));
    });

    group('with chunked conversion', () {
      test('percent-encodes byte arrays', () {
        var results = <String>[];
        var controller = StreamController<String>(sync: true);
        controller.stream.listen(results.add);
        var sink = percent.encoder.startChunkedConversion(controller.sink);

        sink.add([...'a+b=\x80'.codeUnits]);
        expect(results, equals(['a%2Bb%3D%80']));

        sink.add([0x00, 0x01, 0xfe, 0xff]);
        expect(results, equals(['a%2Bb%3D%80', '%00%01%FE%FF']));
      });

      test('handles empty and single-byte lists', () {
        var results = <String>[];
        var controller = StreamController<String>(sync: true);
        controller.stream.listen(results.add);
        var sink = percent.encoder.startChunkedConversion(controller.sink);

        sink.add([]);
        expect(results, equals(['']));

        sink.add([0x00]);
        expect(results, equals(['', '%00']));

        sink.add([]);
        expect(results, equals(['', '%00', '']));
      });
    });

    test('rejects non-bytes', () {
      expect(() => percent.encode([0x100]), throwsFormatException);

      var sink =
          percent.encoder.startChunkedConversion(StreamController(sync: true));
      expect(() => sink.add([0x100]), throwsFormatException);
    });
  });

  group('decoder', () {
    test('converts percent-encoded strings to byte arrays', () {
      expect(
          percent.decode('a%2Bb%3D%801'), equals([...'a+b=\x801'.codeUnits]));
    });

    test('supports lowercase letters', () {
      expect(percent.decode('a%2bb%3d%80'), equals([...'a+b=\x80'.codeUnits]));
    });

    test('supports more aggressive encoding', () {
      expect(percent.decode('%61%2E%5A'), equals([...'a.Z'.codeUnits]));
    });

    test('supports less aggressive encoding', () {
      var chars = ' `{@[,/^}\x7F\x00';
      expect(percent.decode(chars), equals([...chars.codeUnits]));
    });

    group('with chunked conversion', () {
      late List<List<int>> results;
      late StringConversionSink sink;
      setUp(() {
        results = [];
        var controller = StreamController<List<int>>(sync: true);
        controller.stream.listen(results.add);
        sink = percent.decoder.startChunkedConversion(controller.sink);
      });

      test('converts percent to byte arrays', () {
        sink.add('a%2Bb%3D%801');
        expect(
            results,
            equals([
              [...'a+b=\x801'.codeUnits]
            ]));

        sink.add('%00%01%FE%FF');
        expect(
            results,
            equals([
              [...'a+b=\x801'.codeUnits],
              [0x00, 0x01, 0xfe, 0xff]
            ]));
      });

      test('supports trailing percents and digits split across chunks', () {
        sink.add('ab%');
        expect(
            results,
            equals([
              [...'ab'.codeUnits]
            ]));

        sink.add('2');
        expect(
            results,
            equals([
              [...'ab'.codeUnits]
            ]));

        sink.add('0cd%2');
        expect(
            results,
            equals([
              [...'ab'.codeUnits],
              [...' cd'.codeUnits]
            ]));

        sink.add('0');
        expect(
            results,
            equals([
              [...'ab'.codeUnits],
              [...' cd'.codeUnits],
              [...' '.codeUnits]
            ]));
      });

      test('supports empty strings', () {
        sink.add('');
        expect(results, isEmpty);

        sink.add('%');
        expect(results, equals([[]]));

        sink.add('');
        expect(results, equals([[]]));

        sink.add('2');
        expect(results, equals([[]]));

        sink.add('');
        expect(results, equals([[]]));

        sink.add('0');
        expect(
            results,
            equals([
              [],
              [0x20]
            ]));
      });

      test('rejects dangling % detected in close()', () {
        sink.add('ab%');
        expect(
            results,
            equals([
              [...'ab'.codeUnits]
            ]));
        expect(() => sink.close(), throwsFormatException);
      });

      test('rejects dangling digit detected in close()', () {
        sink.add('ab%2');
        expect(
            results,
            equals([
              [...'ab'.codeUnits]
            ]));
        expect(() => sink.close(), throwsFormatException);
      });

      test('rejects danging % detected in addSlice()', () {
        sink.addSlice('ab%', 0, 3, false);
        expect(
            results,
            equals([
              [...'ab'.codeUnits]
            ]));

        expect(() => sink.addSlice('ab%', 0, 3, true), throwsFormatException);
      });

      test('rejects danging digit detected in addSlice()', () {
        sink.addSlice('ab%2', 0, 3, false);
        expect(
            results,
            equals([
              [...'ab'.codeUnits]
            ]));

        expect(() => sink.addSlice('ab%2', 0, 3, true), throwsFormatException);
      });
    });

    group('rejects non-ASCII character', () {
      for (var char in ['\u0141', '\u{10041}']) {
        test('"$char"', () {
          expect(() => percent.decode('a$char'), throwsFormatException);
          expect(() => percent.decode('${char}a'), throwsFormatException);

          var sink = percent.decoder
              .startChunkedConversion(StreamController(sync: true));
          expect(() => sink.add(char), throwsFormatException);
        });
      }
    });

    test('rejects % followed by non-hex', () {
      expect(() => percent.decode('%z2'), throwsFormatException);
      expect(() => percent.decode('%2z'), throwsFormatException);
    });

    test('rejects dangling % detected in convert()', () {
      expect(() => percent.decode('ab%'), throwsFormatException);
    });

    test('rejects dangling digit detected in convert()', () {
      expect(() => percent.decode('ab%2'), throwsFormatException);
    });
  });
}
