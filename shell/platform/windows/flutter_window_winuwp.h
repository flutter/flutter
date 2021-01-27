// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_UWP_FLUTTER_WINDOW_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_UWP_FLUTTER_WINDOW_H_

#include <winrt/Windows.Graphics.Display.h>
#include <winrt/Windows.System.Profile.h>
#include <winrt/Windows.UI.Input.h>
#include <winrt/Windows.UI.ViewManagement.Core.h>

#include <windows.ui.core.h>
#include <winrt/Windows.UI.Composition.h>
#include <winrt/Windows.UI.Core.h>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"

namespace flutter {

struct WindowBoundsWinUWP {
  float width;
  float height;
};

// Implements a UWP CoreWindow.  Underlying window has been created and provided
// by the runner.
//
// Specifically handles window events within windows.
class FlutterWindowWinUWP : public WindowBindingHandler {
 public:
  explicit FlutterWindowWinUWP(ABI::Windows::UI::Core::CoreWindow* window);

  virtual ~FlutterWindowWinUWP();

  // |WindowBindingHandler|
  void SetView(WindowBindingHandlerDelegate* view) override;

  // |WindowBindingHandler|
  WindowsRenderTarget GetRenderTarget() override;

  // |WindowBindingHandler|
  float GetDpiScale() override;

  // |WindowBindingHandler|
  PhysicalWindowBounds GetPhysicalWindowBounds() override;

  // |WindowBindingHandler|
  void UpdateFlutterCursor(const std::string& cursor_name) override;

  // |WindowBindingHandler|
  void UpdateCursorRect(const Rect& rect) override;

  // |WindowBindingHandler|
  void OnWindowResized() override;

 private:
  // Returns a bounds structure containing width and height information
  // for the backing CoreWindow in either view or physical pixels depending on
  // |physical|.
  WindowBoundsWinUWP GetBounds(
      winrt::Windows::Graphics::Display::DisplayInformation const& disp,
      bool physical);

  // Returns a scaling factor representing the current DPI scale applied to the
  // backing CoreWindow.
  float GetDpiScale(
      winrt::Windows::Graphics::Display::DisplayInformation const&);

  // Undoes the scale transform applied by the Windows compositor in order to
  // render at native scale and produce smooth results on high DPI screens.
  void ApplyInverseDpiScalingTransform();

  // Hooks up event handers for keyboard, mouse, size, DPI changed events on the
  // underlying CoreWindow.
  void SetEventHandlers();

  // Notifies current |WindowBindingHandlerDelegate| of DPI Changed events.
  void OnDpiChanged(
      winrt::Windows::Graphics::Display::DisplayInformation const& args,
      winrt::Windows::Foundation::IInspectable const&);

  // Notifies current |WindowBindingHandlerDelegate| of pointer pressed events.
  void OnPointerPressed(winrt::Windows::Foundation::IInspectable const&,
                        winrt::Windows::UI::Core::PointerEventArgs const& args);

  // Notifies current |WindowBindingHandlerDelegate| of pointer released events.
  void OnPointerReleased(
      winrt::Windows::Foundation::IInspectable const&,
      winrt::Windows::UI::Core::PointerEventArgs const& args);

  // Notifies current |WindowBindingHandlerDelegate| of pointer pressed events.
  void OnBoundsChanged(
      winrt::Windows::UI::ViewManagement::ApplicationView const& appView,
      winrt::Windows::Foundation::IInspectable const&);

  // Notifies current |WindowBindingHandlerDelegate| of pointer moved events.
  void OnPointerMoved(winrt::Windows::Foundation::IInspectable const&,
                      winrt::Windows::UI::Core::PointerEventArgs const& args);

  // Notifies current |WindowBindingHandlerDelegate| of mouse wheel events.
  void OnPointerWheelChanged(
      winrt::Windows::Foundation::IInspectable const&,
      winrt::Windows::UI::Core::PointerEventArgs const& args);

  // Notifies current |WindowBindingHandlerDelegate| of key up events.
  void OnKeyUp(winrt::Windows::Foundation::IInspectable const&,
               winrt::Windows::UI::Core::KeyEventArgs const& args);

  // Notifies current |WindowBindingHandlerDelegate| of key down events.
  void OnKeyDown(winrt::Windows::Foundation::IInspectable const&,
                 winrt::Windows::UI::Core::KeyEventArgs const& args);

  // Notifies current |WindowBindingHandlerDelegate| of character received
  // events.
  void OnCharacterReceived(
      winrt::Windows::Foundation::IInspectable const&,
      winrt::Windows::UI::Core::CharacterReceivedEventArgs const& args);

  // Creates a visual representing the emulated cursor and add to the  visual
  // tree
  winrt::Windows::UI::Composition::Visual CreateCursorVisual();

  // Test is current context is running on an xbox device and perform device
  // specific initialization.
  void ConfigureXboxSpecific();

  // Converts from logical point to physical X value.
  double GetPosX(winrt::Windows::UI::Core::PointerEventArgs const& args);

  // Converts from logical point to physical Y value.
  double GetPosY(winrt::Windows::UI::Core::PointerEventArgs const& args);

  // Token representing current worker thread.
  winrt::Windows::Foundation::IAsyncAction worker_loop_{nullptr};

  // Backing CoreWindow. nullptr if not set.
  winrt::Windows::UI::Core::CoreWindow window_{nullptr};

  // Pointer to a FlutterWindowsView that can be
  // used to update engine windowing and input state.
  WindowBindingHandlerDelegate* binding_handler_delegate_;

  // Current active compositor. nullptr if not set.
  winrt::Windows::UI::Composition::Compositor compositor_{nullptr};

  // Current CompositionTarget for binding the
  // rendering context to the CoreWindow. nullptr if not set.
  winrt::Windows::UI::Composition::CompositionTarget target_{nullptr};

  // Composition tree root object.
  winrt::Windows::UI::Composition::ContainerVisual visual_tree_root_{nullptr};

  // Composition visual representing the emulated
  // cursor visual.
  winrt::Windows::UI::Composition::Visual cursor_visual_{nullptr};

  // Compositor object that represents the render target binding the backing
  // SwapChain to the CoreWindow.
  winrt::Windows::UI::Composition::SpriteVisual render_target_{nullptr};

  // Is current context is executing on an XBOX
  // device.
  bool running_on_xbox_ = false;

  // Current X overscan compensation factor.
  float xbox_overscan_x_offset_ = 0.0f;

  // Current Y overscan compensation factor.
  float xbox_overscan_y_offset_ = 0.0f;

  // Most recent display information.
  winrt::Windows::Graphics::Display::DisplayInformation current_display_info_{
      nullptr};
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_UWP_FLUTTER_WINDOW_H_
