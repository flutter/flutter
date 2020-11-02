// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <EGL/egl.h>

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

EGLBoolean eglBindAPI(EGLenum api) {
  return bool_success();
}

EGLBoolean eglChooseConfig(EGLDisplay dpy,
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

EGLContext eglCreateContext(EGLDisplay dpy,
                            EGLConfig config,
                            EGLContext share_context,
                            const EGLint* attrib_list) {
  if (!check_display(dpy) || !check_initialized(dpy) || !check_config(config)) {
    return EGL_NO_CONTEXT;
  }

  mock_error = EGL_SUCCESS;
  return &mock_context;
}

EGLSurface eglCreatePbufferSurface(EGLDisplay dpy,
                                   EGLConfig config,
                                   const EGLint* attrib_list) {
  if (!check_display(dpy) || !check_initialized(dpy) || !check_config(config)) {
    return EGL_NO_SURFACE;
  }

  mock_error = EGL_SUCCESS;
  return &mock_surface;
}

EGLSurface eglCreateWindowSurface(EGLDisplay dpy,
                                  EGLConfig config,
                                  EGLNativeWindowType win,
                                  const EGLint* attrib_list) {
  if (!check_display(dpy) || !check_initialized(dpy) || !check_config(config)) {
    return EGL_NO_SURFACE;
  }

  mock_error = EGL_SUCCESS;
  return &mock_surface;
}

EGLBoolean eglGetConfigAttrib(EGLDisplay dpy,
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

EGLDisplay eglGetDisplay(EGLNativeDisplayType display_id) {
  return &mock_display;
}

EGLint eglGetError() {
  EGLint error = mock_error;
  mock_error = EGL_SUCCESS;
  return error;
}

void (*eglGetProcAddress(const char* procname))(void) {
  mock_error = EGL_SUCCESS;
  return nullptr;
}

EGLBoolean eglInitialize(EGLDisplay dpy, EGLint* major, EGLint* minor) {
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

EGLBoolean eglMakeCurrent(EGLDisplay dpy,
                          EGLSurface draw,
                          EGLSurface read,
                          EGLContext ctx) {
  if (!check_display(dpy) || !check_initialized(dpy)) {
    return EGL_FALSE;
  }

  return bool_success();
}

EGLBoolean eglSwapBuffers(EGLDisplay dpy, EGLSurface surface) {
  if (!check_display(dpy) || !check_initialized(dpy)) {
    return EGL_FALSE;
  }

  return bool_success();
}
