// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'platform.dart';

/// The [TargetPlatform] that matches the platform on which the framework is
/// currently executing.
///
/// This is the default value of [ThemeData.platform] (hence the name). Widgets
/// from the material library should use [Theme.of] to determine the current
/// platform for styling purposes, rather than using [defaultTargetPlatform].
/// However, if there is widget behavior that depends on the actual underlying
/// platform, then depending on [defaultTargetPlatform] makes sense.
/// [dart.io.Platform.environment] should be used directly only when it's
/// critical to actually know the current platform, without any overrides
/// possible (for example, when a system API is about to be called).
///
/// In a test environment, the platform returned is [TargetPlatform.android]
/// regardless of the host platform. (Android was chosen because the tests were
/// originally written assuming Android-like behavior, and we added platform
/// adaptations for iOS later). Tests can check iOS behavior by using the
/// platform override APIs (such as [ThemeData.platform] in the material
/// library) or by setting [debugDefaultTargetPlatformOverride].
//
// When adding support for a new platform (e.g. Windows Phone, macOS), first
// create a new value on the [TargetPlatform] enum, then add a rule for
// selecting that platform here.
//
// It would be incorrect to make a platform that isn't supported by
// [TargetPlatform] default to the behavior of another platform, because doing
// that would mean we'd be stuck with that platform forever emulating the other,
// and we'd never be able to introduce dedicated behavior for that platform
// (since doing so would be a big breaking change).
TargetPlatform get defaultTargetPlatform {
  throw UnimplementedError();
}

/// The largest SMI value.
///
/// See <https://www.dartlang.org/articles/numeric-computation/#smis-and-mints>
///
/// When compiling to JavaScript, this value is not supported since it is
/// larger than the maximum safe 32bit integer.
const int kMaxUnsignedSMI = 0;

/// A BitField over an enum (or other class whose values implement "index").
/// Only the first 62 values of the enum can be used as indices.
///
/// When compiling to JavaScript, this class is not supported.
class BitField<T extends dynamic> {
  /// Creates a bit field of all zeros.
  ///
  /// The given length must be at most 62.
  // ignore: avoid_unused_constructor_parameters
  BitField(int length) {
    throw UnimplementedError();
  }

  /// Creates a bit field filled with a particular value.
  ///
  /// If the value argument is true, the bits are filled with ones. Otherwise,
  /// the bits are filled with zeros.
  ///
  /// The given length must be at most 62.
  // ignore: avoid_unused_constructor_parameters
  BitField.filled(int length, bool value) {
    throw UnimplementedError();
  }

  /// Returns whether the bit with the given index is set to one.
  bool operator [](T index) {
    throw UnimplementedError();
  }

  /// Sets the bit with the given index to the given value.
  ///
  /// If value is true, the bit with the given index is set to one. Otherwise,
  /// the bit is set to zero.
  void operator []=(T index, bool value) {
    throw UnimplementedError();
  }
  /// Sets all the bits to the given value.
  ///
  /// If the value is true, the bits are all set to one. Otherwise, the bits are
  /// all set to zero. Defaults to setting all the bits to zero.
  void reset([ bool value = false ]) {
    throw UnimplementedError();
  }
}


/// Signature for the callback passed to [compute].
///
/// {@macro flutter.foundation.compute.types}
///
/// Instances of [ComputeCallback] must be top-level functions or static methods
/// of classes, not closures or instance methods of objects.
///
/// {@macro flutter.foundation.compute.limitations}
typedef ComputeCallback<Q, R> = FutureOr<R> Function(Q message);

/// Spawn an isolate, run `callback` on that isolate, passing it `message`, and
/// (eventually) return the value returned by `callback`.
///
/// This is useful for operations that take longer than a few milliseconds, and
/// which would therefore risk skipping frames. For tasks that will only take a
/// few milliseconds, consider [scheduleTask] instead.
///
/// {@template flutter.foundation.compute.types}
/// `Q` is the type of the message that kicks off the computation.
///
/// `R` is the type of the value returned.
/// {@endtemplate}
///
/// The `callback` argument must be a top-level function, not a closure or an
/// instance or static method of a class.
///
/// {@template flutter.foundation.compute.limitations}
/// There are limitations on the values that can be sent and received to and
/// from isolates. These limitations constrain the values of `Q` and `R` that
/// are possible. See the discussion at [SendPort.send].
/// {@endtemplate}
///
/// The `debugLabel` argument can be specified to provide a name to add to the
/// [Timeline]. This is useful when profiling an application.
Future<R> compute<Q, R>(ComputeCallback<Q, R> callback, Q message, { String debugLabel }) async {
  throw UnimplementedError();
}