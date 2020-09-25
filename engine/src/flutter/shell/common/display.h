// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_DISPLAY_H_
#define FLUTTER_SHELL_COMMON_DISPLAY_H_

#include <optional>

namespace flutter {

/// Unique ID per display that is stable until the Flutter application restarts.
/// See also: `flutter::Display`
typedef uint64_t DisplayId;

/// To be used when the display refresh rate is unknown.
static constexpr double kUnknownDisplayRefreshRate = 0;

/// Display refers to a graphics hardware system consisting of a framebuffer,
/// typically a monitor or a screen. This class holds the various display
/// settings.
class Display {
 public:
  //------------------------------------------------------------------------------
  /// @brief Construct a new Display object in case where the display id of the
  /// display is known. In cases where there is more than one display, every
  /// display is expected to have a display id.
  ///
  Display(DisplayId display_id, double refresh_rate)
      : display_id_(display_id), refresh_rate_(refresh_rate) {}

  //------------------------------------------------------------------------------
  /// @brief Construct a new Display object when there is only a single display.
  /// When there are multiple displays, every display must have a display id.
  ///
  explicit Display(double refresh_rate)
      : display_id_({}), refresh_rate_(refresh_rate) {}

  ~Display() = default;

  // Get the display's maximum refresh rate in the unit of frame per second.
  // Return `kUnknownDisplayRefreshRate` if the refresh rate is unknown.
  double GetRefreshRate() const { return refresh_rate_; }

  /// Returns the `DisplayId` of the display.
  std::optional<DisplayId> GetDisplayId() const { return display_id_; }

 private:
  std::optional<DisplayId> display_id_;
  double refresh_rate_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_COMMON_DISPLAY_H_
