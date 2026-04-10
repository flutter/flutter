// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_EGL_IMAGE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_EGL_IMAGE_H_

#include <epoxy/egl.h>
#include <glib-object.h>

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlEGLImage, fl_egl_image, FL, EGL_IMAGE, GObject)

/**
 * fl_egl_image_new:
 * @texture: the texture to create an EGL image for.
 *
 * Creates an object that manages an EGL image.
 *
 * Returns: a new #FlEGLImage.
 */
FlEGLImage* fl_egl_image_new(GLuint texture);

/**
 * fl_egl_image_get_image:
 * @image: an #FlEGLImage.
 *
 * Gets the EGL image managed by this object.
 *
 * Returns: the EGL image.
 */
EGLImage fl_egl_image_get_image(FlEGLImage* image);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_EGL_IMAGE_H_
