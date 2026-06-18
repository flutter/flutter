// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <epoxy/egl.h>
#include <gdk/gdkwayland.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/shell/platform/linux/fl_opengl_manager.h"

// Vertex shader to draw Flutter window contents.
static const char* vertex_shader_src =
    "attribute vec2 position;\n"
    "attribute vec2 in_texcoord;\n"
    "uniform vec2 offset;\n"
    "uniform vec2 scale;\n"
    "varying vec2 texcoord;\n"
    "\n"
    "void main() {\n"
    "  gl_Position = vec4(offset + position * scale, 0, 1);\n"
    "  texcoord = in_texcoord;\n"
    "}\n";

// Fragment shader to draw Flutter window contents.
static const char* fragment_shader_src =
    "#ifdef GL_ES\n"
    "precision mediump float;\n"
    "#endif\n"
    "\n"
    "uniform sampler2D texture;\n"
    "varying vec2 texcoord;\n"
    "\n"
    "void main() {\n"
    "  gl_FragColor = texture2D(texture, texcoord);\n"
    "}\n";

struct _FlOpenGLManager {
  GObject parent_instance;

  // Display being rendered to.
  EGLDisplay display;

  // Context used by the Flutter engine for rendering.
  EGLContext render_context;

  // Context used by the Flutter engine to share resources.
  EGLContext resource_context;

  // Context used by platform thread.
  EGLContext platform_context;

  // Shader program.
  GLuint program;

  // Location of layer offset in [program].
  GLuint offset_location;

  // Location of layer scale in [program].
  GLuint scale_location;

  // Vertices for the uniform square.
  GLuint vertex_buffer;
};

G_DEFINE_TYPE(FlOpenGLManager, fl_opengl_manager, G_TYPE_OBJECT)

// Returns the log for the given OpenGL shader. Must be freed by the caller.
static gchar* get_shader_log(GLuint shader) {
  GLint log_length;
  gchar* log;

  glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &log_length);

  log = static_cast<gchar*>(g_malloc(log_length + 1));
  glGetShaderInfoLog(shader, log_length, nullptr, log);

  return log;
}

// Returns the log for the given OpenGL program. Must be freed by the caller.
static gchar* get_program_log(GLuint program) {
  GLint log_length;
  gchar* log;

  glGetProgramiv(program, GL_INFO_LOG_LENGTH, &log_length);

  log = static_cast<gchar*>(g_malloc(log_length + 1));
  glGetProgramInfoLog(program, log_length, nullptr, log);

  return log;
}

static void setup_shader(FlOpenGLManager* self) {
  if (!fl_opengl_manager_make_platform_current(self)) {
    g_warning(
        "Failed to setup shaders, unable to make OpenGL context "
        "current");
    return;
  }

  GLuint vertex_shader = glCreateShader(GL_VERTEX_SHADER);
  glShaderSource(vertex_shader, 1, &vertex_shader_src, nullptr);
  glCompileShader(vertex_shader);
  GLint vertex_compile_status;
  glGetShaderiv(vertex_shader, GL_COMPILE_STATUS, &vertex_compile_status);
  if (vertex_compile_status == GL_FALSE) {
    g_autofree gchar* shader_log = get_shader_log(vertex_shader);
    g_warning("Failed to compile vertex shader: %s", shader_log);
  }

  GLuint fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);
  glShaderSource(fragment_shader, 1, &fragment_shader_src, nullptr);
  glCompileShader(fragment_shader);
  GLint fragment_compile_status;
  glGetShaderiv(fragment_shader, GL_COMPILE_STATUS, &fragment_compile_status);
  if (fragment_compile_status == GL_FALSE) {
    g_autofree gchar* shader_log = get_shader_log(fragment_shader);
    g_warning("Failed to compile fragment shader: %s", shader_log);
  }

  self->program = glCreateProgram();
  glAttachShader(self->program, vertex_shader);
  glAttachShader(self->program, fragment_shader);
  glLinkProgram(self->program);

  GLint link_status;
  glGetProgramiv(self->program, GL_LINK_STATUS, &link_status);
  if (link_status == GL_FALSE) {
    g_autofree gchar* program_log = get_program_log(self->program);
    g_warning("Failed to link program: %s", program_log);
  }

  self->offset_location = glGetUniformLocation(self->program, "offset");
  self->scale_location = glGetUniformLocation(self->program, "scale");

  glDeleteShader(vertex_shader);
  glDeleteShader(fragment_shader);

  // The uniform square abcd in two triangles cba + cdb
  // a--b
  // |  |
  // c--d
  GLfloat vertex_data[] = {-1, -1, 0, 0, 1, 1,  1, 1, -1, 1, 0, 1,
                           -1, -1, 0, 0, 1, -1, 1, 0, 1,  1, 1, 1};

  glGenBuffers(1, &self->vertex_buffer);
  glBindBuffer(GL_ARRAY_BUFFER, self->vertex_buffer);
  glBufferData(GL_ARRAY_BUFFER, sizeof(vertex_data), vertex_data,
               GL_STATIC_DRAW);
}

static void cleanup_shader(FlOpenGLManager* self) {
  if (!fl_opengl_manager_make_platform_current(self)) {
    g_warning(
        "Failed to cleanup shaders, unable to make OpenGL context "
        "current");
    return;
  }

  if (self->program != 0) {
    glDeleteProgram(self->program);
  }
  if (self->vertex_buffer != 0) {
    glDeleteBuffers(1, &self->vertex_buffer);
  }
}

GLuint fl_opengl_manager_get_program(FlOpenGLManager* self) {
  return self->program;
}

GLuint fl_opengl_manager_get_vertex_buffer(FlOpenGLManager* self) {
  return self->vertex_buffer;
}

GLuint fl_opengl_manager_get_offset_location(FlOpenGLManager* self) {
  return self->offset_location;
}

GLuint fl_opengl_manager_get_scale_location(FlOpenGLManager* self) {
  return self->scale_location;
}

static void fl_opengl_manager_dispose(GObject* object) {
  FlOpenGLManager* self = FL_OPENGL_MANAGER(object);

  cleanup_shader(self);

  eglDestroyContext(self->display, self->render_context);
  eglDestroyContext(self->display, self->resource_context);
  eglDestroyContext(self->display, self->platform_context);
  eglTerminate(self->display);

  G_OBJECT_CLASS(fl_opengl_manager_parent_class)->dispose(object);
}

static void fl_opengl_manager_class_init(FlOpenGLManagerClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_opengl_manager_dispose;
}

static void fl_opengl_manager_init(FlOpenGLManager* self) {
  GdkDisplay* display = gdk_display_get_default();
  if (GDK_IS_WAYLAND_DISPLAY(display)) {
    self->display = eglGetPlatformDisplayEXT(
        EGL_PLATFORM_WAYLAND_EXT, gdk_wayland_display_get_wl_display(display),
        NULL);
#ifdef GDK_WINDOWING_X11
  } else if (GDK_IS_X11_DISPLAY(display)) {
    self->display = eglGetPlatformDisplayEXT(
        EGL_PLATFORM_X11_EXT, gdk_x11_display_get_xdisplay(display), NULL);
#endif
  } else {
    g_critical("Unsupported GDK backend, unable to get EGL display");
  }

  eglInitialize(self->display, nullptr, nullptr);

  const EGLint config_attributes[] = {EGL_RED_SIZE,   8, EGL_GREEN_SIZE,   8,
                                      EGL_BLUE_SIZE,  8, EGL_ALPHA_SIZE,   8,
                                      EGL_DEPTH_SIZE, 8, EGL_STENCIL_SIZE, 8,
                                      EGL_NONE};
  EGLConfig config = nullptr;
  EGLint num_config = 0;
  eglChooseConfig(self->display, config_attributes, &config, 1, &num_config);

  const EGLint context_attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE};

  self->render_context = eglCreateContext(self->display, config, EGL_NO_CONTEXT,
                                          context_attributes);
  if (self->render_context == EGL_NO_CONTEXT) {
    g_warning("Failed to create EGL context for rendering");
  }

  self->resource_context = eglCreateContext(
      self->display, config, self->render_context, context_attributes);
  if (self->resource_context == EGL_NO_CONTEXT) {
    g_warning("Failed to create EGL context for resource sharing");
  }

  self->platform_context = eglCreateContext(
      self->display, config, self->render_context, context_attributes);
  if (self->platform_context == EGL_NO_CONTEXT) {
    g_warning("Failed to create EGL context for platform thread");
  }

  setup_shader(self);
}

FlOpenGLManager* fl_opengl_manager_new() {
  FlOpenGLManager* self =
      FL_OPENGL_MANAGER(g_object_new(fl_opengl_manager_get_type(), nullptr));
  return self;
}

gboolean fl_opengl_manager_make_current(FlOpenGLManager* self) {
  return eglMakeCurrent(self->display, EGL_NO_SURFACE, EGL_NO_SURFACE,
                        self->render_context) == EGL_TRUE;
}

gboolean fl_opengl_manager_make_resource_current(FlOpenGLManager* self) {
  return eglMakeCurrent(self->display, EGL_NO_SURFACE, EGL_NO_SURFACE,
                        self->resource_context) == EGL_TRUE;
}

gboolean fl_opengl_manager_make_platform_current(FlOpenGLManager* self) {
  return eglMakeCurrent(self->display, EGL_NO_SURFACE, EGL_NO_SURFACE,
                        self->platform_context) == EGL_TRUE;
}

gboolean fl_opengl_manager_clear_current(FlOpenGLManager* self) {
  return eglMakeCurrent(self->display, EGL_NO_SURFACE, EGL_NO_SURFACE,
                        EGL_NO_CONTEXT) == EGL_TRUE;
}
