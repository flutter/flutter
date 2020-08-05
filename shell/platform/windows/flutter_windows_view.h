// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WINDOWS_VIEW_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WINDOWS_VIEW_H_

#include <windowsx.h>

#include <memory>
#include <string>
#include <vector>

#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/plugin_registrar.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/windows/angle_surface_manager.h"
#include "flutter/shell/platform/windows/cursor_handler.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/key_event_handler.h"
#include "flutter/shell/platform/windows/keyboard_hook_handler.h"
#include "flutter/shell/platform/windows/public/flutter_windows.h"
#include "flutter/shell/platform/windows/text_input_plugin.h"
#include "flutter/shell/platform/windows/win32_platform_handler.h"
#include "flutter/shell/platform/windows/window_binding_handler.h"
#include "flutter/shell/platform/windows/window_binding_handler_delegate.h"
#include "flutter/shell/platform/windows/window_state.h"

namespace flutter {

// An OS-windowing neutral abstration for flutter
// view that works with win32 hwnds and Windows::UI::Composition visuals.
class FlutterWindowsView : public WindowBindingHandlerDelegate {
 public:
  // Creates a FlutterWindowsView with the given implementator of
  // WindowBindingHandler.
  //
  // In order for object to render Flutter content the SetEngine method must be
  // called with a valid FlutterWindowsEngine instance.
  FlutterWindowsView(std::unique_ptr<WindowBindingHandler> window_binding);

  ~FlutterWindowsView();

  // Configures the window instance with an instance of a running Flutter
  // engine.
  void SetEngine(std::unique_ptr<FlutterWindowsEngine> engine);

  // Creates rendering surface for Flutter engine to draw into.
  // Should be called before calling FlutterEngineRun using this view.
  void CreateRenderSurface();

  // Destroys current rendering surface if one has been allocated.
  void DestroyRenderSurface();

  // Return the currently configured WindowsRenderTarget.
  WindowsRenderTarget* GetRenderTarget();

  // Returns the engine backing this view.
  FlutterWindowsEngine* GetEngine();

  // Callbacks for clearing context, settings context and swapping buffers.
  bool ClearContext();
  bool MakeCurrent();
  bool MakeResourceCurrent();
  bool SwapBuffers();

  // |WindowBindingHandlerDelegate|
  void OnWindowSizeChanged(size_t width, size_t height) const override;

  // |WindowBindingHandlerDelegate|
  void OnPointerMove(double x, double y) override;

  // |WindowBindingHandlerDelegate|
  void OnPointerDown(double x,
                     double y,
                     FlutterPointerMouseButtons button) override;

  // |WindowBindingHandlerDelegate|
  void OnPointerUp(double x,
                   double y,
                   FlutterPointerMouseButtons button) override;

  // |WindowBindingHandlerDelegate|
  void OnPointerLeave() override;

  // |WindowBindingHandlerDelegate|
  void OnText(const std::u16string&) override;

  // |WindowBindingHandlerDelegate|
  void OnKey(int key, int scancode, int action, char32_t character) override;

  // |WindowBindingHandlerDelegate|
  void OnScroll(double x,
                double y,
                double delta_x,
                double delta_y,
                int scroll_offset_multiplier) override;

  // |WindowBindingHandlerDelegate|
  void OnFontChange() override;

 private:
  // Struct holding the mouse state. The engine doesn't keep track of which
  // mouse buttons have been pressed, so it's the embedding's responsibility.
  struct MouseState {
    // True if the last event sent to Flutter had at least one mouse button.
    // pressed.
    bool flutter_state_is_down = false;

    // True if kAdd has been sent to Flutter. Used to determine whether
    // to send a kAdd event before sending an incoming mouse event, since
    // Flutter expects pointers to be added before events are sent for them.
    bool flutter_state_is_added = false;

    // The currently pressed buttons, as represented in FlutterPointerEvent.
    uint64_t buttons = 0;
  };

  // Sends a window metrics update to the Flutter engine using current window
  // dimensions in physical
  void SendWindowMetrics(size_t width, size_t height, double dpiscale) const;

  // Reports a mouse movement to Flutter engine.
  void SendPointerMove(double x, double y);

  // Reports mouse press to Flutter engine.
  void SendPointerDown(double x, double y);

  // Reports mouse release to Flutter engine.
  void SendPointerUp(double x, double y);

  // Reports mouse left the window client area.
  //
  // Win32 api doesn't have "mouse enter" event. Therefore, there is no
  // SendPointerEnter method. A mouse enter event is tracked then the "move"
  // event is called.
  void SendPointerLeave();

  // Reports a keyboard character to Flutter engine.
  void SendText(const std::u16string&);

  // Reports a raw keyboard message to Flutter engine.
  void SendKey(int key, int scancode, int action, char32_t character);

  // Reports scroll wheel events to Flutter engine.
  void SendScroll(double x,
                  double y,
                  double delta_x,
                  double delta_y,
                  int scroll_offset_multiplier);

  // Sets |event_data|'s phase to either kMove or kHover depending on the
  // current primary mouse button state.
  void SetEventPhaseFromCursorButtonState(
      FlutterPointerEvent* event_data) const;

  // Sends a pointer event to the Flutter engine based on given data.  Since
  // all input messages are passed in physical pixel values, no translation is
  // needed before passing on to engine.
  void SendPointerEventWithData(const FlutterPointerEvent& event_data);

  // Resets the mouse state to its default values.
  void ResetMouseState() { mouse_state_ = MouseState(); }

  // Updates the mouse state to whether the last event to Flutter had at least
  // one mouse button pressed.
  void SetMouseFlutterStateDown(bool is_down) {
    mouse_state_.flutter_state_is_down = is_down;
  }

  // Updates the mouse state to whether the last event to Flutter was a kAdd
  // event.
  void SetMouseFlutterStateAdded(bool is_added) {
    mouse_state_.flutter_state_is_added = is_added;
  }

  // Updates the currently pressed buttons.
  void SetMouseButtons(uint64_t buttons) { mouse_state_.buttons = buttons; }

  // Currently configured WindowsRenderTarget for this view used by
  // surface_manager for creation of render surfaces and bound to the physical
  // os window.
  std::unique_ptr<WindowsRenderTarget> render_target_;

  // An object used for intializing Angle and creating / destroying render
  // surfaces. Surface creation functionality requires a valid render_target.
  std::unique_ptr<AngleSurfaceManager> surface_manager_;

  // The engine associated with this view.
  std::unique_ptr<FlutterWindowsEngine> engine_;

  // Keeps track of mouse state in relation to the window.
  MouseState mouse_state_;

  // The plugin registrar managing internal plugins.
  std::unique_ptr<flutter::PluginRegistrar> internal_plugin_registrar_;

  // Handlers for keyboard events from Windows.
  std::vector<std::unique_ptr<flutter::KeyboardHookHandler>>
      keyboard_hook_handlers_;

  // Handler for the flutter/platform channel.
  std::unique_ptr<flutter::PlatformHandler> platform_handler_;

  // Handler for cursor events.
  std::unique_ptr<flutter::CursorHandler> cursor_handler_;

  // Currently configured WindowBindingHandler for view.
  std::unique_ptr<flutter::WindowBindingHandler> binding_handler_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WINDOWS_VIEW_H_
