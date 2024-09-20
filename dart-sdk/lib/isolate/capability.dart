// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.isolate;

/// An unforgeable object that comes back as equal when passed through other
/// isolates.
///
/// Sending a capability object to another isolate, and getting it back,
/// will produce an object that is equal to the original.
/// There is no other way to create objects equal to a capability object.
///
/// Capabilities can be used as access guards.
/// An isolate can receive requests for operations from other isolates,
/// but only allow them if the request contains the correct capability object.
/// This allows exposing the same interface to multiple clients,
/// but restricting some operations to only those clients
/// that have also been given the corresponding capability.
///
/// Capabilities can be used inside a single isolate,
/// but they have no advantage over
/// just using `Object()` to create a unique object,
/// and it offers no real security against other code
/// running in the same isolate.
abstract interface class Capability {
  /// Create a new unforgeable capability object.
  external factory Capability();
}
