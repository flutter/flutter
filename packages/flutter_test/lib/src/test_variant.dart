// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'test_compat.dart';
/// @docImport 'widget_tester.dart';
library;

import 'package:flutter/foundation.dart';

/// An abstract base class for describing test environment variants.
///
/// These serve as elements of the `variant` argument to [test] and
/// [testWidgets].
///
/// Use care when adding more testing variants: it multiplies the number of
/// tests which run. This can drastically increase the time it takes to run all
/// the tests.
abstract class TestVariant<T> {
  /// A const constructor so that subclasses can be const.
  const TestVariant();

  /// Returns an iterable of the variations that this test dimension represents.
  ///
  /// The variations returned should be unique so that the same variation isn't
  /// needlessly run twice.
  Iterable<T> get values;

  /// Returns the string that will be used to both add to the test description, and
  /// be printed when a test fails for this variation.
  String describeValue(T value);

  /// A function that will be called before each value is tested, with the
  /// value that will be tested.
  ///
  /// This function should preserve any state needed to restore the testing
  /// environment back to its base state when [tearDown] is called in the
  /// `Object` that is returned. The returned object will then be passed to
  /// [tearDown] as a `memento` when the test is complete.
  Future<Object?> setUp(T value);

  /// A function that is guaranteed to be called after a value is tested, even
  /// if it throws an exception.
  ///
  /// Calling this function must return the testing environment back to the base
  /// state it was in before [setUp] was called. The [memento] is the object
  /// returned from [setUp] when it was called.
  Future<void> tearDown(T value, covariant Object? memento);
}

/// The [TestVariant] that represents the "default" test that is run if no
/// `variant` is specified for [test] or [testWidgets].
///
/// This variant can be added into a list of other test variants to provide
/// a "control" test where nothing is changed from the base test environment.
class DefaultTestVariant extends TestVariant<void> {
  /// A const constructor for a [DefaultTestVariant].
  const DefaultTestVariant();

  @override
  Iterable<void> get values => const <void>[null];

  @override
  String describeValue(void value) => '';

  @override
  Future<void> setUp(void value) async {}

  @override
  Future<void> tearDown(void value, void memento) async {}
}

/// A [TestVariant] that runs tests with [debugDefaultTargetPlatformOverride]
/// set to different values of [TargetPlatform].
class TargetPlatformVariant extends TestVariant<TargetPlatform> {
  /// Creates a [TargetPlatformVariant] that tests the given [values].
  const TargetPlatformVariant(this.values);

  /// Creates a [TargetPlatformVariant] that tests all values from
  /// the [TargetPlatform] enum. If [excluding] is provided, will test all platforms
  /// except those in [excluding].
  TargetPlatformVariant.all({Set<TargetPlatform> excluding = const <TargetPlatform>{}})
    : values = TargetPlatform.values.toSet()..removeAll(excluding);

  /// Creates a [TargetPlatformVariant] that includes platforms that are
  /// considered desktop platforms.
  TargetPlatformVariant.desktop()
    : values = <TargetPlatform>{TargetPlatform.linux, TargetPlatform.macOS, TargetPlatform.windows};

  /// Creates a [TargetPlatformVariant] that includes platforms that are
  /// considered mobile platforms.
  TargetPlatformVariant.mobile()
    : values = <TargetPlatform>{TargetPlatform.android, TargetPlatform.iOS, TargetPlatform.fuchsia};

  /// Creates a [TargetPlatformVariant] that tests only the given value of
  /// [TargetPlatform].
  TargetPlatformVariant.only(TargetPlatform platform) : values = <TargetPlatform>{platform};

  @override
  final Set<TargetPlatform> values;

  @override
  String describeValue(TargetPlatform value) => value.toString();

  @override
  Future<TargetPlatform?> setUp(TargetPlatform value) async {
    final TargetPlatform? previousTargetPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = value;
    return previousTargetPlatform;
  }

  @override
  Future<void> tearDown(TargetPlatform value, TargetPlatform? memento) async {
    debugDefaultTargetPlatformOverride = memento;
  }
}

/// A [TestVariant] that runs separate tests with each of the given values.
///
/// To use this variant, define it before the test, and then access
/// [currentValue] inside the test.
///
/// The values are typically enums, but they don't have to be. The `toString`
/// for the given value will be used to describe the variant. Values will have
/// their type name stripped from their `toString` output, so that enum values
/// will only print the value, not the type.
///
/// {@tool snippet}
/// This example shows how to set up the test to access the [currentValue]. In
/// this example, two tests will be run, one with `value1`, and one with
/// `value2`. The test with `value2` will fail. The names of the tests will be:
///
///   - `Test handling of TestScenario (value1)`
///   - `Test handling of TestScenario (value2)`
///
/// ```dart
/// enum TestScenario {
///   value1,
///   value2,
///   value3,
/// }
///
/// final ValueVariant<TestScenario> variants = ValueVariant<TestScenario>(
///   <TestScenario>{TestScenario.value1, TestScenario.value2},
/// );
/// void main() {
///   testWidgets('Test handling of TestScenario', (WidgetTester tester) async {
///     expect(variants.currentValue, equals(TestScenario.value1));
///   }, variant: variants);
/// }
/// ```
/// {@end-tool}
class ValueVariant<T> extends TestVariant<T> {
  /// Creates a [ValueVariant] that tests the given [values].
  ValueVariant(this.values);

  /// Returns the value currently under test.
  T? get currentValue => _currentValue;
  T? _currentValue;

  @override
  final Set<T> values;

  @override
  String describeValue(T value) => value.toString().replaceFirst('$T.', '');

  @override
  Future<T> setUp(T value) async => _currentValue = value;

  @override
  Future<void> tearDown(T value, T memento) async {}
}
