// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_compositor_opengl_shader.h"

#include <epoxy/gl.h>

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

struct _FlCompositorOpenGLShader {
  GObject parent_instance;

  // Flutter OpenGL contexts.
  FlOpenGLManager* opengl_manager;

  // Shader program.
  GLuint program;

  // Location of layer offset in [program].
  GLint offset_location;

  // Location of layer scale in [program].
  GLint scale_location;

  // Verticies for the uniform square.
  GLuint vertex_buffer;
};

G_DEFINE_TYPE(FlCompositorOpenGLShader,
              fl_compositor_opengl_shader,
              G_TYPE_OBJECT)

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

static void setup_shader(FlCompositorOpenGLShader* self) {
  if (!fl_opengl_manager_make_platform_current(self->opengl_manager)) {
    g_warning(
        "Failed to setup compositor shaders, unable to make OpenGL context "
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
  GLfloat const vertex_data[] = {-1, -1, 0, 0, 1, 1,  1, 1, -1, 1, 0, 1,
                                 -1, -1, 0, 0, 1, -1, 1, 0, 1,  1, 1, 1};

  glGenBuffers(1, &self->vertex_buffer);
  glBindBuffer(GL_ARRAY_BUFFER, self->vertex_buffer);
  glBufferData(GL_ARRAY_BUFFER, sizeof(vertex_data), vertex_data,
               GL_STATIC_DRAW);
}

static void fl_compositor_opengl_shader_dispose(GObject* object) {
  FlCompositorOpenGLShader* self = FL_COMPOSITOR_OPENGL_SHADER(object);

  if (self->opengl_manager != nullptr) {
    if (fl_opengl_manager_make_platform_current(self->opengl_manager)) {
      if (self->program != 0) {
        glDeleteProgram(self->program);
      }
      if (self->vertex_buffer != 0) {
        glDeleteBuffers(1, &self->vertex_buffer);
      }
    } else {
      g_warning(
          "Failed to cleanup compositor shaders, unable to make OpenGL context "
          "current");
    }
  }
  self->program = 0;
  self->vertex_buffer = 0;

  g_clear_object(&self->opengl_manager);

  G_OBJECT_CLASS(fl_compositor_opengl_shader_parent_class)->dispose(object);
}

static void fl_compositor_opengl_shader_class_init(
    FlCompositorOpenGLShaderClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_compositor_opengl_shader_dispose;
}

static void fl_compositor_opengl_shader_init(FlCompositorOpenGLShader* self) {}

FlCompositorOpenGLShader* fl_compositor_opengl_shader_new(
    FlOpenGLManager* opengl_manager) {
  g_return_val_if_fail(FL_IS_OPENGL_MANAGER(opengl_manager), nullptr);

  FlCompositorOpenGLShader* self = FL_COMPOSITOR_OPENGL_SHADER(
      g_object_new(fl_compositor_opengl_shader_get_type(), nullptr));

  self->opengl_manager = FL_OPENGL_MANAGER(g_object_ref(opengl_manager));

  setup_shader(self);

  return self;
}

void fl_compositor_opengl_shader_use(FlCompositorOpenGLShader* self) {
  g_return_if_fail(FL_IS_COMPOSITOR_OPENGL_SHADER(self));

  glBindBuffer(GL_ARRAY_BUFFER, self->vertex_buffer);
  GLint position_location = glGetAttribLocation(self->program, "position");
  glEnableVertexAttribArray(position_location);
  glVertexAttribPointer(position_location, 2, GL_FLOAT, GL_FALSE,
                        sizeof(GLfloat) * 4, 0);
  GLint texcoord_location = glGetAttribLocation(self->program, "in_texcoord");
  glEnableVertexAttribArray(texcoord_location);
  glVertexAttribPointer(texcoord_location, 2, GL_FLOAT, GL_FALSE,
                        sizeof(GLfloat) * 4,
                        reinterpret_cast<void*>(sizeof(GLfloat) * 2));

  glUseProgram(self->program);
}

void fl_compositor_opengl_shader_set_offset(FlCompositorOpenGLShader* self,
                                            double x,
                                            double y) {
  g_return_if_fail(FL_IS_COMPOSITOR_OPENGL_SHADER(self));
  glUniform2f(self->offset_location, x, y);
}

void fl_compositor_opengl_shader_set_scale(FlCompositorOpenGLShader* self,
                                           double x,
                                           double y) {
  g_return_if_fail(FL_IS_COMPOSITOR_OPENGL_SHADER(self));
  glUniform2f(self->scale_location, x, y);
}
