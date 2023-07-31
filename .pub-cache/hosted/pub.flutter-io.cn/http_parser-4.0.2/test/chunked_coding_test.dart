// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:http_parser/http_parser.dart';
import 'package:http_parser/src/chunked_coding/charcodes.dart';
import 'package:test/test.dart';

void main() {
  group('encoder', () {
    test('adds a header to the chunk of bytes', () {
      expect(chunkedCoding.encode([1, 2, 3]),
          equals([$3, $cr, $lf, 1, 2, 3, $cr, $lf, $0, $cr, $lf, $cr, $lf]));
    });

    test('uses hex for chunk size', () {
      final data = Iterable<int>.generate(0xA7).toList();
      expect(
          chunkedCoding.encode(data),
          equals(
              [$a, $7, $cr, $lf, ...data, $cr, $lf, $0, $cr, $lf, $cr, $lf]));
    });

    test('just generates a footer for an empty input', () {
      expect(chunkedCoding.encode([]), equals([$0, $cr, $lf, $cr, $lf]));
    });

    group('with chunked conversion', () {
      late List<List<int>> results;
      late ByteConversionSink sink;
      setUp(() {
        results = [];
        final controller = StreamController<List<int>>(sync: true);
        controller.stream.listen(results.add);
        sink = chunkedCoding.encoder.startChunkedConversion(controller.sink);
      });

      test('adds headers to each chunk of bytes', () {
        sink.add([1, 2, 3, 4]);
        expect(
            results,
            equals([
              [$4, $cr, $lf, 1, 2, 3, 4, $cr, $lf]
            ]));

        sink.add([5, 6, 7]);
        expect(
            results,
            equals([
              [$4, $cr, $lf, 1, 2, 3, 4, $cr, $lf],
              [$3, $cr, $lf, 5, 6, 7, $cr, $lf],
            ]));

        sink.close();
        expect(
            results,
            equals([
              [$4, $cr, $lf, 1, 2, 3, 4, $cr, $lf],
              [$3, $cr, $lf, 5, 6, 7, $cr, $lf],
              [$0, $cr, $lf, $cr, $lf],
            ]));
      });

      test('handles empty chunks', () {
        sink.add([]);
        expect(results, equals([[]]));

        sink.add([1, 2, 3]);
        expect(
            results,
            equals([
              [],
              [$3, $cr, $lf, 1, 2, 3, $cr, $lf]
            ]));

        sink.add([]);
        expect(
            results,
            equals([
              [],
              [$3, $cr, $lf, 1, 2, 3, $cr, $lf],
              []
            ]));

        sink.close();
        expect(
            results,
            equals([
              [],
              [$3, $cr, $lf, 1, 2, 3, $cr, $lf],
              [],
              [$0, $cr, $lf, $cr, $lf],
            ]));
      });

      group('addSlice()', () {
        test('adds bytes from the specified slice', () {
          sink.addSlice([1, 2, 3, 4, 5], 1, 4, false);
          expect(
              results,
              equals([
                [$3, $cr, $lf, 2, 3, 4, $cr, $lf]
              ]));
        });

        test("doesn't add a header if the slice is empty", () {
          sink.addSlice([1, 2, 3, 4, 5], 1, 1, false);
          expect(results, equals([[]]));
        });

        test('adds a footer if isLast is true', () {
          sink.addSlice([1, 2, 3, 4, 5], 1, 4, true);
          expect(
              results,
              equals([
                [$3, $cr, $lf, 2, 3, 4, $cr, $lf, $0, $cr, $lf, $cr, $lf]
              ]));

          // Setting isLast shuld close the sink.
          expect(() => sink.add([]), throwsStateError);
        });

        group('disallows', () {
          test('start < 0', () {
            expect(() => sink.addSlice([1, 2, 3, 4, 5], -1, 4, false),
                throwsRangeError);
          });

          test('start > end', () {
            expect(() => sink.addSlice([1, 2, 3, 4, 5], 3, 2, false),
                throwsRangeError);
          });

          test('end > length', () {
            expect(() => sink.addSlice([1, 2, 3, 4, 5], 1, 10, false),
                throwsRangeError);
          });
        });
      });
    });
  });

  group('decoder', () {
    test('parses chunked data', () {
      expect(
          chunkedCoding.decode([
            $3,
            $cr,
            $lf,
            1,
            2,
            3,
            $cr,
            $lf,
            $4,
            $cr,
            $lf,
            4,
            5,
            6,
            7,
            $cr,
            $lf,
            $0,
            $cr,
            $lf,
            $cr,
            $lf,
          ]),
          equals([1, 2, 3, 4, 5, 6, 7]));
    });

    test('parses hex size', () {
      final data = Iterable<int>.generate(0xA7).toList();
      expect(
          chunkedCoding.decode(
              [$a, $7, $cr, $lf, ...data, $cr, $lf, $0, $cr, $lf, $cr, $lf]),
          equals(data));
    });

    test('parses capital hex size', () {
      final data = Iterable<int>.generate(0xA7).toList();
      expect(
          chunkedCoding.decode(
              [$A, $7, $cr, $lf, ...data, $cr, $lf, $0, $cr, $lf, $cr, $lf]),
          equals(data));
    });

    test('parses an empty message', () {
      expect(chunkedCoding.decode([$0, $cr, $lf, $cr, $lf]), isEmpty);
    });

    group('disallows a message', () {
      test('that ends without any input', () {
        expect(() => chunkedCoding.decode([]), throwsFormatException);
      });

      test('that ends after the size', () {
        expect(() => chunkedCoding.decode([$a]), throwsFormatException);
      });

      test('that ends after CR', () {
        expect(() => chunkedCoding.decode([$a, $cr]), throwsFormatException);
      });

      test('that ends after LF', () {
        expect(
            () => chunkedCoding.decode([$a, $cr, $lf]), throwsFormatException);
      });

      test('that ends after insufficient bytes', () {
        expect(() => chunkedCoding.decode([$a, $cr, $lf, 1, 2, 3]),
            throwsFormatException);
      });

      test("that ends after a chunk's bytes", () {
        expect(() => chunkedCoding.decode([$1, $cr, $lf, 1]),
            throwsFormatException);
      });

      test("that ends after a chunk's CR", () {
        expect(() => chunkedCoding.decode([$1, $cr, $lf, 1, $cr]),
            throwsFormatException);
      });

      test("that ends atfter a chunk's LF", () {
        expect(() => chunkedCoding.decode([$1, $cr, $lf, 1, $cr, $lf]),
            throwsFormatException);
      });

      test('that ends after the empty chunk', () {
        expect(
            () => chunkedCoding.decode([$0, $cr, $lf]), throwsFormatException);
      });

      test('that ends after the closing CR', () {
        expect(() => chunkedCoding.decode([$0, $cr, $lf, $cr]),
            throwsFormatException);
      });

      test('with a chunk without a size', () {
        expect(() => chunkedCoding.decode([$cr, $lf, $0, $cr, $lf, $cr, $lf]),
            throwsFormatException);
      });

      test('with a chunk with a non-hex size', () {
        expect(
            () => chunkedCoding.decode([$q, $cr, $lf, $0, $cr, $lf, $cr, $lf]),
            throwsFormatException);
      });
    });

    group('with chunked conversion', () {
      late List<List<int>> results;
      late ByteConversionSink sink;
      setUp(() {
        results = [];
        final controller = StreamController<List<int>>(sync: true);
        controller.stream.listen(results.add);
        sink = chunkedCoding.decoder.startChunkedConversion(controller.sink);
      });

      test('decodes each chunk of bytes', () {
        sink.add([$4, $cr, $lf, 1, 2, 3, 4, $cr, $lf]);
        expect(
            results,
            equals([
              [1, 2, 3, 4]
            ]));

        sink.add([$3, $cr, $lf, 5, 6, 7, $cr, $lf]);
        expect(
            results,
            equals([
              [1, 2, 3, 4],
              [5, 6, 7]
            ]));

        sink.add([$0, $cr, $lf, $cr, $lf]);
        sink.close();
        expect(
            results,
            equals([
              [1, 2, 3, 4],
              [5, 6, 7]
            ]));
      });

      test('handles empty chunks', () {
        sink.add([]);
        expect(results, isEmpty);

        sink.add([$3, $cr, $lf, 1, 2, 3, $cr, $lf]);
        expect(
            results,
            equals([
              [1, 2, 3]
            ]));

        sink.add([]);
        expect(
            results,
            equals([
              [1, 2, 3]
            ]));

        sink.add([$0, $cr, $lf, $cr, $lf]);
        sink.close();
        expect(
            results,
            equals([
              [1, 2, 3]
            ]));
      });

      test('throws if the sink is closed before the message is done', () {
        sink.add([$3, $cr, $lf, 1, 2, 3]);
        expect(() => sink.close(), throwsFormatException);
      });

      group('preserves state when a byte array ends', () {
        test('within chunk size', () {
          sink.add([$a]);
          expect(results, isEmpty);

          final data = Iterable<int>.generate(0xA7).toList();
          sink.add([$7, $cr, $lf, ...data]);
          expect(results, equals([data]));
        });

        test('after chunk size', () {
          sink.add([$3]);
          expect(results, isEmpty);

          sink.add([$cr, $lf, 1, 2, 3]);
          expect(
              results,
              equals([
                [1, 2, 3]
              ]));
        });

        test('after CR', () {
          sink.add([$3, $cr]);
          expect(results, isEmpty);

          sink.add([$lf, 1, 2, 3]);
          expect(
              results,
              equals([
                [1, 2, 3]
              ]));
        });

        test('after LF', () {
          sink.add([$3, $cr, $lf]);
          expect(results, isEmpty);

          sink.add([1, 2, 3]);
          expect(
              results,
              equals([
                [1, 2, 3]
              ]));
        });

        test('after some bytes', () {
          sink.add([$3, $cr, $lf, 1, 2]);
          expect(
              results,
              equals([
                [1, 2]
              ]));

          sink.add([3]);
          expect(
              results,
              equals([
                [1, 2],
                [3]
              ]));
        });

        test('after all bytes', () {
          sink.add([$3, $cr, $lf, 1, 2, 3]);
          expect(
              results,
              equals([
                [1, 2, 3]
              ]));

          sink.add([$cr, $lf, $3, $cr, $lf, 2, 3, 4, $cr, $lf]);
          expect(
              results,
              equals([
                [1, 2, 3],
                [2, 3, 4]
              ]));
        });

        test('after a post-chunk CR', () {
          sink.add([$3, $cr, $lf, 1, 2, 3, $cr]);
          expect(
              results,
              equals([
                [1, 2, 3]
              ]));

          sink.add([$lf, $3, $cr, $lf, 2, 3, 4, $cr, $lf]);
          expect(
              results,
              equals([
                [1, 2, 3],
                [2, 3, 4]
              ]));
        });

        test('after a post-chunk LF', () {
          sink.add([$3, $cr, $lf, 1, 2, 3, $cr, $lf]);
          expect(
              results,
              equals([
                [1, 2, 3]
              ]));

          sink.add([$3, $cr, $lf, 2, 3, 4, $cr, $lf]);
          expect(
              results,
              equals([
                [1, 2, 3],
                [2, 3, 4]
              ]));
        });

        test('after empty chunk size', () {
          sink.add([$0]);
          expect(results, isEmpty);

          sink.add([$cr, $lf, $cr, $lf]);
          expect(results, isEmpty);

          sink.close();
          expect(results, isEmpty);
        });

        test('after first empty chunk CR', () {
          sink.add([$0, $cr]);
          expect(results, isEmpty);

          sink.add([$lf, $cr, $lf]);
          expect(results, isEmpty);

          sink.close();
          expect(results, isEmpty);
        });

        test('after first empty chunk LF', () {
          sink.add([$0, $cr, $lf]);
          expect(results, isEmpty);

          sink.add([$cr, $lf]);
          expect(results, isEmpty);

          sink.close();
          expect(results, isEmpty);
        });

        test('after second empty chunk CR', () {
          sink.add([$0, $cr, $lf, $cr]);
          expect(results, isEmpty);

          sink.add([$lf]);
          expect(results, isEmpty);

          sink.close();
          expect(results, isEmpty);
        });
      });

      group('addSlice()', () {
        test('adds bytes from the specified slice', () {
          sink.addSlice([1, $3, $cr, $lf, 2, 3, 4, 5], 1, 7, false);
          expect(
              results,
              equals([
                [2, 3, 4]
              ]));
        });

        test("doesn't decode if the slice is empty", () {
          sink.addSlice([1, 2, 3, 4, 5], 1, 1, false);
          expect(results, isEmpty);
        });

        test('closes the sink if isLast is true', () {
          sink.addSlice([1, $0, $cr, $lf, $cr, $lf, 7], 1, 6, true);
          expect(results, isEmpty);
        });

        group('disallows', () {
          test('start < 0', () {
            expect(() => sink.addSlice([1, 2, 3, 4, 5], -1, 4, false),
                throwsRangeError);
          });

          test('start > end', () {
            expect(() => sink.addSlice([1, 2, 3, 4, 5], 3, 2, false),
                throwsRangeError);
          });

          test('end > length', () {
            expect(() => sink.addSlice([1, 2, 3, 4, 5], 1, 10, false),
                throwsRangeError);
          });
        });
      });
    });
  });
}
