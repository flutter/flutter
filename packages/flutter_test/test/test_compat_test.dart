// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_api/hooks.dart' show TestHandle;

enum _TestScenario { first, second }

/// A [TestVariant] that records the order in which its [setUp] and [tearDown]
/// run relative to the body of the test that uses it.
class _RecordingVariant extends TestVariant<String> {
  _RecordingVariant(this.values);

  @override
  final Set<String> values;

  final List<String> log = <String>[];

  @override
  String describeValue(String value) => value;

  @override
  Future<Object?> setUp(String value) async {
    log.add('setUp:$value');
    return 'memento:$value';
  }

  @override
  Future<void> tearDown(String value, Object? memento) async {
    log.add('tearDown:$value:$memento');
  }
}

/// A [TestVariant] with no values, which is not allowed.
class _EmptyVariant extends TestVariant<void> {
  const _EmptyVariant();

  @override
  Iterable<void> get values => const <void>[];

  @override
  String describeValue(void value) => '';

  @override
  Future<void> setUp(void value) async {}

  @override
  Future<void> tearDown(void value, void memento) async {}
}

void main() {
  group('test() variants', () {
    final scenarios = ValueVariant<_TestScenario>(<_TestScenario>{
      _TestScenario.first,
      _TestScenario.second,
    });
    final visitedScenarios = <_TestScenario?>[];

    test('run once for each value provided', () {
      visitedScenarios.add(scenarios.currentValue);
    }, variant: scenarios);

    tearDownAll(() {
      expect(visitedScenarios, <_TestScenario>[_TestScenario.first, _TestScenario.second]);
    });

    test('have descriptions with the variant appended', () {
      expect(
        TestHandle.current.name,
        endsWith('have descriptions with the variant appended (variant: first)'),
      );
    }, variant: ValueVariant<_TestScenario>(<_TestScenario>{_TestScenario.first}));

    test('leave the description alone when no variant is provided', () {
      expect(
        TestHandle.current.name,
        endsWith('leave the description alone when no variant is provided'),
      );
      expect(TestHandle.current.name, isNot(contains('variant:')));
    });

    test('leave the description alone when the variant describes no value', () {
      expect(
        TestHandle.current.name,
        endsWith('leave the description alone when the variant describes no value'),
      );
    }, variant: _RecordingVariant(<String>{''}));

    test('assert when the variant has no values', () {
      expect(
        () => test('never registered', () {}, variant: const _EmptyVariant()),
        throwsAssertionError,
      );
    });
  });

  group('test() variant setUp and tearDown', () {
    final recording = _RecordingVariant(<String>{'a', 'b'});

    test('wrap the body', () async {
      recording.log.add('body:start');
      await Future<void>.delayed(Duration.zero);
      recording.log.add('body:end');
    }, variant: recording);

    tearDownAll(() {
      expect(recording.log, <String>[
        'setUp:a',
        'body:start',
        'body:end',
        'tearDown:a:memento:a',
        'setUp:b',
        'body:start',
        'body:end',
        'tearDown:b:memento:b',
      ]);
    });
  });

  group('TargetPlatformVariant with test()', () {
    TargetPlatform? originalTargetPlatform;

    setUpAll(() {
      originalTargetPlatform = debugDefaultTargetPlatformOverride;
    });

    tearDownAll(() {
      expect(debugDefaultTargetPlatformOverride, originalTargetPlatform);
    });

    test('overrides the target platform for the duration of the test', () {
      expect(debugDefaultTargetPlatformOverride, TargetPlatform.iOS);
      expect(defaultTargetPlatform, TargetPlatform.iOS);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    final visitedPlatforms = <TargetPlatform>{};

    test('runs every platform when using TargetPlatformVariant.all', () {
      visitedPlatforms.add(defaultTargetPlatform);
    }, variant: TargetPlatformVariant.all());

    tearDownAll(() {
      expect(visitedPlatforms, TargetPlatform.values.toSet());
    });
  });
}
