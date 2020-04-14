// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_DART_PROJECT_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_DART_PROJECT_H_

#include <glib-object.h>

#if !defined(__FLUTTER_LINUX_INSIDE__) && !defined(FLUTTER_LINUX_COMPILATION)
#error "Only <flutter_linux/flutter_linux.h> can be included directly."
#endif

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlDartProject, fl_dart_project, FL, DART_PROJECT, GObject)

/**
 * FlDartProject:
 *
 * #FlDartProject represents a Dart project. It is used to provide information
 * about the application when creating a #FlView.
 */

/**
 * fl_dart_project_new:
 * @path: a file path, e.g. "my_dart_project"
 *
 * Create a Flutter project. The project path should contain the following
 * top-level items:
 * - icudtl.dat (provided as a resource by the Flutter tool)
 * - flutter_assets (as built by the Flutter tool)
 *
 * The path can either be absolute, or relative to the directory containing the
 * running executable.
 *
 * Returns: a new #FlDartProject
 */

/**
 * fl_dart_project_new:
 * @path: a file path, e.g. "my_dart_project"
 *
 * Creates a Flutter project. The project path should contain the following
 * top-level items:
 * - icudtl.dat (provided as a resource by the Flutter tool)
 * - flutter_assets (as built by the Flutter tool)
 *
 * The path can either be absolute, or relative to the directory containing the
 * running executable.
 *
 * Returns: a new #FlDartProject
 */
FlDartProject* fl_dart_project_new(const gchar* path);

/**
 * fl_dart_project_get_path:
 * @project: a #FlDartProject
 *
 * Gets the path to the directory containing the Flutter application.
 *
 * Returns: (type filename): a file path, e.g. "/projects/my_dart_project"
 */
const gchar* fl_dart_project_get_path(FlDartProject* project);

/**
 * fl_dart_project_get_assets_path:
 * @project: a #FlDartProject
 *
 * Gets the path to the directory containing the assets used in the Flutter
 * application.
 *
 * Returns: (type filename): a file path, e.g.
 * "/projects/my_dart_project/assets"
 */
gchar* fl_dart_project_get_assets_path(FlDartProject* project);

/**
 * fl_dart_project_get_icu_data_path:
 * @project: a #FlDartProject
 *
 * Gets the path to the ICU data file in the Flutter application.
 *
 * Returns: (type filename): a file path, e.g.
 * "/projects/my_dart_project/icudtl.dat"
 */
gchar* fl_dart_project_get_icu_data_path(FlDartProject* project);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_DART_PROJECT_H_
