// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDER_TEXTURE_GTK4_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDER_TEXTURE_GTK4_H_

#include <gtk/gtk.h>

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlRenderTextureGtk4,
                     fl_render_texture_gtk4,
                     FL,
                     RENDER_TEXTURE_GTK4,
                     GtkWidget)

GtkWidget* fl_render_texture_gtk4_new(void);

void fl_render_texture_gtk4_set_flip_y(FlRenderTextureGtk4* self,
                                       gboolean flip_y);

void fl_render_texture_gtk4_set_texture(FlRenderTextureGtk4* self,
                                        GdkTexture* texture);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDER_TEXTURE_GTK4_H_
