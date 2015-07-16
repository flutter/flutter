// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/display/util/display_util.h"

#include "base/logging.h"

namespace ui {

namespace {

// A list of bogus sizes in mm that should be ignored.
// See crbug.com/136533. The first element maintains the minimum
// size required to be valid size.
const int kInvalidDisplaySizeList[][2] = {
  {40, 30},
  {50, 40},
  {160, 90},
  {160, 100},
};

// The DPI threshold to detect high density screen.
// Higher DPI than this will use device_scale_factor=2.
const unsigned int kHighDensityDPIThresholdSmall = 170;

// The HiDPI threshold for large (usually external) monitors. Lower threshold
// makes sense for large monitors, because such monitors should be located
// farther from the user's face usually. See http://crbug.com/348279
const unsigned int kHighDensityDPIThresholdLarge = 150;

// The width threshold in mm for "large" monitors.
const int kLargeDisplayWidthThresholdMM = 500;

// 1 inch in mm.
const float kInchInMm = 25.4f;

}  // namespace

bool IsDisplaySizeBlackListed(const gfx::Size& physical_size) {
  // Ignore if the reported display is smaller than minimum size.
  if (physical_size.width() <= kInvalidDisplaySizeList[0][0] ||
      physical_size.height() <= kInvalidDisplaySizeList[0][1]) {
    VLOG(1) << "Smaller than minimum display size";
    return true;
  }
  for (size_t i = 1; i < arraysize(kInvalidDisplaySizeList); ++i) {
    const gfx::Size size(kInvalidDisplaySizeList[i][0],
                         kInvalidDisplaySizeList[i][1]);
    if (physical_size == size) {
      VLOG(1) << "Black listed display size detected:" << size.ToString();
      return true;
    }
  }
  return false;
}

float GetScaleFactor(const gfx::Size& physical_size_in_mm,
                     const gfx::Size& screen_size_in_pixels) {
  if (IsDisplaySizeBlackListed(physical_size_in_mm))
    return 1.0f;

  const unsigned int dpi = static_cast<unsigned int>(
      kInchInMm * screen_size_in_pixels.width() / physical_size_in_mm.width());
  const unsigned int threshold =
      (physical_size_in_mm.width() >= kLargeDisplayWidthThresholdMM) ?
      kHighDensityDPIThresholdLarge : kHighDensityDPIThresholdSmall;
  return (dpi > threshold) ? 2.0f : 1.0f;
}

}  // namespace ui
