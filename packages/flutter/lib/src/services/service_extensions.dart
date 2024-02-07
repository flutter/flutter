// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Service extension constants for the services library.
///
/// These constants will be used when registering service extensions in the
/// framework, and they will also be used by tools and services that call these
/// service extensions.
///
/// The String value for each of these extension names should be accessed by
/// calling the `.name` property on the enum value.
enum ServicesServiceExtensions {
  /// Name of service extension that, when called, will toggle whether
  /// statistics about the usage of Platform Channels will be printed out
  /// periodically to the console and Timeline events will show the time between
  /// sending and receiving a message (encoding and decoding time excluded).
  ///
  /// See also:
  ///
  /// * [debugProfilePlatformChannels], which is the flag that this service
  ///   extension exposes.
  /// * [ServicesBinding.initServiceExtensions], where the service extension is
  ///   registered.
  profilePlatformChannels,

  /// Name of service extension that, when called, will evict an image from the
  /// rootBundle cache and cause the image cache to be cleared.
  ///
  /// This is used by hot reload mode to clear out the cache of resources that
  /// have changed. This service extension should be called with a String value
  /// of the image path (e.g. foo.png).
  ///
  /// See also:
  ///
  /// * [ServicesBinding.initServiceExtensions], where the service extension is
  ///   registered.
  evict,
}
