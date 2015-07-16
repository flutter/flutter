// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_DISPLAY_TYPES_DISPLAY_MODE_H_
#define UI_DISPLAY_TYPES_DISPLAY_MODE_H_

#include <string>

#include "base/macros.h"
#include "ui/display/types/display_types_export.h"
#include "ui/gfx/geometry/size.h"

namespace ui {

// This class represents the basic information for a native mode. Platforms will
// extend this class to add platform specific information about the mode.
class DISPLAY_TYPES_EXPORT DisplayMode {
 public:
  DisplayMode(const gfx::Size& size, bool interlaced, float refresh_rate);
  virtual ~DisplayMode();

  const gfx::Size& size() const { return size_; }
  bool is_interlaced() const { return is_interlaced_; }
  float refresh_rate() const { return refresh_rate_; }

  virtual std::string ToString() const;

 private:
  gfx::Size size_;
  bool is_interlaced_;
  float refresh_rate_;

  DISALLOW_COPY_AND_ASSIGN(DisplayMode);
};

}  // namespace ui

#endif  // UI_DISPLAY_TYPES_DISPLAY_MODE_H_
