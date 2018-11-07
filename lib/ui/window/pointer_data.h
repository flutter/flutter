// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_WINDOW_POINTER_DATA_H_
#define FLUTTER_LIB_UI_WINDOW_POINTER_DATA_H_

#include <stdint.h>

namespace blink {

// This structure is unpacked by hooks.dart.
struct alignas(8) PointerData {
  // Must match the PointerChange enum in pointer.dart.
  enum class Change : int64_t {
    kCancel,
    kAdd,
    kRemove,
    kHover,
    kDown,
    kMove,
    kUp,
  };

  // Must match the PointerDeviceKind enum in pointer.dart.
  enum class DeviceKind : int64_t {
    kTouch,
    kMouse,
    kStylus,
    kInvertedStylus,
  };

  int64_t time_stamp;
  Change change;
  DeviceKind kind;
  int64_t device;
  double physical_x;
  double physical_y;
  int64_t buttons;
  int64_t obscured;
  double pressure;
  double pressure_min;
  double pressure_max;
  double distance;
  double distance_max;
  double size;
  double radius_major;
  double radius_minor;
  double radius_min;
  double radius_max;
  double orientation;
  double tilt;
  int64_t platformData;

  void Clear();
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_WINDOW_POINTER_DATA_H_
