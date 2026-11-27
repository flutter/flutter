// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/public/flutter_linux/fl_plugin_registrar.h"
#include "flutter/shell/platform/linux/fl_plugin_registrar_private.h"

#include <gmodule.h>

#include "flutter/common/constants.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_renderable.h"

G_DECLARE_FINAL_TYPE(FlPluginRegistrarImpl,
                     fl_plugin_registrar_impl,
                     FL,
                     PLUGIN_REGISTRAR_IMPL,
                     GObject)

struct _FlPluginRegistrarImpl {
  GObject parent_instance;

  // Engine that plugin is registered with.
  GWeakRef engine;

  // View that plugin is controlling.
  GWeakRef view;

  // Messenger to communicate on.
  FlBinaryMessenger* messenger;

  // Texture registrar in use.
  FlTextureRegistrar* texture_registrar;
};

static void fl_plugin_registrar_impl_iface_init(
    FlPluginRegistrarInterface* iface);

G_DEFINE_INTERFACE(FlPluginRegistrar, fl_plugin_registrar, G_TYPE_OBJECT)

G_DEFINE_TYPE_WITH_CODE(
    FlPluginRegistrarImpl,
    fl_plugin_registrar_impl,
    G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE(fl_plugin_registrar_get_type(),
                          fl_plugin_registrar_impl_iface_init))

static void fl_plugin_registrar_default_init(
    FlPluginRegistrarInterface* iface) {}

static void fl_plugin_registrar_impl_dispose(GObject* object) {
  FlPluginRegistrarImpl* self = FL_PLUGIN_REGISTRAR_IMPL(object);

  g_weak_ref_clear(&self->engine);
  g_weak_ref_clear(&self->view);
  g_clear_object(&self->messenger);
  g_clear_object(&self->texture_registrar);

  G_OBJECT_CLASS(fl_plugin_registrar_impl_parent_class)->dispose(object);
}

static void fl_plugin_registrar_impl_class_init(
    FlPluginRegistrarImplClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_plugin_registrar_impl_dispose;
}

static FlBinaryMessenger* get_messenger(FlPluginRegistrar* registrar) {
  FlPluginRegistrarImpl* self = FL_PLUGIN_REGISTRAR_IMPL(registrar);
  return self->messenger;
}

static FlTextureRegistrar* get_texture_registrar(FlPluginRegistrar* registrar) {
  FlPluginRegistrarImpl* self = FL_PLUGIN_REGISTRAR_IMPL(registrar);
  return self->texture_registrar;
}

static FlView* get_view_by_id(FlPluginRegistrar* registrar, int64_t view_id) {
  FlPluginRegistrarImpl* self = FL_PLUGIN_REGISTRAR_IMPL(registrar);
  g_autoptr(FlEngine) engine = FL_ENGINE(g_weak_ref_get(&self->engine));
  if (engine == nullptr) {
    return nullptr;
  }
  g_autoptr(FlRenderable) renderable =
      fl_engine_get_renderable(engine, view_id);
  if (renderable == nullptr || !FL_IS_VIEW(renderable)) {
    return nullptr;
  }
  return FL_VIEW(renderable);
}

static FlView* get_view(FlPluginRegistrar* registrar) {
  FlPluginRegistrarImpl* self = FL_PLUGIN_REGISTRAR_IMPL(registrar);
  g_autoptr(FlView) view = FL_VIEW(g_weak_ref_get(&self->view));
  if (view != nullptr) {
    return view;
  }
  return get_view_by_id(registrar, flutter::kFlutterImplicitViewId);
}

static void fl_plugin_registrar_impl_iface_init(
    FlPluginRegistrarInterface* iface) {
  iface->get_messenger = get_messenger;
  iface->get_texture_registrar = get_texture_registrar;
  iface->get_view = get_view;
  iface->get_view_by_id = get_view_by_id;
}

static void fl_plugin_registrar_impl_init(FlPluginRegistrarImpl* self) {}

FlPluginRegistrar* fl_plugin_registrar_new(
    FlEngine* engine,
    FlView* view,
    FlBinaryMessenger* messenger,
    FlTextureRegistrar* texture_registrar) {
  g_return_val_if_fail(engine == nullptr || FL_IS_ENGINE(engine), nullptr);
  g_return_val_if_fail(view == nullptr || FL_IS_VIEW(view), nullptr);
  g_return_val_if_fail(FL_IS_BINARY_MESSENGER(messenger), nullptr);
  g_return_val_if_fail(FL_IS_TEXTURE_REGISTRAR(texture_registrar), nullptr);

  FlPluginRegistrarImpl* self = FL_PLUGIN_REGISTRAR_IMPL(
      g_object_new(fl_plugin_registrar_impl_get_type(), nullptr));

  // Added to stop compiler complaining about an unused function.
  FL_IS_PLUGIN_REGISTRAR_IMPL(self);

  g_weak_ref_init(&self->engine, engine);
  g_weak_ref_init(&self->view, view);
  self->messenger = FL_BINARY_MESSENGER(g_object_ref(messenger));
  self->texture_registrar =
      FL_TEXTURE_REGISTRAR(g_object_ref(texture_registrar));

  return FL_PLUGIN_REGISTRAR(self);
}

G_MODULE_EXPORT FlBinaryMessenger* fl_plugin_registrar_get_messenger(
    FlPluginRegistrar* self) {
  g_return_val_if_fail(FL_IS_PLUGIN_REGISTRAR(self), nullptr);

  return FL_PLUGIN_REGISTRAR_GET_IFACE(self)->get_messenger(self);
}

G_MODULE_EXPORT FlTextureRegistrar* fl_plugin_registrar_get_texture_registrar(
    FlPluginRegistrar* self) {
  g_return_val_if_fail(FL_IS_PLUGIN_REGISTRAR(self), nullptr);

  return FL_PLUGIN_REGISTRAR_GET_IFACE(self)->get_texture_registrar(self);
}

G_MODULE_EXPORT FlView* fl_plugin_registrar_get_view(FlPluginRegistrar* self) {
  g_return_val_if_fail(FL_IS_PLUGIN_REGISTRAR(self), nullptr);

  return FL_PLUGIN_REGISTRAR_GET_IFACE(self)->get_view(self);
}

G_MODULE_EXPORT FlView* fl_plugin_registrar_get_view_by_id(
    FlPluginRegistrar* self,
    int64_t view_id) {
  g_return_val_if_fail(FL_IS_PLUGIN_REGISTRAR(self), nullptr);

  FlPluginRegistrarInterface* iface = FL_PLUGIN_REGISTRAR_GET_IFACE(self);
  if (iface->get_view_by_id == nullptr) {
    return nullptr;
  }
  return iface->get_view_by_id(self, view_id);
}
