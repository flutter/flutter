// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'server_timestamp_behavior.dart';
import 'source.dart';

/// An options class that configures the behavior of get() calls on [DocumentReference] and [Query].
///
/// By providing a GetOptions object, these methods can be configured to fetch
/// results only from the server, only from the local cache or attempt to fetch
/// results from the server and fall back to the cache (which is the default).
class GetOptions {
  /// Describes whether we should get from server or cache.
  ///
  /// Setting to [Source.serverAndCache] (default value), causes Firestore to try to
  /// retrieve an up-to-date (server-retrieved) snapshot, but fall back to
  /// returning cached data if the server can't be reached.
  ///
  /// Setting to [Source.server] causes Firestore to avoid the cache, generating an error
  /// if the server cannot be reached. Note that the cache will still be updated
  /// if the server request succeeds. Also note that latency-compensation still
  /// takes effect, so any pending write operations will be visible in the
  /// returned data (merged into the server-provided data).
  ///
  /// Setting to [Source.cache] causes Firestore to immediately return a value
  /// from the cache, ignoring the server completely (implying that the returned
  /// value may be stale with respect to the value on the server.) If there is
  /// no data in the cache to satisfy the get() call, DocumentReference.get()
  /// will return an error and QuerySnapshot.get() will return an empty
  /// QuerySnapshot with no documents.
  final Source source;

  /// If set, controls the return value for server timestamps that have not yet been set to their final value.
  ///
  /// By specifying [ServerTimestampBehavior.estimate], pending server timestamps return an estimate based on the local clock.
  /// This estimate will differ from the final value and cause these values to change once the server result becomes available.
  ///
  /// By specifying [ServerTimestampBehavior.previous], pending timestamps will be ignored and return their previous value instead.
  ///
  /// If omitted or set to [ServerTimestampBehavior.none], null will be returned by default until the server value becomes available.
  final ServerTimestampBehavior serverTimestampBehavior;

  /// Creates a [GetOptions] instance.
  const GetOptions({
    this.source = Source.serverAndCache,
    this.serverTimestampBehavior = ServerTimestampBehavior.none,
  });
}
