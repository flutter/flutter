// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:convert/src/fixed_datetime_formatter.dart';
import 'package:test/test.dart';

void main() {
  var noFractionalSeconds = DateTime.utc(0);
  var skipWeb = <String, Skip>{
    'js': const Skip(
        'Web does not support microseconds (see https://github.com/dart-lang/sdk/issues/44876)')
  };
  // Testing `decode`.
  test('Parse only year', () {
    var time = FixedDateTimeFormatter('YYYY').decode('1996');
    expect(time, DateTime.utc(1996));
  });
  test('Escaped chars are ignored', () {
    var time = FixedDateTimeFormatter('YYYY kiwi MM').decode('1996 rnad 01');
    expect(time, DateTime.utc(1996));
  });
  test('Parse two years throws', () {
    expect(() => FixedDateTimeFormatter('YYYY YYYY'), throwsException);
  });
  test('Parse year and century', () {
    var time = FixedDateTimeFormatter('CCYY').decode('1996');
    expect(time, DateTime.utc(1996));
  });
  test('Parse year, decade and century', () {
    var time = FixedDateTimeFormatter('CCEY').decode('1996');
    expect(time, DateTime.utc(1996));
  });
  test('Parse year, century, month', () {
    var time = FixedDateTimeFormatter('CCYY MM').decode('1996 04');
    expect(time, DateTime.utc(1996, 4));
  });
  test('Parse year, century, month, day', () {
    var time = FixedDateTimeFormatter('CCYY MM-DD').decode('1996 04-25');
    expect(time, DateTime.utc(1996, 4, 25));
  });
  test('Parse year, century, month, day, hour, minute, second', () {
    var time = FixedDateTimeFormatter('CCYY MM-DD hh:mm:ss')
        .decode('1996 04-25 05:03:22');
    expect(time, DateTime.utc(1996, 4, 25, 5, 3, 22));
  });
  test('Parse YYYYMMDDhhmmssSSS', () {
    var time =
        FixedDateTimeFormatter('YYYYMMDDhhmmssSSS').decode('19960425050322533');
    expect(time, DateTime.utc(1996, 4, 25, 5, 3, 22, 533));
  });
  test('Parse S 1/10 of a second', () {
    var time = FixedDateTimeFormatter('S').decode('1');
    expect(time, noFractionalSeconds.add(const Duration(milliseconds: 100)));
  });
  test('Parse SS 1/100 of a second', () {
    var time = FixedDateTimeFormatter('SS').decode('01');
    expect(time, noFractionalSeconds.add(const Duration(milliseconds: 10)));
  });
  test('Parse SSS a millisecond', () {
    var time = FixedDateTimeFormatter('SSS').decode('001');
    expect(time, noFractionalSeconds.add(const Duration(milliseconds: 1)));
  });
  test('Parse SSSSSS a microsecond', () {
    var time = FixedDateTimeFormatter('SSSSSS').decode('000001');
    expect(time, noFractionalSeconds.add(const Duration(microseconds: 1)));
  }, onPlatform: skipWeb);
  test('Parse SSSSSS a millisecond', () {
    var time = FixedDateTimeFormatter('SSSSSS').decode('001000');
    expect(time, noFractionalSeconds.add(const Duration(milliseconds: 1)));
  });
  test('Parse SSSSSS a millisecond and a microsecond', () {
    var time = FixedDateTimeFormatter('SSSSSS').decode('001001');
    expect(
        time,
        noFractionalSeconds.add(const Duration(
          milliseconds: 1,
          microseconds: 1,
        )));
  }, onPlatform: skipWeb);
  test('Parse ssSSSSSS a second and a microsecond', () {
    var time = FixedDateTimeFormatter('ssSSSSSS').decode('01000001');
    expect(
        time,
        noFractionalSeconds.add(const Duration(
          seconds: 1,
          microseconds: 1,
        )));
  }, onPlatform: skipWeb);
  test('7 S throws', () {
    expect(
      () => FixedDateTimeFormatter('S' * 7),
      throwsFormatException,
    );
  });
  test('10 Y throws', () {
    expect(
      () => FixedDateTimeFormatter('Y' * 10),
      throwsFormatException,
    );
  });
  test('Parse hex year throws', () {
    expect(
      () => FixedDateTimeFormatter('YYYY').decode('0xAB'),
      throwsFormatException,
    );
  });
  // Testing `tryDecode`.
  test('Try parse year', () {
    var time = FixedDateTimeFormatter('YYYY').tryDecode('1996');
    expect(time, DateTime.utc(1996));
  });
  test('Try parse hex year returns null', () {
    var time = FixedDateTimeFormatter('YYYY').tryDecode('0xAB');
    expect(time, null);
  });
  test('Try parse invalid returns null', () {
    var time = FixedDateTimeFormatter('YYYY').tryDecode('1x96');
    expect(time, null);
  });
  // Testing `encode`.
  test('Format simple', () {
    var time = DateTime.utc(1996);
    expect(FixedDateTimeFormatter('YYYY kiwi MM').encode(time), '1996 kiwi 01');
  });
  test('Format YYYYMMDDhhmmss', () {
    var time = DateTime.utc(1996, 4, 25, 5, 3, 22);
    expect(
      FixedDateTimeFormatter('YYYYMMDDhhmmss').encode(time),
      '19960425050322',
    );
  });
  test('Format CCEY-MM', () {
    var str = FixedDateTimeFormatter('CCEY-MM').encode(DateTime.utc(1996, 4));
    expect(str, '1996-04');
  });
  test('Format XCCEY-MMX', () {
    var str = FixedDateTimeFormatter('XCCEY-MMX').encode(DateTime.utc(1996, 4));
    expect(str, 'X1996-04X');
  });
  test('Format S 1/10 of a second', () {
    var str = FixedDateTimeFormatter('S')
        .encode(noFractionalSeconds.add(const Duration(milliseconds: 100)));
    expect(str, '1');
  });
  test('Format SS 1/100 of a second', () {
    var str = FixedDateTimeFormatter('SS')
        .encode(noFractionalSeconds.add(const Duration(milliseconds: 10)));
    expect(str, '01');
  });
  test('Format SSS 1/100 of a second', () {
    var str = FixedDateTimeFormatter('SSS')
        .encode(noFractionalSeconds.add(const Duration(milliseconds: 10)));
    expect(str, '010');
  });
  test('Format SSSS no fractions', () {
    var str = FixedDateTimeFormatter('SSSS').encode(noFractionalSeconds);
    expect(str, '0000');
  });
  test('Format SSSSSS no fractions', () {
    var str = FixedDateTimeFormatter('SSSSSS').encode(noFractionalSeconds);
    expect(str, '000000');
  });
  test('Format SSSS 1/10 of a second', () {
    var str = FixedDateTimeFormatter('SSSS')
        .encode(noFractionalSeconds.add(const Duration(milliseconds: 100)));
    expect(str, '1000');
  });
  test('Format SSSS 1/100 of a second', () {
    var str = FixedDateTimeFormatter('SSSS')
        .encode(noFractionalSeconds.add(const Duration(milliseconds: 10)));
    expect(str, '0100');
  });
  test('Format SSSS a millisecond', () {
    var str = FixedDateTimeFormatter('SSSS')
        .encode(noFractionalSeconds.add(const Duration(milliseconds: 1)));
    expect(str, '0010');
  });
  test('Format SSSSSS a microsecond', () {
    var str = FixedDateTimeFormatter('SSSSSS')
        .encode(DateTime.utc(0, 1, 1, 0, 0, 0, 0, 1));
    expect(str, '000001');
  }, onPlatform: skipWeb);
  test('Format SSSSSS a millisecond and a microsecond', () {
    var dateTime = noFractionalSeconds.add(const Duration(
      milliseconds: 1,
      microseconds: 1,
    ));
    var str = FixedDateTimeFormatter('SSSSSS').encode(dateTime);
    expect(str, '001001');
  }, onPlatform: skipWeb);
  test('Format SSSSSS0 a microsecond', () {
    var str = FixedDateTimeFormatter('SSSSSS0')
        .encode(noFractionalSeconds.add(const Duration(microseconds: 1)));
    expect(str, '0000010');
  }, onPlatform: skipWeb);
  test('Format SSSSSS0 1/10 of a second', () {
    var str = FixedDateTimeFormatter('SSSSSS0')
        .encode(noFractionalSeconds.add(const Duration(milliseconds: 100)));
    expect(str, '1000000');
  });
  test('Parse ssSSSSSS a second and a microsecond', () {
    var dateTime = noFractionalSeconds.add(const Duration(
      seconds: 1,
      microseconds: 1,
    ));
    var str = FixedDateTimeFormatter('ssSSSSSS').encode(dateTime);
    expect(str, '01000001');
  }, onPlatform: skipWeb);
  test('Parse ssSSSSSS0 a second and a microsecond', () {
    var dateTime = noFractionalSeconds.add(const Duration(
      seconds: 1,
      microseconds: 1,
    ));
    var str = FixedDateTimeFormatter('ssSSSSSS0').encode(dateTime);
    expect(str, '010000010');
  }, onPlatform: skipWeb);
  test('Parse negative year throws Error', () {
    expect(
      () => FixedDateTimeFormatter('YYYY').encode(DateTime(-1)),
      throwsArgumentError,
    );
  });
}
