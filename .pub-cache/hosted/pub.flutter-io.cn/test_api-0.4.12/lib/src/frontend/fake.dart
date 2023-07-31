// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A stand-in for another object which cannot be used except for specifically
/// overridden methods.
///
/// A fake has a default behavior for every field and method of throwing
/// [UnimplementedError]. Fields and methods that are exercised by the code
/// under test should be manually overridden in the implementing class.
///
/// A fake does not have any support for verification or defining behavior from
/// the test, it cannot be used as a mock.
///
/// In most cases a shared full fake implementation without a `noSuchMethod` is
/// preferable to `extends Fake`, however `extends Fake` is preferred against
/// `extends Mock` mixed with manual `@override` implementations.
///
/// __Example use__:
///
///     // Real class.
///     class Cat {
///       String meow(String suffix) => 'Meow$suffix';
///       String hiss(String suffix) => 'Hiss$suffix';
///     }
///
///     // Fake class.
///     class FakeCat extends Fake implements Cat {
///       @override
///       String meow(String suffix) => 'FakeMeow$suffix';
///     }
///
///     void main() {
///       // Create a new fake Cat at runtime.
///       var cat = new FakeCat();
///
///       // Try making a Cat sound...
///       print(cat.meow('foo')); // Prints 'FakeMeowfoo'
///       print(cat.hiss('foo')); // Throws
///     }
///
/// **WARNING**: [Fake] uses [noSuchMethod](goo.gl/r3IQUH), which is a _form_ of
/// runtime reflection, and causes sub-standard code to be generated. As such,
/// [Fake] should strictly _not_ be used in any production code, especially if
/// used within the context of Dart for Web (dart2js, DDC) and Dart for Mobile
/// (Flutter).
abstract class Fake {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(invocation.memberName.toString().split('"')[1]);
  }
}
