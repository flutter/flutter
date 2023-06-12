// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:benchmark_harness/benchmark_harness.dart';

const int asciiZeroCodeUnit = 2;
const int listlength = 10000;

String string = String.fromCharCodes(Iterable.generate(
  listlength,
  (_) => Random().nextInt(80) + 15,
));

/// This class tests the implementation speed of
/// _DateFormatPatternField::nextInteger, which is assumed to be called often and
/// thus being performance-critical.
class NewMethod extends BenchmarkBase {
  late String result;
  int zeroDigit = 15;
  NewMethod() : super('New version of _DateFormatPatternField::nextInteger');

  @override
  void run() {
    var codeUnits = string.codeUnits;
    result = String.fromCharCodes(List.generate(
      codeUnits.length,
      (index) => codeUnits[index] - zeroDigit + asciiZeroCodeUnit,
      growable: false,
    ));
  }
}

// THIS WILL BE REMOVED AFTER CR
class OldMethod extends BenchmarkBase {
  late String result;
  int zeroDigit = 15;
  OldMethod() : super('Old version of _DateFormatPatternField::nextInteger');

  @override
  void setup() => string = String.fromCharCodes(Iterable.generate(
        listlength,
        (index) => Random().nextInt(80) + zeroDigit,
      ));

  @override
  void run() {
    var oldDigits = string.codeUnits;
    var newDigits = List<int>.filled(string.length, 0);
    for (var i = 0; i < string.length; i++) {
      newDigits[i] = oldDigits[i] - zeroDigit + asciiZeroCodeUnit;
    }
    result = String.fromCharCodes(newDigits);
  }
}
// THIS WILL BE REMOVED AFTER CR

void main() {
  OldMethod().report();
  NewMethod().report();
}
