// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_UWP_FLUTTER_WINDOW_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_UWP_FLUTTER_WINDOW_H_

#include <third_party/cppwinrt/generated/winrt/Windows.ApplicationModel.Core.h>
#include <third_party/cppwinrt/generated/winrt/Windows.Devices.Input.h>
#include <third_party/cppwinrt/generated/winrt/Windows.UI.Composition.h>
#include <third_party/cppwinrt/generated/winrt/Windows.UI.Input.h>
#include <third_party/cppwinrt/generated/winrt/Windows.UI.Text.Core.h>
#include <third_party/cppwinrt/generated/winrt/Windows.UI.ViewManagement.Core.h>
#include <third_party/cppwinrt/generated/winrt/Windows.UI.ViewManagement.h>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/windows/display_helper_winuwp.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/shell/platform/windows/game_pad_cursor_winuwp.h"

namespace flutter {

// Implements a UWP CoreWindow.  Underlying window has been created and provided
// by the runner.
//
// Specifically handles window events within windows.
class FlutterWindowWinUWP : public WindowBindingHandler {
 public:
  explicit FlutterWindowWinUWP(
      ABI::Windows::ApplicationModel::Core::CoreApplicationView* window);

  virtual ~FlutterWindowWinUWP();

  // |WindowBindingHandler|
  void SetView(WindowBindingHandlerDelegate* view) override;

  // |WindowBindingHandler|
  WindowsRenderTarget GetRenderTarget() override;

  // |FlutterWindowBindingHandler|
  PlatformWindow GetPlatformWindow() override;

  // |WindowBindingHandler|
  float GetDpiScale() override;

  // |FlutterWindowBindingHandler|
  bool IsVisible() override;

  // |WindowBindingHandler|
  PhysicalWindowBounds GetPhysicalWindowBounds() override;

  // |WindowBindingHandler|
  void UpdateFlutterCursor(const std::string& cursor_name) override;

  // |WindowBindingHandler|
  void OnCursorRectUpdated(const Rect& rect) override;

  // |WindowBindingHandler|
  void OnWindowResized() override;

  // |WindowBindingHandler|
  bool OnBitmapSurfaceUpdated(const void* allocation,
                              size_t row_bytes,
                              size_t height) override;

 private:
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

  // Converts from logical point to physical X value.
  double GetPosX(winrt::Windows::UI::Core::PointerEventArgs const& args);

  // Converts from logical point to physical Y value.
  double GetPosY(winrt::Windows::UI::Core::PointerEventArgs const& args);

  // Gets the pointer kind.
  FlutterPointerDeviceKind GetPointerDeviceKind(
      winrt::Windows::UI::Core::PointerEventArgs const& args);

  // Backing CoreWindow. nullptr if not set.
  winrt::Windows::UI::Core::CoreWindow window_{nullptr};

  // CoreApplicationView that owns window_. nullptr if not set.
  winrt::Windows::ApplicationModel::Core::CoreApplicationView application_view_{
      nullptr};

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

  // Compositor object that represents the render target binding the backing
  // SwapChain to the CoreWindow.
  winrt::Windows::UI::Composition::SpriteVisual render_target_{nullptr};

  // GamepadCursorWinUWP object used to manage an emulated cursor visual driven
  // by gamepad.
  std::unique_ptr<GamepadCursorWinUWP> game_pad_cursor_{nullptr};

  // DisplayHelper object used to determine window bounds, DPI etc.
  std::unique_ptr<DisplayHelperWinUWP> display_helper_ = {nullptr};
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_UWP_FLUTTER_WINDOW_H_
