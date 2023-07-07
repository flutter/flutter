// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The possible focus modes that can be set for a camera.
enum FocusMode {
  /// Automatically determine focus settings.
  auto,

  /// Lock the currently determined focus settings.
  locked,
}

/// Returns the focus mode as a String.
String serializeFocusMode(FocusMode focusMode) {
  switch (focusMode) {
    case FocusMode.locked:
      return 'locked';
    case FocusMode.auto:
      return 'auto';
    default:
      throw ArgumentError('Unknown FocusMode value');
  }
}

/// Returns the focus mode for a given String.
FocusMode deserializeFocusMode(String str) {
  switch (str) {
    case 'locked':
      return FocusMode.locked;
    case 'auto':
      return FocusMode.auto;
    default:
      throw ArgumentError('"$str" is not a valid FocusMode value');
  }
}
