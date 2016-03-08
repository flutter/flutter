// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/ios/flutter_touch_mapper.h"

namespace sky {
namespace shell {

TouchMapper::TouchMapper() : free_spots_(~0) {}

TouchMapper::~TouchMapper() = default;

int TouchMapper::registerTouch(UITouch* touch) {
  int freeSpot = ffsll(free_spots_);
  touch_map_[touch] = freeSpot;
  free_spots_ &= ~(1 << (freeSpot - 1));
  return freeSpot;
}

int TouchMapper::unregisterTouch(UITouch* touch) {
  auto index = touch_map_[touch];
  free_spots_ |= 1 << (index - 1);
  touch_map_.erase(touch);
  return index;
}

int TouchMapper::identifierOf(UITouch* touch) const {
  return touch_map_.at(touch);
}

}  // namespace shell
}  // namespace sky
