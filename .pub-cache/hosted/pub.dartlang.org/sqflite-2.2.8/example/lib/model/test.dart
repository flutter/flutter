import 'dart:async';

/// Test definition.
class Test {
  /// Test definition.
  Test(this.name, this.fn, {bool? solo, bool? skip})
      : solo = solo == true,
        skip = skip == true;

  /// Only run this test.
  final bool solo;

  /// Skip this test.
  final bool skip;

  /// Test name.
  String name;

  /// Test body.
  FutureOr Function() fn;
}
