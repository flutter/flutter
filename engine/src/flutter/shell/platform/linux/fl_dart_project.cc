// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/public/flutter_linux/fl_dart_project.h"

#include <gmodule.h>

/**
 * FlDartProject:
 *
 * #FlDartProject represents a Dart project. It is used provide information
 * about the application when creating a #FlView.
 */

struct _FlDartProject {
  GObject parent_instance;

  gchar* assets_path;
  gchar* icu_data_path;
};

enum { PROP_ASSETS_PATH = 1, PROP_ICU_DATA_PATH, PROP_LAST };

G_DEFINE_TYPE(FlDartProject, fl_dart_project, G_TYPE_OBJECT)

static void fl_dart_project_set_property(GObject* object,
                                         guint prop_id,
                                         const GValue* value,
                                         GParamSpec* pspec) {
  FlDartProject* self = FL_DART_PROJECT(object);

  switch (prop_id) {
    case PROP_ASSETS_PATH:
      g_free(self->assets_path);
      self->assets_path = g_strdup(g_value_get_string(value));
      break;
    case PROP_ICU_DATA_PATH:
      g_free(self->icu_data_path);
      self->icu_data_path = g_strdup(g_value_get_string(value));
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
      g_value_set_string(value, self->assets_path);
      break;
    case PROP_ICU_DATA_PATH:
      g_value_set_string(value, self->icu_data_path);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec);
      break;
  }
}

static void fl_dart_project_dispose(GObject* object) {
  FlDartProject* self = FL_DART_PROJECT(object);

  g_clear_pointer(&self->assets_path, g_free);
  g_clear_pointer(&self->icu_data_path, g_free);

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
          static_cast<GParamFlags>(G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY |
                                   G_PARAM_STATIC_STRINGS)));
  g_object_class_install_property(
      G_OBJECT_CLASS(klass), PROP_ICU_DATA_PATH,
      g_param_spec_string(
          "icu-data-path", "icu-data-path", "Path to ICU data", nullptr,
          static_cast<GParamFlags>(G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY |
                                   G_PARAM_STATIC_STRINGS)));
}

static void fl_dart_project_init(FlDartProject* self) {}

/**
 * fl_dart_project_new:
 * @assets_path: a file path, e.g. "build/assets"
 * @icu_data_path: a file path, e.g. "build/icudtl.dat"
 *
 * Create a Flutter project.
 *
 * Returns: a new #FlDartProject
 */
G_MODULE_EXPORT FlDartProject* fl_dart_project_new(const gchar* assets_path,
                                                   const gchar* icu_data_path) {
  return static_cast<FlDartProject*>(
      g_object_new(fl_dart_project_get_type(), "assets-path", assets_path,
                   "icu-data-path", icu_data_path, nullptr));
}

/**
 * fl_dart_project_get_assets_path:
 * @view: a #FlDartProject
 *
 * Get the path to the directory containing the assets used in the Flutter
 * application.
 *
 * Returns: a file path, e.g. "build/assets"
 */
G_MODULE_EXPORT const gchar* fl_dart_project_get_assets_path(
    FlDartProject* self) {
  g_return_val_if_fail(FL_IS_DART_PROJECT(self), nullptr);
  return self->assets_path;
}

/**
 * fl_dart_project_get_icu_data_path:
 * @view: a #FlDartProject
 *
 * Get the path to the ICU data file in the Flutter application.
 *
 * Returns: a file path, e.g. "build/icudtl.dat"
 */
G_MODULE_EXPORT const gchar* fl_dart_project_get_icu_data_path(
    FlDartProject* self) {
  g_return_val_if_fail(FL_IS_DART_PROJECT(self), nullptr);
  return self->icu_data_path;
}
