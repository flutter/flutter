// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_WINDOW_KEY_DATA_H_
#define FLUTTER_LIB_UI_WINDOW_KEY_DATA_H_

#include <cstdint>

namespace flutter {

// If this value changes, update the key data unpacking code in hooks.dart.
static constexpr int kKeyDataFieldCount = 5;
static constexpr int kBytesPerKeyField = sizeof(int64_t);

// The change of the key event, used by KeyData.
//
// Must match the KeyEventType enum in ui/key.dart.
enum class KeyEventType : int64_t {
  kDown = 0,
  kUp,
  kRepeat,
};

// The fixed-length sections of a KeyDataPacket.
//
// KeyData does not contain `character`, for variable-length data are stored in
// a different way in KeyDataPacket.
//
// This structure is unpacked by hooks.dart.
//
// Changes to this struct must also be made to
// io/flutter/embedding/android/KeyData.java.
struct alignas(8) KeyData {
  // Timestamp in microseconds from an arbitrary and consistent start point
  uint64_t timestamp;
  KeyEventType type;
  uint64_t physical;
  uint64_t logical;
  // True if the event does not correspond to a native event.
  //
  // The value is 1 for true, and 0 for false.
  uint64_t synthesized;

  // Sets all contents of `Keydata` to 0.
  void Clear();
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_WINDOW_POINTER_DATA_H_
