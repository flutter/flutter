// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_DISPLAY_TYPES_NATIVE_DISPLAY_DELEGATE_H_
#define UI_DISPLAY_TYPES_NATIVE_DISPLAY_DELEGATE_H_

#include <stdint.h>

#include <vector>

#include "ui/display/types/display_constants.h"
#include "ui/display/types/display_types_export.h"

namespace gfx {
class Point;
class Size;
}

namespace ui {
class DisplayMode;
class DisplaySnapshot;

class NativeDisplayObserver;

// Interface for classes that perform display configuration actions on behalf
// of DisplayConfigurator.
class DISPLAY_TYPES_EXPORT NativeDisplayDelegate {
 public:
  virtual ~NativeDisplayDelegate() {}

  virtual void Initialize() = 0;

  // Grabs and refreshes any display server related resources. Must be balanced
  // by a call to UngrabServer().
  virtual void GrabServer() = 0;

  // Released the display server and any resources allocated by GrabServer().
  virtual void UngrabServer() = 0;

  // Flushes all pending requests and waits for replies.
  virtual void SyncWithServer() = 0;

  // Sets the window's background color to |color_argb|.
  virtual void SetBackgroundColor(uint32_t color_argb) = 0;

  // Enables DPMS and forces it to the "on" state.
  virtual void ForceDPMSOn() = 0;

  // Returns information about the current outputs. This method may block for
  // 60 milliseconds or more.
  // NativeDisplayDelegate maintains ownership of the ui::DisplaySnapshot
  // pointers.
  virtual std::vector<ui::DisplaySnapshot*> GetDisplays() = 0;

  // Adds |mode| to |output|. |mode| must be a valid display mode pointer.
  virtual void AddMode(const ui::DisplaySnapshot& output,
                       const ui::DisplayMode* mode) = 0;

  // Configures the display represented by |output| to use |mode| and positions
  // the display to |origin| in the framebuffer. |mode| can be NULL, which
  // represents disabling the display. Returns true on success.
  virtual bool Configure(const ui::DisplaySnapshot& output,
                         const ui::DisplayMode* mode,
                         const gfx::Point& origin) = 0;

  // Called to set the frame buffer (underlying XRR "screen") size.
  virtual void CreateFrameBuffer(const gfx::Size& size) = 0;

  // Gets HDCP state of output.
  virtual bool GetHDCPState(const ui::DisplaySnapshot& output,
                            ui::HDCPState* state) = 0;

  // Sets HDCP state of output.
  virtual bool SetHDCPState(const ui::DisplaySnapshot& output,
                            ui::HDCPState state) = 0;

  // Gets the available list of color calibrations.
  virtual std::vector<ui::ColorCalibrationProfile>
      GetAvailableColorCalibrationProfiles(
          const ui::DisplaySnapshot& output) = 0;

  // Sets the color calibration of |output| to |new_profile|.
  virtual bool SetColorCalibrationProfile(
      const ui::DisplaySnapshot& output,
      ui::ColorCalibrationProfile new_profile) = 0;

  virtual void AddObserver(NativeDisplayObserver* observer) = 0;

  virtual void RemoveObserver(NativeDisplayObserver* observer) = 0;
};

}  // namespace ui

#endif  // UI_DISPLAY_TYPES_NATIVE_DISPLAY_DELEGATE_H_
