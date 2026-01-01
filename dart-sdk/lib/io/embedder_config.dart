// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "dart:io";

/// Embedder-specific, fine-grained `dart:io` configuration.
///
/// This class contains per-Isolate flags that an embedder can set to put
/// fine-grained limitations on what process-visible operations Isolates are
/// permitted to use (e.g. [exit]). By default, the whole `dart:io` API is
/// enabled. When a disallowed operation is attempted, an `UnsupportedError` is
/// thrown.
///
/// Embedders should not modify these flags directly and should instead
/// configure `dart:io` by passing appropriate settings to
/// `dart::bin::SetupDartIoLibrary`.
@pragma('vm:entry-point')
abstract class _EmbedderConfig {
  /// Whether the isolate may call [exit].
  @pragma("vm:entry-point")
  static bool _mayExit = true;
}
