// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/public/flutter_linux/fl_texture_registrar.h"

#include <gmodule.h>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_pixel_buffer_texture_private.h"
#include "flutter/shell/platform/linux/fl_texture_gl_private.h"
#include "flutter/shell/platform/linux/fl_texture_private.h"
#include "flutter/shell/platform/linux/fl_texture_registrar_private.h"

struct _FlTextureRegistrar {
  GObject parent_instance;

  // Weak reference to the engine this texture registrar is created for.
  FlEngine* engine;

  // Internal record for registered textures.
  //
  // It is a map from Flutter texture ID to #FlTexture instance created by
  // plugins.  The keys are directly stored int64s. The values are stored
  // pointer to #FlTexture.  This table is freed by the responder.
  GHashTable* textures;
};

G_DEFINE_TYPE(FlTextureRegistrar, fl_texture_registrar, G_TYPE_OBJECT)

static void engine_weak_notify_cb(gpointer user_data,
                                  GObject* where_the_object_was) {
  FlTextureRegistrar* self = FL_TEXTURE_REGISTRAR(user_data);
  self->engine = nullptr;

  // Unregister any textures.
  g_autoptr(GHashTable) textures = self->textures;
  self->textures = g_hash_table_new_full(g_direct_hash, g_direct_equal, nullptr,
                                         g_object_unref);
  g_hash_table_remove_all(textures);
}

static void fl_texture_registrar_dispose(GObject* object) {
  FlTextureRegistrar* self = FL_TEXTURE_REGISTRAR(object);

  g_clear_pointer(&self->textures, g_hash_table_unref);

  if (self->engine != nullptr) {
    g_object_weak_unref(G_OBJECT(self->engine), engine_weak_notify_cb, self);
    self->engine = nullptr;
  }

  G_OBJECT_CLASS(fl_texture_registrar_parent_class)->dispose(object);
}

static void fl_texture_registrar_class_init(FlTextureRegistrarClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_texture_registrar_dispose;
}

static void fl_texture_registrar_init(FlTextureRegistrar* self) {
  self->textures = g_hash_table_new_full(g_direct_hash, g_direct_equal, nullptr,
                                         g_object_unref);
}

G_MODULE_EXPORT gboolean
fl_texture_registrar_register_texture(FlTextureRegistrar* self,
                                      FlTexture* texture) {
  g_return_val_if_fail(FL_IS_TEXTURE_REGISTRAR(self), FALSE);
  g_return_val_if_fail(FL_IS_TEXTURE(texture), FALSE);

  if (FL_IS_TEXTURE_GL(texture) || FL_IS_PIXEL_BUFFER_TEXTURE(texture)) {
    g_hash_table_insert(self->textures,
                        GINT_TO_POINTER(fl_texture_get_texture_id(texture)),
                        g_object_ref(texture));

    if (self->engine == nullptr) {
      return FALSE;
    }

    return fl_engine_register_external_texture(
        self->engine, fl_texture_get_texture_id(texture));
  } else {
    // We currently only support #FlTextureGL and #FlPixelBufferTexture.
    return FALSE;
  }
}

G_MODULE_EXPORT gboolean
fl_texture_registrar_mark_texture_frame_available(FlTextureRegistrar* self,
                                                  FlTexture* texture) {
  g_return_val_if_fail(FL_IS_TEXTURE_REGISTRAR(self), FALSE);

  if (self->engine == nullptr) {
    return FALSE;
  }

  if (fl_texture_registrar_get_texture(
          self, fl_texture_get_texture_id(texture)) == nullptr) {
    g_warning("Unregistered texture %p", texture);
    return FALSE;
  }

  return fl_engine_mark_texture_frame_available(
      self->engine, fl_texture_get_texture_id(texture));
}

gboolean fl_texture_registrar_populate_gl_external_texture(
    FlTextureRegistrar* self,
    int64_t texture_id,
    uint32_t width,
    uint32_t height,
    FlutterOpenGLTexture* opengl_texture,
    GError** error) {
  FlTexture* texture = fl_texture_registrar_get_texture(self, texture_id);
  if (texture == nullptr) {
    g_set_error(error, fl_engine_error_quark(), FL_ENGINE_ERROR_FAILED,
                "Unable to find texture %" G_GINT64_FORMAT, texture_id);
    return FALSE;
  }
  if (FL_IS_TEXTURE_GL(texture)) {
    return fl_texture_gl_populate(FL_TEXTURE_GL(texture), width, height,
                                  opengl_texture, error);
  } else if (FL_IS_PIXEL_BUFFER_TEXTURE(texture)) {
    return fl_pixel_buffer_texture_populate(
        FL_PIXEL_BUFFER_TEXTURE(texture), width, height, opengl_texture, error);
  } else {
    g_set_error(error, fl_engine_error_quark(), FL_ENGINE_ERROR_FAILED,
                "Unsupported texture type %" G_GINT64_FORMAT, texture_id);
    return FALSE;
  }
}

G_MODULE_EXPORT gboolean
fl_texture_registrar_unregister_texture(FlTextureRegistrar* self,
                                        FlTexture* texture) {
  g_return_val_if_fail(FL_IS_TEXTURE_REGISTRAR(self), FALSE);

  if (!g_hash_table_remove(
          self->textures,
          GINT_TO_POINTER(fl_texture_get_texture_id(texture)))) {
    g_warning("Unregistering a non-existent texture %p", texture);
    return FALSE;
  }

  if (self->engine == nullptr) {
    return FALSE;
  }

  return fl_engine_unregister_external_texture(
      self->engine, fl_texture_get_texture_id(texture));
}

FlTexture* fl_texture_registrar_get_texture(FlTextureRegistrar* registrar,
                                            int64_t texture_id) {
  return reinterpret_cast<FlTexture*>(
      g_hash_table_lookup(registrar->textures, GINT_TO_POINTER(texture_id)));
}

FlTextureRegistrar* fl_texture_registrar_new(FlEngine* engine) {
  FlTextureRegistrar* self = FL_TEXTURE_REGISTRAR(
      g_object_new(fl_texture_registrar_get_type(), nullptr));

  self->engine = engine;
  g_object_weak_ref(G_OBJECT(engine), engine_weak_notify_cb, self);

  return self;
}
