// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK4_RUNTIME_API_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK4_RUNTIME_API_H_

#include <gtk/gtk.h>

#if FLUTTER_LINUX_GTK4

#if GTK_CHECK_VERSION(4, 14, 0)
using FlGdkDmabufFormats = GdkDmabufFormats;
using FlGdkDmabufTextureBuilder = GdkDmabufTextureBuilder;
#else
typedef struct _GdkDmabufFormats FlGdkDmabufFormats;
typedef struct _GdkDmabufTextureBuilder FlGdkDmabufTextureBuilder;
#endif

constexpr guint kFlGtk4DmabufMaxPlanes = 4;

struct FlGtk4DmabufPlane {
  int fd;
  guint stride;
  guint offset;
};

struct FlGtk4DmabufDescriptor {
  guint width;
  guint height;
  guint32 fourcc;
  guint64 modifier;
  gboolean premultiplied;
  guint n_planes;
  FlGtk4DmabufPlane planes[kFlGtk4DmabufMaxPlanes];
};

using FlGtk4DmabufFormatCallback = void (*)(guint32 fourcc,
                                            guint64 modifier,
                                            gpointer user_data);

#if GTK_CHECK_VERSION(4, 14, 0)
using FlGtkAccessibleAnnouncementPriority = GtkAccessibleAnnouncementPriority;
#else
using FlGtkAccessibleAnnouncementPriority = gint;
#endif

#if GTK_CHECK_VERSION(4, 10, 0)
using FlGtkAccessiblePlatformState = GtkAccessiblePlatformState;
#else
enum FlGtkAccessiblePlatformState {
  FL_GTK_ACCESSIBLE_PLATFORM_STATE_FOCUSABLE = 0,
  FL_GTK_ACCESSIBLE_PLATFORM_STATE_FOCUSED = 1,
  FL_GTK_ACCESSIBLE_PLATFORM_STATE_ACTIVE = 2,
};
#endif

// GTK 4.10 appended these virtual methods to GtkAccessibleInterface. This
// mirror lets a GTK 4.8-header build install them on a newer runtime.
struct FlGtkAccessibleInterface4_10 {
  GTypeInterface g_iface;
  GtkATContext* (*get_at_context)(GtkAccessible* self);
  gboolean (*get_platform_state)(GtkAccessible* self,
                                 FlGtkAccessiblePlatformState state);
  GtkAccessible* (*get_accessible_parent)(GtkAccessible* self);
  GtkAccessible* (*get_first_accessible_child)(GtkAccessible* self);
  GtkAccessible* (*get_next_accessible_sibling)(GtkAccessible* self);
  gboolean (*get_bounds)(GtkAccessible* self,
                         int* x,
                         int* y,
                         int* width,
                         int* height);
};

// GTK 4.14 introduced GtkAccessibleText. Keep this ABI mirror independent of
// the build headers so a GTK 4.8-header build can use the interface when the
// loaded GTK library exports it.
struct FlGtkAccessibleTextRange4_14 {
  gsize start;
  gsize length;
};

enum FlGtkAccessibleTextGranularity4_14 {
  FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_CHARACTER = 0,
  FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_WORD = 1,
  FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_SENTENCE = 2,
  FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_LINE = 3,
  FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_PARAGRAPH = 4,
};

struct FlGtkAccessibleTextInterface4_14 {
  GTypeInterface g_iface;
  GBytes* (*get_contents)(GtkAccessible* self,
                          unsigned int start,
                          unsigned int end);
  GBytes* (*get_contents_at)(GtkAccessible* self,
                             unsigned int offset,
                             FlGtkAccessibleTextGranularity4_14 granularity,
                             unsigned int* start,
                             unsigned int* end);
  unsigned int (*get_caret_position)(GtkAccessible* self);
  gboolean (*get_selection)(GtkAccessible* self,
                            gsize* n_ranges,
                            FlGtkAccessibleTextRange4_14** ranges);
  gboolean (*get_attributes)(GtkAccessible* self,
                             unsigned int offset,
                             gsize* n_ranges,
                             FlGtkAccessibleTextRange4_14** ranges,
                             char*** attribute_names,
                             char*** attribute_values);
  void (*get_default_attributes)(GtkAccessible* self,
                                 char*** attribute_names,
                                 char*** attribute_values);
  gboolean (*get_extents)(GtkAccessible* self,
                          unsigned int start,
                          unsigned int end,
                          gpointer extents);
  gboolean (*get_offset)(GtkAccessible* self,
                         gconstpointer point,
                         unsigned int* offset);
};

struct FlGtkRuntimeApi {
  gboolean gtk_at_least_4_10;
  gboolean gtk_at_least_4_14;

  GType (*gtk_accessible_text_get_type)();
  void (*gtk_accessible_text_update_caret_position)(GtkAccessible* self);
  void (*gtk_accessible_text_update_selection_bound)(GtkAccessible* self);
  void (*gtk_accessible_text_update_contents)(GtkAccessible* self,
                                              gint change,
                                              unsigned int start,
                                              unsigned int end);

  void (*gtk_accessible_set_accessible_parent)(GtkAccessible* self,
                                               GtkAccessible* parent,
                                               GtkAccessible* next_sibling);
  GtkAccessible* (*gtk_accessible_get_first_accessible_child)(
      GtkAccessible* self);
  void (*gtk_accessible_announce)(GtkAccessible* self,
                                  const char* message,
                                  FlGtkAccessibleAnnouncementPriority priority);

  FlGdkDmabufFormats* (*gdk_display_get_dmabuf_formats)(GdkDisplay* display);
  FlGdkDmabufFormats* (*gdk_dmabuf_formats_ref)(FlGdkDmabufFormats* formats);
  void (*gdk_dmabuf_formats_unref)(FlGdkDmabufFormats* formats);
  gsize (*gdk_dmabuf_formats_get_n_formats)(FlGdkDmabufFormats* formats);
  void (*gdk_dmabuf_formats_get_format)(FlGdkDmabufFormats* formats,
                                        gsize index,
                                        guint32* fourcc,
                                        guint64* modifier);
  gboolean (*gdk_dmabuf_formats_contains)(FlGdkDmabufFormats* formats,
                                          guint32 fourcc,
                                          guint64 modifier);
  FlGdkDmabufTextureBuilder* (*gdk_dmabuf_texture_builder_new)();
  void (*gdk_dmabuf_texture_builder_set_display)(
      FlGdkDmabufTextureBuilder* self,
      GdkDisplay* display);
  void (*gdk_dmabuf_texture_builder_set_width)(FlGdkDmabufTextureBuilder* self,
                                               unsigned int width);
  void (*gdk_dmabuf_texture_builder_set_height)(FlGdkDmabufTextureBuilder* self,
                                                unsigned int height);
  void (*gdk_dmabuf_texture_builder_set_fourcc)(FlGdkDmabufTextureBuilder* self,
                                                guint32 fourcc);
  void (*gdk_dmabuf_texture_builder_set_modifier)(
      FlGdkDmabufTextureBuilder* self,
      guint64 modifier);
  void (*gdk_dmabuf_texture_builder_set_premultiplied)(
      FlGdkDmabufTextureBuilder* self,
      gboolean premultiplied);
  void (*gdk_dmabuf_texture_builder_set_n_planes)(
      FlGdkDmabufTextureBuilder* self,
      unsigned int n_planes);
  void (*gdk_dmabuf_texture_builder_set_fd)(FlGdkDmabufTextureBuilder* self,
                                            unsigned int plane,
                                            int fd);
  void (*gdk_dmabuf_texture_builder_set_stride)(FlGdkDmabufTextureBuilder* self,
                                                unsigned int plane,
                                                unsigned int stride);
  void (*gdk_dmabuf_texture_builder_set_offset)(FlGdkDmabufTextureBuilder* self,
                                                unsigned int plane,
                                                unsigned int offset);
  GdkTexture* (*gdk_dmabuf_texture_builder_build)(
      FlGdkDmabufTextureBuilder* self,
      GDestroyNotify destroy,
      gpointer data,
      GError** error);
};

const FlGtkRuntimeApi* fl_gtk_runtime_api_get();
gboolean fl_gtk_runtime_supports_native_accessibility_tree();
gboolean fl_gtk_runtime_supports_native_accessibility_text();
GType fl_gtk_runtime_accessible_text_get_type();
void fl_gtk_runtime_accessible_text_update_caret_position(GtkAccessible* self);
void fl_gtk_runtime_accessible_text_update_selection_bound(GtkAccessible* self);
void fl_gtk_runtime_accessible_text_update_contents(GtkAccessible* self,
                                                    gint change,
                                                    unsigned int start,
                                                    unsigned int end);
gboolean fl_gtk_runtime_supports_dmabuf_textures();
gboolean fl_gtk_runtime_dmabuf_format_supported(GdkDisplay* display,
                                                guint32 fourcc,
                                                guint64 modifier);
void fl_gtk_runtime_for_each_dmabuf_format(GdkDisplay* display,
                                           FlGtk4DmabufFormatCallback callback,
                                           gpointer user_data);
GdkTexture* fl_gtk_runtime_build_dmabuf_texture(
    GdkDisplay* display,
    const FlGtk4DmabufDescriptor* descriptor,
    GDestroyNotify destroy,
    gpointer data,
    GError** error);
void fl_gtk_runtime_accessible_set_accessible_parent(
    GtkAccessible* self,
    GtkAccessible* parent,
    GtkAccessible* next_sibling);
GtkAccessible* fl_gtk_runtime_accessible_get_first_accessible_child(
    GtkAccessible* self);
void fl_gtk_runtime_accessible_announce(GtkAccessible* self,
                                        const char* message,
                                        gint priority);

#endif  // FLUTTER_LINUX_GTK4

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK4_RUNTIME_API_H_
