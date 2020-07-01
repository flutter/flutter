// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "egl_utils.h"

#include <EGL/egl.h>

// Converts an EGL decimal value to a string.
static gchar* egl_decimal_to_string(EGLint value) {
  return g_strdup_printf("%d", value);
}

// Converts an EGL hexadecimal value to a string.
static gchar* egl_hexadecimal_to_string(EGLint value) {
  return g_strdup_printf("0x%x", value);
}

// Converts an EGL enumerated value to a string.
static gchar* egl_enum_to_string(EGLint value) {
  if (value == EGL_FALSE)
    return g_strdup("EGL_FALSE");
  else if (value == EGL_LUMINANCE_BUFFER)
    return g_strdup("EGL_LUMINANCE_BUFFER");
  else if (value == EGL_NONE)
    return g_strdup("EGL_NONE");
  else if (value == EGL_NON_CONFORMANT_CONFIG)
    return g_strdup("EGL_NON_CONFORMANT_CONFIG");
  else if (value == EGL_RGB_BUFFER)
    return g_strdup("EGL_RGB_BUFFER");
  else if (value == EGL_SLOW_CONFIG)
    return g_strdup("EGL_SLOW_CONFIG");
  else if (value == EGL_TRANSPARENT_RGB)
    return g_strdup("EGL_TRANSPARENT_RGB");
  else if (value == EGL_TRUE)
    return g_strdup("EGL_TRUE");
  else
    return nullptr;
}

// Ensures the given bit is not set in a bitfield. Returns TRUE if that bit was
// cleared.
static gboolean clear_bit(EGLint* field, EGLint bit) {
  if ((*field & bit) == 0)
    return FALSE;

  *field ^= bit;
  return TRUE;
}

// Converts an EGL renderable type bitfield to a string.
static gchar* egl_renderable_type_to_string(EGLint value) {
  EGLint v = value;
  g_autoptr(GPtrArray) strings = g_ptr_array_new_with_free_func(g_free);
  if (clear_bit(&v, EGL_OPENGL_ES_BIT))
    g_ptr_array_add(strings, g_strdup("EGL_OPENGL_ES_BIT"));
  if (clear_bit(&v, EGL_OPENVG_BIT))
    g_ptr_array_add(strings, g_strdup("EGL_OPENVG_BIT"));
  if (clear_bit(&v, EGL_OPENGL_ES2_BIT))
    g_ptr_array_add(strings, g_strdup("EGL_OPENGL_ES2_BIT"));
  if (clear_bit(&v, EGL_OPENGL_BIT))
    g_ptr_array_add(strings, g_strdup("EGL_OPENGL_BIT"));
  if (clear_bit(&v, EGL_OPENGL_ES3_BIT))
    g_ptr_array_add(strings, g_strdup("EGL_OPENGL_ES3_BIT"));
  if (v != 0)
    g_ptr_array_add(strings, egl_hexadecimal_to_string(v));
  g_ptr_array_add(strings, nullptr);

  return g_strjoinv("|", reinterpret_cast<gchar**>(strings->pdata));
}

// Converts an EGL surface type bitfield to a string.
static gchar* egl_surface_type_to_string(EGLint value) {
  EGLint v = value;
  g_autoptr(GPtrArray) strings = g_ptr_array_new_with_free_func(g_free);
  if (clear_bit(&v, EGL_PBUFFER_BIT))
    g_ptr_array_add(strings, g_strdup("EGL_PBUFFER_BIT"));
  if (clear_bit(&v, EGL_PIXMAP_BIT))
    g_ptr_array_add(strings, g_strdup("EGL_PIXMAP_BIT"));
  if (clear_bit(&v, EGL_WINDOW_BIT))
    g_ptr_array_add(strings, g_strdup("EGL_WINDOW_BIT"));
  if (v != 0)
    g_ptr_array_add(strings, egl_hexadecimal_to_string(v));
  g_ptr_array_add(strings, nullptr);

  return g_strjoinv("|", reinterpret_cast<gchar**>(strings->pdata));
}

const gchar* egl_error_to_string(EGLint error) {
  switch (error) {
    case EGL_SUCCESS:
      return "Success";
    case EGL_NOT_INITIALIZED:
      return "Not Initialized";
    case EGL_BAD_ACCESS:
      return "Bad Access";
    case EGL_BAD_ALLOC:
      return "Bad Allocation";
    case EGL_BAD_ATTRIBUTE:
      return "Bad Attribute";
    case EGL_BAD_CONTEXT:
      return "Bad Context";
    case EGL_BAD_CONFIG:
      return "Bad Configuration";
    case EGL_BAD_CURRENT_SURFACE:
      return "Bad Current Surface";
    case EGL_BAD_DISPLAY:
      return "Bad Display";
    case EGL_BAD_SURFACE:
      return "Bad Surface";
    case EGL_BAD_MATCH:
      return "Bad Match";
    case EGL_BAD_PARAMETER:
      return "Bad Parameter";
    case EGL_BAD_NATIVE_PIXMAP:
      return "Bad Native Pixmap";
    case EGL_BAD_NATIVE_WINDOW:
      return "Bad Native Window";
    case EGL_CONTEXT_LOST:
      return "Context Lost";
    default:
      return "Unknown Error";
  }
}

gchar* egl_config_to_string(EGLDisplay display, EGLConfig config) {
  struct {
    EGLint attribute;
    const gchar* name;
    gchar* (*to_string)(EGLint value);
  } config_items[] = {{
                          EGL_CONFIG_ID,
                          "EGL_CONFIG_ID",
                          egl_decimal_to_string,
                      },
                      {
                          EGL_BUFFER_SIZE,
                          "EGL_BUFFER_SIZE",
                          egl_decimal_to_string,
                      },
                      {
                          EGL_COLOR_BUFFER_TYPE,
                          "EGL_COLOR_BUFFER_TYPE",
                          egl_enum_to_string,
                      },
                      {
                          EGL_TRANSPARENT_TYPE,
                          "EGL_TRANSPARENT_TYPE",
                          egl_enum_to_string,
                      },
                      {
                          EGL_LEVEL,
                          "EGL_LEVEL",
                          egl_decimal_to_string,
                      },
                      {
                          EGL_RED_SIZE,
                          "EGL_RED_SIZE",
                          egl_decimal_to_string,
                      },
                      {
                          EGL_GREEN_SIZE,
                          "EGL_GREEN_SIZE",
                          egl_decimal_to_string,
                      },
                      {
                          EGL_BLUE_SIZE,
                          "EGL_BLUE_SIZE",
                          egl_decimal_to_string,
                      },
                      {
                          EGL_ALPHA_SIZE,
                          "EGL_ALPHA_SIZE",
                          egl_decimal_to_string,
                      },
                      {
                          EGL_DEPTH_SIZE,
                          "EGL_DEPTH_SIZE",
                          egl_decimal_to_string,
                      },
                      {
                          EGL_STENCIL_SIZE,
                          "EGL_STENCIL_SIZE",
                          egl_decimal_to_string,
                      },
                      {
                          EGL_SAMPLES,
                          "EGL_SAMPLES",
                          egl_decimal_to_string,
                      },
                      {
                          EGL_SAMPLE_BUFFERS,
                          "EGL_SAMPLE_BUFFERS",
                          egl_decimal_to_string,
                      },
                      {
                          EGL_NATIVE_VISUAL_ID,
                          "EGL_NATIVE_VISUAL_ID",
                          egl_hexadecimal_to_string,
                      },
                      {
                          EGL_NATIVE_VISUAL_TYPE,
                          "EGL_NATIVE_VISUAL_TYPE",
                          egl_hexadecimal_to_string,
                      },
                      {
                          EGL_NATIVE_RENDERABLE,
                          "EGL_NATIVE_RENDERABLE",
                          egl_enum_to_string,
                      },
                      {
                          EGL_CONFIG_CAVEAT,
                          "EGL_CONFIG_CAVEAT",
                          egl_enum_to_string,
                      },
                      {
                          EGL_BIND_TO_TEXTURE_RGB,
                          "EGL_BIND_TO_TEXTURE_RGB",
                          egl_enum_to_string,
                      },
                      {
                          EGL_BIND_TO_TEXTURE_RGBA,
                          "EGL_BIND_TO_TEXTURE_RGBA",
                          egl_enum_to_string,
                      },
                      {
                          EGL_RENDERABLE_TYPE,
                          "EGL_RENDERABLE_TYPE",
                          egl_renderable_type_to_string,
                      },
                      {
                          EGL_CONFORMANT,
                          "EGL_CONFORMANT",
                          egl_renderable_type_to_string,
                      },
                      {
                          EGL_SURFACE_TYPE,
                          "EGL_SURFACE_TYPE",
                          egl_surface_type_to_string,
                      },
                      {
                          EGL_MAX_PBUFFER_WIDTH,
                          "EGL_MAX_PBUFFER_WIDTH",
                          egl_decimal_to_string,
                      },
                      {
                          EGL_MAX_PBUFFER_HEIGHT,
                          "EGL_MAX_PBUFFER_HEIGHT",
                          egl_decimal_to_string,
                      },
                      {
                          EGL_MAX_PBUFFER_PIXELS,
                          "EGL_MAX_PBUFFER_PIXELS",
                          egl_decimal_to_string,
                      },
                      {
                          EGL_MIN_SWAP_INTERVAL,
                          "EGL_MIN_SWAP_INTERVAL",
                          egl_decimal_to_string,
                      },
                      {
                          EGL_MAX_SWAP_INTERVAL,
                          "EGL_MAX_SWAP_INTERVAL",
                          egl_decimal_to_string,
                      },
                      {EGL_NONE, nullptr, nullptr}};

  g_autoptr(GPtrArray) strings = g_ptr_array_new_with_free_func(g_free);
  for (int i = 0; config_items[i].attribute != EGL_NONE; i++) {
    EGLint value;
    if (!eglGetConfigAttrib(display, config, config_items[i].attribute, &value))
      continue;
    g_autofree gchar* value_string = config_items[i].to_string(value);
    if (value_string == nullptr)
      value_string = egl_hexadecimal_to_string(value);
    g_ptr_array_add(
        strings, g_strdup_printf("%s=%s", config_items[i].name, value_string));
  }
  g_ptr_array_add(strings, nullptr);

  return g_strjoinv(" ", reinterpret_cast<gchar**>(strings->pdata));
}
