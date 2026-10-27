// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_compositor_vulkan.h"

#include <cmath>

#include "flutter/shell/platform/linux/fl_vulkan_manager.h"

struct _FlCompositorVulkan {
  FlCompositor parent_instance;
  FlTaskRunner* task_runner;
  GMutex frame_mutex;
  GBytes* pixels;
  size_t width;
  size_t height;
};

G_DEFINE_TYPE(FlCompositorVulkan,
              fl_compositor_vulkan,
              fl_compositor_get_type())

static gboolean present_layers(FlCompositor* compositor,
                               const FlutterLayer** layers,
                               size_t count) {
  auto* self = FL_COMPOSITOR_VULKAN(compositor);
  size_t width = 0;
  size_t height = 0;
  for (size_t i = 0; i < count; i++) {
    const auto* layer = layers[i];
    if (layer->type != kFlutterLayerContentTypeBackingStore ||
        layer->backing_store->type != kFlutterBackingStoreTypeVulkan ||
        !std::isfinite(layer->offset.x) || !std::isfinite(layer->offset.y) ||
        !std::isfinite(layer->size.width) ||
        !std::isfinite(layer->size.height) || layer->offset.x < 0 ||
        layer->offset.y < 0 || layer->size.width < 1 ||
        layer->size.height < 1 ||
        layer->offset.x + layer->size.width > INT32_MAX / 4 ||
        layer->offset.y + layer->size.height > INT32_MAX / 4) {
      g_warning("Unsupported Vulkan compositor layer");
      return FALSE;
    }
    width = MAX(width,
                static_cast<size_t>(ceil(layer->offset.x + layer->size.width)));
    height =
        MAX(height,
            static_cast<size_t>(ceil(layer->offset.y + layer->size.height)));
  }
  if (count == 0) {
    g_autoptr(GMutexLocker) lock = g_mutex_locker_new(&self->frame_mutex);
    g_clear_pointer(&self->pixels, g_bytes_unref);
    if (self->width > 0 && self->height > 0) {
      const size_t length = self->width * self->height * 4;
      self->pixels = g_bytes_new_take(g_malloc0(length), length);
    }
    fl_task_runner_stop_wait(self->task_runner);
    return TRUE;
  }
  // Composite immutable readbacks in layer order. Cairo's native ARGB32 layout
  // differs from Vulkan RGBA8; convert explicitly rather than assuming
  // endianness.
  cairo_surface_t* surface =
      cairo_image_surface_create(CAIRO_FORMAT_ARGB32, width, height);
  cairo_t* cr = cairo_create(surface);
  bool success = cairo_surface_status(surface) == CAIRO_STATUS_SUCCESS;
  for (size_t i = 0; success && i < count; i++) {
    size_t image_width = 0, image_height = 0;
    g_autoptr(GError) error = nullptr;
    g_autoptr(GBytes) rgba = fl_vulkan_backing_store_read_pixels(
        layers[i]->backing_store, &image_width, &image_height, &error);
    if (rgba == nullptr) {
      g_warning("Vulkan readback failed: %s", error->message);
      success = false;
      break;
    }
    const auto* src =
        static_cast<const uint8_t*>(g_bytes_get_data(rgba, nullptr));
    cairo_surface_t* image = cairo_image_surface_create(
        CAIRO_FORMAT_ARGB32, image_width, image_height);
    if (cairo_surface_status(image) != CAIRO_STATUS_SUCCESS) {
      cairo_surface_destroy(image);
      success = false;
      break;
    }
    auto* dst =
        reinterpret_cast<uint32_t*>(cairo_image_surface_get_data(image));
    size_t stride = cairo_image_surface_get_stride(image) / sizeof(uint32_t);
    for (size_t y = 0; y < image_height; y++) {
      for (size_t x = 0; x < image_width; x++) {
        const auto* p = src + (y * image_width + x) * 4;
        dst[y * stride + x] = (uint32_t(p[3]) << 24) | (uint32_t(p[0]) << 16) |
                              (uint32_t(p[1]) << 8) | p[2];
      }
    }
    cairo_surface_mark_dirty(image);
    cairo_save(cr);
    cairo_rectangle(cr, layers[i]->offset.x, layers[i]->offset.y,
                    layers[i]->size.width, layers[i]->size.height);
    cairo_clip(cr);
    cairo_set_source_surface(cr, image, layers[i]->offset.x,
                             layers[i]->offset.y);
    cairo_paint(cr);
    cairo_restore(cr);
    cairo_surface_destroy(image);
  }
  success = success && cairo_status(cr) == CAIRO_STATUS_SUCCESS;
  cairo_destroy(cr);
  if (success) {
    cairo_surface_flush(surface);
    g_autoptr(GBytes) pixels =
        g_bytes_new(cairo_image_surface_get_data(surface),
                    cairo_image_surface_get_stride(surface) * height);
    g_autoptr(GMutexLocker) lock = g_mutex_locker_new(&self->frame_mutex);
    g_clear_pointer(&self->pixels, g_bytes_unref);
    self->pixels = g_bytes_ref(pixels);
    self->width = width;
    self->height = height;
    fl_task_runner_stop_wait(self->task_runner);
  }
  cairo_surface_destroy(surface);
  return success;
}

static void get_frame_size(FlCompositor* compositor,
                           size_t* width,
                           size_t* height) {
  auto* self = FL_COMPOSITOR_VULKAN(compositor);
  g_autoptr(GMutexLocker) lock = g_mutex_locker_new(&self->frame_mutex);
  if (width)
    *width = self->width;
  if (height)
    *height = self->height;
}

static GdkTexture* acquire_texture(FlCompositor* compositor,
                                   FlGdkSurface*,
                                   GdkGLContext*,
                                   size_t width,
                                   size_t height,
                                   gboolean wait_for_frame) {
  auto* self = FL_COMPOSITOR_VULKAN(compositor);
  g_autoptr(GMutexLocker) lock = g_mutex_locker_new(&self->frame_mutex);
  if (wait_for_frame) {
    const gint64 deadline =
        g_get_monotonic_time() + kCompositorRenderTimeoutMicroseconds;
    while ((self->width != width || self->height != height) &&
           g_get_monotonic_time() < deadline) {
      g_mutex_unlock(&self->frame_mutex);
      fl_task_runner_wait(self->task_runner, deadline);
      g_mutex_lock(&self->frame_mutex);
    }
  }
  if (self->pixels == nullptr)
    return nullptr;
  return gdk_memory_texture_new(self->width, self->height, GDK_MEMORY_DEFAULT,
                                self->pixels, self->width * 4);
}

static void dispose(GObject* object) {
  auto* self = FL_COMPOSITOR_VULKAN(object);
  g_clear_object(&self->task_runner);
  g_clear_pointer(&self->pixels, g_bytes_unref);
  G_OBJECT_CLASS(fl_compositor_vulkan_parent_class)->dispose(object);
}

static void finalize(GObject* object) {
  g_mutex_clear(&FL_COMPOSITOR_VULKAN(object)->frame_mutex);
  G_OBJECT_CLASS(fl_compositor_vulkan_parent_class)->finalize(object);
}

static void fl_compositor_vulkan_class_init(FlCompositorVulkanClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = dispose;
  G_OBJECT_CLASS(klass)->finalize = finalize;
  FL_COMPOSITOR_CLASS(klass)->present_layers = present_layers;
  FL_COMPOSITOR_CLASS(klass)->get_frame_size = get_frame_size;
  FL_COMPOSITOR_CLASS(klass)->acquire_texture = acquire_texture;
}

static void fl_compositor_vulkan_init(FlCompositorVulkan* self) {
  g_mutex_init(&self->frame_mutex);
}

FlCompositorVulkan* fl_compositor_vulkan_new(FlTaskRunner* task_runner) {
  auto* self = FL_COMPOSITOR_VULKAN(
      g_object_new(fl_compositor_vulkan_get_type(), nullptr));
  self->task_runner = FL_TASK_RUNNER(g_object_ref(task_runner));
  return self;
}
