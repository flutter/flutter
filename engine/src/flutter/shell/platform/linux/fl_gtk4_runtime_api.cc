// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"

#if FLUTTER_LINUX_GTK4

#include <dlfcn.h>
#if defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT)
#include <mutex>
#endif

#include "flutter/shell/platform/linux/fl_linux_gtk4_debug.h"

static gboolean gtk_runtime_at_least(int major, int minor, int micro) {
  return gtk_check_version(major, minor, micro) == nullptr;
}

template <typename T>
static T lookup_symbol(const char* name) {
  return reinterpret_cast<T>(dlsym(RTLD_DEFAULT, name));
}

#if defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT)
static void log_fallback_once(const char* symbol, const char* fallback) {
  static std::mutex mutex;
  static GHashTable* warned_symbols = nullptr;

  std::lock_guard<std::mutex> lock(mutex);
  if (warned_symbols == nullptr) {
    warned_symbols = g_hash_table_new(g_str_hash, g_str_equal);
  }
  if (g_hash_table_contains(warned_symbols, symbol)) {
    return;
  }
  g_hash_table_add(warned_symbols, const_cast<char*>(symbol));
  flutter_linux_gtk4_dbg("gtk4_runtime_api", "%s unavailable, using %s", symbol,
                         fallback);
}
#endif

const FlGtkRuntimeApi* fl_gtk_runtime_api_get() {
  static const FlGtkRuntimeApi api = [] {
    FlGtkRuntimeApi result = {};
    result.gtk_at_least_4_10 = gtk_runtime_at_least(4, 10, 0);
    result.gtk_at_least_4_14 = gtk_runtime_at_least(4, 14, 0);
    result.gtk_accessible_text_get_type =
        lookup_symbol<decltype(result.gtk_accessible_text_get_type)>(
            "gtk_accessible_text_get_type");
    result.gtk_accessible_text_update_caret_position = lookup_symbol<
        decltype(result.gtk_accessible_text_update_caret_position)>(
        "gtk_accessible_text_update_caret_position");
    result.gtk_accessible_text_update_selection_bound = lookup_symbol<
        decltype(result.gtk_accessible_text_update_selection_bound)>(
        "gtk_accessible_text_update_selection_bound");
    result.gtk_accessible_text_update_contents =
        lookup_symbol<decltype(result.gtk_accessible_text_update_contents)>(
            "gtk_accessible_text_update_contents");
    result.gtk_accessible_set_accessible_parent =
        lookup_symbol<decltype(result.gtk_accessible_set_accessible_parent)>(
            "gtk_accessible_set_accessible_parent");
    result.gtk_accessible_get_first_accessible_child = lookup_symbol<
        decltype(result.gtk_accessible_get_first_accessible_child)>(
        "gtk_accessible_get_first_accessible_child");
    result.gtk_accessible_announce =
        lookup_symbol<decltype(result.gtk_accessible_announce)>(
            "gtk_accessible_announce");
    result.gdk_display_get_dmabuf_formats =
        lookup_symbol<decltype(result.gdk_display_get_dmabuf_formats)>(
            "gdk_display_get_dmabuf_formats");
    result.gdk_dmabuf_formats_ref =
        lookup_symbol<decltype(result.gdk_dmabuf_formats_ref)>(
            "gdk_dmabuf_formats_ref");
    result.gdk_dmabuf_formats_unref =
        lookup_symbol<decltype(result.gdk_dmabuf_formats_unref)>(
            "gdk_dmabuf_formats_unref");
    result.gdk_dmabuf_formats_get_n_formats =
        lookup_symbol<decltype(result.gdk_dmabuf_formats_get_n_formats)>(
            "gdk_dmabuf_formats_get_n_formats");
    result.gdk_dmabuf_formats_get_format =
        lookup_symbol<decltype(result.gdk_dmabuf_formats_get_format)>(
            "gdk_dmabuf_formats_get_format");
    result.gdk_dmabuf_formats_contains =
        lookup_symbol<decltype(result.gdk_dmabuf_formats_contains)>(
            "gdk_dmabuf_formats_contains");
    result.gdk_dmabuf_texture_builder_new =
        lookup_symbol<decltype(result.gdk_dmabuf_texture_builder_new)>(
            "gdk_dmabuf_texture_builder_new");
    result.gdk_dmabuf_texture_builder_set_display =
        lookup_symbol<decltype(result.gdk_dmabuf_texture_builder_set_display)>(
            "gdk_dmabuf_texture_builder_set_display");
    result.gdk_dmabuf_texture_builder_set_width =
        lookup_symbol<decltype(result.gdk_dmabuf_texture_builder_set_width)>(
            "gdk_dmabuf_texture_builder_set_width");
    result.gdk_dmabuf_texture_builder_set_height =
        lookup_symbol<decltype(result.gdk_dmabuf_texture_builder_set_height)>(
            "gdk_dmabuf_texture_builder_set_height");
    result.gdk_dmabuf_texture_builder_set_fourcc =
        lookup_symbol<decltype(result.gdk_dmabuf_texture_builder_set_fourcc)>(
            "gdk_dmabuf_texture_builder_set_fourcc");
    result.gdk_dmabuf_texture_builder_set_modifier =
        lookup_symbol<decltype(result.gdk_dmabuf_texture_builder_set_modifier)>(
            "gdk_dmabuf_texture_builder_set_modifier");
    result.gdk_dmabuf_texture_builder_set_premultiplied = lookup_symbol<
        decltype(result.gdk_dmabuf_texture_builder_set_premultiplied)>(
        "gdk_dmabuf_texture_builder_set_premultiplied");
    result.gdk_dmabuf_texture_builder_set_n_planes =
        lookup_symbol<decltype(result.gdk_dmabuf_texture_builder_set_n_planes)>(
            "gdk_dmabuf_texture_builder_set_n_planes");
    result.gdk_dmabuf_texture_builder_set_fd =
        lookup_symbol<decltype(result.gdk_dmabuf_texture_builder_set_fd)>(
            "gdk_dmabuf_texture_builder_set_fd");
    result.gdk_dmabuf_texture_builder_set_stride =
        lookup_symbol<decltype(result.gdk_dmabuf_texture_builder_set_stride)>(
            "gdk_dmabuf_texture_builder_set_stride");
    result.gdk_dmabuf_texture_builder_set_offset =
        lookup_symbol<decltype(result.gdk_dmabuf_texture_builder_set_offset)>(
            "gdk_dmabuf_texture_builder_set_offset");
    result.gdk_dmabuf_texture_builder_build =
        lookup_symbol<decltype(result.gdk_dmabuf_texture_builder_build)>(
            "gdk_dmabuf_texture_builder_build");
    return result;
  }();
  return &api;
}

gboolean fl_gtk_runtime_supports_dmabuf_textures() {
#if !defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT) && \
    GTK_CHECK_VERSION(4, 14, 0)
  return TRUE;
#else
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  return api->gtk_at_least_4_14 &&
         api->gdk_display_get_dmabuf_formats != nullptr &&
         api->gdk_dmabuf_formats_ref != nullptr &&
         api->gdk_dmabuf_formats_unref != nullptr &&
         api->gdk_dmabuf_formats_get_n_formats != nullptr &&
         api->gdk_dmabuf_formats_get_format != nullptr &&
         api->gdk_dmabuf_formats_contains != nullptr &&
         api->gdk_dmabuf_texture_builder_new != nullptr &&
         api->gdk_dmabuf_texture_builder_set_display != nullptr &&
         api->gdk_dmabuf_texture_builder_set_width != nullptr &&
         api->gdk_dmabuf_texture_builder_set_height != nullptr &&
         api->gdk_dmabuf_texture_builder_set_fourcc != nullptr &&
         api->gdk_dmabuf_texture_builder_set_modifier != nullptr &&
         api->gdk_dmabuf_texture_builder_set_premultiplied != nullptr &&
         api->gdk_dmabuf_texture_builder_set_n_planes != nullptr &&
         api->gdk_dmabuf_texture_builder_set_fd != nullptr &&
         api->gdk_dmabuf_texture_builder_set_stride != nullptr &&
         api->gdk_dmabuf_texture_builder_set_offset != nullptr &&
         api->gdk_dmabuf_texture_builder_build != nullptr;
#endif
}

gboolean fl_gtk_runtime_dmabuf_format_supported(GdkDisplay* display,
                                                guint32 fourcc,
                                                guint64 modifier) {
  g_return_val_if_fail(GDK_IS_DISPLAY(display), FALSE);

#if !defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT) && \
    GTK_CHECK_VERSION(4, 14, 0)
  GdkDmabufFormats* formats = gdk_display_get_dmabuf_formats(display);
  return formats != nullptr &&
         gdk_dmabuf_formats_contains(formats, fourcc, modifier);
#else
  if (!fl_gtk_runtime_supports_dmabuf_textures()) {
    return FALSE;
  }
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  FlGdkDmabufFormats* formats = api->gdk_display_get_dmabuf_formats(display);
  return formats != nullptr &&
         api->gdk_dmabuf_formats_contains(formats, fourcc, modifier);
#endif
}

void fl_gtk_runtime_for_each_dmabuf_format(GdkDisplay* display,
                                           FlGtk4DmabufFormatCallback callback,
                                           gpointer user_data) {
  g_return_if_fail(GDK_IS_DISPLAY(display));
  g_return_if_fail(callback != nullptr);

  if (!fl_gtk_runtime_supports_dmabuf_textures()) {
    return;
  }

#if !defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT) && \
    GTK_CHECK_VERSION(4, 14, 0)
  GdkDmabufFormats* formats = gdk_display_get_dmabuf_formats(display);
  if (formats == nullptr) {
    return;
  }
  const gsize format_count = gdk_dmabuf_formats_get_n_formats(formats);
  for (gsize i = 0; i < format_count; ++i) {
    guint32 fourcc = 0;
    guint64 modifier = 0;
    gdk_dmabuf_formats_get_format(formats, i, &fourcc, &modifier);
    callback(fourcc, modifier, user_data);
  }
#else
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  FlGdkDmabufFormats* formats = api->gdk_display_get_dmabuf_formats(display);
  if (formats == nullptr) {
    return;
  }
  const gsize format_count = api->gdk_dmabuf_formats_get_n_formats(formats);
  for (gsize i = 0; i < format_count; ++i) {
    guint32 fourcc = 0;
    guint64 modifier = 0;
    api->gdk_dmabuf_formats_get_format(formats, i, &fourcc, &modifier);
    callback(fourcc, modifier, user_data);
  }
#endif
}

GdkTexture* fl_gtk_runtime_build_dmabuf_texture(
    GdkDisplay* display,
    const FlGtk4DmabufDescriptor* descriptor,
    GDestroyNotify destroy,
    gpointer data,
    GError** error) {
  g_return_val_if_fail(GDK_IS_DISPLAY(display), nullptr);
  g_return_val_if_fail(descriptor != nullptr, nullptr);
  g_return_val_if_fail(descriptor->n_planes > 0, nullptr);
  g_return_val_if_fail(descriptor->n_planes <= kFlGtk4DmabufMaxPlanes, nullptr);

#if !defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT) && \
    GTK_CHECK_VERSION(4, 14, 0)
  g_autoptr(GdkDmabufTextureBuilder) builder = gdk_dmabuf_texture_builder_new();
#define FL_DMABUF_CALL(name, ...) name(builder, __VA_ARGS__)
#else
  if (!fl_gtk_runtime_supports_dmabuf_textures()) {
    return nullptr;
  }
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  FlGdkDmabufTextureBuilder* builder = api->gdk_dmabuf_texture_builder_new();
#define FL_DMABUF_CALL(name, ...) api->name(builder, __VA_ARGS__)
#endif

  FL_DMABUF_CALL(gdk_dmabuf_texture_builder_set_display, display);
  FL_DMABUF_CALL(gdk_dmabuf_texture_builder_set_width, descriptor->width);
  FL_DMABUF_CALL(gdk_dmabuf_texture_builder_set_height, descriptor->height);
  FL_DMABUF_CALL(gdk_dmabuf_texture_builder_set_fourcc, descriptor->fourcc);
  FL_DMABUF_CALL(gdk_dmabuf_texture_builder_set_modifier, descriptor->modifier);
  FL_DMABUF_CALL(gdk_dmabuf_texture_builder_set_premultiplied,
                 descriptor->premultiplied);
  FL_DMABUF_CALL(gdk_dmabuf_texture_builder_set_n_planes, descriptor->n_planes);
  for (guint i = 0; i < descriptor->n_planes; ++i) {
    FL_DMABUF_CALL(gdk_dmabuf_texture_builder_set_fd, i,
                   descriptor->planes[i].fd);
    FL_DMABUF_CALL(gdk_dmabuf_texture_builder_set_stride, i,
                   descriptor->planes[i].stride);
    FL_DMABUF_CALL(gdk_dmabuf_texture_builder_set_offset, i,
                   descriptor->planes[i].offset);
  }

#if !defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT) && \
    GTK_CHECK_VERSION(4, 14, 0)
  return gdk_dmabuf_texture_builder_build(builder, destroy, data, error);
#else
  GdkTexture* texture =
      api->gdk_dmabuf_texture_builder_build(builder, destroy, data, error);
  g_object_unref(builder);
  return texture;
#endif
#undef FL_DMABUF_CALL
}

gboolean fl_gtk_runtime_supports_native_accessibility_tree() {
#if defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT)
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  return api->gtk_at_least_4_10 &&
         api->gtk_accessible_set_accessible_parent != nullptr &&
         api->gtk_accessible_get_first_accessible_child != nullptr;
#else
  return GTK_CHECK_VERSION(4, 10, 0);
#endif
}

gboolean fl_gtk_runtime_supports_native_accessibility_text() {
#if !defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT) && \
    GTK_CHECK_VERSION(4, 14, 0)
  return TRUE;
#else
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  return api->gtk_at_least_4_14 &&
         api->gtk_accessible_text_get_type != nullptr &&
         api->gtk_accessible_text_update_caret_position != nullptr &&
         api->gtk_accessible_text_update_selection_bound != nullptr &&
         api->gtk_accessible_text_update_contents != nullptr;
#endif
}

GType fl_gtk_runtime_accessible_text_get_type() {
#if !defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT) && \
    GTK_CHECK_VERSION(4, 14, 0)
  return gtk_accessible_text_get_type();
#else
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  return fl_gtk_runtime_supports_native_accessibility_text()
             ? api->gtk_accessible_text_get_type()
             : G_TYPE_INVALID;
#endif
}

void fl_gtk_runtime_accessible_text_update_caret_position(GtkAccessible* self) {
#if !defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT) && \
    GTK_CHECK_VERSION(4, 14, 0)
  gtk_accessible_text_update_caret_position(
      reinterpret_cast<GtkAccessibleText*>(self));
#else
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  if (fl_gtk_runtime_supports_native_accessibility_text()) {
    api->gtk_accessible_text_update_caret_position(self);
    return;
  }
  log_fallback_once("gtk_accessible_text_update_caret_position",
                    "no-op compatible path");
#endif
}

void fl_gtk_runtime_accessible_text_update_selection_bound(
    GtkAccessible* self) {
#if !defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT) && \
    GTK_CHECK_VERSION(4, 14, 0)
  gtk_accessible_text_update_selection_bound(
      reinterpret_cast<GtkAccessibleText*>(self));
#else
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  if (fl_gtk_runtime_supports_native_accessibility_text()) {
    api->gtk_accessible_text_update_selection_bound(self);
    return;
  }
  log_fallback_once("gtk_accessible_text_update_selection_bound",
                    "no-op compatible path");
#endif
}

void fl_gtk_runtime_accessible_text_update_contents(GtkAccessible* self,
                                                    gint change,
                                                    unsigned int start,
                                                    unsigned int end) {
#if !defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT) && \
    GTK_CHECK_VERSION(4, 14, 0)
  gtk_accessible_text_update_contents(
      reinterpret_cast<GtkAccessibleText*>(self),
      static_cast<GtkAccessibleTextContentChange>(change), start, end);
#else
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  if (fl_gtk_runtime_supports_native_accessibility_text()) {
    api->gtk_accessible_text_update_contents(self, change, start, end);
    return;
  }
  log_fallback_once("gtk_accessible_text_update_contents",
                    "no-op compatible path");
#endif
}

GtkAccessible* fl_gtk_runtime_accessible_get_first_accessible_child(
    GtkAccessible* self) {
#if defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT)
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  if (api->gtk_at_least_4_10 &&
      api->gtk_accessible_get_first_accessible_child != nullptr) {
    return api->gtk_accessible_get_first_accessible_child(self);
  }
  log_fallback_once("gtk_accessible_get_first_accessible_child",
                    "no-op compatible path");
  (void)self;
  return nullptr;
#else
#if GTK_CHECK_VERSION(4, 10, 0)
  return gtk_accessible_get_first_accessible_child(self);
#else
  (void)self;
  return nullptr;
#endif
#endif
}

void fl_gtk_runtime_accessible_set_accessible_parent(
    GtkAccessible* self,
    GtkAccessible* parent,
    GtkAccessible* next_sibling) {
#if defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT)
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  if (api->gtk_at_least_4_10 &&
      api->gtk_accessible_set_accessible_parent != nullptr) {
    api->gtk_accessible_set_accessible_parent(self, parent, next_sibling);
    return;
  }
  log_fallback_once("gtk_accessible_set_accessible_parent",
                    "no-op compatible path");
#else
#if GTK_CHECK_VERSION(4, 10, 0)
  gtk_accessible_set_accessible_parent(self, parent, next_sibling);
#else
  (void)self;
  (void)parent;
  (void)next_sibling;
#endif
#endif
}

void fl_gtk_runtime_accessible_announce(GtkAccessible* self,
                                        const char* message,
                                        gint priority) {
#if defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT)
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  if (api->gtk_at_least_4_14 && api->gtk_accessible_announce != nullptr) {
    api->gtk_accessible_announce(
        self, message,
        static_cast<FlGtkAccessibleAnnouncementPriority>(priority));
    return;
  }
  log_fallback_once("gtk_accessible_announce", "no-op compatible path");
  (void)self;
  (void)message;
  (void)priority;
#else
#if GTK_CHECK_VERSION(4, 14, 0)
  gtk_accessible_announce(
      self, message, static_cast<GtkAccessibleAnnouncementPriority>(priority));
#else
  (void)self;
  (void)message;
  (void)priority;
#endif
#endif
}

#endif  // FLUTTER_LINUX_GTK4
