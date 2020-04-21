#include "flutter/shell/platform/windows/win32_flutter_window.h"

#include <chrono>

namespace flutter {

// The Windows DPI system is based on this
// constant for machines running at 100% scaling.
constexpr int base_dpi = 96;

Win32FlutterWindow::Win32FlutterWindow(int width, int height) {
  surface_manager = std::make_unique<AngleSurfaceManager>();
  Win32Window::InitializeChild("FLUTTERVIEW", width, height);
}

Win32FlutterWindow::~Win32FlutterWindow() {
  DestroyRenderSurface();
  if (plugin_registrar_ && plugin_registrar_->destruction_handler) {
    plugin_registrar_->destruction_handler(plugin_registrar_.get());
  }
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

// Translates button codes from Win32 API to FlutterPointerMouseButtons.
static uint64_t ConvertWinButtonToFlutterButton(UINT button) {
  switch (button) {
    case WM_LBUTTONDOWN:
    case WM_LBUTTONUP:
      return kFlutterPointerButtonMousePrimary;
    case WM_RBUTTONDOWN:
    case WM_RBUTTONUP:
      return kFlutterPointerButtonMouseSecondary;
    case WM_MBUTTONDOWN:
    case WM_MBUTTONUP:
      return kFlutterPointerButtonMouseMiddle;
    case XBUTTON1:
      return kFlutterPointerButtonMouseBack;
    case XBUTTON2:
      return kFlutterPointerButtonMouseForward;
  }
  std::cerr << "Mouse button not recognized: " << button << std::endl;
  return 0;
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

void Win32FlutterWindow::OnPointerDown(double x, double y, UINT button) {
  if (process_events_) {
    uint64_t flutter_button = ConvertWinButtonToFlutterButton(button);
    if (flutter_button != 0) {
      uint64_t mouse_buttons = GetMouseState().buttons | flutter_button;
      SetMouseButtons(mouse_buttons);
      SendPointerDown(x, y);
    }
  }
}

void Win32FlutterWindow::OnPointerUp(double x, double y, UINT button) {
  if (process_events_) {
    uint64_t flutter_button = ConvertWinButtonToFlutterButton(button);
    if (flutter_button != 0) {
      uint64_t mouse_buttons = GetMouseState().buttons & ~flutter_button;
      SetMouseButtons(mouse_buttons);
      SendPointerUp(x, y);
    }
  }
}

void Win32FlutterWindow::OnPointerLeave() {
  if (process_events_) {
    SendPointerLeave();
  }
}

void Win32FlutterWindow::OnText(const std::u16string& text) {
  if (process_events_) {
    SendText(text);
  }
}

void Win32FlutterWindow::OnKey(int key,
                               int scancode,
                               int action,
                               char32_t character) {
  if (process_events_) {
    SendKey(key, scancode, action, character);
  }
}

void Win32FlutterWindow::OnScroll(double delta_x, double delta_y) {
  if (process_events_) {
    SendScroll(delta_x, delta_y);
  }
}

void Win32FlutterWindow::OnFontChange() {
  if (engine_ == nullptr) {
    return;
  }
  FlutterEngineReloadSystemFonts(engine_);
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
  MouseState state = GetMouseState();
  // For details about this logic, see FlutterPointerPhase in the embedder.h
  // file.
  event_data->phase = state.buttons == 0 ? state.flutter_state_is_down
                                               ? FlutterPointerPhase::kUp
                                               : FlutterPointerPhase::kHover
                                         : state.flutter_state_is_down
                                               ? FlutterPointerPhase::kMove
                                               : FlutterPointerPhase::kDown;
}

void Win32FlutterWindow::SendPointerMove(double x, double y) {
  FlutterPointerEvent event = {};
  event.x = x;
  event.y = y;
  SetEventPhaseFromCursorButtonState(&event);
  SendPointerEventWithData(event);
}

void Win32FlutterWindow::SendPointerDown(double x, double y) {
  FlutterPointerEvent event = {};
  SetEventPhaseFromCursorButtonState(&event);
  event.x = x;
  event.y = y;
  SendPointerEventWithData(event);
  SetMouseFlutterStateDown(true);
}

void Win32FlutterWindow::SendPointerUp(double x, double y) {
  FlutterPointerEvent event = {};
  SetEventPhaseFromCursorButtonState(&event);
  event.x = x;
  event.y = y;
  SendPointerEventWithData(event);
  if (event.phase == FlutterPointerPhase::kUp) {
    SetMouseFlutterStateDown(false);
  }
}

void Win32FlutterWindow::SendPointerLeave() {
  FlutterPointerEvent event = {};
  event.phase = FlutterPointerPhase::kRemove;
  SendPointerEventWithData(event);
}

void Win32FlutterWindow::SendText(const std::u16string& text) {
  for (const auto& handler : keyboard_hook_handlers_) {
    handler->TextHook(this, text);
  }
}

void Win32FlutterWindow::SendKey(int key,
                                 int scancode,
                                 int action,
                                 char32_t character) {
  for (const auto& handler : keyboard_hook_handlers_) {
    handler->KeyboardHook(this, key, scancode, action, character);
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
  MouseState mouse_state = GetMouseState();
  // If sending anything other than an add, and the pointer isn't already added,
  // synthesize an add to satisfy Flutter's expectations about events.
  if (!mouse_state.flutter_state_is_added &&
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
  if (mouse_state.flutter_state_is_added &&
      event_data.phase == FlutterPointerPhase::kAdd) {
    return;
  }

  FlutterPointerEvent event = event_data;
  event.device_kind = kFlutterPointerDeviceKindMouse;
  event.buttons = mouse_state.buttons;

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
