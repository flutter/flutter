// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_DISPLAY_HELPER_WINUWP_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_DISPLAY_HELPER_WINUWP_H_

#include <DispatcherQueue.h>
#include <third_party/cppwinrt/generated/winrt/Windows.Graphics.Display.h>
#include <third_party/cppwinrt/generated/winrt/Windows.System.Profile.h>
#include <third_party/cppwinrt/generated/winrt/Windows.UI.Composition.h>
#include <third_party/cppwinrt/generated/winrt/Windows.UI.Core.h>
#include <third_party/cppwinrt/generated/winrt/Windows.UI.ViewManagement.Core.h>
#include "third_party/cppwinrt/generated/winrt/Windows.System.Threading.h"

#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/shell/platform/windows/game_pad_winuwp.h"

namespace flutter {

struct WindowBoundsWinUWP {
  float width;
  float height;
};

// Helper that enables consumers to determine window bounds, DPI and some XBOX
// specific characteristics in the case when the current application is running
// on those devices.
class DisplayHelperWinUWP {
 public:
  DisplayHelperWinUWP();

  // physical = true
  // Returns with the physical bounds of the active window.
  WindowBoundsWinUWP GetPhysicalBounds();

  // Returns with the logical bounds of the active window.
  WindowBoundsWinUWP GetLogicalBounds();

  // Returns a bounds structure containing width and height information
  // for the backing CoreWindow in either view or physical pixels depending on
  // |physical|.
  WindowBoundsWinUWP GetBounds(
      winrt::Windows::Graphics::Display::DisplayInformation const& disp,
      bool physical);

  // Returns a scaling factor representing the current DPI scale applied to the
  // backing CoreWindow.
  float GetDpiScale();

  bool IsRunningOnLargeScreenDevice();

  // Returns a value representing the overscan to correct for X.
  float GetRenderTargetXOffset();

  // Returns a value representing the overscan to correct for Y.
  float GetRenderTargetYOffset();

 private:
  // Test is current context is running on an xbox device and perform device
  // specific initialization.
  void ConfigureXboxSpecific();

  // Most recent display information.
  winrt::Windows::Graphics::Display::DisplayInformation current_display_info_{
      nullptr};

  // Is current context is executing on a large screen device.
  bool large_screen_device_ = false;

  // Current X overscan compensation factor.
  float render_target_x_offset_ = 1.0f;

  // Current Y overscan compensation factor.
  float render_target_y_offset_ = 1.0f;
};
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_DISPLAY_HELPER_WINUWP_H_
