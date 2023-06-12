// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:http_parser/http_parser.dart';
import 'package:test/test.dart';

void main() {
  group('format', () {
    test('many values with 9', () {
      final date = DateTime.utc(2014, 9, 9, 9, 9, 9);
      final formatted = formatHttpDate(date);

      expect(formatted, 'Tue, 09 Sep 2014 09:09:09 GMT');
      final parsed = parseHttpDate(formatted);

      expect(parsed, date);
    });

    test('end of year', () {
      final date = DateTime.utc(1999, 12, 31, 23, 59, 59);
      final formatted = formatHttpDate(date);

      expect(formatted, 'Fri, 31 Dec 1999 23:59:59 GMT');
      final parsed = parseHttpDate(formatted);

      expect(parsed, date);
    });

    test('start of year', () {
      final date = DateTime.utc(2000);
      final formatted = formatHttpDate(date);

      expect(formatted, 'Sat, 01 Jan 2000 00:00:00 GMT');
      final parsed = parseHttpDate(formatted);

      expect(parsed, date);
    });
  });

  group('parse', () {
    group('RFC 1123', () {
      test('parses the example date', () {
        final date = parseHttpDate('Sun, 06 Nov 1994 08:49:37 GMT');
        expect(date.day, equals(6));
        expect(date.month, equals(DateTime.november));
        expect(date.year, equals(1994));
        expect(date.hour, equals(8));
        expect(date.minute, equals(49));
        expect(date.second, equals(37));
        expect(date.timeZoneName, equals('UTC'));
      });

      test('whitespace is required', () {
        expect(() => parseHttpDate('Sun,06 Nov 1994 08:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun, 06Nov 1994 08:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun, 06 Nov1994 08:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun, 06 Nov 199408:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun, 06 Nov 1994 08:49:37GMT'),
            throwsFormatException);
      });

      test('exactly one space is required', () {
        expect(() => parseHttpDate('Sun,  06 Nov 1994 08:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun, 06  Nov 1994 08:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun, 06 Nov  1994 08:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun, 06 Nov 1994  08:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun, 06 Nov 1994 08:49:37  GMT'),
            throwsFormatException);
      });

      test('requires precise number lengths', () {
        expect(() => parseHttpDate('Sun, 6 Nov 1994 08:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun, 06 Nov 94 08:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun, 06 Nov 1994 8:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun, 06 Nov 1994 08:9:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun, 06 Nov 1994 08:49:7 GMT'),
            throwsFormatException);
      });

      test('requires reasonable numbers', () {
        expect(() => parseHttpDate('Sun, 00 Nov 1994 08:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun, 31 Nov 1994 08:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun, 32 Aug 1994 08:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun, 06 Nov 1994 24:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun, 06 Nov 1994 08:60:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun, 06 Nov 1994 08:49:60 GMT'),
            throwsFormatException);
      });

      test('only allows short weekday names', () {
        expect(() => parseHttpDate('Sunday, 6 Nov 1994 08:49:37 GMT'),
            throwsFormatException);
      });

      test('only allows short month names', () {
        expect(() => parseHttpDate('Sun, 6 November 1994 08:49:37 GMT'),
            throwsFormatException);
      });

      test('only allows GMT', () {
        expect(() => parseHttpDate('Sun, 6 Nov 1994 08:49:37 PST'),
            throwsFormatException);
      });

      test('disallows trailing whitespace', () {
        expect(() => parseHttpDate('Sun, 6 Nov 1994 08:49:37 GMT '),
            throwsFormatException);
      });
    });

    group('RFC 850', () {
      test('parses the example date', () {
        final date = parseHttpDate('Sunday, 06-Nov-94 08:49:37 GMT');
        expect(date.day, equals(6));
        expect(date.month, equals(DateTime.november));
        expect(date.year, equals(1994));
        expect(date.hour, equals(8));
        expect(date.minute, equals(49));
        expect(date.second, equals(37));
        expect(date.timeZoneName, equals('UTC'));
      });

      test('whitespace is required', () {
        expect(() => parseHttpDate('Sunday,06-Nov-94 08:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sunday, 06-Nov-9408:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sunday, 06-Nov-94 08:49:37GMT'),
            throwsFormatException);
      });

      test('exactly one space is required', () {
        expect(() => parseHttpDate('Sunday,  06-Nov-94 08:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sunday, 06-Nov-94  08:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sunday, 06-Nov-94 08:49:37  GMT'),
            throwsFormatException);
      });

      test('requires precise number lengths', () {
        expect(() => parseHttpDate('Sunday, 6-Nov-94 08:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sunday, 06-Nov-1994 08:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sunday, 06-Nov-94 8:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sunday, 06-Nov-94 08:9:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sunday, 06-Nov-94 08:49:7 GMT'),
            throwsFormatException);
      });

      test('requires reasonable numbers', () {
        expect(() => parseHttpDate('Sunday, 00-Nov-94 08:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sunday, 31-Nov-94 08:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sunday, 32-Aug-94 08:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sunday, 06-Nov-94 24:49:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sunday, 06-Nov-94 08:60:37 GMT'),
            throwsFormatException);

        expect(() => parseHttpDate('Sunday, 06-Nov-94 08:49:60 GMT'),
            throwsFormatException);
      });

      test('only allows long weekday names', () {
        expect(() => parseHttpDate('Sun, 6-Nov-94 08:49:37 GMT'),
            throwsFormatException);
      });

      test('only allows short month names', () {
        expect(() => parseHttpDate('Sunday, 6-November-94 08:49:37 GMT'),
            throwsFormatException);
      });

      test('only allows GMT', () {
        expect(() => parseHttpDate('Sunday, 6-Nov-94 08:49:37 PST'),
            throwsFormatException);
      });

      test('disallows trailing whitespace', () {
        expect(() => parseHttpDate('Sunday, 6-Nov-94 08:49:37 GMT '),
            throwsFormatException);
      });
    });

    group('asctime()', () {
      test('parses the example date', () {
        final date = parseHttpDate('Sun Nov  6 08:49:37 1994');
        expect(date.day, equals(6));
        expect(date.month, equals(DateTime.november));
        expect(date.year, equals(1994));
        expect(date.hour, equals(8));
        expect(date.minute, equals(49));
        expect(date.second, equals(37));
        expect(date.timeZoneName, equals('UTC'));
      });

      test('parses a date with a two-digit day', () {
        final date = parseHttpDate('Sun Nov 16 08:49:37 1994');
        expect(date.day, equals(16));
        expect(date.month, equals(DateTime.november));
        expect(date.year, equals(1994));
        expect(date.hour, equals(8));
        expect(date.minute, equals(49));
        expect(date.second, equals(37));
        expect(date.timeZoneName, equals('UTC'));
      });

      test('whitespace is required', () {
        expect(() => parseHttpDate('SunNov  6 08:49:37 1994'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun Nov6 08:49:37 1994'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun Nov  608:49:37 1994'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun Nov  6 08:49:371994'),
            throwsFormatException);
      });

      test('the right amount of whitespace is required', () {
        expect(() => parseHttpDate('Sun  Nov  6 08:49:37 1994'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun Nov   6 08:49:37 1994'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun Nov 6 08:49:37 1994'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun Nov  6  08:49:37 1994'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun Nov  6 08:49:37  1994'),
            throwsFormatException);
      });

      test('requires precise number lengths', () {
        expect(() => parseHttpDate('Sun Nov 016 08:49:37 1994'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun Nov  6 8:49:37 1994'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun Nov  6 08:9:37 1994'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun Nov  6 08:49:7 1994'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun Nov  6 08:49:37 94'),
            throwsFormatException);
      });

      test('requires reasonable numbers', () {
        expect(() => parseHttpDate('Sun Nov 0 08:49:37 1994'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun Nov 31 08:49:37 1994'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun Aug 32 08:49:37 1994'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun Nov  6 24:49:37 1994'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun Nov  6 08:60:37 1994'),
            throwsFormatException);

        expect(() => parseHttpDate('Sun Nov  6 08:49:60 1994'),
            throwsFormatException);
      });

      test('only allows short weekday names', () {
        expect(() => parseHttpDate('Sunday Nov 0 08:49:37 1994'),
            throwsFormatException);
      });

      test('only allows short month names', () {
        expect(() => parseHttpDate('Sun November 0 08:49:37 1994'),
            throwsFormatException);
      });

      test('disallows trailing whitespace', () {
        expect(() => parseHttpDate('Sun November 0 08:49:37 1994 '),
            throwsFormatException);
      });
    });
  });
}
