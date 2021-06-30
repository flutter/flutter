// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/flutter_windows_view.h"

#include <chrono>

#include "flutter/shell/platform/windows/keyboard_key_channel_handler.h"
#include "flutter/shell/platform/windows/keyboard_key_embedder_handler.h"
#include "flutter/shell/platform/windows/text_input_plugin.h"

namespace flutter {

/// Returns true if the surface will be updated as part of the resize process.
///
/// This is called on window resize to determine if the platform thread needs
/// to be blocked until the frame with the right size has been rendered. It
/// should be kept in-sync with how the engine deals with a new surface request
/// as seen in `CreateOrUpdateSurface` in `GPUSurfaceGL`.
static bool SurfaceWillUpdate(size_t cur_width,
                              size_t cur_height,
                              size_t target_width,
                              size_t target_height) {
  // TODO (https://github.com/flutter/flutter/issues/65061) : Avoid special
  // handling for zero dimensions.
  bool non_zero_target_dims = target_height > 0 && target_width > 0;
  bool not_same_size =
      (cur_height != target_height) || (cur_width != target_width);
  return non_zero_target_dims && not_same_size;
}

FlutterWindowsView::FlutterWindowsView(
    std::unique_ptr<WindowBindingHandler> window_binding) {
  // Take the binding handler, and give it a pointer back to self.
  binding_handler_ = std::move(window_binding);
  binding_handler_->SetView(this);

  render_target_ = std::make_unique<WindowsRenderTarget>(
      binding_handler_->GetRenderTarget());
}

FlutterWindowsView::~FlutterWindowsView() {
  DestroyRenderSurface();
}

void FlutterWindowsView::SetEngine(
    std::unique_ptr<FlutterWindowsEngine> engine) {
  engine_ = std::move(engine);

  engine_->SetView(this);

  internal_plugin_registrar_ =
      std::make_unique<flutter::PluginRegistrar>(engine_->GetRegistrar());

  // Set up the system channel handlers.
  auto internal_plugin_messenger = internal_plugin_registrar_->messenger();
  RegisterKeyboardHandlers(internal_plugin_messenger);
  platform_handler_ = PlatformHandler::Create(internal_plugin_messenger, this);
  cursor_handler_ = std::make_unique<flutter::CursorHandler>(
      internal_plugin_messenger, binding_handler_.get());

  PhysicalWindowBounds bounds = binding_handler_->GetPhysicalWindowBounds();

  SendWindowMetrics(bounds.width, bounds.height,
                    binding_handler_->GetDpiScale());
}

void FlutterWindowsView::RegisterKeyboardHandlers(
    flutter::BinaryMessenger* messenger) {
  // There must be only one handler that receives |SendInput|, i.e. only one
  // handler that might redispatch events. (See the documentation of
  // |KeyboardKeyHandler| to learn about redispatching.)
  //
  // Whether an event is a redispatched event is decided by calculating the hash
  // of the event. In order to allow the same real event in the future, the
  // handler is "toggled" when events pass through, therefore the redispatching
  // algorithm does not allow more than 1 handler that takes |SendInput|.
#ifdef WINUWP
  flutter::KeyboardKeyHandler::EventRedispatcher redispatch_event = nullptr;
  flutter::KeyboardKeyEmbedderHandler::GetKeyStateHandler get_key_state =
      nullptr;
#else
  flutter::KeyboardKeyHandler::EventRedispatcher redispatch_event = SendInput;
  flutter::KeyboardKeyEmbedderHandler::GetKeyStateHandler get_key_state =
      GetKeyState;
#endif
  auto key_handler =
      std::make_unique<flutter::KeyboardKeyHandler>(redispatch_event);
  key_handler->AddDelegate(std::make_unique<KeyboardKeyEmbedderHandler>(
      [this](const FlutterKeyEvent& event, FlutterKeyEventCallback callback,
             void* user_data) {
        return engine_->SendKeyEvent(event, callback, user_data);
      },
      get_key_state));
  key_handler->AddDelegate(
      std::make_unique<KeyboardKeyChannelHandler>(messenger));
  AddKeyboardHandler(std::move(key_handler));
  AddKeyboardHandler(
      std::make_unique<flutter::TextInputPlugin>(messenger, this));
}

void FlutterWindowsView::AddKeyboardHandler(
    std::unique_ptr<flutter::KeyboardHandlerBase> handler) {
  keyboard_handlers_.push_back(std::move(handler));
}

uint32_t FlutterWindowsView::GetFrameBufferId(size_t width, size_t height) {
  // Called on an engine-controlled (non-platform) thread.
  std::unique_lock<std::mutex> lock(resize_mutex_);

  if (resize_status_ != ResizeState::kResizeStarted) {
    return kWindowFrameBufferID;
  }

  if (resize_target_width_ == width && resize_target_height_ == height) {
    // Platform thread is blocked for the entire duration until the
    // resize_status_ is set to kDone.
    engine_->surface_manager()->ResizeSurface(GetRenderTarget(), width, height);
    engine_->surface_manager()->MakeCurrent();
    resize_status_ = ResizeState::kFrameGenerated;
  }

  return kWindowFrameBufferID;
}

void FlutterWindowsView::ForceRedraw() {
  if (resize_status_ == ResizeState::kDone) {
    // Request new frame
    // TODO(knopp): Replace with more specific call once there is API for it
    // https://github.com/flutter/flutter/issues/69716
    SendWindowMetrics(resize_target_width_, resize_target_height_,
                      binding_handler_->GetDpiScale());
  }
}

void FlutterWindowsView::OnWindowSizeChanged(size_t width, size_t height) {
  // Called on the platform thread.
  std::unique_lock<std::mutex> lock(resize_mutex_);

  if (!engine_->surface_manager()) {
    SendWindowMetrics(width, height, binding_handler_->GetDpiScale());
    return;
  }

  EGLint surface_width, surface_height;
  engine_->surface_manager()->GetSurfaceDimensions(&surface_width,
                                                   &surface_height);

  bool surface_will_update =
      SurfaceWillUpdate(surface_width, surface_height, width, height);
  if (surface_will_update) {
    resize_status_ = ResizeState::kResizeStarted;
    resize_target_width_ = width;
    resize_target_height_ = height;
  }

  SendWindowMetrics(width, height, binding_handler_->GetDpiScale());

  if (surface_will_update) {
    // Block the platform thread until:
    //   1. GetFrameBufferId is called with the right frame size.
    //   2. Any pending SwapBuffers calls have been invoked.
    resize_cv_.wait(lock, [&resize_status = resize_status_] {
      return resize_status == ResizeState::kDone;
    });
  }
}

void FlutterWindowsView::OnPointerMove(double x,
                                       double y,
                                       FlutterPointerDeviceKind device_kind) {
  SendPointerMove(x, y, device_kind);
}

void FlutterWindowsView::OnPointerDown(
    double x,
    double y,
    FlutterPointerDeviceKind device_kind,
    FlutterPointerMouseButtons flutter_button) {
  if (flutter_button != 0) {
    uint64_t mouse_buttons = mouse_state_.buttons | flutter_button;
    SetMouseButtons(mouse_buttons);
    SendPointerDown(x, y, device_kind);
  }
}

void FlutterWindowsView::OnPointerUp(
    double x,
    double y,
    FlutterPointerDeviceKind device_kind,
    FlutterPointerMouseButtons flutter_button) {
  if (flutter_button != 0) {
    uint64_t mouse_buttons = mouse_state_.buttons & ~flutter_button;
    SetMouseButtons(mouse_buttons);
    SendPointerUp(x, y, device_kind);
  }
}

void FlutterWindowsView::OnPointerLeave(FlutterPointerDeviceKind device_kind) {
  SendPointerLeave(device_kind);
}

void FlutterWindowsView::OnText(const std::u16string& text) {
  SendText(text);
}

bool FlutterWindowsView::OnKey(int key,
                               int scancode,
                               int action,
                               char32_t character,
                               bool extended,
                               bool was_down) {
  return SendKey(key, scancode, action, character, extended, was_down);
}

void FlutterWindowsView::OnComposeBegin() {
  SendComposeBegin();
}

void FlutterWindowsView::OnComposeCommit() {
  SendComposeCommit();
}

void FlutterWindowsView::OnComposeEnd() {
  SendComposeEnd();
}

void FlutterWindowsView::OnComposeChange(const std::u16string& text,
                                         int cursor_pos) {
  SendComposeChange(text, cursor_pos);
}

void FlutterWindowsView::OnScroll(double x,
                                  double y,
                                  double delta_x,
                                  double delta_y,
                                  int scroll_offset_multiplier) {
  SendScroll(x, y, delta_x, delta_y, scroll_offset_multiplier);
}

void FlutterWindowsView::OnCursorRectUpdated(const Rect& rect) {
  binding_handler_->OnCursorRectUpdated(rect);
}

// Sends new size  information to FlutterEngine.
void FlutterWindowsView::SendWindowMetrics(size_t width,
                                           size_t height,
                                           double dpiScale) const {
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = width;
  event.height = height;
  event.pixel_ratio = dpiScale;
  engine_->SendWindowMetricsEvent(event);
}

void FlutterWindowsView::SendInitialBounds() {
  PhysicalWindowBounds bounds = binding_handler_->GetPhysicalWindowBounds();

  SendWindowMetrics(bounds.width, bounds.height,
                    binding_handler_->GetDpiScale());
}

// Set's |event_data|'s phase to either kMove or kHover depending on the current
// primary mouse button state.
void FlutterWindowsView::SetEventPhaseFromCursorButtonState(
    FlutterPointerEvent* event_data) const {
  // For details about this logic, see FlutterPointerPhase in the embedder.h
  // file.
  if (mouse_state_.buttons == 0) {
    event_data->phase = mouse_state_.flutter_state_is_down
                            ? FlutterPointerPhase::kUp
                            : FlutterPointerPhase::kHover;
  } else {
    event_data->phase = mouse_state_.flutter_state_is_down
                            ? FlutterPointerPhase::kMove
                            : FlutterPointerPhase::kDown;
  }
}

void FlutterWindowsView::SendPointerMove(double x,
                                         double y,
                                         FlutterPointerDeviceKind device_kind) {
  FlutterPointerEvent event = {};
  event.x = x;
  event.y = y;
  event.device_kind = device_kind;
  SetEventPhaseFromCursorButtonState(&event);
  SendPointerEventWithData(event);
}

void FlutterWindowsView::SendPointerDown(double x,
                                         double y,
                                         FlutterPointerDeviceKind device_kind) {
  FlutterPointerEvent event = {};
  SetEventPhaseFromCursorButtonState(&event);
  event.x = x;
  event.y = y;
  event.device_kind = device_kind;
  SendPointerEventWithData(event);
  SetMouseFlutterStateDown(true);
}

void FlutterWindowsView::SendPointerUp(double x,
                                       double y,
                                       FlutterPointerDeviceKind device_kind) {
  FlutterPointerEvent event = {};
  SetEventPhaseFromCursorButtonState(&event);
  event.x = x;
  event.y = y;
  event.device_kind = device_kind;
  SendPointerEventWithData(event);
  if (event.phase == FlutterPointerPhase::kUp) {
    SetMouseFlutterStateDown(false);
  }
}

void FlutterWindowsView::SendPointerLeave(
    FlutterPointerDeviceKind device_kind) {
  FlutterPointerEvent event = {};
  event.device_kind = device_kind;
  event.phase = FlutterPointerPhase::kRemove;
  SendPointerEventWithData(event);
}

void FlutterWindowsView::SendText(const std::u16string& text) {
  for (const auto& handler : keyboard_handlers_) {
    handler->TextHook(this, text);
  }
}

bool FlutterWindowsView::SendKey(int key,
                                 int scancode,
                                 int action,
                                 char32_t character,
                                 bool extended,
                                 bool was_down) {
  for (const auto& handler : keyboard_handlers_) {
    if (handler->KeyboardHook(this, key, scancode, action, character, extended,
                              was_down)) {
      // key event was handled, so don't send to other handlers.
      return true;
    }
  }
  return false;
}

void FlutterWindowsView::SendComposeBegin() {
  for (const auto& handler : keyboard_handlers_) {
    handler->ComposeBeginHook();
  }
}

void FlutterWindowsView::SendComposeCommit() {
  for (const auto& handler : keyboard_handlers_) {
    handler->ComposeCommitHook();
  }
}

void FlutterWindowsView::SendComposeEnd() {
  for (const auto& handler : keyboard_handlers_) {
    handler->ComposeEndHook();
  }
}

void FlutterWindowsView::SendComposeChange(const std::u16string& text,
                                           int cursor_pos) {
  for (const auto& handler : keyboard_handlers_) {
    handler->ComposeChangeHook(text, cursor_pos);
  }
}

void FlutterWindowsView::SendScroll(double x,
                                    double y,
                                    double delta_x,
                                    double delta_y,
                                    int scroll_offset_multiplier) {
  FlutterPointerEvent event = {};
  SetEventPhaseFromCursorButtonState(&event);
  event.signal_kind = FlutterPointerSignalKind::kFlutterPointerSignalKindScroll;
  event.x = x;
  event.y = y;
  event.scroll_delta_x = delta_x * scroll_offset_multiplier;
  event.scroll_delta_y = delta_y * scroll_offset_multiplier;
  SendPointerEventWithData(event);
}

void FlutterWindowsView::SendPointerEventWithData(
    const FlutterPointerEvent& event_data) {
  // If sending anything other than an add, and the pointer isn't already added,
  // synthesize an add to satisfy Flutter's expectations about events.
  if (!mouse_state_.flutter_state_is_added &&
      event_data.phase != FlutterPointerPhase::kAdd) {
    FlutterPointerEvent event = {};
    event.phase = FlutterPointerPhase::kAdd;
    event.x = event_data.x;
    event.y = event_data.y;
    event.buttons = 0;
    SendPointerEventWithData(event);
  }
  // Don't double-add (e.g., if events are delivered out of order, so an add has
  // already been synthesized).
  if (mouse_state_.flutter_state_is_added &&
      event_data.phase == FlutterPointerPhase::kAdd) {
    return;
  }

  FlutterPointerEvent event = event_data;
  event.buttons = mouse_state_.buttons;

  // Set metadata that's always the same regardless of the event.
  event.struct_size = sizeof(event);
  event.timestamp =
      std::chrono::duration_cast<std::chrono::microseconds>(
          std::chrono::high_resolution_clock::now().time_since_epoch())
          .count();

  engine_->SendPointerEvent(event);

  if (event_data.phase == FlutterPointerPhase::kAdd) {
    SetMouseFlutterStateAdded(true);
  } else if (event_data.phase == FlutterPointerPhase::kRemove) {
    SetMouseFlutterStateAdded(false);
    ResetMouseState();
  }
}

bool FlutterWindowsView::MakeCurrent() {
  return engine_->surface_manager()->MakeCurrent();
}

bool FlutterWindowsView::MakeResourceCurrent() {
  return engine_->surface_manager()->MakeResourceCurrent();
}

bool FlutterWindowsView::ClearContext() {
  return engine_->surface_manager()->ClearContext();
}

bool FlutterWindowsView::SwapBuffers() {
  // Called on an engine-controlled (non-platform) thread.
  std::unique_lock<std::mutex> lock(resize_mutex_);

  switch (resize_status_) {
    // SwapBuffer requests during resize are ignored until the frame with the
    // right dimensions has been generated. This is marked with
    // kFrameGenerated resize status.
    case ResizeState::kResizeStarted:
      return false;
    case ResizeState::kFrameGenerated: {
      bool visible = binding_handler_->IsVisible();
      bool swap_buffers_result;
      // For visible windows swap the buffers while resize handler is waiting.
      // For invisible windows unblock the handler first and then swap buffers.
      // SwapBuffers waits for vsync and there's no point doing that for
      // invisible windows.
      if (visible) {
        swap_buffers_result = engine_->surface_manager()->SwapBuffers();
      }
      resize_status_ = ResizeState::kDone;
      lock.unlock();
      resize_cv_.notify_all();
      binding_handler_->OnWindowResized();
      if (!visible) {
        swap_buffers_result = engine_->surface_manager()->SwapBuffers();
      }
      return swap_buffers_result;
    }
    case ResizeState::kDone:
    default:
      return engine_->surface_manager()->SwapBuffers();
  }
}

bool FlutterWindowsView::PresentSoftwareBitmap(const void* allocation,
                                               size_t row_bytes,
                                               size_t height) {
  return binding_handler_->OnBitmapSurfaceUpdated(allocation, row_bytes,
                                                  height);
}

void FlutterWindowsView::CreateRenderSurface() {
  if (engine_ && engine_->surface_manager()) {
    PhysicalWindowBounds bounds = binding_handler_->GetPhysicalWindowBounds();
    engine_->surface_manager()->CreateSurface(GetRenderTarget(), bounds.width,
                                              bounds.height);
  }
}

void FlutterWindowsView::DestroyRenderSurface() {
  if (engine_ && engine_->surface_manager()) {
    engine_->surface_manager()->DestroySurface();
  }
}

WindowsRenderTarget* FlutterWindowsView::GetRenderTarget() const {
  return render_target_.get();
}

PlatformWindow FlutterWindowsView::GetPlatformWindow() const {
  return binding_handler_->GetPlatformWindow();
}

FlutterWindowsEngine* FlutterWindowsView::GetEngine() {
  return engine_.get();
}

}  // namespace flutter
