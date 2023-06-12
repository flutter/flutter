// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// We permit local variable types in this test because they statically 'assert'
// that the operations have an expected type.
//
// ignore_for_file: omit_local_variable_types

library int64test;

import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

import 'test_shared.dart';

void main() {
  group('fromBytes', () {
    test('fromBytes', () {
      void checkBytes(List<int> bytes, int h, int l) {
        expect(Int64.fromBytes(bytes), Int64.fromInts(h, l));
      }

      checkBytes([0, 0, 0, 0, 0, 0, 0, 0], 0, 0);
      checkBytes([1, 0, 0, 0, 0, 0, 0, 0], 0, 1);
      checkBytes([1, 2, 3, 4, 5, 6, 7, 8], 0x08070605, 0x04030201);
      checkBytes([0xfe, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff], 0xffffffff,
          0xfffffffe);
      checkBytes([0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff], 0xffffffff,
          0xffffffff);
    });
    test('fromBytesBigEndian', () {
      void checkBytes(List<int> bytes, int h, int l) {
        expect(Int64.fromBytesBigEndian(bytes), Int64.fromInts(h, l));
      }

      checkBytes([0, 0, 0, 0, 0, 0, 0, 0], 0, 0);
      checkBytes([0, 0, 0, 0, 0, 0, 0, 1], 0, 1);
      checkBytes([8, 7, 6, 5, 4, 3, 2, 1], 0x08070605, 0x04030201);
      checkBytes([0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe], 0xffffffff,
          0xfffffffe);
      checkBytes([0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff], 0xffffffff,
          0xffffffff);
    });
  });

  void argumentErrorTest(
    Object Function(Int64, Object) op, [
    Int64 receiver = Int64.ONE,
  ]) {
    expect(
      () => op(receiver, 'foo'),
      throwsA(
        isA<ArgumentError>()
            .having((p0) => p0.toString(), 'toString', contains('"foo"')),
      ),
    );
  }

  group('is-tests', () {
    test('isEven', () {
      expect((-Int64.ONE).isEven, false);
      expect(Int64.ZERO.isEven, true);
      expect(Int64.ONE.isEven, false);
      expect(Int64.TWO.isEven, true);
    });
    test('isMaxValue', () {
      expect(Int64.MIN_VALUE.isMaxValue, false);
      expect(Int64.ZERO.isMaxValue, false);
      expect(Int64.MAX_VALUE.isMaxValue, true);
    });
    test('isMinValue', () {
      expect(Int64.MIN_VALUE.isMinValue, true);
      expect(Int64.ZERO.isMinValue, false);
      expect(Int64.MAX_VALUE.isMinValue, false);
    });
    test('isNegative', () {
      expect(Int64.MIN_VALUE.isNegative, true);
      expect(Int64.ZERO.isNegative, false);
      expect(Int64.ONE.isNegative, false);
    });
    test('isOdd', () {
      expect((-Int64.ONE).isOdd, true);
      expect(Int64.ZERO.isOdd, false);
      expect(Int64.ONE.isOdd, true);
      expect(Int64.TWO.isOdd, false);
    });
    test('isZero', () {
      expect(Int64.MIN_VALUE.isZero, false);
      expect(Int64.ZERO.isZero, true);
      expect(Int64.MAX_VALUE.isZero, false);
    });
    test('bitLength', () {
      expect(Int64(-2).bitLength, 1);
      expect((-Int64.ONE).bitLength, 0);
      expect(Int64.ZERO.bitLength, 0);
      expect((Int64.ONE << 21).bitLength, 22);
      expect((Int64.ONE << 22).bitLength, 23);
      expect((Int64.ONE << 43).bitLength, 44);
      expect((Int64.ONE << 44).bitLength, 45);
      expect(Int64(2).bitLength, 2);
      expect(Int64.MAX_VALUE.bitLength, 63);
      expect(Int64.MIN_VALUE.bitLength, 63);
    });
  });

  group('arithmetic operators', () {
    Int64 n1 = Int64(1234);
    Int64 n2 = Int64(9876);
    Int64 n3 = Int64(-1234);
    Int64 n4 = Int64(-9876);
    Int64 n5 = Int64.fromInts(0x12345678, 0xabcdabcd);
    Int64 n6 = Int64.fromInts(0x77773333, 0x22224444);

    test('+', () {
      expect(n1 + n2, Int64(11110));
      expect(n3 + n2, Int64(8642));
      expect(n3 + n4, Int64(-11110));
      expect(n5 + n6, Int64.fromInts(0x89ab89ab, 0xcdeff011));
      expect(Int64.MAX_VALUE + 1, Int64.MIN_VALUE);
      argumentErrorTest((a, b) => a + b);
    });

    test('-', () {
      expect(n1 - n2, Int64(-8642));
      expect(n3 - n2, Int64(-11110));
      expect(n3 - n4, Int64(8642));
      expect(n5 - n6, Int64.fromInts(0x9abd2345, 0x89ab6789));
      expect(Int64.MIN_VALUE - 1, Int64.MAX_VALUE);
      argumentErrorTest((a, b) => a - b);
    });

    test('unary -', () {
      expect(-n1, Int64(-1234));
      expect(-Int64.ZERO, Int64.ZERO);
    });

    test('*', () {
      expect(Int64(1111) * Int64(3), Int64(3333));
      expect(Int64(1111) * Int64(-3), Int64(-3333));
      expect(Int64(-1111) * Int64(3), Int64(-3333));
      expect(Int64(-1111) * Int64(-3), Int64(3333));
      expect(Int64(100) * Int64.ZERO, Int64.ZERO);

      expect(
          Int64.fromInts(0x12345678, 0x12345678) *
              Int64.fromInts(0x1234, 0x12345678),
          Int64.fromInts(0x7ff63f7c, 0x1df4d840));
      expect(
          Int64.fromInts(0xf2345678, 0x12345678) *
              Int64.fromInts(0x1234, 0x12345678),
          Int64.fromInts(0x7ff63f7c, 0x1df4d840));
      expect(
          Int64.fromInts(0xf2345678, 0x12345678) *
              Int64.fromInts(0xffff1234, 0x12345678),
          Int64.fromInts(0x297e3f7c, 0x1df4d840));

      // RHS Int32
      expect(Int64(123456789) * Int32(987654321),
          Int64.fromInts(0x1b13114, 0xfbff5385));
      expect(Int64(123456789) * Int32(987654321),
          Int64.fromInts(0x1b13114, 0xfbff5385));

      // Wraparound
      expect(Int64(123456789) * Int64(987654321),
          Int64.fromInts(0x1b13114, 0xfbff5385));

      expect(Int64.MIN_VALUE * Int64(2), Int64.ZERO);
      expect(Int64.MIN_VALUE * Int64(1), Int64.MIN_VALUE);
      expect(Int64.MIN_VALUE * Int64(-1), Int64.MIN_VALUE);
      argumentErrorTest((a, b) => a * b);
    });

    test('~/', () {
      Int64 deadBeef = Int64.fromInts(0xDEADBEEF, 0xDEADBEEF);
      Int64 ten = Int64(10);

      expect(deadBeef ~/ ten, Int64.fromInts(0xfcaaf97e, 0x63115fe5));
      expect(Int64.ONE ~/ Int64.TWO, Int64.ZERO);
      expect(
          Int64.MAX_VALUE ~/ Int64.TWO, Int64.fromInts(0x3fffffff, 0xffffffff));
      expect(Int64.ZERO ~/ Int64(1000), Int64.ZERO);
      expect(Int64.MIN_VALUE ~/ Int64.MIN_VALUE, Int64.ONE);
      expect(Int64(1000) ~/ Int64.MIN_VALUE, Int64.ZERO);
      expect(Int64.MIN_VALUE ~/ Int64(8192), Int64(-1125899906842624));
      expect(Int64.MIN_VALUE ~/ Int64(8193), Int64(-1125762484664320));
      expect(Int64(-1000) ~/ Int64(8192), Int64.ZERO);
      expect(Int64(-1000) ~/ Int64(8193), Int64.ZERO);
      expect(Int64(-1000000000) ~/ Int64(8192), Int64(-122070));
      expect(Int64(-1000000000) ~/ Int64(8193), Int64(-122055));
      expect(Int64(1000000000) ~/ Int64(8192), Int64(122070));
      expect(Int64(1000000000) ~/ Int64(8193), Int64(122055));
      expect(Int64.MAX_VALUE ~/ Int64.fromInts(0x00000000, 0x00000400),
          Int64.fromInts(0x1fffff, 0xffffffff));
      expect(Int64.MAX_VALUE ~/ Int64.fromInts(0x00000000, 0x00040000),
          Int64.fromInts(0x1fff, 0xffffffff));
      expect(Int64.MAX_VALUE ~/ Int64.fromInts(0x00000000, 0x04000000),
          Int64.fromInts(0x1f, 0xffffffff));
      expect(Int64.MAX_VALUE ~/ Int64.fromInts(0x00000004, 0x00000000),
          Int64(536870911));
      expect(Int64.MAX_VALUE ~/ Int64.fromInts(0x00000400, 0x00000000),
          Int64(2097151));
      expect(Int64.MAX_VALUE ~/ Int64.fromInts(0x00040000, 0x00000000),
          Int64(8191));
      expect(
          Int64.MAX_VALUE ~/ Int64.fromInts(0x04000000, 0x00000000), Int64(31));
      expect(Int64.MAX_VALUE ~/ Int64.fromInts(0x00000000, 0x00000300),
          Int64.fromInts(0x2AAAAA, 0xAAAAAAAA));
      expect(Int64.MAX_VALUE ~/ Int64.fromInts(0x00000000, 0x30000000),
          Int64.fromInts(0x2, 0xAAAAAAAA));
      expect(Int64.MAX_VALUE ~/ Int64.fromInts(0x00300000, 0x00000000),
          Int64(0x2AA));
      expect(Int64.MAX_VALUE ~/ Int64(0x123456),
          Int64.fromInts(0x708, 0x002E9501));
      expect(Int64.MAX_VALUE % Int64(0x123456), Int64(0x3BDA9));
      expect(Int64(5) ~/ Int64(5), Int64.ONE);
      expect(Int64(1000) ~/ Int64(3), Int64(333));
      expect(Int64(1000) ~/ Int64(-3), Int64(-333));
      expect(Int64(-1000) ~/ Int64(3), Int64(-333));
      expect(Int64(-1000) ~/ Int64(-3), Int64(333));
      expect(Int64(3) ~/ Int64(1000), Int64.ZERO);
      expect(
          Int64.fromInts(0x12345678, 0x12345678) ~/ Int64.fromInts(0x0, 0x123),
          Int64.fromInts(0x1003d0, 0xe84f5ae8));
      expect(
          Int64.fromInts(0x12345678, 0x12345678) ~/
              Int64.fromInts(0x1234, 0x12345678),
          Int64.fromInts(0x0, 0x10003));
      expect(
          Int64.fromInts(0xf2345678, 0x12345678) ~/
              Int64.fromInts(0x1234, 0x12345678),
          Int64.fromInts(0xffffffff, 0xffff3dfe));
      expect(
          Int64.fromInts(0xf2345678, 0x12345678) ~/
              Int64.fromInts(0xffff1234, 0x12345678),
          Int64.fromInts(0x0, 0xeda));
      expect(Int64(829893893) ~/ Int32(1919), Int32(432461));
      expect(Int64(829893893) ~/ Int64(1919), Int32(432461));
      expect(Int64(829893893) ~/ 1919, Int32(432461));
      expect(() => Int64(1) ~/ Int64.ZERO,
          throwsA(isIntegerDivisionByZeroException));
      expect(
          Int64.MIN_VALUE ~/ Int64(2), Int64.fromInts(0xc0000000, 0x00000000));
      expect(Int64.MIN_VALUE ~/ Int64(1), Int64.MIN_VALUE);
      expect(Int64.MIN_VALUE ~/ Int64(-1), Int64.MIN_VALUE);
      expect(() => Int64(17) ~/ Int64.ZERO,
          throwsA(isIntegerDivisionByZeroException));
      argumentErrorTest((a, b) => a ~/ b);
    });

    test('%', () {
      // Define % as Euclidean mod, with positive result for all arguments
      expect(Int64.ZERO % Int64(1000), Int64.ZERO);
      expect(Int64.MIN_VALUE % Int64.MIN_VALUE, Int64.ZERO);
      expect(Int64(1000) % Int64.MIN_VALUE, Int64(1000));
      expect(Int64.MIN_VALUE % Int64(8192), Int64.ZERO);
      expect(Int64.MIN_VALUE % Int64(8193), Int64(6145));
      expect(Int64(-1000) % Int64(8192), Int64(7192));
      expect(Int64(-1000) % Int64(8193), Int64(7193));
      expect(Int64(-1000000000) % Int64(8192), Int64(5632));
      expect(Int64(-1000000000) % Int64(8193), Int64(4808));
      expect(Int64(1000000000) % Int64(8192), Int64(2560));
      expect(Int64(1000000000) % Int64(8193), Int64(3385));
      expect(Int64.MAX_VALUE % Int64.fromInts(0x00000000, 0x00000400),
          Int64.fromInts(0x0, 0x3ff));
      expect(Int64.MAX_VALUE % Int64.fromInts(0x00000000, 0x00040000),
          Int64.fromInts(0x0, 0x3ffff));
      expect(Int64.MAX_VALUE % Int64.fromInts(0x00000000, 0x04000000),
          Int64.fromInts(0x0, 0x3ffffff));
      expect(Int64.MAX_VALUE % Int64.fromInts(0x00000004, 0x00000000),
          Int64.fromInts(0x3, 0xffffffff));
      expect(Int64.MAX_VALUE % Int64.fromInts(0x00000400, 0x00000000),
          Int64.fromInts(0x3ff, 0xffffffff));
      expect(Int64.MAX_VALUE % Int64.fromInts(0x00040000, 0x00000000),
          Int64.fromInts(0x3ffff, 0xffffffff));
      expect(Int64.MAX_VALUE % Int64.fromInts(0x04000000, 0x00000000),
          Int64.fromInts(0x3ffffff, 0xffffffff));
      expect(Int64(0x12345678).remainder(Int64(0x22)),
          Int64(0x12345678.remainder(0x22)));
      expect(Int64(0x12345678).remainder(Int64(-0x22)),
          Int64(0x12345678.remainder(-0x22)));
      expect(Int64(-0x12345678).remainder(Int64(-0x22)),
          Int64(-0x12345678.remainder(-0x22)));
      expect(Int64(-0x12345678).remainder(Int64(0x22)),
          Int64(-0x12345678.remainder(0x22)));
      expect(Int32(0x12345678).remainder(Int64(0x22)),
          Int64(0x12345678.remainder(0x22)));
      argumentErrorTest((a, b) => a % b);
    });

    test('clamp', () {
      Int64 val = Int64(17);
      expect(val.clamp(20, 30), Int64(20));
      expect(val.clamp(10, 20), Int64(17));
      expect(val.clamp(10, 15), Int64(15));

      expect(val.clamp(Int32(20), Int32(30)), Int64(20));
      expect(val.clamp(Int32(10), Int32(20)), Int64(17));
      expect(val.clamp(Int32(10), Int32(15)), Int64(15));

      expect(val.clamp(Int64(20), Int64(30)), Int64(20));
      expect(val.clamp(Int64(10), Int64(20)), Int64(17));
      expect(val.clamp(Int64(10), Int64(15)), Int64(15));
      expect(val.clamp(Int64.MIN_VALUE, Int64(30)), Int64(17));
      expect(val.clamp(Int64(10), Int64.MAX_VALUE), Int64(17));

      expect(() => val.clamp(1, 'b'), throwsA(isArgumentError));
      expect(() => val.clamp('a', 1), throwsA(isArgumentError));
    });
  });

  group('leading/trailing zeros', () {
    test('numberOfLeadingZeros', () {
      void checkZeros(Int64 value, int zeros) {
        expect(value.numberOfLeadingZeros(), zeros);
      }

      checkZeros(Int64(0), 64);
      checkZeros(Int64(1), 63);
      checkZeros(Int64.fromInts(0x00000000, 0x003fffff), 42);
      checkZeros(Int64.fromInts(0x00000000, 0x00400000), 41);
      checkZeros(Int64.fromInts(0x00000fff, 0xffffffff), 20);
      checkZeros(Int64.fromInts(0x00001000, 0x00000000), 19);
      checkZeros(Int64.fromInts(0x7fffffff, 0xffffffff), 1);
      checkZeros(Int64(-1), 0);
    });

    test('numberOfTrailingZeros', () {
      void checkZeros(Int64 value, int zeros) {
        expect(value.numberOfTrailingZeros(), zeros);
      }

      checkZeros(Int64(-1), 0);
      checkZeros(Int64(1), 0);
      checkZeros(Int64(2), 1);
      checkZeros(Int64.fromInts(0x00000000, 0x00200000), 21);
      checkZeros(Int64.fromInts(0x00000000, 0x00400000), 22);
      checkZeros(Int64.fromInts(0x00000800, 0x00000000), 43);
      checkZeros(Int64.fromInts(0x00001000, 0x00000000), 44);
      checkZeros(Int64.fromInts(0x80000000, 0x00000000), 63);
      checkZeros(Int64(0), 64);
    });
  });

  group('comparison operators', () {
    Int64 largeNeg = Int64.fromInts(0x82341234, 0x0);
    Int64 largePos = Int64.fromInts(0x12341234, 0x0);
    Int64 largePosPlusOne = largePos + Int64(1);

    test('<', () {
      expect(Int64(10) < Int64(11), true);
      expect(Int64(10) < Int64(10), false);
      expect(Int64(10) < Int64(9), false);
      expect(Int64(10) < Int32(11), true);
      expect(Int64(10) < Int32(10), false);
      expect(Int64(10) < Int32(9), false);
      expect(Int64(-10) < Int64(-11), false);
      expect(Int64.MIN_VALUE < Int64.ZERO, true);
      expect(largeNeg < largePos, true);
      expect(largePos < largePosPlusOne, true);
      expect(largePos < largePos, false);
      expect(largePosPlusOne < largePos, false);
      expect(Int64.MIN_VALUE < Int64.MAX_VALUE, true);
      expect(Int64.MAX_VALUE < Int64.MIN_VALUE, false);
      argumentErrorTest((a, b) => a < b);
    });

    test('<=', () {
      expect(Int64(10) <= Int64(11), true);
      expect(Int64(10) <= Int64(10), true);
      expect(Int64(10) <= Int64(9), false);
      expect(Int64(10) <= Int32(11), true);
      expect(Int64(10) <= Int32(10), true);
      expect(Int64(10) <= Int64(9), false);
      expect(Int64(-10) <= Int64(-11), false);
      expect(Int64(-10) <= Int64(-10), true);
      expect(largeNeg <= largePos, true);
      expect(largePos <= largeNeg, false);
      expect(largePos <= largePosPlusOne, true);
      expect(largePos <= largePos, true);
      expect(largePosPlusOne <= largePos, false);
      expect(Int64.MIN_VALUE <= Int64.MAX_VALUE, true);
      expect(Int64.MAX_VALUE <= Int64.MIN_VALUE, false);
      argumentErrorTest((a, b) => a <= b);
    });

    test('==', () {
      expect(Int64(0), equals(Int64(0)));
      expect(Int64(0), isNot(equals(Int64(1))));
      expect(Int64(0), equals(Int32(0)));
      expect(Int64(0), isNot(equals(Int32(1))));
      expect(Int64(0) == 0, isTrue);
      expect(Int64(0), isNot(equals(1)));
      expect(Int64(10), isNot(equals(Int64(11))));
      expect(Int64(10), equals(Int64(10)));
      expect(Int64(10), isNot(equals(Int64(9))));
      expect(Int64(10), isNot(equals(Int32(11))));
      expect(Int64(10), equals(Int32(10)));
      expect(Int64(10), isNot(equals(Int32(9))));
      expect(Int64(10), isNot(equals(11)));
      expect(Int64(10) == 10, isTrue);
      expect(Int64(10), isNot(equals(9)));
      expect(Int64(-10), equals(Int64(-10)));
      expect(Int64(-10) != Int64(-10), false);
      expect(Int64(-10) == -10, isTrue);
      expect(Int64(-10), isNot(equals(-9)));
      expect(largePos, equals(largePos));
      expect(largePos, isNot(equals(largePosPlusOne)));
      expect(largePosPlusOne, isNot(equals(largePos)));
      expect(Int64.MIN_VALUE, isNot(equals(Int64.MAX_VALUE)));
      expect(Int64(17), isNot(equals(Object())));
      expect(Int64(17), isNot(equals(null)));
    });

    test('>=', () {
      expect(Int64(10) >= Int64(11), false);
      expect(Int64(10) >= Int64(10), true);
      expect(Int64(10) >= Int64(9), true);
      expect(Int64(10) >= Int32(11), false);
      expect(Int64(10) >= Int32(10), true);
      expect(Int64(10) >= Int32(9), true);
      expect(Int64(-10) >= Int64(-11), true);
      expect(Int64(-10) >= Int64(-10), true);
      expect(largePos >= largeNeg, true);
      expect(largeNeg >= largePos, false);
      expect(largePos >= largePosPlusOne, false);
      expect(largePos >= largePos, true);
      expect(largePosPlusOne >= largePos, true);
      expect(Int64.MIN_VALUE >= Int64.MAX_VALUE, false);
      expect(Int64.MAX_VALUE >= Int64.MIN_VALUE, true);
      argumentErrorTest((a, b) => a >= b);
    });

    test('>', () {
      expect(Int64(10) > Int64(11), false);
      expect(Int64(10) > Int64(10), false);
      expect(Int64(10) > Int64(9), true);
      expect(Int64(10) > Int32(11), false);
      expect(Int64(10) > Int32(10), false);
      expect(Int64(10) > Int32(9), true);
      expect(Int64(-10) > Int64(-11), true);
      expect(Int64(10) > Int64(-11), true);
      expect(Int64(-10) > Int64(11), false);
      expect(largePos > largeNeg, true);
      expect(largeNeg > largePos, false);
      expect(largePos > largePosPlusOne, false);
      expect(largePos > largePos, false);
      expect(largePosPlusOne > largePos, true);
      expect(Int64.ZERO > Int64.MIN_VALUE, true);
      expect(Int64.MIN_VALUE > Int64.MAX_VALUE, false);
      expect(Int64.MAX_VALUE > Int64.MIN_VALUE, true);
      argumentErrorTest((a, b) => a > b);
    });
  });

  group('bitwise operators', () {
    Int64 n1 = Int64(1234);
    Int64 n2 = Int64(9876);
    Int64 n3 = Int64(-1234);
    Int64 n4 = Int64(0x1234) << 32;
    Int64 n5 = Int64(0x9876) << 32;

    test('&', () {
      expect(n1 & n2, Int64(1168));
      expect(n3 & n2, Int64(8708));
      expect(n4 & n5, Int64(0x1034) << 32);
      argumentErrorTest((a, b) => a & b);
    });

    test('|', () {
      expect(n1 | n2, Int64(9942));
      expect(n3 | n2, Int64(-66));
      expect(n4 | n5, Int64(0x9a76) << 32);
      argumentErrorTest((a, b) => a | b);
    });

    test('^', () {
      expect(n1 ^ n2, Int64(8774));
      expect(n3 ^ n2, Int64(-8774));
      expect(n4 ^ n5, Int64(0x8a42) << 32);
      argumentErrorTest((a, b) => a ^ b);
    });

    test('~', () {
      expect(-Int64(1), Int64(-1));
      expect(-Int64(-1), Int64(1));
      expect(-Int64.MIN_VALUE, Int64.MIN_VALUE);

      expect(~n1, Int64(-1235));
      expect(~n2, Int64(-9877));
      expect(~n3, Int64(1233));
      expect(~n4, Int64.fromInts(0xffffedcb, 0xffffffff));
      expect(~n5, Int64.fromInts(0xffff6789, 0xffffffff));
    });
  });

  group('bitshift operators', () {
    test('<<', () {
      expect(Int64.fromInts(0x12341234, 0x45674567) << 10,
          Int64.fromInts(0xd048d115, 0x9d159c00));
      expect(Int64.fromInts(0x92341234, 0x45674567) << 10,
          Int64.fromInts(0xd048d115, 0x9d159c00));
      expect(Int64(-1) << 5, Int64(-32));
      expect(Int64(-1) << 0, Int64(-1));
      expect(Int64(42) << 64, Int64.ZERO);
      expect(Int64(42) << 65, Int64.ZERO);
      expect(() => Int64(17) << -1, throwsArgumentError);
    });

    test('>>', () {
      expect((Int64.MIN_VALUE >> 13).toString(), '-1125899906842624');
      expect(Int64.fromInts(0x12341234, 0x45674567) >> 10,
          Int64.fromInts(0x48d04, 0x8d1159d1));
      expect(Int64.fromInts(0x92341234, 0x45674567) >> 10,
          Int64.fromInts(0xffe48d04, 0x8d1159d1));
      expect(Int64.fromInts(0xFFFFFFF, 0xFFFFFFFF) >> 34, Int64(67108863));
      expect(Int64(42) >> 64, Int64.ZERO);
      expect(Int64(42) >> 65, Int64.ZERO);
      for (int n = 0; n <= 66; n++) {
        expect(Int64(-1) >> n, Int64(-1));
      }
      expect(Int64.fromInts(0x72345678, 0x9abcdef0) >> 8,
          Int64.fromInts(0x00723456, 0x789abcde));
      expect(Int64.fromInts(0x72345678, 0x9abcdef0) >> 16,
          Int64.fromInts(0x00007234, 0x56789abc));
      expect(Int64.fromInts(0x72345678, 0x9abcdef0) >> 24,
          Int64.fromInts(0x00000072, 0x3456789a));
      expect(Int64.fromInts(0x72345678, 0x9abcdef0) >> 28,
          Int64.fromInts(0x00000007, 0x23456789));
      expect(Int64.fromInts(0x72345678, 0x9abcdef0) >> 32,
          Int64.fromInts(0x00000000, 0x72345678));
      expect(Int64.fromInts(0x72345678, 0x9abcdef0) >> 36,
          Int64.fromInts(0x00000000, 0x07234567));
      expect(Int64.fromInts(0x72345678, 0x9abcdef0) >> 40,
          Int64.fromInts(0x00000000, 0x00723456));
      expect(Int64.fromInts(0x72345678, 0x9abcde00) >> 44,
          Int64.fromInts(0x00000000, 0x00072345));
      expect(Int64.fromInts(0x72345678, 0x9abcdef0) >> 48,
          Int64.fromInts(0x00000000, 0x00007234));
      expect(Int64.fromInts(0x92345678, 0x9abcdef0) >> 8,
          Int64.fromInts(0xff923456, 0x789abcde));
      expect(Int64.fromInts(0x92345678, 0x9abcdef0) >> 16,
          Int64.fromInts(0xffff9234, 0x56789abc));
      expect(Int64.fromInts(0x92345678, 0x9abcdef0) >> 24,
          Int64.fromInts(0xffffff92, 0x3456789a));
      expect(Int64.fromInts(0x92345678, 0x9abcdef0) >> 28,
          Int64.fromInts(0xfffffff9, 0x23456789));
      expect(Int64.fromInts(0x92345678, 0x9abcdef0) >> 32,
          Int64.fromInts(0xffffffff, 0x92345678));
      expect(Int64.fromInts(0x92345678, 0x9abcdef0) >> 36,
          Int64.fromInts(0xffffffff, 0xf9234567));
      expect(Int64.fromInts(0x92345678, 0x9abcdef0) >> 40,
          Int64.fromInts(0xffffffff, 0xff923456));
      expect(Int64.fromInts(0x92345678, 0x9abcdef0) >> 44,
          Int64.fromInts(0xffffffff, 0xfff92345));
      expect(Int64.fromInts(0x92345678, 0x9abcdef0) >> 48,
          Int64.fromInts(0xffffffff, 0xffff9234));
      expect(() => Int64(17) >> -1, throwsArgumentError);
    });

    test('shiftRightUnsigned', () {
      expect(Int64.fromInts(0x12341234, 0x45674567).shiftRightUnsigned(10),
          Int64.fromInts(0x48d04, 0x8d1159d1));
      expect(Int64.fromInts(0x92341234, 0x45674567).shiftRightUnsigned(10),
          Int64.fromInts(0x248d04, 0x8d1159d1));
      expect(Int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(8),
          Int64.fromInts(0x00723456, 0x789abcde));
      expect(Int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(16),
          Int64.fromInts(0x00007234, 0x56789abc));
      expect(Int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(24),
          Int64.fromInts(0x00000072, 0x3456789a));
      expect(Int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(28),
          Int64.fromInts(0x00000007, 0x23456789));
      expect(Int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(32),
          Int64.fromInts(0x00000000, 0x72345678));
      expect(Int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(36),
          Int64.fromInts(0x00000000, 0x07234567));
      expect(Int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(40),
          Int64.fromInts(0x00000000, 0x00723456));
      expect(Int64.fromInts(0x72345678, 0x9abcde00).shiftRightUnsigned(44),
          Int64.fromInts(0x00000000, 0x00072345));
      expect(Int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(48),
          Int64.fromInts(0x00000000, 0x00007234));
      expect(Int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(8),
          Int64.fromInts(0x00923456, 0x789abcde));
      expect(Int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(16),
          Int64.fromInts(0x00009234, 0x56789abc));
      expect(Int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(24),
          Int64.fromInts(0x00000092, 0x3456789a));
      expect(Int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(28),
          Int64.fromInts(0x00000009, 0x23456789));
      expect(Int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(32),
          Int64.fromInts(0x00000000, 0x92345678));
      expect(Int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(36),
          Int64.fromInts(0x00000000, 0x09234567));
      expect(Int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(40),
          Int64.fromInts(0x00000000, 0x00923456));
      expect(Int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(44),
          Int64.fromInts(0x00000000, 0x00092345));
      expect(Int64.fromInts(0x00000000, 0x00009234),
          Int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(48));
      expect(Int64(-1).shiftRightUnsigned(64), Int64.ZERO);
      expect(Int64(1).shiftRightUnsigned(64), Int64.ZERO);
      expect(() => Int64(17).shiftRightUnsigned(-1), throwsArgumentError);
    });

    test('overflow', () {
      expect((Int64(1) << 63) >> 1, -Int64.fromInts(0x40000000, 0x00000000));
      expect((Int64(-1) << 32) << 32, Int64(0));
      expect(Int64.MIN_VALUE << 0, Int64.MIN_VALUE);
      expect(Int64.MIN_VALUE << 1, Int64(0));
      expect(
          (-Int64.fromInts(8, 0)) >> 1, Int64.fromInts(0xfffffffc, 0x00000000));
      expect((-Int64.fromInts(8, 0)).shiftRightUnsigned(1),
          Int64.fromInts(0x7ffffffc, 0x0));
    });
  });

  group('conversions', () {
    test('toSigned', () {
      expect((Int64.ONE << 44).toSigned(46), Int64.ONE << 44);
      expect((Int64.ONE << 44).toSigned(45), -(Int64.ONE << 44));
      expect((Int64.ONE << 22).toSigned(24), Int64.ONE << 22);
      expect((Int64.ONE << 22).toSigned(23), -(Int64.ONE << 22));
      expect(Int64.ONE.toSigned(2), Int64.ONE);
      expect(Int64.ONE.toSigned(1), -Int64.ONE);
      expect(Int64.MAX_VALUE.toSigned(64), Int64.MAX_VALUE);
      expect(Int64.MIN_VALUE.toSigned(64), Int64.MIN_VALUE);
      expect(Int64.MAX_VALUE.toSigned(63), -Int64.ONE);
      expect(Int64.MIN_VALUE.toSigned(63), Int64.ZERO);
      expect(() => Int64.ONE.toSigned(0), throwsRangeError);
      expect(() => Int64.ONE.toSigned(65), throwsRangeError);
    });
    test('toUnsigned', () {
      expect((Int64.ONE << 44).toUnsigned(45), Int64.ONE << 44);
      expect((Int64.ONE << 44).toUnsigned(44), Int64.ZERO);
      expect((Int64.ONE << 22).toUnsigned(23), Int64.ONE << 22);
      expect((Int64.ONE << 22).toUnsigned(22), Int64.ZERO);
      expect(Int64.ONE.toUnsigned(1), Int64.ONE);
      expect(Int64.ONE.toUnsigned(0), Int64.ZERO);
      expect(Int64.MAX_VALUE.toUnsigned(64), Int64.MAX_VALUE);
      expect(Int64.MIN_VALUE.toUnsigned(64), Int64.MIN_VALUE);
      expect(Int64.MAX_VALUE.toUnsigned(63), Int64.MAX_VALUE);
      expect(Int64.MIN_VALUE.toUnsigned(63), Int64.ZERO);
      expect(() => Int64.ONE.toUnsigned(-1), throwsRangeError);
      expect(() => Int64.ONE.toUnsigned(65), throwsRangeError);
    });
    test('toDouble', () {
      expect(Int64(0).toDouble(), same(0.0));
      expect(Int64(100).toDouble(), same(100.0));
      expect(Int64(-100).toDouble(), same(-100.0));
      expect(Int64(2147483647).toDouble(), same(2147483647.0));
      expect(Int64(2147483648).toDouble(), same(2147483648.0));
      expect(Int64(-2147483647).toDouble(), same(-2147483647.0));
      expect(Int64(-2147483648).toDouble(), same(-2147483648.0));
      expect(Int64(4503599627370495).toDouble(), same(4503599627370495.0));
      expect(Int64(4503599627370496).toDouble(), same(4503599627370496.0));
      expect(Int64(-4503599627370495).toDouble(), same(-4503599627370495.0));
      expect(Int64(-4503599627370496).toDouble(), same(-4503599627370496.0));
      expect(Int64.parseInt('-10000000000000000').toDouble().toStringAsFixed(1),
          '-10000000000000000.0');
      expect(Int64.parseInt('-10000000000000001').toDouble().toStringAsFixed(1),
          '-10000000000000000.0');
      expect(Int64.parseInt('-10000000000000002').toDouble().toStringAsFixed(1),
          '-10000000000000002.0');
      expect(Int64.parseInt('-10000000000000003').toDouble().toStringAsFixed(1),
          '-10000000000000004.0');
      expect(Int64.parseInt('-10000000000000004').toDouble().toStringAsFixed(1),
          '-10000000000000004.0');
      expect(Int64.parseInt('-10000000000000005').toDouble().toStringAsFixed(1),
          '-10000000000000004.0');
      expect(Int64.parseInt('-10000000000000006').toDouble().toStringAsFixed(1),
          '-10000000000000006.0');
      expect(Int64.parseInt('-10000000000000007').toDouble().toStringAsFixed(1),
          '-10000000000000008.0');
      expect(Int64.parseInt('-10000000000000008').toDouble().toStringAsFixed(1),
          '-10000000000000008.0');
    });

    test('toInt', () {
      expect(Int64(0).toInt(), 0);
      expect(Int64(100).toInt(), 100);
      expect(Int64(-100).toInt(), -100);
      expect(Int64(2147483647).toInt(), 2147483647);
      expect(Int64(2147483648).toInt(), 2147483648);
      expect(Int64(-2147483647).toInt(), -2147483647);
      expect(Int64(-2147483648).toInt(), -2147483648);
      expect(Int64(4503599627370495).toInt(), 4503599627370495);
      expect(Int64(4503599627370496).toInt(), 4503599627370496);
      expect(Int64(-4503599627370495).toInt(), -4503599627370495);
      expect(Int64(-4503599627370496).toInt(), -4503599627370496);
    });

    test('toInt32', () {
      expect(Int64(0).toInt32(), Int32(0));
      expect(Int64(1).toInt32(), Int32(1));
      expect(Int64(-1).toInt32(), Int32(-1));
      expect(Int64(2147483647).toInt32(), Int32(2147483647));
      expect(Int64(2147483648).toInt32(), Int32(-2147483648));
      expect(Int64(2147483649).toInt32(), Int32(-2147483647));
      expect(Int64(2147483650).toInt32(), Int32(-2147483646));
      expect(Int64(-2147483648).toInt32(), Int32(-2147483648));
      expect(Int64(-2147483649).toInt32(), Int32(2147483647));
      expect(Int64(-2147483650).toInt32(), Int32(2147483646));
      expect(Int64(-2147483651).toInt32(), Int32(2147483645));
    });

    test('toBytes', () {
      expect(Int64(0).toBytes(), [0, 0, 0, 0, 0, 0, 0, 0]);
      expect(Int64.fromInts(0x08070605, 0x04030201).toBytes(),
          [1, 2, 3, 4, 5, 6, 7, 8]);
      expect(Int64.fromInts(0x01020304, 0x05060708).toBytes(),
          [8, 7, 6, 5, 4, 3, 2, 1]);
      expect(Int64(-1).toBytes(),
          [0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]);
    });
  });

  test('JavaScript 53-bit integer boundary', () {
    Int64 _factorial(Int64 n) {
      if (n.isZero) {
        return Int64(1);
      } else {
        return n * _factorial(n - Int64(1));
      }
    }

    Int64 fact18 = _factorial(Int64(18));
    Int64 fact17 = _factorial(Int64(17));
    expect(fact18 ~/ fact17, Int64(18));
  });

  test('min, max values', () {
    expect(Int64(1) << 63, Int64.MIN_VALUE);
    expect(-(Int64.MIN_VALUE + Int64(1)), Int64.MAX_VALUE);
  });

  test('negation', () {
    void check(int n) {
      // Sign change should commute with conversion.
      expect(-Int64(-n), Int64(n));
      expect(Int64(-n), -Int64(n));
    }

    check(10);
    check(1000000000000000000);
    check(9223372000000000000); // near Int64.MAX_VALUE, has exact double value
  });

  group('parse', () {
    test('parseRadix10', () {
      void checkInt(int x) {
        expect(Int64.parseRadix('$x', 10), Int64(x));
      }

      checkInt(0);
      checkInt(1);
      checkInt(-1);
      checkInt(1000);
      checkInt(12345678);
      checkInt(-12345678);
      checkInt(2147483647);
      checkInt(2147483648);
      checkInt(-2147483647);
      checkInt(-2147483648);
      checkInt(4294967295);
      checkInt(4294967296);
      checkInt(-4294967295);
      checkInt(-4294967296);
      expect(() => Int64.parseRadix('xyzzy', -1), throwsArgumentError);
      expect(() => Int64.parseRadix('plugh', 10), throwsFormatException);
      expect(() => Int64.parseRadix('', 10), throwsFormatException);
      expect(() => Int64.parseRadix('-', 10), throwsFormatException);
    });

    test('parseHex', () {
      void checkHex(String hexStr, int h, int l) {
        expect(Int64.parseHex(hexStr), Int64.fromInts(h, l));
      }

      checkHex('0', 0, 0);
      checkHex('-0', 0, 0);
      checkHex('00', 0, 0);
      checkHex('01', 0, 1);
      checkHex('-01', 0xffffffff, 0xffffffff);
      checkHex('0a', 0, 10);
      checkHex('0A', 0, 10);
      checkHex('10', 0, 16);
      checkHex('3FFFFF', 0, 0x3fffff);
      checkHex('400000', 0, 0x400000);
      checkHex('FFFFFFFFFFF', 0xfff, 0xffffffff);
      checkHex('FFFFFFFFFFFFFFFE', 0xffffffff, 0xfffffffe);
      checkHex('FFFFFFFFFFFFFFFF', 0xffffffff, 0xffffffff);
      expect(() => Int64.parseHex(''), throwsFormatException);
      expect(() => Int64.parseHex('-'), throwsFormatException);
    });

    test('parseRadix', () {
      void check(String s, int r, String x) {
        expect(Int64.parseRadix(s, r).toString(), x);
      }

      check('ghoul', 36, '27699213');
      check('ghoul', 35, '24769346');
      // Min and max value.
      check('-9223372036854775808', 10, '-9223372036854775808');
      check('9223372036854775807', 10, '9223372036854775807');
      // Overflow during parsing.
      check('9223372036854775808', 10, '-9223372036854775808');

      expect(() => Int64.parseRadix('0', 1), throwsRangeError);
      expect(() => Int64.parseRadix('0', 37), throwsRangeError);
      expect(() => Int64.parseRadix('xyzzy', -1), throwsRangeError);
      expect(() => Int64.parseRadix('xyzzy', 10), throwsFormatException);
    });

    test('parseRadixN', () {
      void check(String s, int r) {
        expect(Int64.parseRadix(s, r).toRadixString(r), s);
      }

      check('2ppp111222333', 33); // This value & radix requires three chunks.
    });
  });

  group('string representation', () {
    test('toString', () {
      expect(Int64(0).toString(), '0');
      expect(Int64(1).toString(), '1');
      expect(Int64(-1).toString(), '-1');
      expect(Int64(-10).toString(), '-10');
      expect(Int64.MIN_VALUE.toString(), '-9223372036854775808');
      expect(Int64.MAX_VALUE.toString(), '9223372036854775807');

      int top = 922337201;
      int bottom = 967490662;
      Int64 fullnum = (Int64(1000000000) * Int64(top)) + Int64(bottom);
      expect(fullnum.toString(), '922337201967490662');
      expect((-fullnum).toString(), '-922337201967490662');
      expect(Int64(123456789).toString(), '123456789');
    });

    test('toHexString', () {
      Int64 deadbeef12341234 = Int64.fromInts(0xDEADBEEF, 0x12341234);
      expect(Int64.ZERO.toHexString(), '0');
      expect(deadbeef12341234.toHexString(), 'DEADBEEF12341234');
      expect(Int64.fromInts(0x17678A7, 0xDEF01234).toHexString(),
          '17678A7DEF01234');
      expect(Int64(123456789).toHexString(), '75BCD15');
    });

    test('toRadixString', () {
      expect(Int64(123456789).toRadixString(5), '223101104124');
      expect(Int64.MIN_VALUE.toRadixString(2),
          '-1000000000000000000000000000000000000000000000000000000000000000');
      expect(Int64.MIN_VALUE.toRadixString(3),
          '-2021110011022210012102010021220101220222');
      expect(Int64.MIN_VALUE.toRadixString(4),
          '-20000000000000000000000000000000');
      expect(Int64.MIN_VALUE.toRadixString(5), '-1104332401304422434310311213');
      expect(Int64.MIN_VALUE.toRadixString(6), '-1540241003031030222122212');
      expect(Int64.MIN_VALUE.toRadixString(7), '-22341010611245052052301');
      expect(Int64.MIN_VALUE.toRadixString(8), '-1000000000000000000000');
      expect(Int64.MIN_VALUE.toRadixString(9), '-67404283172107811828');
      expect(Int64.MIN_VALUE.toRadixString(10), '-9223372036854775808');
      expect(Int64.MIN_VALUE.toRadixString(11), '-1728002635214590698');
      expect(Int64.MIN_VALUE.toRadixString(12), '-41a792678515120368');
      expect(Int64.MIN_VALUE.toRadixString(13), '-10b269549075433c38');
      expect(Int64.MIN_VALUE.toRadixString(14), '-4340724c6c71dc7a8');
      expect(Int64.MIN_VALUE.toRadixString(15), '-160e2ad3246366808');
      expect(Int64.MIN_VALUE.toRadixString(16), '-8000000000000000');
      expect(Int64.MAX_VALUE.toRadixString(2),
          '111111111111111111111111111111111111111111111111111111111111111');
      expect(Int64.MAX_VALUE.toRadixString(3),
          '2021110011022210012102010021220101220221');
      expect(
          Int64.MAX_VALUE.toRadixString(4), '13333333333333333333333333333333');
      expect(Int64.MAX_VALUE.toRadixString(5), '1104332401304422434310311212');
      expect(Int64.MAX_VALUE.toRadixString(6), '1540241003031030222122211');
      expect(Int64.MAX_VALUE.toRadixString(7), '22341010611245052052300');
      expect(Int64.MAX_VALUE.toRadixString(8), '777777777777777777777');
      expect(Int64.MAX_VALUE.toRadixString(9), '67404283172107811827');
      expect(Int64.MAX_VALUE.toRadixString(10), '9223372036854775807');
      expect(Int64.MAX_VALUE.toRadixString(11), '1728002635214590697');
      expect(Int64.MAX_VALUE.toRadixString(12), '41a792678515120367');
      expect(Int64.MAX_VALUE.toRadixString(13), '10b269549075433c37');
      expect(Int64.MAX_VALUE.toRadixString(14), '4340724c6c71dc7a7');
      expect(Int64.MAX_VALUE.toRadixString(15), '160e2ad3246366807');
      expect(Int64.MAX_VALUE.toRadixString(16), '7fffffffffffffff');
      expect(() => Int64(42).toRadixString(-1), throwsArgumentError);
      expect(() => Int64(42).toRadixString(0), throwsArgumentError);
      expect(() => Int64(42).toRadixString(37), throwsArgumentError);
    });

    test('toStringUnsigned', () {
      List<Int64> values = [];
      for (int high = 0; high < 16; high++) {
        for (int low = -2; low <= 2; low++) {
          values.add((Int64(high) << (64 - 4)) + Int64(low));
        }
      }

      for (Int64 value in values) {
        for (int radix = 2; radix <= 36; radix++) {
          String s1 = value.toRadixStringUnsigned(radix);
          Int64 v2 = Int64.parseRadix(s1, radix);
          expect(v2, value);
          String s2 = v2.toRadixStringUnsigned(radix);
          expect(s2, s1);
        }
        String s3 = value.toStringUnsigned();
        Int64 v4 = Int64.parseInt(s3);
        expect(v4, value);
        String s4 = v4.toStringUnsigned();
        expect(s4, s3);
      }
    });
  });
}
