// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library plugin_platform_interface;

import 'package:meta/meta.dart';

/// Base class for platform interfaces.
///
/// Provides a static helper method for ensuring that platform interfaces are
/// implemented using `extends` instead of `implements`.
///
/// Platform interface classes are expected to have a private static token object which will be
/// be passed to [verify] along with a platform interface object for verification.
///
/// Sample usage:
///
/// ```dart
/// abstract class UrlLauncherPlatform extends PlatformInterface {
///   UrlLauncherPlatform() : super(token: _token);
///
///   static UrlLauncherPlatform _instance = MethodChannelUrlLauncher();
///
///   static final Object _token = Object();
///
///   static UrlLauncherPlatform get instance => _instance;
///
///   /// Platform-specific plugins should set this with their own platform-specific
///   /// class that extends [UrlLauncherPlatform] when they register themselves.
///   static set instance(UrlLauncherPlatform instance) {
///     PlatformInterface.verify(instance, _token);
///     _instance = instance;
///   }
///
///  }
/// ```
///
/// Mockito mocks of platform interfaces will fail the verification, in test code only it is possible
/// to include the [MockPlatformInterfaceMixin] for the verification to be temporarily disabled. See
/// [MockPlatformInterfaceMixin] for a sample of using Mockito to mock a platform interface.
abstract class PlatformInterface {
  /// Constructs a PlatformInterface, for use only in constructors of abstract
  /// derived classes.
  ///
  /// @param token The same, non-`const` `Object` that will be passed to `verify`.
  PlatformInterface({required Object token}) {
    _instanceTokens[this] = token;
  }

  /// Expando mapping instances of PlatformInterface to their associated tokens.
  /// The reason this is not simply a private field of type `Object?` is because
  /// as of the implementation of field promotion in Dart
  /// (https://github.com/dart-lang/language/issues/2020), it is a runtime error
  /// to invoke a private member that is mocked in another library.  The expando
  /// approach prevents [_verify] from triggering this runtime exception when
  /// encountering an implementation that uses `implements` rather than
  /// `extends`.  This in turn allows [_verify] to throw an [AssertionError] (as
  /// documented).
  static final Expando<Object> _instanceTokens = Expando<Object>();

  /// Ensures that the platform instance was constructed with a non-`const` token
  /// that matches the provided token and throws [AssertionError] if not.
  ///
  /// This is used to ensure that implementers are using `extends` rather than
  /// `implements`.
  ///
  /// Subclasses of [MockPlatformInterfaceMixin] are assumed to be valid in debug
  /// builds.
  ///
  /// This is implemented as a static method so that it cannot be overridden
  /// with `noSuchMethod`.
  static void verify(PlatformInterface instance, Object token) {
    _verify(instance, token, preventConstObject: true);
  }

  /// Performs the same checks as `verify` but without throwing an
  /// [AssertionError] if `const Object()` is used as the instance token.
  ///
  /// This method will be deprecated in a future release.
  static void verifyToken(PlatformInterface instance, Object token) {
    _verify(instance, token, preventConstObject: false);
  }

  static void _verify(
    PlatformInterface instance,
    Object token, {
    required bool preventConstObject,
  }) {
    if (instance is MockPlatformInterfaceMixin) {
      bool assertionsEnabled = false;
      assert(() {
        assertionsEnabled = true;
        return true;
      }());
      if (!assertionsEnabled) {
        throw AssertionError(
            '`MockPlatformInterfaceMixin` is not intended for use in release builds.');
      }
      return;
    }
    if (preventConstObject &&
        identical(_instanceTokens[instance], const Object())) {
      throw AssertionError('`const Object()` cannot be used as the token.');
    }
    if (!identical(token, _instanceTokens[instance])) {
      throw AssertionError(
          'Platform interfaces must not be implemented with `implements`');
    }
  }
}

/// A [PlatformInterface] mixin that can be combined with fake or mock objects,
/// such as test's `Fake` or mockito's `Mock`.
///
/// It passes the [PlatformInterface.verify] check even though it isn't
/// using `extends`.
///
/// This class is intended for use in tests only.
///
/// Sample usage (assuming `UrlLauncherPlatform` extends [PlatformInterface]):
///
/// ```dart
/// class UrlLauncherPlatformMock extends Mock
///    with MockPlatformInterfaceMixin
///    implements UrlLauncherPlatform {}
/// ```
@visibleForTesting
abstract class MockPlatformInterfaceMixin implements PlatformInterface {}
