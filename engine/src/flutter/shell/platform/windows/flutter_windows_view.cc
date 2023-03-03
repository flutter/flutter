// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/flutter_windows_view.h"

#include <chrono>

#include "flutter/fml/platform/win/wstring_conversion.h"
#include "flutter/shell/platform/common/accessibility_bridge.h"
#include "flutter/shell/platform/windows/keyboard_key_channel_handler.h"
#include "flutter/shell/platform/windows/text_input_plugin.h"
#include "flutter/third_party/accessibility/ax/platform/ax_platform_node_win.h"

namespace flutter {

namespace {
// The maximum duration to block the platform thread for while waiting
// for a window resize operation to complete.
constexpr std::chrono::milliseconds kWindowResizeTimeout{100};

/// Returns true if the surface will be updated as part of the resize process.
///
/// This is called on window resize to determine if the platform thread needs
/// to be blocked until the frame with the right size has been rendered. It
/// should be kept in-sync with how the engine deals with a new surface request
/// as seen in `CreateOrUpdateSurface` in `GPUSurfaceGL`.
bool SurfaceWillUpdate(size_t cur_width,
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
}  // namespace

FlutterWindowsView::FlutterWindowsView(
    std::unique_ptr<WindowBindingHandler> window_binding) {
  // Take the binding handler, and give it a pointer back to self.
  binding_handler_ = std::move(window_binding);
  binding_handler_->SetView(this);

  render_target_ = std::make_unique<WindowsRenderTarget>(
      binding_handler_->GetRenderTarget());
}

FlutterWindowsView::~FlutterWindowsView() {
  if (engine_) {
    engine_->SetView(nullptr);
  }
  DestroyRenderSurface();
}

void FlutterWindowsView::SetEngine(
    std::unique_ptr<FlutterWindowsEngine> engine) {
  engine_ = std::move(engine);

  engine_->SetView(this);

  PhysicalWindowBounds bounds = binding_handler_->GetPhysicalWindowBounds();

  SendWindowMetrics(bounds.width, bounds.height,
                    binding_handler_->GetDpiScale());
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

void FlutterWindowsView::UpdateFlutterCursor(const std::string& cursor_name) {
  binding_handler_->UpdateFlutterCursor(cursor_name);
}

void FlutterWindowsView::SetFlutterCursor(HCURSOR cursor) {
  binding_handler_->SetFlutterCursor(cursor);
}

void FlutterWindowsView::ForceRedraw() {
  if (resize_status_ == ResizeState::kDone) {
    // Request new frame.
    engine_->ScheduleFrame();
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
    resize_cv_.wait_for(lock, kWindowResizeTimeout,
                        [&resize_status = resize_status_] {
                          return resize_status == ResizeState::kDone;
                        });
  }
}

void FlutterWindowsView::OnWindowRepaint() {
  ForceRedraw();
}

void FlutterWindowsView::OnPointerMove(double x,
                                       double y,
                                       FlutterPointerDeviceKind device_kind,
                                       int32_t device_id,
                                       int modifiers_state) {
  engine_->keyboard_key_handler()->SyncModifiersIfNeeded(modifiers_state);
  SendPointerMove(x, y, GetOrCreatePointerState(device_kind, device_id));
}

void FlutterWindowsView::OnPointerDown(
    double x,
    double y,
    FlutterPointerDeviceKind device_kind,
    int32_t device_id,
    FlutterPointerMouseButtons flutter_button) {
  if (flutter_button != 0) {
    auto state = GetOrCreatePointerState(device_kind, device_id);
    state->buttons |= flutter_button;
    SendPointerDown(x, y, state);
  }
}

void FlutterWindowsView::OnPointerUp(
    double x,
    double y,
    FlutterPointerDeviceKind device_kind,
    int32_t device_id,
    FlutterPointerMouseButtons flutter_button) {
  if (flutter_button != 0) {
    auto state = GetOrCreatePointerState(device_kind, device_id);
    state->buttons &= ~flutter_button;
    SendPointerUp(x, y, state);
  }
}

void FlutterWindowsView::OnPointerLeave(double x,
                                        double y,
                                        FlutterPointerDeviceKind device_kind,
                                        int32_t device_id) {
  SendPointerLeave(x, y, GetOrCreatePointerState(device_kind, device_id));
}

void FlutterWindowsView::OnPointerPanZoomStart(int32_t device_id) {
  PointerLocation point = binding_handler_->GetPrimaryPointerLocation();
  SendPointerPanZoomStart(device_id, point.x, point.y);
}

void FlutterWindowsView::OnPointerPanZoomUpdate(int32_t device_id,
                                                double pan_x,
                                                double pan_y,
                                                double scale,
                                                double rotation) {
  SendPointerPanZoomUpdate(device_id, pan_x, pan_y, scale, rotation);
}

void FlutterWindowsView::OnPointerPanZoomEnd(int32_t device_id) {
  SendPointerPanZoomEnd(device_id);
}

void FlutterWindowsView::OnText(const std::u16string& text) {
  SendText(text);
}

void FlutterWindowsView::OnKey(int key,
                               int scancode,
                               int action,
                               char32_t character,
                               bool extended,
                               bool was_down,
                               KeyEventCallback callback) {
  SendKey(key, scancode, action, character, extended, was_down, callback);
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
                                  int scroll_offset_multiplier,
                                  FlutterPointerDeviceKind device_kind,
                                  int32_t device_id) {
  SendScroll(x, y, delta_x, delta_y, scroll_offset_multiplier, device_kind,
             device_id);
}

void FlutterWindowsView::OnScrollInertiaCancel(int32_t device_id) {
  PointerLocation point = binding_handler_->GetPrimaryPointerLocation();
  SendScrollInertiaCancel(device_id, point.x, point.y);
}

void FlutterWindowsView::OnUpdateSemanticsEnabled(bool enabled) {
  engine_->UpdateSemanticsEnabled(enabled);
}

gfx::NativeViewAccessible FlutterWindowsView::GetNativeViewAccessible() {
  return engine_->GetNativeViewAccessible();
}

void FlutterWindowsView::OnCursorRectUpdated(const Rect& rect) {
  binding_handler_->OnCursorRectUpdated(rect);
}

void FlutterWindowsView::OnResetImeComposing() {
  binding_handler_->OnResetImeComposing();
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

FlutterWindowsView::PointerState* FlutterWindowsView::GetOrCreatePointerState(
    FlutterPointerDeviceKind device_kind,
    int32_t device_id) {
  // Create a virtual pointer ID that is unique across all device types
  // to prevent pointers from clashing in the engine's converter
  // (lib/ui/window/pointer_data_packet_converter.cc)
  int32_t pointer_id = (static_cast<int32_t>(device_kind) << 28) | device_id;

  auto [it, added] = pointer_states_.try_emplace(pointer_id, nullptr);
  if (added) {
    auto state = std::make_unique<PointerState>();
    state->device_kind = device_kind;
    state->pointer_id = pointer_id;
    it->second = std::move(state);
  }

  return it->second.get();
}

// Set's |event_data|'s phase to either kMove or kHover depending on the current
// primary mouse button state.
void FlutterWindowsView::SetEventPhaseFromCursorButtonState(
    FlutterPointerEvent* event_data,
    const PointerState* state) const {
  // For details about this logic, see FlutterPointerPhase in the embedder.h
  // file.
  if (state->buttons == 0) {
    event_data->phase = state->flutter_state_is_down
                            ? FlutterPointerPhase::kUp
                            : FlutterPointerPhase::kHover;
  } else {
    event_data->phase = state->flutter_state_is_down
                            ? FlutterPointerPhase::kMove
                            : FlutterPointerPhase::kDown;
  }
}

void FlutterWindowsView::SendPointerMove(double x,
                                         double y,
                                         PointerState* state) {
  FlutterPointerEvent event = {};
  event.x = x;
  event.y = y;

  SetEventPhaseFromCursorButtonState(&event, state);
  SendPointerEventWithData(event, state);
}

void FlutterWindowsView::SendPointerDown(double x,
                                         double y,
                                         PointerState* state) {
  FlutterPointerEvent event = {};
  event.x = x;
  event.y = y;

  SetEventPhaseFromCursorButtonState(&event, state);
  SendPointerEventWithData(event, state);

  state->flutter_state_is_down = true;
}

void FlutterWindowsView::SendPointerUp(double x,
                                       double y,
                                       PointerState* state) {
  FlutterPointerEvent event = {};
  event.x = x;
  event.y = y;

  SetEventPhaseFromCursorButtonState(&event, state);
  SendPointerEventWithData(event, state);
  if (event.phase == FlutterPointerPhase::kUp) {
    state->flutter_state_is_down = false;
  }
}

void FlutterWindowsView::SendPointerLeave(double x,
                                          double y,
                                          PointerState* state) {
  FlutterPointerEvent event = {};
  event.x = x;
  event.y = y;
  event.phase = FlutterPointerPhase::kRemove;
  SendPointerEventWithData(event, state);
}

void FlutterWindowsView::SendPointerPanZoomStart(int32_t device_id,
                                                 double x,
                                                 double y) {
  auto state =
      GetOrCreatePointerState(kFlutterPointerDeviceKindTrackpad, device_id);
  state->pan_zoom_start_x = x;
  state->pan_zoom_start_y = y;
  FlutterPointerEvent event = {};
  event.x = x;
  event.y = y;
  event.phase = FlutterPointerPhase::kPanZoomStart;
  SendPointerEventWithData(event, state);
}

void FlutterWindowsView::SendPointerPanZoomUpdate(int32_t device_id,
                                                  double pan_x,
                                                  double pan_y,
                                                  double scale,
                                                  double rotation) {
  auto state =
      GetOrCreatePointerState(kFlutterPointerDeviceKindTrackpad, device_id);
  FlutterPointerEvent event = {};
  event.x = state->pan_zoom_start_x;
  event.y = state->pan_zoom_start_y;
  event.pan_x = pan_x;
  event.pan_y = pan_y;
  event.scale = scale;
  event.rotation = rotation;
  event.phase = FlutterPointerPhase::kPanZoomUpdate;
  SendPointerEventWithData(event, state);
}

void FlutterWindowsView::SendPointerPanZoomEnd(int32_t device_id) {
  auto state =
      GetOrCreatePointerState(kFlutterPointerDeviceKindTrackpad, device_id);
  FlutterPointerEvent event = {};
  event.x = state->pan_zoom_start_x;
  event.y = state->pan_zoom_start_y;
  event.phase = FlutterPointerPhase::kPanZoomEnd;
  SendPointerEventWithData(event, state);
}

void FlutterWindowsView::SendText(const std::u16string& text) {
  engine_->text_input_plugin()->TextHook(text);
}

void FlutterWindowsView::SendKey(int key,
                                 int scancode,
                                 int action,
                                 char32_t character,
                                 bool extended,
                                 bool was_down,
                                 KeyEventCallback callback) {
  engine_->keyboard_key_handler()->KeyboardHook(
      key, scancode, action, character, extended, was_down,
      [=, callback = std::move(callback)](bool handled) {
        if (!handled) {
          engine_->text_input_plugin()->KeyboardHook(
              key, scancode, action, character, extended, was_down);
        }
        callback(handled);
      });
}

void FlutterWindowsView::SendComposeBegin() {
  engine_->text_input_plugin()->ComposeBeginHook();
}

void FlutterWindowsView::SendComposeCommit() {
  engine_->text_input_plugin()->ComposeCommitHook();
}

void FlutterWindowsView::SendComposeEnd() {
  engine_->text_input_plugin()->ComposeEndHook();
}

void FlutterWindowsView::SendComposeChange(const std::u16string& text,
                                           int cursor_pos) {
  engine_->text_input_plugin()->ComposeChangeHook(text, cursor_pos);
}

void FlutterWindowsView::SendScroll(double x,
                                    double y,
                                    double delta_x,
                                    double delta_y,
                                    int scroll_offset_multiplier,
                                    FlutterPointerDeviceKind device_kind,
                                    int32_t device_id) {
  auto state = GetOrCreatePointerState(device_kind, device_id);

  FlutterPointerEvent event = {};
  event.x = x;
  event.y = y;
  event.signal_kind = FlutterPointerSignalKind::kFlutterPointerSignalKindScroll;
  event.scroll_delta_x = delta_x * scroll_offset_multiplier;
  event.scroll_delta_y = delta_y * scroll_offset_multiplier;
  SetEventPhaseFromCursorButtonState(&event, state);
  SendPointerEventWithData(event, state);
}

void FlutterWindowsView::SendScrollInertiaCancel(int32_t device_id,
                                                 double x,
                                                 double y) {
  auto state =
      GetOrCreatePointerState(kFlutterPointerDeviceKindTrackpad, device_id);

  FlutterPointerEvent event = {};
  event.x = x;
  event.y = y;
  event.signal_kind =
      FlutterPointerSignalKind::kFlutterPointerSignalKindScrollInertiaCancel;
  SetEventPhaseFromCursorButtonState(&event, state);
  SendPointerEventWithData(event, state);
}

void FlutterWindowsView::SendPointerEventWithData(
    const FlutterPointerEvent& event_data,
    PointerState* state) {
  // If sending anything other than an add, and the pointer isn't already added,
  // synthesize an add to satisfy Flutter's expectations about events.
  if (!state->flutter_state_is_added &&
      event_data.phase != FlutterPointerPhase::kAdd) {
    FlutterPointerEvent event = {};
    event.phase = FlutterPointerPhase::kAdd;
    event.x = event_data.x;
    event.y = event_data.y;
    event.buttons = 0;
    SendPointerEventWithData(event, state);
  }

  // Don't double-add (e.g., if events are delivered out of order, so an add has
  // already been synthesized).
  if (state->flutter_state_is_added &&
      event_data.phase == FlutterPointerPhase::kAdd) {
    return;
  }

  FlutterPointerEvent event = event_data;
  event.device_kind = state->device_kind;
  event.device = state->pointer_id;
  event.buttons = state->buttons;

  // Set metadata that's always the same regardless of the event.
  event.struct_size = sizeof(event);
  event.timestamp =
      std::chrono::duration_cast<std::chrono::microseconds>(
          std::chrono::high_resolution_clock::now().time_since_epoch())
          .count();

  engine_->SendPointerEvent(event);

  if (event_data.phase == FlutterPointerPhase::kAdd) {
    state->flutter_state_is_added = true;
  } else if (event_data.phase == FlutterPointerPhase::kRemove) {
    auto it = pointer_states_.find(state->pointer_id);
    if (it != pointer_states_.end()) {
      pointer_states_.erase(it);
    }
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
    resize_target_width_ = bounds.width;
    resize_target_height_ = bounds.height;
  }
}

void FlutterWindowsView::DestroyRenderSurface() {
  if (engine_ && engine_->surface_manager()) {
    engine_->surface_manager()->DestroySurface();
  }
}

void FlutterWindowsView::SendInitialAccessibilityFeatures() {
  binding_handler_->SendInitialAccessibilityFeatures();
}

void FlutterWindowsView::UpdateHighContrastEnabled(bool enabled) {
  engine_->UpdateHighContrastEnabled(enabled);
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

void FlutterWindowsView::AnnounceAlert(const std::wstring& text) {
  auto alert_delegate = binding_handler_->GetAlertDelegate();
  if (!alert_delegate) {
    return;
  }
  alert_delegate->SetText(fml::WideStringToUtf16(text));
  ui::AXPlatformNodeWin* alert_node = binding_handler_->GetAlert();
  NotifyWinEventWrapper(alert_node, ax::mojom::Event::kAlert);
}

void FlutterWindowsView::NotifyWinEventWrapper(ui::AXPlatformNodeWin* node,
                                               ax::mojom::Event event) {
  if (node) {
    node->NotifyAccessibilityEvent(event);
  }
}

ui::AXFragmentRootDelegateWin* FlutterWindowsView::GetAxFragmentRootDelegate() {
  return engine_->accessibility_bridge().lock().get();
}

ui::AXPlatformNodeWin* FlutterWindowsView::AlertNode() const {
  return binding_handler_->GetAlert();
}

}  // namespace flutter
