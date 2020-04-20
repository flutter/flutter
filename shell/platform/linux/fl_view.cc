// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES2/gl2.h>
#include <gdk/gdkx.h>

#include "flutter/shell/platform/embedder/embedder.h"

struct _FlView {
  GtkWidget parent_instance;

  EGLDisplay egl_display;
  EGLSurface egl_surface;
  EGLContext egl_context;

  FlDartProject* flutter_project;
  FLUTTER_API_SYMBOL(FlutterEngine) flutter_engine;
  int64_t button_state;
};

enum { PROP_FLUTTER_PROJECT = 1, PROP_LAST };

G_DEFINE_TYPE(FlView, fl_view, GTK_TYPE_WIDGET)

static gboolean initialize_egl(FlView* self) {
  /* Note that we don't provide the XDisplay from GTK, this would make both
   * GTK and EGL share the same X connection and this would crash when used by
   * a Flutter thread. So the EGL display and GTK both have separate
   * connections.
   */
  self->egl_display = eglGetDisplay(EGL_DEFAULT_DISPLAY);

  EGLint egl_major, egl_minor;
  if (!eglInitialize(self->egl_display, &egl_major, &egl_minor)) {
    g_warning("Failed to initialze EGL");
    return FALSE;
  }
  // TODO(robert-ancell): It would probably be useful to store the EGL version
  // for debugging purposes

  EGLint attributes[] = {EGL_RENDERABLE_TYPE,
                         EGL_OPENGL_ES2_BIT,
                         EGL_RED_SIZE,
                         8,
                         EGL_GREEN_SIZE,
                         8,
                         EGL_BLUE_SIZE,
                         8,
                         EGL_ALPHA_SIZE,
                         8,
                         EGL_NONE};
  EGLConfig egl_config;
  EGLint n_config;
  if (!eglChooseConfig(self->egl_display, attributes, &egl_config, 1,
                       &n_config)) {
    g_warning("Failed to choose EGL config");
    return FALSE;
  }
  if (n_config == 0) {
    g_warning("Failed to find appropriate EGL config");
    return FALSE;
  }
  if (!eglBindAPI(EGL_OPENGL_ES_API)) {
    g_warning("Failed to bind EGL OpenGL ES API");
    return FALSE;
  }

  Window xid = gdk_x11_window_get_xid(gtk_widget_get_window(GTK_WIDGET(self)));
  self->egl_surface =
      eglCreateWindowSurface(self->egl_display, egl_config, xid, nullptr);
  EGLint context_attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE};
  self->egl_context = eglCreateContext(self->egl_display, egl_config,
                                       EGL_NO_CONTEXT, context_attributes);
  EGLint value;
  eglQueryContext(self->egl_display, self->egl_context,
                  EGL_CONTEXT_CLIENT_VERSION, &value);

  return TRUE;
}

static void* fl_view_gl_proc_resolver(void* user_data, const char* name) {
  return reinterpret_cast<void*>(eglGetProcAddress(name));
}

static bool fl_view_gl_make_current(void* user_data) {
  FlView* self = static_cast<FlView*>(user_data);

  if (!eglMakeCurrent(self->egl_display, self->egl_surface, self->egl_surface,
                      self->egl_context))
    g_warning("Failed to make EGL context current");

  return true;
}

static bool fl_view_gl_clear_current(void* user_data) {
  FlView* self = static_cast<FlView*>(user_data);

  if (!eglMakeCurrent(self->egl_display, EGL_NO_SURFACE, EGL_NO_SURFACE,
                      EGL_NO_CONTEXT))
    g_warning("Failed to make EGL context current");

  return true;
}

static uint32_t fl_view_gl_fbo_callback(void* user_data) {
  /* There is only one frame buffer object - always return that */
  return 0;
}

static bool fl_view_gl_present(void* user_data) {
  FlView* self = static_cast<FlView*>(user_data);

  if (!eglSwapBuffers(self->egl_display, self->egl_surface))
    g_warning("Failed to swap EGL buffers");

  return true;
}

static gboolean run_flutter_engine(FlView* self) {
  FlutterRendererConfig config = {};
  config.type = kOpenGL;
  config.open_gl.struct_size = sizeof(FlutterOpenGLRendererConfig);
  config.open_gl.gl_proc_resolver = fl_view_gl_proc_resolver;
  config.open_gl.make_current = fl_view_gl_make_current;
  config.open_gl.clear_current = fl_view_gl_clear_current;
  config.open_gl.fbo_callback = fl_view_gl_fbo_callback;
  config.open_gl.present = fl_view_gl_present;

  g_autofree gchar* assets_path =
      fl_dart_project_get_assets_path(self->flutter_project);
  g_autofree gchar* icu_data_path =
      fl_dart_project_get_icu_data_path(self->flutter_project);

  FlutterProjectArgs args = {};
  args.struct_size = sizeof(FlutterProjectArgs);
  args.assets_path = assets_path;
  args.icu_data_path = icu_data_path;

  FlutterEngineResult result = FlutterEngineInitialize(
      FLUTTER_ENGINE_VERSION, &config, &args, self, &self->flutter_engine);
  if (result != kSuccess)
    return FALSE;

  result = FlutterEngineRunInitialized(self->flutter_engine);
  if (result != kSuccess)
    return FALSE;

  return TRUE;
}

/* Convert a GDK button event into a Flutter event and send to the engine */
static gboolean fl_view_send_pointer_button_event(FlView* self,
                                                  GdkEventButton* event) {
  FlutterPointerEvent fl_event = {};
  fl_event.struct_size = sizeof(fl_event);
  fl_event.timestamp = event->time * 1000;

  int64_t button;
  switch (event->button) {
    case 1:
      button = kFlutterPointerButtonMousePrimary;
      break;
    case 2:
      button = kFlutterPointerButtonMouseMiddle;
      break;
    case 3:
      button = kFlutterPointerButtonMouseSecondary;
      break;
    default:
      return FALSE;
  }
  int old_button_state = self->button_state;
  if (event->type == GDK_BUTTON_PRESS) {
    // Drop the event if Flutter already thinks the button is down
    if ((self->button_state & button) != 0)
      return FALSE;
    self->button_state ^= button;

    fl_event.phase = old_button_state == 0 ? kDown : kMove;
  } else if (event->type == GDK_BUTTON_RELEASE) {
    // Drop the event if Flutter already thinks the button is up
    if ((self->button_state & button) == 0)
      return FALSE;
    self->button_state ^= button;

    fl_event.phase = self->button_state == 0 ? kUp : kMove;
  }

  if (self->flutter_engine == nullptr)
    return FALSE;

  fl_event.x = event->x;
  fl_event.y = event->y;
  fl_event.device_kind = kFlutterPointerDeviceKindMouse;
  fl_event.buttons = self->button_state;
  FlutterEngineSendPointerEvent(self->flutter_engine, &fl_event, 1);

  return TRUE;
}

static void fl_view_set_property(GObject* object,
                                 guint prop_id,
                                 const GValue* value,
                                 GParamSpec* pspec) {
  FlView* self = FL_VIEW(object);

  switch (prop_id) {
    case PROP_FLUTTER_PROJECT:
      g_set_object(&self->flutter_project,
                   static_cast<FlDartProject*>(g_value_get_object(value)));
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec);
      break;
  }
}

static void fl_view_get_property(GObject* object,
                                 guint prop_id,
                                 GValue* value,
                                 GParamSpec* pspec) {
  FlView* self = FL_VIEW(object);

  switch (prop_id) {
    case PROP_FLUTTER_PROJECT:
      g_value_set_object(value, self->flutter_project);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec);
      break;
  }
}

static void fl_view_dispose(GObject* object) {
  FlView* self = FL_VIEW(object);

  FlutterEngineDeinitialize(self->flutter_engine);
  FlutterEngineShutdown(self->flutter_engine);

  if (!eglDestroyContext(self->egl_display, self->egl_context))
    g_warning("Failed to destroy EGL context");
  if (!eglDestroySurface(self->egl_display, self->egl_surface))
    g_warning("Failed to destroy EGL surface");
  if (!eglTerminate(self->egl_display))
    g_warning("Failed to terminate EGL display");

  g_clear_object(&self->flutter_project);

  G_OBJECT_CLASS(fl_view_parent_class)->dispose(object);
}

static void fl_view_realize(GtkWidget* widget) {
  FlView* self = FL_VIEW(widget);

  gtk_widget_set_realized(widget, TRUE);

  GtkAllocation allocation;
  gtk_widget_get_allocation(widget, &allocation);

  GdkWindowAttr window_attributes;
  window_attributes.window_type = GDK_WINDOW_CHILD;
  window_attributes.x = allocation.x;
  window_attributes.y = allocation.y;
  window_attributes.width = allocation.width;
  window_attributes.height = allocation.height;
  window_attributes.wclass = GDK_INPUT_OUTPUT;
  window_attributes.visual = gtk_widget_get_visual(widget);
  window_attributes.event_mask =
      gtk_widget_get_events(widget) | GDK_EXPOSURE_MASK |
      GDK_POINTER_MOTION_MASK | GDK_BUTTON_PRESS_MASK | GDK_BUTTON_RELEASE_MASK;

  gint window_attributes_mask = GDK_WA_X | GDK_WA_Y | GDK_WA_VISUAL;

  GdkWindow* window =
      gdk_window_new(gtk_widget_get_parent_window(widget), &window_attributes,
                     window_attributes_mask);
  gtk_widget_register_window(widget, window);
  gtk_widget_set_window(widget, window);

  if (initialize_egl(self))
    run_flutter_engine(self);
}

static void fl_view_size_allocate(GtkWidget* widget,
                                  GtkAllocation* allocation) {
  FlView* self = FL_VIEW(widget);

  gtk_widget_set_allocation(widget, allocation);

  if (gtk_widget_get_realized(widget) && gtk_widget_get_has_window(widget))
    gdk_window_move_resize(gtk_widget_get_window(widget), allocation->x,
                           allocation->y, allocation->width,
                           allocation->height);

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(FlutterWindowMetricsEvent);
  event.width = allocation->width;
  event.height = allocation->height;
  event.pixel_ratio =
      1;  // TODO(robert-ancell): This won't work on hidpi displays
  FlutterEngineSendWindowMetricsEvent(self->flutter_engine, &event);
}

static gboolean fl_view_button_press_event(GtkWidget* widget,
                                           GdkEventButton* event) {
  FlView* self = FL_VIEW(widget);

  // Flutter doesn't handle double and triple click events
  if (event->type == GDK_DOUBLE_BUTTON_PRESS ||
      event->type == GDK_TRIPLE_BUTTON_PRESS)
    return FALSE;

  return fl_view_send_pointer_button_event(self, event);
}

static gboolean fl_view_button_release_event(GtkWidget* widget,
                                             GdkEventButton* event) {
  FlView* self = FL_VIEW(widget);

  return fl_view_send_pointer_button_event(self, event);
}

static gboolean fl_view_motion_notify_event(GtkWidget* widget,
                                            GdkEventMotion* event) {
  FlView* self = FL_VIEW(widget);

  if (self->flutter_engine == nullptr)
    return FALSE;

  FlutterPointerEvent fl_event = {};
  fl_event.struct_size = sizeof(fl_event);
  fl_event.timestamp = event->time * 1000;
  fl_event.phase = self->button_state != 0 ? kMove : kHover;
  fl_event.x = event->x;
  fl_event.y = event->y;
  fl_event.device_kind = kFlutterPointerDeviceKindMouse;
  fl_event.buttons = self->button_state;
  FlutterEngineSendPointerEvent(self->flutter_engine, &fl_event, 1);

  return TRUE;
}

static void fl_view_class_init(FlViewClass* klass) {
  G_OBJECT_CLASS(klass)->set_property = fl_view_set_property;
  G_OBJECT_CLASS(klass)->get_property = fl_view_get_property;
  G_OBJECT_CLASS(klass)->dispose = fl_view_dispose;
  GTK_WIDGET_CLASS(klass)->realize = fl_view_realize;
  GTK_WIDGET_CLASS(klass)->size_allocate = fl_view_size_allocate;
  GTK_WIDGET_CLASS(klass)->button_press_event = fl_view_button_press_event;
  GTK_WIDGET_CLASS(klass)->button_release_event = fl_view_button_release_event;
  GTK_WIDGET_CLASS(klass)->motion_notify_event = fl_view_motion_notify_event;

  g_object_class_install_property(
      G_OBJECT_CLASS(klass), PROP_FLUTTER_PROJECT,
      g_param_spec_object(
          "flutter-project", "flutter-project", "Flutter project in use",
          fl_dart_project_get_type(),
          static_cast<GParamFlags>(G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY |
                                   G_PARAM_STATIC_STRINGS)));
}

static void fl_view_init(FlView* self) {}

G_MODULE_EXPORT FlView* fl_view_new(FlDartProject* project) {
  return static_cast<FlView*>(
      g_object_new(fl_view_get_type(), "flutter-project", project, nullptr));
}
