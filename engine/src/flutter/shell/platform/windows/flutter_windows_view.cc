// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/flutter_windows_view.h"

#include <chrono>

namespace flutter {

FlutterWindowsView::FlutterWindowsView(
    std::unique_ptr<WindowBindingHandler> window_binding) {
  surface_manager_ = std::make_unique<AngleSurfaceManager>();

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
  RegisterKeyboardHookHandlers(internal_plugin_messenger);
  platform_handler_ = PlatformHandler::Create(internal_plugin_messenger, this);
  cursor_handler_ = std::make_unique<flutter::CursorHandler>(
      internal_plugin_messenger, binding_handler_.get());

  PhysicalWindowBounds bounds = binding_handler_->GetPhysicalWindowBounds();

  SendWindowMetrics(bounds.width, bounds.height,
                    binding_handler_->GetDpiScale());
}

void FlutterWindowsView::RegisterKeyboardHookHandlers(
    flutter::BinaryMessenger* messenger) {
  AddKeyboardHookHandler(std::make_unique<flutter::KeyEventHandler>(messenger));
  AddKeyboardHookHandler(
      std::make_unique<flutter::TextInputPlugin>(messenger, this));
}

void FlutterWindowsView::AddKeyboardHookHandler(
    std::unique_ptr<flutter::KeyboardHookHandler> handler) {
  keyboard_hook_handlers_.push_back(std::move(handler));
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
    surface_manager_->ResizeSurface(GetRenderTarget(), width, height);
    surface_manager_->MakeCurrent();
    resize_status_ = ResizeState::kFrameGenerated;
  }

  return kWindowFrameBufferID;
}

void FlutterWindowsView::OnWindowSizeChanged(size_t width, size_t height) {
  // Called on the platform thread.
  std::unique_lock<std::mutex> lock(resize_mutex_);
  resize_status_ = ResizeState::kResizeStarted;
  resize_target_width_ = width;
  resize_target_height_ = height;
  SendWindowMetrics(width, height, binding_handler_->GetDpiScale());

  if (width > 0 && height > 0) {
    // Block the platform thread until:
    //   1. GetFrameBufferId is called with the right frame size.
    //   2. Any pending SwapBuffers calls have been invoked.
    resize_cv_.wait(lock, [&resize_status = resize_status_] {
      return resize_status == ResizeState::kDone;
    });
  }
}

void FlutterWindowsView::OnPointerMove(double x, double y) {
  SendPointerMove(x, y);
}

void FlutterWindowsView::OnPointerDown(
    double x,
    double y,
    FlutterPointerMouseButtons flutter_button) {
  if (flutter_button != 0) {
    uint64_t mouse_buttons = mouse_state_.buttons | flutter_button;
    SetMouseButtons(mouse_buttons);
    SendPointerDown(x, y);
  }
}

void FlutterWindowsView::OnPointerUp(
    double x,
    double y,
    FlutterPointerMouseButtons flutter_button) {
  if (flutter_button != 0) {
    uint64_t mouse_buttons = mouse_state_.buttons & ~flutter_button;
    SetMouseButtons(mouse_buttons);
    SendPointerUp(x, y);
  }
}

void FlutterWindowsView::OnPointerLeave() {
  SendPointerLeave();
}

void FlutterWindowsView::OnText(const std::u16string& text) {
  SendText(text);
}

bool FlutterWindowsView::OnKey(int key,
                               int scancode,
                               int action,
                               char32_t character,
                               bool extended) {
  return SendKey(key, scancode, action, character, extended);
}

void FlutterWindowsView::OnComposeBegin() {
  SendComposeBegin();
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
  binding_handler_->UpdateCursorRect(rect);
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

void FlutterWindowsView::SendPointerMove(double x, double y) {
  FlutterPointerEvent event = {};
  event.x = x;
  event.y = y;
  SetEventPhaseFromCursorButtonState(&event);
  SendPointerEventWithData(event);
}

void FlutterWindowsView::SendPointerDown(double x, double y) {
  FlutterPointerEvent event = {};
  SetEventPhaseFromCursorButtonState(&event);
  event.x = x;
  event.y = y;
  SendPointerEventWithData(event);
  SetMouseFlutterStateDown(true);
}

void FlutterWindowsView::SendPointerUp(double x, double y) {
  FlutterPointerEvent event = {};
  SetEventPhaseFromCursorButtonState(&event);
  event.x = x;
  event.y = y;
  SendPointerEventWithData(event);
  if (event.phase == FlutterPointerPhase::kUp) {
    SetMouseFlutterStateDown(false);
  }
}

void FlutterWindowsView::SendPointerLeave() {
  FlutterPointerEvent event = {};
  event.phase = FlutterPointerPhase::kRemove;
  SendPointerEventWithData(event);
}

void FlutterWindowsView::SendText(const std::u16string& text) {
  for (const auto& handler : keyboard_hook_handlers_) {
    handler->TextHook(this, text);
  }
}

bool FlutterWindowsView::SendKey(int key,
                                 int scancode,
                                 int action,
                                 char32_t character,
                                 bool extended) {
  for (const auto& handler : keyboard_hook_handlers_) {
    if (handler->KeyboardHook(this, key, scancode, action, character,
                              extended)) {
      // key event was handled, so don't send to other handlers.
      return true;
    }
  }
  return false;
}

void FlutterWindowsView::SendComposeBegin() {
  for (const auto& handler : keyboard_hook_handlers_) {
    handler->ComposeBeginHook();
  }
}

void FlutterWindowsView::SendComposeEnd() {
  for (const auto& handler : keyboard_hook_handlers_) {
    handler->ComposeEndHook();
  }
}

void FlutterWindowsView::SendComposeChange(const std::u16string& text,
                                           int cursor_pos) {
  for (const auto& handler : keyboard_hook_handlers_) {
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
  event.device_kind = kFlutterPointerDeviceKindMouse;
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
  return surface_manager_->MakeCurrent();
}

bool FlutterWindowsView::MakeResourceCurrent() {
  return surface_manager_->MakeResourceCurrent();
}

bool FlutterWindowsView::ClearContext() {
  return surface_manager_->ClearContext();
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
      bool swap_buffers_result = surface_manager_->SwapBuffers();
      resize_status_ = ResizeState::kDone;
      lock.unlock();
      resize_cv_.notify_all();
      binding_handler_->OnWindowResized();
      return swap_buffers_result;
    }
    case ResizeState::kDone:
    default:
      return surface_manager_->SwapBuffers();
  }
}

void FlutterWindowsView::CreateRenderSurface() {
  PhysicalWindowBounds bounds = binding_handler_->GetPhysicalWindowBounds();
  surface_manager_->CreateSurface(GetRenderTarget(), bounds.width,
                                  bounds.height);
}

void FlutterWindowsView::DestroyRenderSurface() {
  if (surface_manager_) {
    surface_manager_->DestroySurface();
  }
}

WindowsRenderTarget* FlutterWindowsView::GetRenderTarget() const {
  return render_target_.get();
}

FlutterWindowsEngine* FlutterWindowsView::GetEngine() {
  return engine_.get();
}

}  // namespace flutter
