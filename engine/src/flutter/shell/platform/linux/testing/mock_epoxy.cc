// Copyright 2013 The Flutter Authors. All rights reserved.

// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <epoxy/egl.h>
#include <epoxy/gl.h>

typedef struct {
  EGLint config_id;
  EGLint buffer_size;
  EGLint color_buffer_type;
  EGLint transparent_type;
  EGLint level;
  EGLint red_size;
  EGLint green_size;
  EGLint blue_size;
  EGLint alpha_size;
  EGLint depth_size;
  EGLint stencil_size;
  EGLint samples;
  EGLint sample_buffers;
  EGLint native_visual_id;
  EGLint native_visual_type;
  EGLint native_renderable;
  EGLint config_caveat;
  EGLint bind_to_texture_rgb;
  EGLint bind_to_texture_rgba;
  EGLint renderable_type;
  EGLint conformant;
  EGLint surface_type;
  EGLint max_pbuffer_width;
  EGLint max_pbuffer_height;
  EGLint max_pbuffer_pixels;
  EGLint min_swap_interval;
  EGLint max_swap_interval;
} MockConfig;

typedef struct {
} MockDisplay;

typedef struct {
} MockContext;

typedef struct {
} MockSurface;

static bool display_initialized = false;
static MockDisplay mock_display;
static MockConfig mock_config;
static MockContext mock_context;
static MockSurface mock_surface;

static EGLint mock_error = EGL_SUCCESS;

static bool check_display(EGLDisplay dpy) {
  if (dpy == nullptr) {
    mock_error = EGL_BAD_DISPLAY;
    return false;
  }

  return true;
}

static bool check_initialized(EGLDisplay dpy) {
  if (!display_initialized) {
    mock_error = EGL_NOT_INITIALIZED;
    return false;
  }

  return true;
}

static bool check_config(EGLConfig config) {
  if (config == nullptr) {
    mock_error = EGL_BAD_CONFIG;
    return false;
  }

  return true;
}

static EGLBoolean bool_success() {
  mock_error = EGL_SUCCESS;
  return EGL_TRUE;
}

static EGLBoolean bool_failure(EGLint error) {
  mock_error = error;
  return EGL_FALSE;
}

EGLBoolean _eglBindAPI(EGLenum api) {
  return bool_success();
}

EGLBoolean _eglChooseConfig(EGLDisplay dpy,
                            const EGLint* attrib_list,
                            EGLConfig* configs,
                            EGLint config_size,
                            EGLint* num_config) {
  if (!check_display(dpy) || !check_initialized(dpy)) {
    return EGL_FALSE;
  }

  if (configs == nullptr) {
    if (num_config != nullptr) {
      *num_config = 1;
    }
    return bool_success();
  }

  EGLint n_returned = 0;
  if (config_size >= 1) {
    configs[0] = &mock_config;
    n_returned++;
  }

  if (num_config != nullptr) {
    *num_config = n_returned;
  }

  return bool_success();
}

EGLContext _eglCreateContext(EGLDisplay dpy,
                             EGLConfig config,
                             EGLContext share_context,
                             const EGLint* attrib_list) {
  if (!check_display(dpy) || !check_initialized(dpy) || !check_config(config)) {
    return EGL_NO_CONTEXT;
  }

  mock_error = EGL_SUCCESS;
  return &mock_context;
}

EGLSurface _eglCreatePbufferSurface(EGLDisplay dpy,
                                    EGLConfig config,
                                    const EGLint* attrib_list) {
  if (!check_display(dpy) || !check_initialized(dpy) || !check_config(config)) {
    return EGL_NO_SURFACE;
  }

  mock_error = EGL_SUCCESS;
  return &mock_surface;
}

EGLSurface _eglCreateWindowSurface(EGLDisplay dpy,
                                   EGLConfig config,
                                   EGLNativeWindowType win,
                                   const EGLint* attrib_list) {
  if (!check_display(dpy) || !check_initialized(dpy) || !check_config(config)) {
    return EGL_NO_SURFACE;
  }

  mock_error = EGL_SUCCESS;
  return &mock_surface;
}

EGLBoolean _eglGetConfigAttrib(EGLDisplay dpy,
                               EGLConfig config,
                               EGLint attribute,
                               EGLint* value) {
  if (!check_display(dpy) || !check_initialized(dpy) || !check_config(config)) {
    return EGL_FALSE;
  }

  MockConfig* c = static_cast<MockConfig*>(config);
  switch (attribute) {
    case EGL_CONFIG_ID:
      *value = c->config_id;
      return bool_success();
    case EGL_BUFFER_SIZE:
      *value = c->buffer_size;
      return bool_success();
    case EGL_COLOR_BUFFER_TYPE:
      *value = c->color_buffer_type;
      return bool_success();
    case EGL_TRANSPARENT_TYPE:
      *value = c->transparent_type;
      return bool_success();
    case EGL_LEVEL:
      *value = c->level;
      return bool_success();
    case EGL_RED_SIZE:
      *value = c->red_size;
      return bool_success();
    case EGL_GREEN_SIZE:
      *value = c->green_size;
      return bool_success();
    case EGL_BLUE_SIZE:
      *value = c->blue_size;
      return bool_success();
    case EGL_ALPHA_SIZE:
      *value = c->alpha_size;
      return bool_success();
    case EGL_DEPTH_SIZE:
      *value = c->depth_size;
      return bool_success();
    case EGL_STENCIL_SIZE:
      *value = c->stencil_size;
      return bool_success();
    case EGL_SAMPLES:
      *value = c->samples;
      return bool_success();
    case EGL_SAMPLE_BUFFERS:
      *value = c->sample_buffers;
      return bool_success();
    case EGL_NATIVE_VISUAL_ID:
      *value = c->native_visual_id;
      return bool_success();
    case EGL_NATIVE_VISUAL_TYPE:
      *value = c->native_visual_type;
      return bool_success();
    case EGL_NATIVE_RENDERABLE:
      *value = c->native_renderable;
      return bool_success();
    case EGL_CONFIG_CAVEAT:
      *value = c->config_caveat;
      return bool_success();
    case EGL_BIND_TO_TEXTURE_RGB:
      *value = c->bind_to_texture_rgb;
      return bool_success();
    case EGL_BIND_TO_TEXTURE_RGBA:
      *value = c->bind_to_texture_rgba;
      return bool_success();
    case EGL_RENDERABLE_TYPE:
      *value = c->renderable_type;
      return bool_success();
    case EGL_CONFORMANT:
      *value = c->conformant;
      return bool_success();
    case EGL_SURFACE_TYPE:
      *value = c->surface_type;
      return bool_success();
    case EGL_MAX_PBUFFER_WIDTH:
      *value = c->max_pbuffer_width;
      return bool_success();
    case EGL_MAX_PBUFFER_HEIGHT:
      *value = c->max_pbuffer_height;
      return bool_success();
    case EGL_MAX_PBUFFER_PIXELS:
      *value = c->max_pbuffer_pixels;
      return bool_success();
    case EGL_MIN_SWAP_INTERVAL:
      *value = c->min_swap_interval;
      return bool_success();
    case EGL_MAX_SWAP_INTERVAL:
      *value = c->max_swap_interval;
      return bool_success();
    default:
      return bool_failure(EGL_BAD_ATTRIBUTE);
  }
}

EGLDisplay _eglGetDisplay(EGLNativeDisplayType display_id) {
  return &mock_display;
}

EGLint _eglGetError() {
  EGLint error = mock_error;
  mock_error = EGL_SUCCESS;
  return error;
}

void (*_eglGetProcAddress(const char* procname))(void) {
  mock_error = EGL_SUCCESS;
  return nullptr;
}

EGLBoolean _eglInitialize(EGLDisplay dpy, EGLint* major, EGLint* minor) {
  if (!check_display(dpy)) {
    return EGL_FALSE;
  }

  if (!display_initialized) {
    mock_config.config_id = 1;
    mock_config.buffer_size = 32;
    mock_config.color_buffer_type = EGL_RGB_BUFFER;
    mock_config.transparent_type = EGL_NONE;
    mock_config.level = 1;
    mock_config.red_size = 8;
    mock_config.green_size = 8;
    mock_config.blue_size = 8;
    mock_config.alpha_size = 0;
    mock_config.depth_size = 0;
    mock_config.stencil_size = 0;
    mock_config.samples = 0;
    mock_config.sample_buffers = 0;
    mock_config.native_visual_id = 1;
    mock_config.native_visual_type = 0;
    mock_config.native_renderable = EGL_TRUE;
    mock_config.config_caveat = EGL_NONE;
    mock_config.bind_to_texture_rgb = EGL_TRUE;
    mock_config.bind_to_texture_rgba = EGL_FALSE;
    mock_config.renderable_type = EGL_OPENGL_ES2_BIT;
    mock_config.conformant = EGL_OPENGL_ES2_BIT;
    mock_config.surface_type = EGL_WINDOW_BIT | EGL_PBUFFER_BIT;
    mock_config.max_pbuffer_width = 1024;
    mock_config.max_pbuffer_height = 1024;
    mock_config.max_pbuffer_pixels = 1024 * 1024;
    mock_config.min_swap_interval = 0;
    mock_config.max_swap_interval = 1000;
    display_initialized = true;
  }

  if (major != nullptr) {
    *major = 1;
  }
  if (minor != nullptr) {
    *minor = 5;
  }

  return bool_success();
}

EGLBoolean _eglMakeCurrent(EGLDisplay dpy,
                           EGLSurface draw,
                           EGLSurface read,
                           EGLContext ctx) {
  if (!check_display(dpy) || !check_initialized(dpy)) {
    return EGL_FALSE;
  }

  return bool_success();
}

EGLBoolean _eglSwapBuffers(EGLDisplay dpy, EGLSurface surface) {
  if (!check_display(dpy) || !check_initialized(dpy)) {
    return EGL_FALSE;
  }

  return bool_success();
}

static void _glBindFramebuffer(GLenum target, GLuint framebuffer) {}

static void _glBindTexture(GLenum target, GLuint texture) {}

void _glDeleteFramebuffers(GLsizei n, const GLuint* framebuffers) {}

void _glDeleteTextures(GLsizei n, const GLuint* textures) {}

static void _glFramebufferTexture2D(GLenum target,
                                    GLenum attachment,
                                    GLenum textarget,
                                    GLuint texture,
                                    GLint level) {}

static void _glGenTextures(GLsizei n, GLuint* textures) {
  for (GLsizei i = 0; i < n; i++) {
    textures[i] = 0;
  }
}

static void _glGenFramebuffers(GLsizei n, GLuint* framebuffers) {
  for (GLsizei i = 0; i < n; i++) {
    framebuffers[i] = 0;
  }
}

static void _glTexParameterf(GLenum target, GLenum pname, GLfloat param) {}

static void _glTexParameteri(GLenum target, GLenum pname, GLint param) {}

static void _glTexImage2D(GLenum target,
                          GLint level,
                          GLint internalformat,
                          GLsizei width,
                          GLsizei height,
                          GLint border,
                          GLenum format,
                          GLenum type,
                          const void* pixels) {}

static GLenum _glGetError() {
  return GL_NO_ERROR;
}

bool epoxy_has_gl_extension(const char* extension) {
  return false;
}

bool epoxy_is_desktop_gl(void) {
  return false;
}

int epoxy_gl_version(void) {
  return 0;
}

#ifdef __GNUC__
#define CONSTRUCT(_func) static void _func(void) __attribute__((constructor));
#define DESTRUCT(_func) static void _func(void) __attribute__((destructor));
#elif defined(_MSC_VER) && (_MSC_VER >= 1500)
#define CONSTRUCT(_func)                                                   \
  static void _func(void);                                                 \
  static int _func##_wrapper(void) {                                       \
    _func();                                                               \
    return 0;                                                              \
  }                                                                        \
  __pragma(section(".CRT$XCU", read))                                      \
      __declspec(allocate(".CRT$XCU")) static int (*_array##_func)(void) = \
          _func##_wrapper;

#else
#error "You will need constructor support for your compiler"
#endif

CONSTRUCT(library_init)

EGLBoolean (*epoxy_eglBindAPI)(EGLenum api);
EGLBoolean (*epoxy_eglChooseConfig)(EGLDisplay dpy,
                                    const EGLint* attrib_list,
                                    EGLConfig* configs,
                                    EGLint config_size,
                                    EGLint* num_config);
EGLContext (*epoxy_eglCreateContext)(EGLDisplay dpy,
                                     EGLConfig config,
                                     EGLContext share_context,
                                     const EGLint* attrib_list);
EGLSurface (*epoxy_eglCreatePbufferSurface)(EGLDisplay dpy,
                                            EGLConfig config,
                                            const EGLint* attrib_list);
EGLSurface (*epoxy_eglCreateWindowSurface)(EGLDisplay dpy,
                                           EGLConfig config,
                                           EGLNativeWindowType win,
                                           const EGLint* attrib_list);
EGLBoolean (*epoxy_eglGetConfigAttrib)(EGLDisplay dpy,
                                       EGLConfig config,
                                       EGLint attribute,
                                       EGLint* value);
EGLDisplay (*epoxy_eglGetDisplay)(EGLNativeDisplayType display_id);
EGLint (*epoxy_eglGetError)();
void (*(*epoxy_eglGetProcAddress)(const char* procname))(void);
EGLBoolean (*epoxy_eglInitialize)(EGLDisplay dpy, EGLint* major, EGLint* minor);
EGLBoolean (*epoxy_eglMakeCurrent)(EGLDisplay dpy,
                                   EGLSurface draw,
                                   EGLSurface read,
                                   EGLContext ctx);
EGLBoolean (*epoxy_eglSwapBuffers)(EGLDisplay dpy, EGLSurface surface);

void (*epoxy_glBindFramebuffer)(GLenum target, GLuint framebuffer);
void (*epoxy_glBindTexture)(GLenum target, GLuint texture);
void (*epoxy_glDeleteFramebuffers)(GLsizei n, const GLuint* framebuffers);
void (*epoxy_glDeleteTextures)(GLsizei n, const GLuint* textures);
void (*epoxy_glFramebufferTexture2D)(GLenum target,
                                     GLenum attachment,
                                     GLenum textarget,
                                     GLuint texture,
                                     GLint level);
void (*epoxy_glGenFramebuffers)(GLsizei n, GLuint* framebuffers);
void (*epoxy_glGenTextures)(GLsizei n, GLuint* textures);
void (*epoxy_glTexParameterf)(GLenum target, GLenum pname, GLfloat param);
void (*epoxy_glTexParameteri)(GLenum target, GLenum pname, GLint param);
void (*epoxy_glTexImage2D)(GLenum target,
                           GLint level,
                           GLint internalformat,
                           GLsizei width,
                           GLsizei height,
                           GLint border,
                           GLenum format,
                           GLenum type,
                           const void* pixels);
GLenum (*epoxy_glGetError)();

static void library_init() {
  epoxy_eglBindAPI = _eglBindAPI;
  epoxy_eglChooseConfig = _eglChooseConfig;
  epoxy_eglCreateContext = _eglCreateContext;
  epoxy_eglCreatePbufferSurface = _eglCreatePbufferSurface;
  epoxy_eglCreateWindowSurface = _eglCreateWindowSurface;
  epoxy_eglGetConfigAttrib = _eglGetConfigAttrib;
  epoxy_eglGetDisplay = _eglGetDisplay;
  epoxy_eglGetError = _eglGetError;
  epoxy_eglGetProcAddress = _eglGetProcAddress;
  epoxy_eglInitialize = _eglInitialize;
  epoxy_eglMakeCurrent = _eglMakeCurrent;
  epoxy_eglSwapBuffers = _eglSwapBuffers;

  epoxy_glBindFramebuffer = _glBindFramebuffer;
  epoxy_glBindTexture = _glBindTexture;
  epoxy_glDeleteFramebuffers = _glDeleteFramebuffers;
  epoxy_glDeleteTextures = _glDeleteTextures;
  epoxy_glFramebufferTexture2D = _glFramebufferTexture2D;
  epoxy_glGenFramebuffers = _glGenFramebuffers;
  epoxy_glGenTextures = _glGenTextures;
  epoxy_glTexParameterf = _glTexParameterf;
  epoxy_glTexParameteri = _glTexParameteri;
  epoxy_glTexImage2D = _glTexImage2D;
  epoxy_glGetError = _glGetError;
}
