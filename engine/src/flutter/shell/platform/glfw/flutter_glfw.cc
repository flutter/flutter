// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/glfw/public/flutter_glfw.h"

#include <assert.h>
#include <algorithm>
#include <chrono>
#include <cstdlib>
#include <iostream>

#include <GLFW/glfw3.h>

#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/plugin_registrar.h"
#include "flutter/shell/platform/common/cpp/incoming_message_dispatcher.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/glfw/key_event_handler.h"
#include "flutter/shell/platform/glfw/keyboard_hook_handler.h"
#include "flutter/shell/platform/glfw/text_input_plugin.h"

#ifdef __linux__
// For plugin-compatible event handling (e.g., modal windows).
#include <X11/Xlib.h>
#include <gtk/gtk.h>
#endif

// GLFW_TRUE & GLFW_FALSE are introduced since libglfw-3.3,
// add definitions here to compile under the old versions.
#ifndef GLFW_TRUE
#define GLFW_TRUE 1
#endif
#ifndef GLFW_FALSE
#define GLFW_FALSE 0
#endif

static_assert(FLUTTER_ENGINE_VERSION == 1, "");

static constexpr double kDpPerInch = 160.0;

// Struct for storing state within an instance of the GLFW Window.
struct FlutterDesktopWindowState {
  // The GLFW window that owns this state object.
  GLFWwindow* window;

  // The handle to the Flutter engine instance.
  FlutterEngine engine;

  // The plugin registrar handle given to API clients.
  std::unique_ptr<FlutterDesktopPluginRegistrar> plugin_registrar;

  // Message dispatch manager for messages from the Flutter engine.
  std::unique_ptr<shell::IncomingMessageDispatcher> message_dispatcher;

  // The plugin registrar managing internal plugins.
  std::unique_ptr<flutter::PluginRegistrar> internal_plugin_registrar;

  // Handlers for keyboard events from GLFW.
  std::vector<std::unique_ptr<shell::KeyboardHookHandler>>
      keyboard_hook_handlers;

  // Whether or not to track mouse movements to send kHover events.
  bool hover_tracking_enabled = false;

  // Whether or not the pointer has been added (or if tracking is enabled, has
  // been added since it was last removed).
  bool pointer_currently_added = false;

  // The screen coordinates per inch on the primary monitor. Defaults to a sane
  // value based on pixel_ratio 1.0.
  double monitor_screen_coordinates_per_inch = kDpPerInch;
  // The ratio of pixels per screen coordinate for the window.
  double window_pixels_per_screen_coordinate = 1.0;
};

// Struct for storing state of a Flutter engine instance.
struct FlutterDesktopEngineState {
  // The handle to the Flutter engine instance.
  FlutterEngine engine;
};

// State associated with the plugin registrar.
struct FlutterDesktopPluginRegistrar {
  // The plugin messenger handle given to API clients.
  std::unique_ptr<FlutterDesktopMessenger> messenger;
};

// State associated with the messenger used to communicate with the engine.
struct FlutterDesktopMessenger {
  // The Flutter engine this messenger sends outgoing messages to.
  FlutterEngine engine;

  // The message dispatcher for handling incoming messages.
  shell::IncomingMessageDispatcher* dispatcher;
};

static constexpr char kDefaultWindowTitle[] = "Flutter";

// Retrieves state bag for the window in question from the GLFWWindow.
static FlutterDesktopWindowState* GetSavedWindowState(GLFWwindow* window) {
  return reinterpret_cast<FlutterDesktopWindowState*>(
      glfwGetWindowUserPointer(window));
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

// Returns the number of screen coordinates per inch for the main monitor.
// If the information is unavailable, returns a default value that assumes
// that a screen coordinate is one dp.
static double GetScreenCoordinatesPerInch() {
  auto* primary_monitor = glfwGetPrimaryMonitor();
  auto* primary_monitor_mode = glfwGetVideoMode(primary_monitor);
  int primary_monitor_width_mm;
  glfwGetMonitorPhysicalSize(primary_monitor, &primary_monitor_width_mm,
                             nullptr);
  if (primary_monitor_width_mm == 0) {
    return kDpPerInch;
  }
  return primary_monitor_mode->width / (primary_monitor_width_mm / 25.4);
}

// When GLFW calls back to the window with a framebuffer size change, notify
// FlutterEngine about the new window metrics.
// The Flutter pixel_ratio is defined as DPI/dp.
static void GLFWFramebufferSizeCallback(GLFWwindow* window,
                                        int width_px,
                                        int height_px) {
  int width;
  glfwGetWindowSize(window, &width, nullptr);

  auto state = GetSavedWindowState(window);
  state->window_pixels_per_screen_coordinate = width_px / width;

  double dpi = state->window_pixels_per_screen_coordinate *
               state->monitor_screen_coordinates_per_inch;
  // Limit the ratio to 1 to avoid rendering a smaller UI in standard resolution
  // monitors.
  double pixel_ratio = std::max(dpi / kDpPerInch, 1.0);

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = width_px;
  event.height = height_px;
  event.pixel_ratio = pixel_ratio;
  FlutterEngineSendWindowMetricsEvent(state->engine, &event);
}

// Sends a pointer event to the Flutter engine with the given phase.
static void SendPointerEventWithPhase(GLFWwindow* window,
                                      FlutterPointerPhase phase,
                                      double x,
                                      double y) {
  auto state = GetSavedWindowState(window);
  // If sending anything other than an add, and the pointer isn't already added,
  // synthesize an add to satisfy Flutter's expectations about events.
  if (!state->pointer_currently_added && phase != FlutterPointerPhase::kAdd) {
    SendPointerEventWithPhase(window, FlutterPointerPhase::kAdd, x, y);
  }
  // Don't double-add (e.g., if events are delivered out of order, so an add has
  // already been synthesized).
  if (state->pointer_currently_added && phase == FlutterPointerPhase::kAdd) {
    return;
  }

  FlutterPointerEvent event = {};
  event.struct_size = sizeof(event);
  event.phase = phase;
  event.x = x * state->window_pixels_per_screen_coordinate;
  event.y = y * state->window_pixels_per_screen_coordinate;
  event.timestamp =
      std::chrono::duration_cast<std::chrono::microseconds>(
          std::chrono::high_resolution_clock::now().time_since_epoch())
          .count();
  FlutterEngineSendPointerEvent(state->engine, &event, 1);

  if (phase == FlutterPointerPhase::kAdd) {
    state->pointer_currently_added = true;
  } else if (phase == FlutterPointerPhase::kRemove) {
    state->pointer_currently_added = false;
  }
}

// Reports the mouse entering or leaving the Flutter view.
static void GLFWCursorEnterCallback(GLFWwindow* window, int entered) {
  double x, y;
  glfwGetCursorPos(window, &x, &y);
  FlutterPointerPhase phase =
      entered ? FlutterPointerPhase::kAdd : FlutterPointerPhase::kRemove;
  SendPointerEventWithPhase(window, phase, x, y);
}

// Reports mouse movement to the Flutter engine.
static void GLFWCursorPositionCallback(GLFWwindow* window, double x, double y) {
  bool button_down =
      glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_LEFT) == GLFW_PRESS;
  FlutterPointerPhase phase =
      button_down ? FlutterPointerPhase::kMove : FlutterPointerPhase::kHover;
  SendPointerEventWithPhase(window, phase, x, y);
}

// Reports mouse button press to the Flutter engine.
static void GLFWMouseButtonCallback(GLFWwindow* window,
                                    int key,
                                    int action,
                                    int mods) {
  // Flutter currently doesn't understand other buttons, so ignore anything
  // other than left.
  if (key != GLFW_MOUSE_BUTTON_LEFT) {
    return;
  }

  double x, y;
  glfwGetCursorPos(window, &x, &y);
  FlutterPointerPhase phase = (action == GLFW_PRESS)
                                  ? FlutterPointerPhase::kDown
                                  : FlutterPointerPhase::kUp;
  SendPointerEventWithPhase(window, phase, x, y);

  // If mouse tracking isn't already enabled, turn it on for the duration of
  // the drag to generate kMove events.
  bool hover_enabled = GetSavedWindowState(window)->hover_tracking_enabled;
  if (!hover_enabled) {
    glfwSetCursorPosCallback(
        window, (action == GLFW_PRESS) ? GLFWCursorPositionCallback : nullptr);
  }
  // Disable enter/exit events while the mouse button is down; GLFW will send
  // an exit event when the mouse button is released, and the pointer should
  // stay valid until then.
  if (hover_enabled) {
    glfwSetCursorEnterCallback(
        window, (action == GLFW_PRESS) ? nullptr : GLFWCursorEnterCallback);
  }
}

// Passes character input events to registered handlers.
static void GLFWCharCallback(GLFWwindow* window, unsigned int code_point) {
  for (const auto& handler :
       GetSavedWindowState(window)->keyboard_hook_handlers) {
    handler->CharHook(window, code_point);
  }
}

// Passes raw key events to registered handlers.
static void GLFWKeyCallback(GLFWwindow* window,
                            int key,
                            int scancode,
                            int action,
                            int mods) {
  for (const auto& handler :
       GetSavedWindowState(window)->keyboard_hook_handlers) {
    handler->KeyboardHook(window, key, scancode, action, mods);
  }
}

// Enables/disables the callbacks related to mouse tracking.
static void SetHoverCallbacksEnabled(GLFWwindow* window, bool enabled) {
  glfwSetCursorEnterCallback(window,
                             enabled ? GLFWCursorEnterCallback : nullptr);
  glfwSetCursorPosCallback(window,
                           enabled ? GLFWCursorPositionCallback : nullptr);
}

// Flushes event queue and then assigns default window callbacks.
static void GLFWAssignEventCallbacks(GLFWwindow* window) {
  glfwPollEvents();
  glfwSetKeyCallback(window, GLFWKeyCallback);
  glfwSetCharCallback(window, GLFWCharCallback);
  glfwSetMouseButtonCallback(window, GLFWMouseButtonCallback);
  if (GetSavedWindowState(window)->hover_tracking_enabled) {
    SetHoverCallbacksEnabled(window, true);
  }
}

// Clears default window events.
static void GLFWClearEventCallbacks(GLFWwindow* window) {
  glfwSetKeyCallback(window, nullptr);
  glfwSetCharCallback(window, nullptr);
  glfwSetMouseButtonCallback(window, nullptr);
  SetHoverCallbacksEnabled(window, false);
}

// The Flutter Engine calls out to this function when new platform messages are
// available
static void GLFWOnFlutterPlatformMessage(
    const FlutterPlatformMessage* engine_message,
    void* user_data) {
  if (engine_message->struct_size != sizeof(FlutterPlatformMessage)) {
    std::cerr << "Invalid message size received. Expected: "
              << sizeof(FlutterPlatformMessage) << " but received "
              << engine_message->struct_size << std::endl;
    return;
  }

  GLFWwindow* window = reinterpret_cast<GLFWwindow*>(user_data);
  auto state = GetSavedWindowState(window);

  auto message = ConvertToDesktopMessage(*engine_message);
  state->message_dispatcher->HandleMessage(
      message, [window] { GLFWClearEventCallbacks(window); },
      [window] { GLFWAssignEventCallbacks(window); });
}

static bool GLFWMakeContextCurrent(void* user_data) {
  GLFWwindow* window = reinterpret_cast<GLFWwindow*>(user_data);
  glfwMakeContextCurrent(window);
  return true;
}

static bool GLFWClearContext(void* user_data) {
  glfwMakeContextCurrent(nullptr);
  return true;
}

static bool GLFWPresent(void* user_data) {
  GLFWwindow* window = reinterpret_cast<GLFWwindow*>(user_data);
  glfwSwapBuffers(window);
  return true;
}

static uint32_t GLFWGetActiveFbo(void* user_data) {
  return 0;
}

// Clears the GLFW window to Material Blue-Grey.
//
// This function is primarily to fix an issue when the Flutter Engine is
// spinning up, wherein artifacts of existing windows are rendered onto the
// canvas for a few moments.
//
// This function isn't necessary, but makes starting the window much easier on
// the eyes.
static void GLFWClearCanvas(GLFWwindow* window) {
  glfwMakeContextCurrent(window);
  // This color is Material Blue Grey.
  glClearColor(236.0f / 255.0f, 239.0f / 255.0f, 241.0f / 255.0f, 0.0f);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glFlush();
  glfwSwapBuffers(window);
  glfwMakeContextCurrent(nullptr);
}

// Resolves the address of the specified OpenGL or OpenGL ES
// core or extension function, if it is supported by the current context.
static void* GLFWProcResolver(void* user_data, const char* name) {
  return reinterpret_cast<void*>(glfwGetProcAddress(name));
}

static void GLFWErrorCallback(int error_code, const char* description) {
  std::cerr << "GLFW error " << error_code << ": " << description << std::endl;
}

// Spins up an instance of the Flutter Engine.
//
// This function launches the Flutter Engine in a background thread, supplying
// the necessary callbacks for rendering within a GLFWwindow (if one is
// provided).
//
// Returns a caller-owned pointer to the engine.
static FlutterEngine RunFlutterEngine(GLFWwindow* window,
                                      const char* assets_path,
                                      const char* icu_data_path,
                                      const char** arguments,
                                      size_t arguments_count) {
  // FlutterProjectArgs is expecting a full argv, so when processing it for
  // flags the first item is treated as the executable and ignored. Add a dummy
  // value so that all provided arguments are used.
  std::vector<const char*> argv = {"placeholder"};
  if (arguments_count > 0) {
    argv.insert(argv.end(), &arguments[0], &arguments[arguments_count]);
  }

  FlutterRendererConfig config = {};
  if (window == nullptr) {
    config.type = kOpenGL;
    config.open_gl.struct_size = sizeof(config.open_gl);
    config.open_gl.make_current = [](void* data) -> bool { return false; };
    config.open_gl.clear_current = [](void* data) -> bool { return false; };
    config.open_gl.present = [](void* data) -> bool { return false; };
    config.open_gl.fbo_callback = [](void* data) -> uint32_t { return 0; };
  } else {
    // Provide the necessary callbacks for rendering within a GLFWwindow.
    config.type = kOpenGL;
    config.open_gl.struct_size = sizeof(config.open_gl);
    config.open_gl.make_current = GLFWMakeContextCurrent;
    config.open_gl.clear_current = GLFWClearContext;
    config.open_gl.present = GLFWPresent;
    config.open_gl.fbo_callback = GLFWGetActiveFbo;
    config.open_gl.gl_proc_resolver = GLFWProcResolver;
  }
  FlutterProjectArgs args = {};
  args.struct_size = sizeof(FlutterProjectArgs);
  args.assets_path = assets_path;
  args.icu_data_path = icu_data_path;
  args.command_line_argc = static_cast<int>(argv.size());
  args.command_line_argv = &argv[0];
  args.platform_message_callback = GLFWOnFlutterPlatformMessage;
  FlutterEngine engine = nullptr;
  auto result =
      FlutterEngineRun(FLUTTER_ENGINE_VERSION, &config, &args, window, &engine);
  if (result != kSuccess || engine == nullptr) {
    std::cerr << "Failed to start Flutter engine: error " << result
              << std::endl;
    return nullptr;
  }
  return engine;
}

bool FlutterDesktopInit() {
  // Before making any GLFW calls, set up a logging error handler.
  glfwSetErrorCallback(GLFWErrorCallback);
  return glfwInit();
}

void FlutterDesktopTerminate() {
  glfwTerminate();
}

FlutterDesktopWindowRef FlutterDesktopCreateWindow(int initial_width,
                                                   int initial_height,
                                                   const char* assets_path,
                                                   const char* icu_data_path,
                                                   const char** arguments,
                                                   size_t argument_count) {
#ifdef __linux__
  gtk_init(0, nullptr);
#endif
  // Create the window.
  auto window = glfwCreateWindow(initial_width, initial_height,
                                 kDefaultWindowTitle, NULL, NULL);
  if (window == nullptr) {
    return nullptr;
  }
  GLFWClearCanvas(window);

  // Start the engine.
  auto engine = RunFlutterEngine(window, assets_path, icu_data_path, arguments,
                                 argument_count);
  if (engine == nullptr) {
    glfwDestroyWindow(window);
    return nullptr;
  }

  // Create a state object attached to the window.
  FlutterDesktopWindowState* state = new FlutterDesktopWindowState();
  state->window = window;
  glfwSetWindowUserPointer(window, state);
  state->engine = engine;

  // TODO: Restructure the internals to follow the structure of the C++ API, so
  // that this isn't a tangle of references.
  auto messenger = std::make_unique<FlutterDesktopMessenger>();
  state->message_dispatcher =
      std::make_unique<shell::IncomingMessageDispatcher>(messenger.get());
  messenger->engine = engine;
  messenger->dispatcher = state->message_dispatcher.get();

  state->plugin_registrar = std::make_unique<FlutterDesktopPluginRegistrar>();
  state->plugin_registrar->messenger = std::move(messenger);

  state->internal_plugin_registrar =
      std::make_unique<flutter::PluginRegistrar>(state->plugin_registrar.get());

  // Set up the keyboard handlers.
  auto internal_plugin_messenger =
      state->internal_plugin_registrar->messenger();
  state->keyboard_hook_handlers.push_back(
      std::make_unique<shell::KeyEventHandler>(internal_plugin_messenger));
  state->keyboard_hook_handlers.push_back(
      std::make_unique<shell::TextInputPlugin>(internal_plugin_messenger));

  // Trigger an initial size callback to send size information to Flutter.
  state->monitor_screen_coordinates_per_inch = GetScreenCoordinatesPerInch();
  int width_px, height_px;
  glfwGetFramebufferSize(window, &width_px, &height_px);
  GLFWFramebufferSizeCallback(window, width_px, height_px);

  // Set up GLFW callbacks for the window.
  glfwSetFramebufferSizeCallback(window, GLFWFramebufferSizeCallback);
  GLFWAssignEventCallbacks(window);

  return state;
}

void FlutterDesktopSetHoverEnabled(FlutterDesktopWindowRef flutter_window,
                                   bool enabled) {
  flutter_window->hover_tracking_enabled = enabled;
  SetHoverCallbacksEnabled(flutter_window->window, enabled);
}

void FlutterDesktopRunWindowLoop(FlutterDesktopWindowRef flutter_window) {
  GLFWwindow* window = flutter_window->window;
#ifdef __linux__
  // Necessary for GTK thread safety.
  XInitThreads();
#endif
  while (!glfwWindowShouldClose(window)) {
    glfwPollEvents();
#ifdef __linux__
    if (gtk_events_pending()) {
      gtk_main_iteration();
    }
#endif
    // TODO(awdavies): This will be deprecated soon.
    __FlutterEngineFlushPendingTasksNow();
  }
  FlutterEngineShutdown(flutter_window->engine);
  delete flutter_window;
  glfwDestroyWindow(window);
}

FlutterDesktopEngineRef FlutterDesktopRunEngine(const char* assets_path,
                                                const char* icu_data_path,
                                                const char** arguments,
                                                size_t argument_count) {
  auto engine = RunFlutterEngine(nullptr, assets_path, icu_data_path, arguments,
                                 argument_count);
  if (engine == nullptr) {
    return nullptr;
  }
  auto engine_state = new FlutterDesktopEngineState();
  engine_state->engine = engine;
  return engine_state;
}

bool FlutterDesktopShutDownEngine(FlutterDesktopEngineRef engine_ref) {
  std::cout << "Shutting down flutter engine process." << std::endl;
  auto result = FlutterEngineShutdown(engine_ref->engine);
  delete engine_ref;
  return (result == kSuccess);
}

FlutterDesktopPluginRegistrarRef FlutterDesktopGetPluginRegistrar(
    FlutterDesktopWindowRef flutter_window,
    const char* plugin_name) {
  // Currently, one registrar acts as the registrar for all plugins, so the
  // name is ignored. It is part of the API to reduce churn in the future when
  // aligning more closely with the Flutter registrar system.
  return flutter_window->plugin_registrar.get();
}

void FlutterDesktopRegistrarEnableInputBlocking(
    FlutterDesktopPluginRegistrarRef registrar,
    const char* channel) {
  registrar->messenger->dispatcher->EnableInputBlockingForChannel(channel);
}

FlutterDesktopMessengerRef FlutterDesktopRegistrarGetMessenger(
    FlutterDesktopPluginRegistrarRef registrar) {
  return registrar->messenger.get();
}

void FlutterDesktopMessengerSend(FlutterDesktopMessengerRef messenger,
                                 const char* channel,
                                 const uint8_t* message,
                                 const size_t message_size) {
  FlutterPlatformMessage platform_message = {
      sizeof(FlutterPlatformMessage),
      channel,
      message,
      message_size,
  };

  FlutterEngineSendPlatformMessage(messenger->engine, &platform_message);
}

void FlutterDesktopMessengerSendResponse(
    FlutterDesktopMessengerRef messenger,
    const FlutterDesktopMessageResponseHandle* handle,
    const uint8_t* data,
    size_t data_length) {
  FlutterEngineSendPlatformMessageResponse(messenger->engine, handle, data,
                                           data_length);
}

void FlutterDesktopMessengerSetCallback(FlutterDesktopMessengerRef messenger,
                                        const char* channel,
                                        FlutterDesktopMessageCallback callback,
                                        void* user_data) {
  messenger->dispatcher->SetMessageCallback(channel, callback, user_data);
}
