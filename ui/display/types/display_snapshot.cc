// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/display/types/display_snapshot.h"

namespace ui {

DisplaySnapshot::DisplaySnapshot(int64_t display_id,
                                 bool has_proper_display_id,
                                 const gfx::Point& origin,
                                 const gfx::Size& physical_size,
                                 DisplayConnectionType type,
                                 bool is_aspect_preserving_scaling,
                                 bool has_overscan,
                                 std::string display_name,
                                 const std::vector<const DisplayMode*>& modes,
                                 const DisplayMode* current_mode,
                                 const DisplayMode* native_mode)
    : display_id_(display_id),
      has_proper_display_id_(has_proper_display_id),
      origin_(origin),
      physical_size_(physical_size),
      type_(type),
      is_aspect_preserving_scaling_(is_aspect_preserving_scaling),
      has_overscan_(has_overscan),
      display_name_(display_name),
      modes_(modes),
      current_mode_(current_mode),
      native_mode_(native_mode) {}

DisplaySnapshot::~DisplaySnapshot() {}

}  // namespace ui
