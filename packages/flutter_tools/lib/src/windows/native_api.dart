// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An indirection around ffi via `package:win32` to simplify google3
/// dependencies.
abstract class NativeApi {
  const NativeApi();

  /// Launch the native windows application with the given [amuid], returning the PID
  /// if successful.
  int launchApp(String amuid);
}
