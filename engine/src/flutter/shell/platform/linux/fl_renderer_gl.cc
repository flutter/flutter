// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_renderer_gl.h"

#include "flutter/shell/platform/linux/fl_backing_store_provider.h"
#include "flutter/shell/platform/linux/fl_view_private.h"

struct _FlRendererGL {
  FlRenderer parent_instance;
};

G_DEFINE_TYPE(FlRendererGL, fl_renderer_gl, fl_renderer_get_type())

// Implements FlRenderer::create_contexts.
static gboolean fl_renderer_gl_create_contexts(FlRenderer* renderer,
                                               GtkWidget* widget,
                                               GdkGLContext** visible,
                                               GdkGLContext** resource,
                                               GError** error) {
  GdkWindow* window = gtk_widget_get_parent_window(widget);

  *visible = gdk_window_create_gl_context(window, error);

  if (*error != nullptr) {
    return FALSE;
  }

  *resource = gdk_window_create_gl_context(window, error);

  if (*error != nullptr) {
    return FALSE;
  }
  return TRUE;
}

// Implements FlRenderer::create_backing_store.
static gboolean fl_renderer_gl_create_backing_store(
    FlRenderer* renderer,
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
  g_autoptr(GError) error = nullptr;
  gboolean result = fl_renderer_make_current(renderer, &error);
  if (!result) {
    g_warning("Failed to make renderer current when creating backing store: %s",
              error->message);
    return FALSE;
  }

  FlBackingStoreProvider* provider =
      fl_backing_store_provider_new(config->size.width, config->size.height);
  if (!provider) {
    g_warning("Failed to create backing store");
    return FALSE;
  }

  uint32_t name = fl_backing_store_provider_get_gl_framebuffer_id(provider);
  uint32_t format = fl_backing_store_provider_get_gl_format(provider);

  backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
  backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeFramebuffer;
  backing_store_out->open_gl.framebuffer.user_data = provider;
  backing_store_out->open_gl.framebuffer.name = name;
  backing_store_out->open_gl.framebuffer.target = format;
  backing_store_out->open_gl.framebuffer.destruction_callback = [](void* p) {
    // Backing store destroyed in fl_renderer_gl_collect_backing_store(), set
    // on FlutterCompositor.collect_backing_store_callback during engine start.
  };

  return TRUE;
}

// Implements FlRenderer::collect_backing_store.
static gboolean fl_renderer_gl_collect_backing_store(
    FlRenderer* renderer,
    const FlutterBackingStore* backing_store) {
  g_autoptr(GError) error = nullptr;
  gboolean result = fl_renderer_make_current(renderer, &error);
  if (!result) {
    g_warning(
        "Failed to make renderer current when collecting backing store: %s",
        error->message);
    return FALSE;
  }

  // OpenGL context is required when destroying #FlBackingStoreProvider.
  g_object_unref(backing_store->open_gl.framebuffer.user_data);
  return TRUE;
}

// Implements FlRenderer::present_layers.
static gboolean fl_renderer_gl_present_layers(FlRenderer* renderer,
                                              const FlutterLayer** layers,
                                              size_t layers_count) {
  FlView* view = fl_renderer_get_view(renderer);
  GdkGLContext* context = fl_renderer_get_context(renderer);
  if (!view || !context) {
    return FALSE;
  }
  fl_view_begin_frame(view);

  for (size_t i = 0; i < layers_count; ++i) {
    const FlutterLayer* layer = layers[i];
    switch (layer->type) {
      case kFlutterLayerContentTypeBackingStore: {
        const FlutterBackingStore* backing_store = layer->backing_store;
        auto framebuffer = &backing_store->open_gl.framebuffer;
        fl_view_add_gl_area(
            view, context,
            reinterpret_cast<FlBackingStoreProvider*>(framebuffer->user_data));
      } break;
      case kFlutterLayerContentTypePlatformView: {
        // Currently unsupported.
      } break;
    }
  }

  fl_view_end_frame(view);
  return TRUE;
}

static void fl_renderer_gl_class_init(FlRendererGLClass* klass) {
  FL_RENDERER_CLASS(klass)->create_contexts = fl_renderer_gl_create_contexts;
  FL_RENDERER_CLASS(klass)->create_backing_store =
      fl_renderer_gl_create_backing_store;
  FL_RENDERER_CLASS(klass)->collect_backing_store =
      fl_renderer_gl_collect_backing_store;
  FL_RENDERER_CLASS(klass)->present_layers = fl_renderer_gl_present_layers;
}

static void fl_renderer_gl_init(FlRendererGL* self) {}

FlRendererGL* fl_renderer_gl_new() {
  return FL_RENDERER_GL(g_object_new(fl_renderer_gl_get_type(), nullptr));
}
