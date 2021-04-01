// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/display_helper_winuwp.h"

namespace flutter {

DisplayHelperWinUWP::DisplayHelperWinUWP() {
  current_display_info_ = winrt::Windows::Graphics::Display::
      DisplayInformation::GetForCurrentView();

  ConfigureXboxSpecific();
}

bool DisplayHelperWinUWP::IsRunningOnLargeScreenDevice() {
  return large_screen_device_;
}

float DisplayHelperWinUWP::GetRenderTargetXOffset() {
  return render_target_x_offset_;
}

float DisplayHelperWinUWP::GetRenderTargetYOffset() {
  return render_target_y_offset_;
}

WindowBoundsWinUWP DisplayHelperWinUWP::GetPhysicalBounds() {
  return GetBounds(current_display_info_, true);
}

WindowBoundsWinUWP DisplayHelperWinUWP::GetLogicalBounds() {
  return GetBounds(current_display_info_, false);
}

WindowBoundsWinUWP DisplayHelperWinUWP::GetBounds(
    winrt::Windows::Graphics::Display::DisplayInformation const& disp,
    bool physical) {
  winrt::Windows::UI::ViewManagement::ApplicationView app_view =
      winrt::Windows::UI::ViewManagement::ApplicationView::GetForCurrentView();
  winrt::Windows::Foundation::Rect bounds = app_view.VisibleBounds();

  if (large_screen_device_) {
    return {bounds.Width + (bounds.X), bounds.Height + (bounds.Y)};
  }

  if (physical) {
    // Return the height in physical pixels
    return {bounds.Width * static_cast<float>(disp.RawPixelsPerViewPixel()),
            bounds.Height * static_cast<float>(disp.RawPixelsPerViewPixel())};
  }

  return {bounds.Width, bounds.Height};
}

void DisplayHelperWinUWP::ConfigureXboxSpecific() {
  bool running_on_xbox =
      winrt::Windows::System::Profile::AnalyticsInfo::VersionInfo()
          .DeviceFamily() == L"Windows.Xbox";

  if (running_on_xbox) {
    large_screen_device_ = running_on_xbox;
    bool result =
        winrt::Windows::UI::ViewManagement::ApplicationView::GetForCurrentView()
            .SetDesiredBoundsMode(winrt::Windows::UI::ViewManagement::
                                      ApplicationViewBoundsMode::UseCoreWindow);
    if (!result) {
      OutputDebugString(L"Couldn't set bounds mode.");
    }

    winrt::Windows::UI::ViewManagement::ApplicationView app_view = winrt::
        Windows::UI::ViewManagement::ApplicationView::GetForCurrentView();
    winrt::Windows::Foundation::Rect bounds = app_view.VisibleBounds();

    // The offset /2 represents how much off-screan the CoreWindow is
    // positioned.
    render_target_x_offset_ = bounds.X / 2;
    render_target_y_offset_ = bounds.Y / 2;
  }
}

float DisplayHelperWinUWP::GetDpiScale() {
  double raw_per_view = current_display_info_.RawPixelsPerViewPixel();

  // TODO(clarkezone): ensure DPI handling is correct:
  // because XBOX has display scaling off, logicalDpi returns 96 which is
  // incorrect check if raw_per_view is more acurate.
  // Also confirm if it is necessary to use this workaround on 10X
  // https://github.com/flutter/flutter/issues/70198

  if (large_screen_device_) {
    return 1.5;
  }
  return static_cast<float>(raw_per_view);
}

}  // namespace flutter
