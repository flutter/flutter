// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK4_RUNTIME_API_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK4_RUNTIME_API_H_

#include <gtk/gtk.h>

#include <cstddef>
#include <type_traits>

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
constexpr auto FL_GTK_ACCESSIBLE_PLATFORM_STATE_FOCUSABLE =
    GTK_ACCESSIBLE_PLATFORM_STATE_FOCUSABLE;
constexpr auto FL_GTK_ACCESSIBLE_PLATFORM_STATE_FOCUSED =
    GTK_ACCESSIBLE_PLATFORM_STATE_FOCUSED;
constexpr auto FL_GTK_ACCESSIBLE_PLATFORM_STATE_ACTIVE =
    GTK_ACCESSIBLE_PLATFORM_STATE_ACTIVE;
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
// the build headers so a GTK 4.8-header build can use the query interface when
// the loaded GTK library exports it. The trailing extents/offset callbacks
// were added in GTK 4.16 and must not be installed without a separately
// validated 4.16 layout gate. The separately gated 4.22 tail below must never
// be accessed merely because a symbol lookup succeeded.
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

// GTK 4.22 appends editing callbacks; never access this tail on older runtimes.
struct FlGtkAccessibleTextInterface4_22 {
  FlGtkAccessibleTextInterface4_14 base;
  gboolean (*set_caret_position)(GtkAccessible* self, unsigned int offset);
  gboolean (*set_selection)(GtkAccessible* self,
                            gsize i,
                            FlGtkAccessibleTextRange4_14* range);
};

// Keep these checks with the mirrors so header-only ABI checks and all engine
// consumers validate them, even when the native accessibility backend is off.
#if GTK_CHECK_VERSION(4, 14, 0)
static_assert(sizeof(FlGtkAccessibleTextRange4_14) ==
              sizeof(GtkAccessibleTextRange));
static_assert(alignof(FlGtkAccessibleTextRange4_14) ==
              alignof(GtkAccessibleTextRange));
static_assert(offsetof(FlGtkAccessibleTextRange4_14, start) ==
              offsetof(GtkAccessibleTextRange, start));
static_assert(offsetof(FlGtkAccessibleTextRange4_14, length) ==
              offsetof(GtkAccessibleTextRange, length));
#define FL_CHECK_TEXT_OFFSET(member)                                  \
  static_assert(offsetof(FlGtkAccessibleTextInterface4_14, member) == \
                offsetof(GtkAccessibleTextInterface, member))
FL_CHECK_TEXT_OFFSET(g_iface);
FL_CHECK_TEXT_OFFSET(get_contents);
FL_CHECK_TEXT_OFFSET(get_contents_at);
FL_CHECK_TEXT_OFFSET(get_caret_position);
FL_CHECK_TEXT_OFFSET(get_selection);
FL_CHECK_TEXT_OFFSET(get_attributes);
FL_CHECK_TEXT_OFFSET(get_default_attributes);
#if GTK_CHECK_VERSION(4, 16, 0)
FL_CHECK_TEXT_OFFSET(get_extents);
FL_CHECK_TEXT_OFFSET(get_offset);
#endif
#undef FL_CHECK_TEXT_OFFSET
#if GTK_CHECK_VERSION(4, 22, 0)
static_assert(sizeof(FlGtkAccessibleTextInterface4_22) ==
              sizeof(GtkAccessibleTextInterface));
static_assert(alignof(FlGtkAccessibleTextInterface4_22) ==
              alignof(GtkAccessibleTextInterface));
static_assert(offsetof(FlGtkAccessibleTextInterface4_22, base) == 0);
static_assert(offsetof(FlGtkAccessibleTextInterface4_22, set_caret_position) ==
              offsetof(GtkAccessibleTextInterface, set_caret_position));
static_assert(offsetof(FlGtkAccessibleTextInterface4_22, set_selection) ==
              offsetof(GtkAccessibleTextInterface, set_selection));
static_assert(
    std::is_same_v<decltype(GtkAccessibleTextInterface::set_caret_position),
                   gboolean (*)(GtkAccessibleText*, unsigned int)>);
static_assert(
    std::is_same_v<
        decltype(GtkAccessibleTextInterface::set_selection),
        gboolean (*)(GtkAccessibleText*, gsize, GtkAccessibleTextRange*)>);
#elif GTK_CHECK_VERSION(4, 16, 0)
static_assert(sizeof(FlGtkAccessibleTextInterface4_14) ==
              sizeof(GtkAccessibleTextInterface));
#else
static_assert(offsetof(FlGtkAccessibleTextInterface4_14, get_extents) ==
              sizeof(GtkAccessibleTextInterface));
#endif
#endif

// Install only on GTK 4.22+, without touching the interface on rejection.
gboolean fl_gtk_runtime_accessible_text_install_editing_callbacks(
    FlGtkAccessibleTextInterface4_14* iface,
    decltype(FlGtkAccessibleTextInterface4_22::set_caret_position) caret,
    decltype(FlGtkAccessibleTextInterface4_22::set_selection) selection);

struct FlGtkRuntimeApi {
  double (*gdk_surface_get_scale)(GdkSurface* surface);
  double (*gdk_monitor_get_scale)(GdkMonitor* monitor);
  gboolean gtk_at_least_4_10;
  gboolean gtk_at_least_4_14;
  gboolean gtk_at_least_4_18;

  void (*gtk_accessible_update_platform_state)(
      GtkAccessible* self,
      FlGtkAccessiblePlatformState state);

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
void fl_gtk_runtime_accessible_update_platform_state(
    GtkAccessible* self,
    FlGtkAccessiblePlatformState state);
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
