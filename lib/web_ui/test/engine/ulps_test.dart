// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:test/bootstrap/browser.dart'; // ignore: import_of_legacy_library_into_null_safe
import 'package:test/test.dart'; // ignore: import_of_legacy_library_into_null_safe
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('Float Int conversions', (){
    test('Should convert signbit to 2\'s compliment', () {
      expect(signBitTo2sCompliment(0), 0);
      expect(signBitTo2sCompliment(0x7fffffff).toUnsigned(32), 0x7fffffff);
      expect(signBitTo2sCompliment(0x80000000), 0);
      expect(signBitTo2sCompliment(0x8f000000).toUnsigned(32), 0xf1000000);
      expect(signBitTo2sCompliment(0x8fffffff).toUnsigned(32), 0xf0000001);
      expect(signBitTo2sCompliment(0xffffffff).toUnsigned(32), 0x80000001);
      expect(signBitTo2sCompliment(0x8f000000), -251658240);
      expect(signBitTo2sCompliment(0x8fffffff), -268435455);
      expect(signBitTo2sCompliment(0xffffffff), -2147483647);
    });

    test('Should convert 2s compliment to signbit', () {
      expect(twosComplimentToSignBit(0), 0);
      expect(twosComplimentToSignBit(0x7fffffff), 0x7fffffff);
      expect(twosComplimentToSignBit(0), 0);
      expect(twosComplimentToSignBit(0xf1000000).toRadixString(16), 0x8f000000.toRadixString(16));
      expect(twosComplimentToSignBit(0xf0000001), 0x8fffffff);
      expect(twosComplimentToSignBit(0x80000001), 0xffffffff);
      expect(twosComplimentToSignBit(0x81234561), 0xfedcba9f);
      expect(twosComplimentToSignBit(-5), 0x80000005);
    });

    test('Should convert float to bits', () {
      Float32List floatList = Float32List(1);
      floatList[0] = 0;
      expect(float2Bits(floatList, 0), 0);
      floatList[0] = 0.1;
      expect(float2Bits(floatList, 0).toUnsigned(32).toRadixString(16), 0x3dcccccd.toRadixString(16));
      floatList[0] = 123456.0;
      expect(float2Bits(floatList, 0).toUnsigned(32).toRadixString(16), 0x47f12000.toRadixString(16));
      floatList[0] = -0.1;
      expect(float2Bits(floatList, 0).toUnsigned(32).toRadixString(16), 0xbdcccccd.toRadixString(16));
      floatList[0] = -123456.0;
      expect(float2Bits(floatList, 0).toUnsigned(32).toRadixString(16), 0xc7f12000.toRadixString(16));
    });
  });
  group('Comparison', () {
    test('Should compare equality based on ulps', () {
      // If number of floats between a=1.1 and b are below 16, equals should
      // return true.
      final double a = 1.1;
      int aBits = floatAs2sCompliment(a);
      double b = twosComplimentAsFloat(aBits + 1);
      expect(almostEqualUlps(a, b), true);
      b = twosComplimentAsFloat(aBits + 15);
      expect(almostEqualUlps(a, b), true);
      b = twosComplimentAsFloat(aBits + 16);
      expect(almostEqualUlps(a, b), false);

      // Test between variant of equalUlps.
      b = twosComplimentAsFloat(aBits + 1);
      expect(almostBequalUlps(a, b), true);
      b = twosComplimentAsFloat(aBits + 1);
      expect(almostBequalUlps(a, b), true);
      b = twosComplimentAsFloat(aBits + 2);
      expect(almostBequalUlps(a, b), false);
    });

    test('Should compare 2 coordinates based on ulps', () {
      double a = 1.1;
      int aBits = floatAs2sCompliment(a);
      double b = twosComplimentAsFloat(aBits + 1);
      expect(approximatelyEqual(5.0, a, 5.0, b), true);
      b = twosComplimentAsFloat(aBits + 16);
      expect(approximatelyEqual(5.0, a, 5.0, b), true);

      // Increase magnitude which should start checking with ulps rather than
      // fltEpsilon.
      a = 3000000.1;
      aBits = floatAs2sCompliment(a);
      b = twosComplimentAsFloat(aBits + 1);
      expect(approximatelyEqual(5.0, a, 5.0, b), true);
      b = twosComplimentAsFloat(aBits + 16);
      expect(approximatelyEqual(5.0, a, 5.0, b), false);
    });
  });
}
