// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:test/test.dart';

class SamplePluginPlatform extends PlatformInterface {
  SamplePluginPlatform() : super(token: _token);

  static final Object _token = Object();

  // ignore: avoid_setters_without_getters
  static set instance(SamplePluginPlatform instance) {
    PlatformInterface.verify(instance, _token);
    // A real implementation would set a static instance field here.
  }
}

class ImplementsSamplePluginPlatform extends Mock
    implements SamplePluginPlatform {}

class ImplementsSamplePluginPlatformUsingNoSuchMethod
    implements SamplePluginPlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ImplementsSamplePluginPlatformUsingMockPlatformInterfaceMixin extends Mock
    with MockPlatformInterfaceMixin
    implements SamplePluginPlatform {}

class ImplementsSamplePluginPlatformUsingFakePlatformInterfaceMixin extends Fake
    with MockPlatformInterfaceMixin
    implements SamplePluginPlatform {}

class ExtendsSamplePluginPlatform extends SamplePluginPlatform {}

class ConstTokenPluginPlatform extends PlatformInterface {
  ConstTokenPluginPlatform() : super(token: _token);

  static const Object _token = Object(); // invalid

  // ignore: avoid_setters_without_getters
  static set instance(ConstTokenPluginPlatform instance) {
    PlatformInterface.verify(instance, _token);
  }
}

class ExtendsConstTokenPluginPlatform extends ConstTokenPluginPlatform {}

class VerifyTokenPluginPlatform extends PlatformInterface {
  VerifyTokenPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  // ignore: avoid_setters_without_getters
  static set instance(VerifyTokenPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    // A real implementation would set a static instance field here.
  }
}

class ImplementsVerifyTokenPluginPlatform extends Mock
    implements VerifyTokenPluginPlatform {}

class ImplementsVerifyTokenPluginPlatformUsingMockPlatformInterfaceMixin
    extends Mock
    with MockPlatformInterfaceMixin
    implements VerifyTokenPluginPlatform {}

class ExtendsVerifyTokenPluginPlatform extends VerifyTokenPluginPlatform {}

class ConstVerifyTokenPluginPlatform extends PlatformInterface {
  ConstVerifyTokenPluginPlatform() : super(token: _token);

  static const Object _token = Object(); // invalid

  // ignore: avoid_setters_without_getters
  static set instance(ConstVerifyTokenPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
  }
}

class ImplementsConstVerifyTokenPluginPlatform extends PlatformInterface
    implements ConstVerifyTokenPluginPlatform {
  ImplementsConstVerifyTokenPluginPlatform() : super(token: const Object());
}

// Ensures that `PlatformInterface` has no instance methods. Adding an
// instance method is discouraged and may be a breaking change if it
// conflicts with instance methods in subclasses.
class StaticMethodsOnlyPlatformInterfaceTest implements PlatformInterface {}

class StaticMethodsOnlyMockPlatformInterfaceMixinTest
    implements MockPlatformInterfaceMixin {}

void main() {
  group('`verify`', () {
    test('prevents implementation with `implements`', () {
      expect(() {
        SamplePluginPlatform.instance = ImplementsSamplePluginPlatform();
      }, throwsA(isA<AssertionError>()));
    });

    test('prevents implmentation with `implements` and `noSuchMethod`', () {
      expect(() {
        SamplePluginPlatform.instance =
            ImplementsSamplePluginPlatformUsingNoSuchMethod();
      }, throwsA(isA<AssertionError>()));
    });

    test('allows mocking with `implements`', () {
      final SamplePluginPlatform mock =
          ImplementsSamplePluginPlatformUsingMockPlatformInterfaceMixin();
      SamplePluginPlatform.instance = mock;
    });

    test('allows faking with `implements`', () {
      final SamplePluginPlatform fake =
          ImplementsSamplePluginPlatformUsingFakePlatformInterfaceMixin();
      SamplePluginPlatform.instance = fake;
    });

    test('allows extending', () {
      SamplePluginPlatform.instance = ExtendsSamplePluginPlatform();
    });

    test('prevents `const Object()` token', () {
      expect(() {
        ConstTokenPluginPlatform.instance = ExtendsConstTokenPluginPlatform();
      }, throwsA(isA<AssertionError>()));
    });
  });

  // Tests of the earlier, to-be-deprecated `verifyToken` method
  group('`verifyToken`', () {
    test('prevents implementation with `implements`', () {
      expect(() {
        VerifyTokenPluginPlatform.instance =
            ImplementsVerifyTokenPluginPlatform();
      }, throwsA(isA<AssertionError>()));
    });

    test('allows mocking with `implements`', () {
      final VerifyTokenPluginPlatform mock =
          ImplementsVerifyTokenPluginPlatformUsingMockPlatformInterfaceMixin();
      VerifyTokenPluginPlatform.instance = mock;
    });

    test('allows extending', () {
      VerifyTokenPluginPlatform.instance = ExtendsVerifyTokenPluginPlatform();
    });

    test('does not prevent `const Object()` token', () {
      ConstVerifyTokenPluginPlatform.instance =
          ImplementsConstVerifyTokenPluginPlatform();
    });
  });
}
