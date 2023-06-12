// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:convert/convert.dart';

/// Test the performance of [FixedDateTimeFormatter.decode].
class DecodeBenchmark extends BenchmarkBase {
  final fixedDateTimeFormatter = FixedDateTimeFormatter('YYYYMMDDhhmmss');
  DecodeBenchmark() : super('Parse 10k strings to DateTime');

  @override
  void run() {
    for (var i = 0; i < 10000; i++) {
      fixedDateTimeFormatter.decode('19960425050322');
    }
  }
}

void main() {
  DecodeBenchmark().report();
}
