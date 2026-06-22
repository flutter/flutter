// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK4_RUNTIME_API_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK4_RUNTIME_API_H_

#include <gtk/gtk.h>

#if FLUTTER_LINUX_GTK4

struct FlGtkRuntimeApi {
  gboolean checked;

  gboolean gtk_at_least_4_10;
  gboolean gtk_at_least_4_14;
  gboolean gtk_at_least_4_18;

  gboolean (*gtk_accessible_get_platform_state)(GtkAccessible* self,
                                                gint state);
  GtkAccessible* (*gtk_accessible_get_accessible_parent)(GtkAccessible* self);
  void (*gtk_accessible_set_accessible_parent)(GtkAccessible* self,
                                               GtkAccessible* parent,
                                               GtkAccessible* next_sibling);
  GtkAccessible* (*gtk_accessible_get_first_accessible_child)(
      GtkAccessible* self);
  GtkAccessible* (*gtk_accessible_get_next_accessible_sibling)(
      GtkAccessible* self);
  void (*gtk_accessible_update_next_accessible_sibling)(
      GtkAccessible* self,
      GtkAccessible* new_sibling);
  gboolean (*gtk_accessible_get_bounds)(GtkAccessible* self,
                                        int* x,
                                        int* y,
                                        int* width,
                                        int* height);
  void (*gtk_accessible_update_state_value)(GtkAccessible* self,
                                            int n_states,
                                            GtkAccessibleState states[],
                                            const GValue values[]);
  void (*gtk_accessible_update_property_value)(
      GtkAccessible* self,
      int n_properties,
      GtkAccessibleProperty properties[],
      const GValue values[]);
  void (*gtk_accessible_update_relation_value)(
      GtkAccessible* self,
      int n_relations,
      GtkAccessibleRelation relations[],
      const GValue values[]);
  void (*gtk_accessible_state_init_value)(GtkAccessibleState state,
                                          GValue* value);
  void (*gtk_accessible_property_init_value)(GtkAccessibleProperty property,
                                             GValue* value);
  void (*gtk_accessible_relation_init_value)(GtkAccessibleRelation relation,
                                             GValue* value);
  void (*gtk_accessible_announce)(GtkAccessible* self,
                                  const char* message,
                                  gint priority);
};

const FlGtkRuntimeApi* fl_gtk_runtime_api_get();
void fl_gtk_runtime_accessible_set_accessible_parent(
    GtkAccessible* self,
    GtkAccessible* parent,
    GtkAccessible* next_sibling);
void fl_gtk_runtime_accessible_update_state_value(GtkAccessible* self,
                                                  int n_states,
                                                  GtkAccessibleState states[],
                                                  const GValue values[]);
void fl_gtk_runtime_accessible_update_property_value(
    GtkAccessible* self,
    int n_properties,
    GtkAccessibleProperty properties[],
    const GValue values[]);
void fl_gtk_runtime_accessible_update_relation_value(
    GtkAccessible* self,
    int n_relations,
    GtkAccessibleRelation relations[],
    const GValue values[]);
void fl_gtk_runtime_accessible_state_init_value(GtkAccessibleState state,
                                                GValue* value);
void fl_gtk_runtime_accessible_property_init_value(
    GtkAccessibleProperty property,
    GValue* value);
void fl_gtk_runtime_accessible_relation_init_value(
    GtkAccessibleRelation relation,
    GValue* value);
void fl_gtk_runtime_accessible_announce(GtkAccessible* self,
                                        const char* message,
                                        gint priority);

#endif  // FLUTTER_LINUX_GTK4

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK4_RUNTIME_API_H_
