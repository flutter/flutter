// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The native backend representation of a paint used for a single draw call.
///
/// A [BackendPaint] is created per draw call from an `EnginePaint` (see
/// `EnginePaint.createBackendPaint`) and is owned by the caller, who must call
/// [dispose] once the draw call has been issued. It is never cached and never
/// registered with a finalizer.
abstract class BackendPaint {
  /// Eagerly frees the native paint object.
  ///
  /// Calling this more than once is a no-op.
  void dispose();
}
