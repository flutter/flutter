// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/public/flutter_linux/fl_engine.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_renderer.h"

#include <gmodule.h>

struct _FlEngine {
  GObject parent_instance;

  FlDartProject* project;
  FlRenderer* renderer;
  FLUTTER_API_SYMBOL(FlutterEngine) engine;
};

G_DEFINE_QUARK(fl_engine_error_quark, fl_engine_error)

G_DEFINE_TYPE(FlEngine, fl_engine, G_TYPE_OBJECT)

// Callback from Flutter engine that are passed to the renderer

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

static void fl_engine_dispose(GObject* object) {
  FlEngine* self = FL_ENGINE(object);

  g_clear_object(&self->project);
  g_clear_object(&self->renderer);

  FlutterEngineShutdown(self->engine);

  G_OBJECT_CLASS(fl_engine_parent_class)->dispose(object);
}

static void fl_engine_class_init(FlEngineClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_engine_dispose;
}

static void fl_engine_init(FlEngine* self) {}

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

  FlutterProjectArgs args = {};
  args.struct_size = sizeof(FlutterProjectArgs);
  args.assets_path = fl_dart_project_get_assets_path(self->project);
  args.icu_data_path = fl_dart_project_get_icu_data_path(self->project);

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
