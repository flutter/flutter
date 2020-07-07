#include "flutter/shell/platform/windows/flutter_windows_view.h"

#include <chrono>

namespace flutter {

FlutterWindowsView::FlutterWindowsView() {
  surface_manager_ = std::make_unique<AngleSurfaceManager>();
}

FlutterWindowsView::~FlutterWindowsView() {
  DestroyRenderSurface();
  if (plugin_registrar_ && plugin_registrar_->destruction_handler) {
    plugin_registrar_->destruction_handler(plugin_registrar_.get());
  }
}

FlutterDesktopViewControllerRef FlutterWindowsView::CreateFlutterWindowsView(
    std::unique_ptr<WindowBindingHandler> windowbinding) {
  auto state = std::make_unique<FlutterDesktopViewControllerState>();
  state->view = std::make_unique<flutter::FlutterWindowsView>();

  // FlutterWindowsView instance owns windowbinding
  state->view->binding_handler_ = std::move(windowbinding);

  // a window wrapper for the state block, distinct from the
  // window_wrapper handed to plugin_registrar.
  state->view_wrapper = std::make_unique<FlutterDesktopView>();

  // Give the binding handler a pointer back to this | FlutterWindowsView |
  state->view->binding_handler_->SetView(state->view.get());

  // opaque pointer to FlutterWindowsView
  state->view_wrapper->view = state->view.get();

  state->view->render_target_ = std::make_unique<WindowsRenderTarget>(
      state->view->binding_handler_->GetRenderTarget());

  return state.release();
}

void FlutterWindowsView::SetState(FLUTTER_API_SYMBOL(FlutterEngine) eng) {
  engine_ = eng;

  auto messenger = std::make_unique<FlutterDesktopMessenger>();
  message_dispatcher_ =
      std::make_unique<flutter::IncomingMessageDispatcher>(messenger.get());
  messenger->engine = engine_;
  messenger->dispatcher = message_dispatcher_.get();

  window_wrapper_ = std::make_unique<FlutterDesktopView>();
  window_wrapper_->view = this;
  plugin_registrar_ = std::make_unique<FlutterDesktopPluginRegistrar>();
  plugin_registrar_->messenger = std::move(messenger);
  plugin_registrar_->view = window_wrapper_.get();

  internal_plugin_registrar_ =
      std::make_unique<flutter::PluginRegistrar>(plugin_registrar_.get());

  // Set up the keyboard handlers.
  auto internal_plugin_messenger = internal_plugin_registrar_->messenger();
  keyboard_hook_handlers_.push_back(
      std::make_unique<flutter::KeyEventHandler>(internal_plugin_messenger));
  keyboard_hook_handlers_.push_back(
      std::make_unique<flutter::TextInputPlugin>(internal_plugin_messenger));
  platform_handler_ = std::make_unique<flutter::PlatformHandler>(
      internal_plugin_messenger, this);

  PhysicalWindowBounds bounds = binding_handler_->GetPhysicalWindowBounds();

  SendWindowMetrics(bounds.width, bounds.height,
                    binding_handler_->GetDpiScale());
}

FlutterDesktopPluginRegistrarRef FlutterWindowsView::GetRegistrar() {
  return plugin_registrar_.get();
}

// Converts a FlutterPlatformMessage to an equivalent FlutterDesktopMessage.
static FlutterDesktopMessage ConvertToDesktopMessage(
    const FlutterPlatformMessage& engine_message) {
  FlutterDesktopMessage message = {};
  message.struct_size = sizeof(message);
  message.channel = engine_message.channel;
  message.message = engine_message.message;
  message.message_size = engine_message.message_size;
  message.response_handle = engine_message.response_handle;
  return message;
}

// The Flutter Engine calls out to this function when new platform messages
// are available.
void FlutterWindowsView::HandlePlatformMessage(
    const FlutterPlatformMessage* engine_message) {
  if (engine_message->struct_size != sizeof(FlutterPlatformMessage)) {
    std::cerr << "Invalid message size received. Expected: "
              << sizeof(FlutterPlatformMessage) << " but received "
              << engine_message->struct_size << std::endl;
    return;
  }

  auto message = ConvertToDesktopMessage(*engine_message);

  message_dispatcher_->HandleMessage(
      message, [this] {}, [this] {});
}

void FlutterWindowsView::OnWindowSizeChanged(size_t width,
                                             size_t height) const {
  SendWindowMetrics(width, height, binding_handler_->GetDpiScale());
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

void FlutterWindowsView::OnKey(int key,
                               int scancode,
                               int action,
                               char32_t character) {
  SendKey(key, scancode, action, character);
}

void FlutterWindowsView::OnScroll(double x,
                                  double y,
                                  double delta_x,
                                  double delta_y,
                                  int scroll_offset_multiplier) {
  SendScroll(x, y, delta_x, delta_y, scroll_offset_multiplier);
}

void FlutterWindowsView::OnFontChange() {
  if (engine_ == nullptr) {
    return;
  }
  FlutterEngineReloadSystemFonts(engine_);
}

// Sends new size  information to FlutterEngine.
void FlutterWindowsView::SendWindowMetrics(size_t width,
                                           size_t height,
                                           double dpiScale) const {
  if (engine_ == nullptr) {
    return;
  }

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = width;
  event.height = height;
  event.pixel_ratio = dpiScale;
  auto result = FlutterEngineSendWindowMetricsEvent(engine_, &event);
}

// Set's |event_data|'s phase to either kMove or kHover depending on the current
// primary mouse button state.
void FlutterWindowsView::SetEventPhaseFromCursorButtonState(
    FlutterPointerEvent* event_data) const {
  // For details about this logic, see FlutterPointerPhase in the embedder.h
  // file.
  event_data->phase =
      mouse_state_.buttons == 0
          ? mouse_state_.flutter_state_is_down ? FlutterPointerPhase::kUp
                                               : FlutterPointerPhase::kHover
          : mouse_state_.flutter_state_is_down ? FlutterPointerPhase::kMove
                                               : FlutterPointerPhase::kDown;
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

void FlutterWindowsView::SendKey(int key,
                                 int scancode,
                                 int action,
                                 char32_t character) {
  for (const auto& handler : keyboard_hook_handlers_) {
    handler->KeyboardHook(this, key, scancode, action, character);
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

  FlutterEngineSendPointerEvent(engine_, &event, 1);

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
  return surface_manager_->SwapBuffers();
}

void FlutterWindowsView::CreateRenderSurface() {
  surface_manager_->CreateSurface(render_target_.get());
}

void FlutterWindowsView::DestroyRenderSurface() {
  if (surface_manager_) {
    surface_manager_->DestroySurface();
  }
}

WindowsRenderTarget* FlutterWindowsView::GetRenderTarget() {
  return render_target_.get();
}

}  // namespace flutter
