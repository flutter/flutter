// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/display_manager.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"

namespace flutter {

DisplayManager::DisplayManager() = default;

DisplayManager::~DisplayManager() = default;

double DisplayManager::GetMainDisplayRefreshRate() const {
  std::scoped_lock lock(displays_mutex_);
  if (displays_.empty()) {
    return kUnknownDisplayRefreshRate;
  } else {
    return displays_[0].GetRefreshRate();
  }
}

void DisplayManager::HandleDisplayUpdates(DisplayUpdateType update_type,
                                          std::vector<Display> displays) {
  std::scoped_lock lock(displays_mutex_);
  CheckDisplayConfiguration(displays);
  switch (update_type) {
    case DisplayUpdateType::kStartup:
      FML_CHECK(displays_.empty());
      displays_ = displays;
      return;
    default:
      FML_CHECK(false) << "Unknown DisplayUpdateType.";
  }
}

void DisplayManager::CheckDisplayConfiguration(
    std::vector<Display> displays) const {
  FML_CHECK(!displays.empty());
  if (displays.size() > 1) {
    for (auto& display : displays) {
      FML_CHECK(display.GetDisplayId().has_value());
    }
  }
}

}  // namespace flutter
