// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/win/display.h"

namespace base {
namespace win {

float GetScaleFactorForHWND(HWND hwnd) {
  HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
  DEVICE_SCALE_FACTOR scale_factor = DEVICE_SCALE_FACTOR_INVALID;
  if (SUCCEEDED(GetScaleFactorForMonitor(monitor, &scale_factor))) {
    return ScaleFactorToFloat(scale_factor);
  }
  return 1.0f;
}

float ScaleFactorToFloat(DEVICE_SCALE_FACTOR scale_factor) {
  switch (scale_factor) {
    case SCALE_100_PERCENT:
      return 1.0f;
    case SCALE_120_PERCENT:
      return 1.2f;
    case SCALE_125_PERCENT:
      return 1.25f;
    case SCALE_140_PERCENT:
      return 1.4f;
    case SCALE_150_PERCENT:
      return 1.5f;
    case SCALE_160_PERCENT:
      return 1.6f;
    case SCALE_175_PERCENT:
      return 1.75f;
    case SCALE_180_PERCENT:
      return 1.8f;
    case SCALE_200_PERCENT:
      return 2.0f;
    case SCALE_225_PERCENT:
      return 2.25f;
    case SCALE_250_PERCENT:
      return 2.5f;
    case SCALE_300_PERCENT:
      return 3.0f;
    case SCALE_350_PERCENT:
      return 3.5f;
    case SCALE_400_PERCENT:
      return 4.0f;
    case SCALE_450_PERCENT:
      return 4.5f;
    case SCALE_500_PERCENT:
      return 5.0f;
    default:
      return 1.0f;
  }
}

}  // namespace win
}  // namespace base
