// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/public/flutter_linux/fl_engine.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"

#include "flutter/shell/platform/linux/fl_binary_messenger_private.h"
#include "flutter/shell/platform/linux/fl_renderer.h"

#include <gmodule.h>

static constexpr int kMicrosecondsPerNanosecond = 1000;

// Unique number associated with platform tasks
static constexpr size_t kPlatformTaskRunnerIdentifier = 1;

struct _FlEngine {
  GObject parent_instance;

  // Thread the GLib main loop is running on
  GThread* thread;

  FlDartProject* project;
  FlRenderer* renderer;
  FlBinaryMessenger* binary_messenger;
  FLUTTER_API_SYMBOL(FlutterEngine) engine;

  // Function to call when a platform message is received
  FlEnginePlatformMessageCallback platform_message_callback;
  gpointer platform_message_callback_data;
};

G_DEFINE_QUARK(fl_engine_error_quark, fl_engine_error)

G_DEFINE_TYPE(FlEngine, fl_engine, G_TYPE_OBJECT)

// Subclass of GSource that integrates Flutter tasks into the GLib main loop
typedef struct {
  GSource parent;
  FlEngine* self;
  FlutterTask task;
} FlutterSource;

// Callback to run a Flutter task in the GLib main loop
static gboolean flutter_source_dispatch(GSource* source,
                                        GSourceFunc callback,
                                        gpointer user_data) {
  FlutterSource* fl_source = reinterpret_cast<FlutterSource*>(source);
  FlEngine* self = fl_source->self;

  FlutterEngineResult result =
      FlutterEngineRunTask(self->engine, &fl_source->task);
  if (result != kSuccess)
    g_warning("Failed to run Flutter task\n");

  return G_SOURCE_REMOVE;
}

// Table of functions for Flutter GLib main loop integration
static GSourceFuncs flutter_source_funcs = {
    nullptr,                  // prepare
    nullptr,                  // check
    flutter_source_dispatch,  // dispatch
    nullptr,                  // finalize
    nullptr,
    nullptr  // Internal usage
};

// Flutter engine callbacks

static void* fl_engine_gl_proc_resolver(void* user_data, const char* name) {
  FlEngine* self = static_cast<FlEngine*>(user_data);
  return fl_renderer_get_proc_address(self->renderer, name);
}

static bool fl_engine_gl_make_current(void* user_data) {
  FlEngine* self = static_cast<FlEngine*>(user_data);
  g_autoptr(GError) error = nullptr;
  gboolean result = fl_renderer_make_current(self->renderer, &error);
  if (!result)
    g_warning("%s", error->message);
  return result;
}

static bool fl_engine_gl_clear_current(void* user_data) {
  FlEngine* self = static_cast<FlEngine*>(user_data);
  g_autoptr(GError) error = nullptr;
  gboolean result = fl_renderer_clear_current(self->renderer, &error);
  if (!result)
    g_warning("%s", error->message);
  return result;
}

static uint32_t fl_engine_gl_fbo_callback(void* user_data) {
  FlEngine* self = static_cast<FlEngine*>(user_data);
  return fl_renderer_get_fbo(self->renderer);
}

static bool fl_engine_gl_present(void* user_data) {
  FlEngine* self = static_cast<FlEngine*>(user_data);
  g_autoptr(GError) error = nullptr;
  gboolean result = fl_renderer_present(self->renderer, &error);
  if (!result)
    g_warning("%s", error->message);
  return result;
}

static bool fl_engine_runs_task_on_current_thread(void* user_data) {
  FlEngine* self = static_cast<FlEngine*>(user_data);
  return self->thread == g_thread_self();
}

static void fl_engine_post_task_callback(FlutterTask task,
                                         uint64_t target_time_nanos,
                                         void* user_data) {
  FlEngine* self = static_cast<FlEngine*>(user_data);

  g_autoptr(GSource) source =
      g_source_new(&flutter_source_funcs, sizeof(FlutterSource));
  FlutterSource* fl_source = reinterpret_cast<FlutterSource*>(source);
  fl_source->self = self;
  fl_source->task = task;
  g_source_set_ready_time(source,
                          target_time_nanos / kMicrosecondsPerNanosecond);
  g_source_attach(source, nullptr);
}

static void fl_engine_platform_message_callback(
    const FlutterPlatformMessage* message,
    void* user_data) {
  FlEngine* self = FL_ENGINE(user_data);

  gboolean handled = FALSE;
  if (self->platform_message_callback != nullptr) {
    g_autoptr(GBytes) data =
        g_bytes_new(message->message, message->message_size);
    handled = self->platform_message_callback(
        self, message->channel, data, message->response_handle,
        self->platform_message_callback_data);
  }

  if (!handled)
    fl_engine_send_platform_message_response(self, message->response_handle,
                                             nullptr, nullptr);
}

static void fl_engine_platform_message_response_callback(const uint8_t* data,
                                                         size_t data_length,
                                                         void* user_data) {
  g_autoptr(GTask) task = G_TASK(user_data);
  g_task_return_pointer(task, g_bytes_new(data, data_length),
                        (GDestroyNotify)g_bytes_unref);
}

static void fl_engine_dispose(GObject* object) {
  FlEngine* self = FL_ENGINE(object);

  FlutterEngineShutdown(self->engine);

  g_clear_object(&self->project);
  g_clear_object(&self->renderer);
  g_clear_object(&self->binary_messenger);

  G_OBJECT_CLASS(fl_engine_parent_class)->dispose(object);
}

static void fl_engine_class_init(FlEngineClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_engine_dispose;
}

static void fl_engine_init(FlEngine* self) {
  self->thread = g_thread_self();

  self->binary_messenger = fl_binary_messenger_new(self);
}

FlEngine* fl_engine_new(FlDartProject* project, FlRenderer* renderer) {
  g_return_val_if_fail(FL_IS_DART_PROJECT(project), nullptr);
  g_return_val_if_fail(FL_IS_RENDERER(renderer), nullptr);

  FlEngine* self =
      static_cast<FlEngine*>(g_object_new(fl_engine_get_type(), nullptr));
  self->project = static_cast<FlDartProject*>(g_object_ref(project));
  self->renderer = static_cast<FlRenderer*>(g_object_ref(renderer));
  return self;
}

gboolean fl_engine_start(FlEngine* self, GError** error) {
  g_return_val_if_fail(FL_IS_ENGINE(self), FALSE);

  if (!fl_renderer_start(self->renderer, error))
    return FALSE;

  FlutterRendererConfig config = {};
  config.type = kOpenGL;
  config.open_gl.struct_size = sizeof(FlutterOpenGLRendererConfig);
  config.open_gl.gl_proc_resolver = fl_engine_gl_proc_resolver;
  config.open_gl.make_current = fl_engine_gl_make_current;
  config.open_gl.clear_current = fl_engine_gl_clear_current;
  config.open_gl.fbo_callback = fl_engine_gl_fbo_callback;
  config.open_gl.present = fl_engine_gl_present;

  FlutterTaskRunnerDescription platform_task_runner = {};
  platform_task_runner.struct_size = sizeof(FlutterTaskRunnerDescription);
  platform_task_runner.user_data = self;
  platform_task_runner.runs_task_on_current_thread_callback =
      fl_engine_runs_task_on_current_thread;
  platform_task_runner.post_task_callback = fl_engine_post_task_callback;
  platform_task_runner.identifier = kPlatformTaskRunnerIdentifier;

  FlutterCustomTaskRunners custom_task_runners = {};
  custom_task_runners.struct_size = sizeof(FlutterCustomTaskRunners);
  custom_task_runners.platform_task_runner = &platform_task_runner;

  FlutterProjectArgs args = {};
  args.struct_size = sizeof(FlutterProjectArgs);
  args.assets_path = fl_dart_project_get_assets_path(self->project);
  args.icu_data_path = fl_dart_project_get_icu_data_path(self->project);
  args.platform_message_callback = fl_engine_platform_message_callback;
  args.custom_task_runners = &custom_task_runners;

  FlutterEngineResult result = FlutterEngineInitialize(
      FLUTTER_ENGINE_VERSION, &config, &args, self, &self->engine);
  if (result != kSuccess) {
    g_set_error(error, fl_engine_error_quark(), FL_ENGINE_ERROR_FAILED,
                "Failed to initialize Flutter engine");
    return FALSE;
  }

  result = FlutterEngineRunInitialized(self->engine);
  if (result != kSuccess) {
    g_set_error(error, fl_engine_error_quark(), FL_ENGINE_ERROR_FAILED,
                "Failed to run Flutter engine");
    return FALSE;
  }

  return TRUE;
}

void fl_engine_set_platform_message_handler(
    FlEngine* self,
    FlEnginePlatformMessageCallback callback,
    gpointer user_data) {
  g_return_if_fail(FL_IS_ENGINE(self));
  g_return_if_fail(callback != nullptr);

  self->platform_message_callback = callback;
  self->platform_message_callback_data = user_data;
}

gboolean fl_engine_send_platform_message_response(
    FlEngine* self,
    const FlutterPlatformMessageResponseHandle* handle,
    GBytes* response,
    GError** error) {
  g_return_val_if_fail(FL_IS_ENGINE(self), FALSE);
  g_return_val_if_fail(handle != nullptr, FALSE);

  gsize data_length = 0;
  const uint8_t* data = nullptr;
  if (response != nullptr)
    data =
        static_cast<const uint8_t*>(g_bytes_get_data(response, &data_length));
  FlutterEngineResult result = FlutterEngineSendPlatformMessageResponse(
      self->engine, handle, data, data_length);

  if (result != kSuccess) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to send platorm message response");
    return FALSE;
  }

  return TRUE;
}

void fl_engine_send_platform_message(FlEngine* self,
                                     const gchar* channel,
                                     GBytes* message,
                                     GCancellable* cancellable,
                                     GAsyncReadyCallback callback,
                                     gpointer user_data) {
  g_return_if_fail(FL_IS_ENGINE(self));

  GTask* task = nullptr;
  FlutterPlatformMessageResponseHandle* response_handle = nullptr;
  if (callback != nullptr) {
    task = g_task_new(self, cancellable, callback, user_data);

    FlutterEngineResult result = FlutterPlatformMessageCreateResponseHandle(
        self->engine, fl_engine_platform_message_response_callback, task,
        &response_handle);
    if (result != kSuccess) {
      g_task_return_new_error(task, fl_engine_error_quark(),
                              FL_ENGINE_ERROR_FAILED,
                              "Failed to create response handle");
      g_object_unref(task);
      return;
    }
  }

  FlutterPlatformMessage fl_message = {};
  fl_message.struct_size = sizeof(fl_message);
  fl_message.channel = channel;
  fl_message.message =
      message != nullptr
          ? static_cast<const uint8_t*>(g_bytes_get_data(message, nullptr))
          : nullptr;
  fl_message.message_size = message != nullptr ? g_bytes_get_size(message) : 0;
  fl_message.response_handle = response_handle;
  FlutterEngineResult result =
      FlutterEngineSendPlatformMessage(self->engine, &fl_message);

  if (result != kSuccess && task != nullptr) {
    g_task_return_new_error(task, fl_engine_error_quark(),
                            FL_ENGINE_ERROR_FAILED,
                            "Failed to send platform messages");
    g_object_unref(task);
  }

  if (response_handle != nullptr)
    FlutterPlatformMessageReleaseResponseHandle(self->engine, response_handle);
}

GBytes* fl_engine_send_platform_message_finish(FlEngine* self,
                                               GAsyncResult* result,
                                               GError** error) {
  g_return_val_if_fail(FL_IS_ENGINE(self), FALSE);
  g_return_val_if_fail(g_task_is_valid(result, self), FALSE);

  return static_cast<GBytes*>(g_task_propagate_pointer(G_TASK(result), error));
}

void fl_engine_send_window_metrics_event(FlEngine* self,
                                         size_t width,
                                         size_t height,
                                         double pixel_ratio) {
  g_return_if_fail(FL_IS_ENGINE(self));

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(FlutterWindowMetricsEvent);
  event.width = width;
  event.height = height;
  event.pixel_ratio = pixel_ratio;
  FlutterEngineSendWindowMetricsEvent(self->engine, &event);
}

void fl_engine_send_mouse_pointer_event(FlEngine* self,
                                        FlutterPointerPhase phase,
                                        size_t timestamp,
                                        double x,
                                        double y,
                                        int64_t buttons) {
  g_return_if_fail(FL_IS_ENGINE(self));

  FlutterPointerEvent fl_event = {};
  fl_event.struct_size = sizeof(fl_event);
  fl_event.phase = phase;
  fl_event.timestamp = timestamp;
  fl_event.x = x;
  fl_event.y = y;
  fl_event.device_kind = kFlutterPointerDeviceKindMouse;
  fl_event.buttons = buttons;
  FlutterEngineSendPointerEvent(self->engine, &fl_event, 1);
}

G_MODULE_EXPORT FlBinaryMessenger* fl_engine_get_binary_messenger(
    FlEngine* self) {
  g_return_val_if_fail(FL_IS_ENGINE(self), nullptr);
  return self->binary_messenger;
}
