#include "flutter/shell/platform/windows/win32_flutter_window.h"

#include <chrono>

namespace flutter {

// the Windows DPI system is based on this
// constant for machines running at 100% scaling.
constexpr int base_dpi = 96;

Win32FlutterWindow::Win32FlutterWindow(int width, int height) {
  surface_manager = std::make_unique<AngleSurfaceManager>();
  Win32Window::InitializeChild("FLUTTERVIEW", width, height);
}

Win32FlutterWindow::~Win32FlutterWindow() {
  DestroyRenderSurface();
  Win32Window::Destroy();
}

FlutterDesktopViewControllerRef Win32FlutterWindow::CreateWin32FlutterWindow(
    const int width,
    const int height) {
  auto state = std::make_unique<FlutterDesktopViewControllerState>();
  state->view = std::make_unique<flutter::Win32FlutterWindow>(width, height);

  // a window wrapper for the state block, distinct from the
  // window_wrapper handed to plugin_registrar.
  state->view_wrapper = std::make_unique<FlutterDesktopView>();
  state->view_wrapper->window = state->view.get();
  return state.release();
}

void Win32FlutterWindow::SetState(FLUTTER_API_SYMBOL(FlutterEngine) eng) {
  engine_ = eng;

  auto messenger = std::make_unique<FlutterDesktopMessenger>();
  message_dispatcher_ =
      std::make_unique<flutter::IncomingMessageDispatcher>(messenger.get());
  messenger->engine = engine_;
  messenger->dispatcher = message_dispatcher_.get();

  window_wrapper_ = std::make_unique<FlutterDesktopView>();
  window_wrapper_->window = this;

  plugin_registrar_ = std::make_unique<FlutterDesktopPluginRegistrar>();
  plugin_registrar_->messenger = std::move(messenger);
  plugin_registrar_->window = window_wrapper_.get();

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

  auto state = std::make_unique<FlutterDesktopViewControllerState>();
  state->engine = engine_;

  process_events_ = true;
}

FlutterDesktopPluginRegistrarRef Win32FlutterWindow::GetRegistrar() {
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
void Win32FlutterWindow::HandlePlatformMessage(
    const FlutterPlatformMessage* engine_message) {
  if (engine_message->struct_size != sizeof(FlutterPlatformMessage)) {
    std::cerr << "Invalid message size received. Expected: "
              << sizeof(FlutterPlatformMessage) << " but received "
              << engine_message->struct_size << std::endl;
    return;
  }

  auto message = ConvertToDesktopMessage(*engine_message);

  message_dispatcher_->HandleMessage(
      message, [this] { this->process_events_ = false; },
      [this] { this->process_events_ = true; });
}

void Win32FlutterWindow::OnDpiScale(unsigned int dpi){};

// When DesktopWindow notifies that a WM_Size message has come in
// lets FlutterEngine know about the new size.
void Win32FlutterWindow::OnResize(unsigned int width, unsigned int height) {
  SendWindowMetrics();
}

void Win32FlutterWindow::OnPointerMove(double x, double y) {
  if (process_events_) {
    SendPointerMove(x, y);
  }
}

void Win32FlutterWindow::OnPointerDown(double x, double y) {
  if (process_events_) {
    SendPointerDown(x, y);
  }
}

void Win32FlutterWindow::OnPointerUp(double x, double y) {
  if (process_events_) {
    SendPointerUp(x, y);
  }
}

void Win32FlutterWindow::OnChar(unsigned int code_point) {
  if (process_events_) {
    SendChar(code_point);
  }
}

void Win32FlutterWindow::OnKey(int key, int scancode, int action, int mods) {
  if (process_events_) {
    SendKey(key, scancode, action, 0);
  }
}

void Win32FlutterWindow::OnScroll(double delta_x, double delta_y) {
  if (process_events_) {
    SendScroll(delta_x, delta_y);
  }
}

void Win32FlutterWindow::OnClose() {
  messageloop_running_ = false;
}

// Sends new size information to FlutterEngine.
void Win32FlutterWindow::SendWindowMetrics() {
  if (engine_ == nullptr) {
    return;
  }

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = GetCurrentWidth();
  event.height = GetCurrentHeight();
  event.pixel_ratio = static_cast<double>(GetCurrentDPI()) / base_dpi;
  auto result = FlutterEngineSendWindowMetricsEvent(engine_, &event);
}

// Updates |event_data| with the current location of the mouse cursor.
void Win32FlutterWindow::SetEventLocationFromCursorPosition(
    FlutterPointerEvent* event_data) {
  POINT point;
  GetCursorPos(&point);

  ScreenToClient(GetWindowHandle(), &point);

  event_data->x = point.x;
  event_data->y = point.y;
}

// Set's |event_data|'s phase to either kMove or kHover depending on the current
// primary mouse button state.
void Win32FlutterWindow::SetEventPhaseFromCursorButtonState(
    FlutterPointerEvent* event_data) {
  event_data->phase = pointer_is_down_ ? FlutterPointerPhase::kMove
                                       : FlutterPointerPhase::kHover;
}

void Win32FlutterWindow::SendPointerMove(double x, double y) {
  FlutterPointerEvent event = {};
  event.x = x;
  event.y = y;
  SetEventPhaseFromCursorButtonState(&event);
  SendPointerEventWithData(event);
}

void Win32FlutterWindow::SendPointerDown(double x, double y) {
  pointer_is_down_ = true;
  FlutterPointerEvent event = {};
  event.phase = FlutterPointerPhase::kDown;
  event.x = x;
  event.y = y;
  SendPointerEventWithData(event);
}

void Win32FlutterWindow::SendPointerUp(double x, double y) {
  pointer_is_down_ = false;
  FlutterPointerEvent event = {};
  event.phase = FlutterPointerPhase::kUp;
  event.x = x;
  event.y = y;
  SendPointerEventWithData(event);
}

void Win32FlutterWindow::SendChar(unsigned int code_point) {
  for (const auto& handler : keyboard_hook_handlers_) {
    handler->CharHook(this, code_point);
  }
}

void Win32FlutterWindow::SendKey(int key, int scancode, int action, int mods) {
  for (const auto& handler : keyboard_hook_handlers_) {
    handler->KeyboardHook(this, key, scancode, action, mods);
  }
}

void Win32FlutterWindow::SendScroll(double delta_x, double delta_y) {
  FlutterPointerEvent event = {};
  SetEventLocationFromCursorPosition(&event);
  SetEventPhaseFromCursorButtonState(&event);
  event.signal_kind = FlutterPointerSignalKind::kFlutterPointerSignalKindScroll;
  // TODO: See if this can be queried from the OS; this value is chosen
  // arbitrarily to get something that feels reasonable.
  const int kScrollOffsetMultiplier = 20;
  event.scroll_delta_x = delta_x * kScrollOffsetMultiplier;
  event.scroll_delta_y = delta_y * kScrollOffsetMultiplier;
  SendPointerEventWithData(event);
}

void Win32FlutterWindow::SendPointerEventWithData(
    const FlutterPointerEvent& event_data) {
  // If sending anything other than an add, and the pointer isn't already added,
  // synthesize an add to satisfy Flutter's expectations about events.
  if (!pointer_currently_added_ &&
      event_data.phase != FlutterPointerPhase::kAdd) {
    FlutterPointerEvent event = {};
    event.phase = FlutterPointerPhase::kAdd;
    event.x = event_data.x;
    event.y = event_data.y;
    SendPointerEventWithData(event);
  }
  // Don't double-add (e.g., if events are delivered out of order, so an add has
  // already been synthesized).
  if (pointer_currently_added_ &&
      event_data.phase == FlutterPointerPhase::kAdd) {
    return;
  }

  FlutterPointerEvent event = event_data;
  // Set metadata that's always the same regardless of the event.
  event.struct_size = sizeof(event);
  event.timestamp =
      std::chrono::duration_cast<std::chrono::microseconds>(
          std::chrono::high_resolution_clock::now().time_since_epoch())
          .count();

  // Windows passes all input in either physical pixels (Per-monitor, System
  // DPI) or pre-scaled to match bitmap scaling of output where process is
  // running in DPI unaware more.  In either case, no need to manually scale
  // input here.  For more information see DPIHelper.
  event.scroll_delta_x;
  event.scroll_delta_y;

  FlutterEngineSendPointerEvent(engine_, &event, 1);

  if (event_data.phase == FlutterPointerPhase::kAdd) {
    pointer_currently_added_ = true;
  } else if (event_data.phase == FlutterPointerPhase::kRemove) {
    pointer_currently_added_ = false;
  }
}

bool Win32FlutterWindow::MakeCurrent() {
  return surface_manager->MakeCurrent(render_surface);
}

bool Win32FlutterWindow::MakeResourceCurrent() {
  return surface_manager->MakeResourceCurrent();
}

bool Win32FlutterWindow::ClearContext() {
  return surface_manager->MakeCurrent(nullptr);
}

bool Win32FlutterWindow::SwapBuffers() {
  return surface_manager->SwapBuffers(render_surface);
}

void Win32FlutterWindow::CreateRenderSurface() {
  if (surface_manager && render_surface == EGL_NO_SURFACE) {
    render_surface = surface_manager->CreateSurface(GetWindowHandle());
  }
}

void Win32FlutterWindow::DestroyRenderSurface() {
  if (surface_manager) {
    surface_manager->DestroySurface(render_surface);
  }
  render_surface = EGL_NO_SURFACE;
}

}  // namespace flutter
