// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_renderer.h"

#include <epoxy/egl.h>
#include <epoxy/gl.h>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/linux/fl_backing_store_provider.h"

G_DEFINE_QUARK(fl_renderer_error_quark, fl_renderer_error)

typedef struct {
  FlView* view;

  GdkGLContext* main_context;
  GdkGLContext* resource_context;
} FlRendererPrivate;

G_DEFINE_TYPE_WITH_PRIVATE(FlRenderer, fl_renderer, G_TYPE_OBJECT)

static void fl_renderer_class_init(FlRendererClass* klass) {}

static void fl_renderer_init(FlRenderer* self) {}

gboolean fl_renderer_start(FlRenderer* self, FlView* view, GError** error) {
  g_return_val_if_fail(FL_IS_RENDERER(self), FALSE);
  FlRendererPrivate* priv = reinterpret_cast<FlRendererPrivate*>(
      fl_renderer_get_instance_private(self));
  priv->view = view;
  gboolean result = FL_RENDERER_GET_CLASS(self)->create_contexts(
      self, GTK_WIDGET(view), &priv->main_context, &priv->resource_context,
      error);

  if (result) {
    gdk_gl_context_realize(priv->main_context, error);
    gdk_gl_context_realize(priv->resource_context, error);
  }

  if (*error != nullptr)
    return FALSE;
  return TRUE;
}

FlView* fl_renderer_get_view(FlRenderer* self) {
  FlRendererPrivate* priv = reinterpret_cast<FlRendererPrivate*>(
      fl_renderer_get_instance_private(self));
  return priv->view;
}

GdkGLContext* fl_renderer_get_context(FlRenderer* self) {
  FlRendererPrivate* priv = reinterpret_cast<FlRendererPrivate*>(
      fl_renderer_get_instance_private(self));
  return priv->main_context;
}

void* fl_renderer_get_proc_address(FlRenderer* self, const char* name) {
  return reinterpret_cast<void*>(eglGetProcAddress(name));
}

gboolean fl_renderer_make_current(FlRenderer* self, GError** error) {
  FlRendererPrivate* priv = reinterpret_cast<FlRendererPrivate*>(
      fl_renderer_get_instance_private(self));
  if (priv->main_context) {
    gdk_gl_context_make_current(priv->main_context);
  }

  return TRUE;
}

gboolean fl_renderer_make_resource_current(FlRenderer* self, GError** error) {
  FlRendererPrivate* priv = reinterpret_cast<FlRendererPrivate*>(
      fl_renderer_get_instance_private(self));
  if (priv->resource_context) {
    gdk_gl_context_make_current(priv->resource_context);
  }

  return TRUE;
}

gboolean fl_renderer_clear_current(FlRenderer* self, GError** error) {
  gdk_gl_context_clear_current();
  return TRUE;
}

guint32 fl_renderer_get_fbo(FlRenderer* self) {
  // There is only one frame buffer object - always return that.
  return 0;
}

gboolean fl_renderer_present(FlRenderer* self, GError** error) {
  return TRUE;
}

gboolean fl_renderer_create_backing_store(
    FlRenderer* self,
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
  return FL_RENDERER_GET_CLASS(self)->create_backing_store(self, config,
                                                           backing_store_out);
}

gboolean fl_renderer_collect_backing_store(
    FlRenderer* self,
    const FlutterBackingStore* backing_store) {
  return FL_RENDERER_GET_CLASS(self)->collect_backing_store(self,
                                                            backing_store);
}

gboolean fl_renderer_present_layers(FlRenderer* self,
                                    const FlutterLayer** layers,
                                    size_t layers_count) {
  return FL_RENDERER_GET_CLASS(self)->present_layers(self, layers,
                                                     layers_count);
}
