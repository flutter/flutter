// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_EGL_UTILS_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_EGL_UTILS_H_

#include <EGL/egl.h>

#include <glib.h>

G_BEGIN_DECLS

/**
 * egl_error_to_string:
 * @error: an EGL error code.
 *
 * Converts an egl error code to a human readable string. e.g. "Bad Match".
 *
 * Returns: an error description.
 */
const gchar* egl_error_to_string(EGLint error);

/**
 * egl_config_to_string:
 * @display: an EGL display.
 * @config: an EGL configuration.
 *
 * Converts an EGL configuration to a human readable string. e.g.
 * "EGL_CONFIG_ID=1 EGL_RED_SIZE=8...".
 *
 * Returns: a configuration description.
 */
gchar* egl_config_to_string(EGLDisplay display, EGLConfig config);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_EGL_UTILS_H_
