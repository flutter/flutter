// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/public/flutter_linux/fl_dart_project.h"

#include <gmodule.h>

struct _FlDartProject {
  GObject parent_instance;

  gchar* path;
};

enum { PROP_ASSETS_PATH = 1, PROP_ICU_DATA_PATH, PROP_PATH, PROP_LAST };

G_DEFINE_TYPE(FlDartProject, fl_dart_project, G_TYPE_OBJECT)

static void fl_dart_project_set_path(FlDartProject* self, const gchar* path) {
  g_free(self->path);

  if (g_path_is_absolute(path))
    self->path = g_strdup(path);
  else {
    g_autoptr(GError) error = NULL;
    g_autofree gchar* exe_path = g_file_read_link("/proc/self/exe", &error);
    if (exe_path == NULL)
      g_critical("Failed to determine location of executable: %s",
                 error->message);
    g_autofree gchar* dir = g_path_get_dirname(exe_path);
    self->path = g_build_filename(dir, path, NULL);
  }
}

static void fl_dart_project_set_property(GObject* object,
                                         guint prop_id,
                                         const GValue* value,
                                         GParamSpec* pspec) {
  FlDartProject* self = FL_DART_PROJECT(object);

  switch (prop_id) {
    case PROP_PATH:
      fl_dart_project_set_path(self, g_value_get_string(value));
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec);
      break;
  }
}

static void fl_dart_project_get_property(GObject* object,
                                         guint prop_id,
                                         GValue* value,
                                         GParamSpec* pspec) {
  FlDartProject* self = FL_DART_PROJECT(object);

  switch (prop_id) {
    case PROP_ASSETS_PATH:
      g_value_take_string(value, fl_dart_project_get_assets_path(self));
      break;
    case PROP_ICU_DATA_PATH:
      g_value_take_string(value, fl_dart_project_get_icu_data_path(self));
      break;
    case PROP_PATH:
      g_value_set_string(value, self->path);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec);
      break;
  }
}

static void fl_dart_project_dispose(GObject* object) {
  FlDartProject* self = FL_DART_PROJECT(object);

  g_clear_pointer(&self->path, g_free);

  G_OBJECT_CLASS(fl_dart_project_parent_class)->dispose(object);
}

static void fl_dart_project_class_init(FlDartProjectClass* klass) {
  G_OBJECT_CLASS(klass)->set_property = fl_dart_project_set_property;
  G_OBJECT_CLASS(klass)->get_property = fl_dart_project_get_property;
  G_OBJECT_CLASS(klass)->dispose = fl_dart_project_dispose;

  g_object_class_install_property(
      G_OBJECT_CLASS(klass), PROP_ASSETS_PATH,
      g_param_spec_string(
          "assets-path", "assets-path", "Path to Flutter assets", nullptr,
          static_cast<GParamFlags>(G_PARAM_READABLE | G_PARAM_STATIC_STRINGS)));

  g_object_class_install_property(
      G_OBJECT_CLASS(klass), PROP_ICU_DATA_PATH,
      g_param_spec_string(
          "icu-data-path", "icu-data-path", "Path to ICU data", nullptr,
          static_cast<GParamFlags>(G_PARAM_READABLE | G_PARAM_STATIC_STRINGS)));

  g_object_class_install_property(
      G_OBJECT_CLASS(klass), PROP_PATH,
      g_param_spec_string(
          "path", "path", "Path to Flutter project", nullptr,
          static_cast<GParamFlags>(G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY |
                                   G_PARAM_STATIC_STRINGS)));
}

static void fl_dart_project_init(FlDartProject* self) {}

G_MODULE_EXPORT FlDartProject* fl_dart_project_new(const gchar* path) {
  return static_cast<FlDartProject*>(
      g_object_new(fl_dart_project_get_type(), "path", path, nullptr));
}

G_MODULE_EXPORT const gchar* fl_dart_project_get_path(FlDartProject* self) {
  g_return_val_if_fail(FL_IS_DART_PROJECT(self), nullptr);
  return self->path;
}

G_MODULE_EXPORT gchar* fl_dart_project_get_assets_path(FlDartProject* self) {
  g_return_val_if_fail(FL_IS_DART_PROJECT(self), nullptr);
  return g_build_filename(self->path, "flutter_assets", NULL);
}

G_MODULE_EXPORT gchar* fl_dart_project_get_icu_data_path(FlDartProject* self) {
  g_return_val_if_fail(FL_IS_DART_PROJECT(self), nullptr);
  return g_build_filename(self->path, "icudtl.dat", NULL);
}
