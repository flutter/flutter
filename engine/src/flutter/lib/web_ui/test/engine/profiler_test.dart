// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

void main() {
  setUp(() {
    Profiler.isBenchmarkMode = true;
    Profiler.ensureInitialized();
  });

  tearDown(() {
    jsOnBenchmark(null);
    Profiler.isBenchmarkMode = false;
  });

  test('works when there is no listener', () {
    expect(() => Profiler.instance.benchmark('foo', 123), returnsNormally);
  });

  test('can listen to benchmarks', () {
    final List<BenchmarkDatapoint> data = <BenchmarkDatapoint>[];
    jsOnBenchmark((String name, num value) {
      data.add(BenchmarkDatapoint(name, value));
    });

    Profiler.instance.benchmark('foo', 123);
    expect(data, <BenchmarkDatapoint>[BenchmarkDatapoint('foo', 123)]);
    data.clear();

    Profiler.instance.benchmark('bar', 0.0125);
    expect(data, <BenchmarkDatapoint>[BenchmarkDatapoint('bar', 0.0125)]);
    data.clear();

    // Remove listener and make sure nothing breaks and the data isn't being
    // sent to the old callback anymore.
    jsOnBenchmark(null);
    expect(() => Profiler.instance.benchmark('baz', 99.999), returnsNormally);
    expect(data, isEmpty);
  });

  test('throws on wrong listener type', () {
    final List<BenchmarkDatapoint> data = <BenchmarkDatapoint>[];

    // Wrong callback signature.
    jsOnBenchmark((num value) {
      data.add(BenchmarkDatapoint('bad', value));
    });
    expect(
      () => Profiler.instance.benchmark('foo', 123),
      throwsA(isA<TypeError>()),
    );
    expect(data, isEmpty);

    // Not even a callback.
    jsOnBenchmark('string');
    expect(
      () => Profiler.instance.benchmark('foo', 123),
      throwsA(isA<TypeError>()),
    );
  });
}

class BenchmarkDatapoint {
  BenchmarkDatapoint(this.name, this.value);

  final String name;
  final num value;

  @override
  int get hashCode => hashValues(name, value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is BenchmarkDatapoint
        && other.name == name
        && other.value == value;
  }

  @override
  String toString() {
    return '$runtimeType("$name", $value)';
  }
}

void jsOnBenchmark(dynamic listener) {
  js_util.setProperty(html.window, '_flutter_internal_on_benchmark', listener);
}
