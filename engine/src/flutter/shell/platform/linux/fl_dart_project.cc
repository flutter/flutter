// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/public/flutter_linux/fl_dart_project.h"

#include <gmodule.h>

#include <string>
#include <vector>

#include "flutter/shell/platform/common/engine_switches.h"
#include "flutter/shell/platform/linux/fl_dart_project_private.h"

struct _FlDartProject {
  GObject parent_instance;

  gboolean enable_mirrors;
  gchar* aot_library_path;
  gchar* assets_path;
  gchar* icu_data_path;
  gchar** dart_entrypoint_args;
};

G_DEFINE_TYPE(FlDartProject, fl_dart_project, G_TYPE_OBJECT)

// Gets the directory the current executable is in.
static gchar* get_executable_dir() {
  g_autoptr(GError) error = nullptr;
  g_autofree gchar* exe_path = g_file_read_link("/proc/self/exe", &error);
  if (exe_path == nullptr) {
    g_critical("Failed to determine location of executable: %s",
               error->message);
    return nullptr;
  }

  return g_path_get_dirname(exe_path);
}

static void fl_dart_project_dispose(GObject* object) {
  FlDartProject* self = FL_DART_PROJECT(object);

  g_clear_pointer(&self->aot_library_path, g_free);
  g_clear_pointer(&self->assets_path, g_free);
  g_clear_pointer(&self->icu_data_path, g_free);
  g_clear_pointer(&self->dart_entrypoint_args, g_strfreev);

  G_OBJECT_CLASS(fl_dart_project_parent_class)->dispose(object);
}

static void fl_dart_project_class_init(FlDartProjectClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_dart_project_dispose;
}

static void fl_dart_project_init(FlDartProject* self) {}

G_MODULE_EXPORT FlDartProject* fl_dart_project_new() {
  FlDartProject* self =
      FL_DART_PROJECT(g_object_new(fl_dart_project_get_type(), nullptr));

  g_autofree gchar* executable_dir = get_executable_dir();
  self->aot_library_path =
      g_build_filename(executable_dir, "lib", "libapp.so", nullptr);
  self->assets_path =
      g_build_filename(executable_dir, "data", "flutter_assets", nullptr);
  self->icu_data_path =
      g_build_filename(executable_dir, "data", "icudtl.dat", nullptr);

  return self;
}

G_MODULE_EXPORT void fl_dart_project_set_enable_mirrors(
    FlDartProject* self,
    gboolean enable_mirrors) {
  g_return_if_fail(FL_IS_DART_PROJECT(self));
  self->enable_mirrors = enable_mirrors;
}

G_MODULE_EXPORT gboolean
fl_dart_project_get_enable_mirrors(FlDartProject* self) {
  g_return_val_if_fail(FL_IS_DART_PROJECT(self), FALSE);
  return self->enable_mirrors;
}

G_MODULE_EXPORT const gchar* fl_dart_project_get_aot_library_path(
    FlDartProject* self) {
  g_return_val_if_fail(FL_IS_DART_PROJECT(self), nullptr);
  return self->aot_library_path;
}

G_MODULE_EXPORT const gchar* fl_dart_project_get_assets_path(
    FlDartProject* self) {
  g_return_val_if_fail(FL_IS_DART_PROJECT(self), nullptr);
  return self->assets_path;
}

G_MODULE_EXPORT const gchar* fl_dart_project_get_icu_data_path(
    FlDartProject* self) {
  g_return_val_if_fail(FL_IS_DART_PROJECT(self), nullptr);
  return self->icu_data_path;
}

G_MODULE_EXPORT gchar** fl_dart_project_get_dart_entrypoint_arguments(
    FlDartProject* self) {
  g_return_val_if_fail(FL_IS_DART_PROJECT(self), nullptr);
  return self->dart_entrypoint_args;
}

G_MODULE_EXPORT void fl_dart_project_set_dart_entrypoint_arguments(
    FlDartProject* self,
    char** argv) {
  g_return_if_fail(FL_IS_DART_PROJECT(self));
  g_clear_pointer(&self->dart_entrypoint_args, g_strfreev);
  self->dart_entrypoint_args = g_strdupv(argv);
}

GPtrArray* fl_dart_project_get_switches(FlDartProject* self) {
  GPtrArray* switches = g_ptr_array_new_with_free_func(g_free);
  std::vector<std::string> env_switches = flutter::GetSwitchesFromEnvironment();
  for (const auto& env_switch : env_switches) {
    g_ptr_array_add(switches, g_strdup(env_switch.c_str()));
  }
  if (self->enable_mirrors) {
    g_ptr_array_add(switches, g_strdup("--dart-flags=--enable_mirrors=true"));
  }
  return switches;
}
