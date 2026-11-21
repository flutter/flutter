// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_presentation_tracker.h"

#include <wayland-client.h>

#include "flutter/shell/platform/linux/fl_engine_private.h"

struct _FlPresentationTracker {
  GObject parent_instance;

  // Engine to report samples to. Weak, the engine outlives the renderer but
  // shutdown must not be blocked by pending callbacks.
  GWeakRef engine;

  // FALSE while the subsurface is synchronized with its parent or after the
  // owner asked to pause feedback. Accessed from the raster and GTK threads.
  gint enabled;

  // Guards @pending, which is written by the raster thread and read by the GTK
  // thread.
  GMutex mutex;

  // Frame callbacks that have been requested but not completed. Keys are
  // struct wl_callback*, values are gint64 commit times in microseconds.
  GHashTable* pending;
};

G_DEFINE_TYPE(FlPresentationTracker, fl_presentation_tracker, G_TYPE_OBJECT)

// Allows distributions and users to turn the phase controller off for
// debugging without rebuilding the engine.
static gboolean presentation_phase_allowed() {
  static gsize initialized = 0;
  static gboolean allowed = TRUE;
  if (g_once_init_enter(&initialized)) {
    const gchar* value = g_getenv("FLUTTER_LINUX_PRESENTATION_PHASE");
    allowed = value == nullptr || g_strcmp0(value, "0") != 0;
    g_once_init_leave(&initialized, 1);
  }
  return allowed;
}

static gint64* pending_commit_time_new(gint64 commit_time_us) {
  gint64* value = g_new(gint64, 1);
  *value = commit_time_us;
  return value;
}

static void frame_done_cb(void* data,
                          struct wl_callback* callback,
                          uint32_t callback_data) {
  FlPresentationTracker* self = FL_PRESENTATION_TRACKER(data);

  gint64 commit_time_us = 0;
  g_mutex_lock(&self->mutex);
  gint64* value =
      static_cast<gint64*>(g_hash_table_lookup(self->pending, callback));
  if (value != nullptr) {
    commit_time_us = *value;
  }
  g_hash_table_remove(self->pending, callback);
  g_mutex_unlock(&self->mutex);

  if (commit_time_us != 0 && g_atomic_int_get(&self->enabled)) {
    // The core protocol does not specify the base of @callback_data, so the
    // arrival time is the only value that can be compared with the engine's
    // monotonic clock. The compositor repaint lead and the main loop dispatch
    // delay are included, but they are common to every frame.
    const gint64 latency_us = g_get_monotonic_time() - commit_time_us;
    if (latency_us > 0) {
      g_autoptr(FlEngine) engine = FL_ENGINE(g_weak_ref_get(&self->engine));
      if (engine != nullptr) {
        fl_engine_add_presentation_sample(engine, latency_us);
      }
    }
  }

  wl_callback_destroy(callback);
}

static const struct wl_callback_listener kFrameListener = {
    .done = frame_done_cb,
};

static void fl_presentation_tracker_dispose(GObject* object) {
  FlPresentationTracker* self = FL_PRESENTATION_TRACKER(object);

  // The owner normally resets before dropping the last reference. Be
  // defensive and destroy any remaining callbacks; the table frees the commit
  // times below.
  fl_presentation_tracker_reset(self);
  g_weak_ref_clear(&self->engine);
  g_clear_pointer(&self->pending, g_hash_table_unref);
  g_mutex_clear(&self->mutex);

  G_OBJECT_CLASS(fl_presentation_tracker_parent_class)->dispose(object);
}

static void fl_presentation_tracker_class_init(
    FlPresentationTrackerClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_presentation_tracker_dispose;
}

static void fl_presentation_tracker_init(FlPresentationTracker* self) {
  g_weak_ref_init(&self->engine, nullptr);
  g_mutex_init(&self->mutex);
  self->pending =
      g_hash_table_new_full(g_direct_hash, g_direct_equal, nullptr, g_free);
  g_atomic_int_set(&self->enabled, presentation_phase_allowed());
}

FlPresentationTracker* fl_presentation_tracker_new(FlEngine* engine) {
  g_return_val_if_fail(FL_IS_ENGINE(engine), nullptr);

  // wl_surface.frame is part of wl_surface version 1, not an optional global,
  // so there is nothing to probe at startup. The renderer only creates a
  // tracker when it has a Wayland subsurface; from then on support is assumed
  // for the lifetime of that surface. A compositor that fails to implement a
  // core request is broken, and its callbacks simply never arrive.

  FlPresentationTracker* self = FL_PRESENTATION_TRACKER(
      g_object_new(fl_presentation_tracker_get_type(), nullptr));
  g_weak_ref_set(&self->engine, engine);
  return self;
}

void fl_presentation_tracker_record_commit(FlPresentationTracker* self,
                                           struct wl_surface* surface) {
  g_return_if_fail(FL_IS_PRESENTATION_TRACKER(self));

  if (!g_atomic_int_get(&self->enabled) || surface == nullptr) {
    return;
  }

  // Frame callbacks are one-shot. This is a memory bound for a compositor that
  // stops answering, not a support check; dropping a request is harmless.
  g_mutex_lock(&self->mutex);
  if (g_hash_table_size(self->pending) >= 256) {
    g_mutex_unlock(&self->mutex);
    return;
  }
  g_mutex_unlock(&self->mutex);

  struct wl_callback* callback = wl_surface_frame(surface);
  if (callback == nullptr) {
    return;
  }

  // wl_surface_frame() is a request; the callback can only arrive after the
  // commit that follows, which is what the caller is about to perform. Insert
  // the commit time before adding the listener so the event can always find it.
  g_mutex_lock(&self->mutex);
  g_hash_table_insert(self->pending, callback,
                      pending_commit_time_new(g_get_monotonic_time()));
  g_mutex_unlock(&self->mutex);

  if (wl_callback_add_listener(callback, &kFrameListener, self) != 0) {
    g_mutex_lock(&self->mutex);
    g_hash_table_remove(self->pending, callback);
    g_mutex_unlock(&self->mutex);
    wl_callback_destroy(callback);
  }
}

void fl_presentation_tracker_set_enabled(FlPresentationTracker* self,
                                         gboolean enable) {
  g_return_if_fail(FL_IS_PRESENTATION_TRACKER(self));

  enable = enable && presentation_phase_allowed();
  if (enable == g_atomic_int_get(&self->enabled)) {
    return;
  }
  g_atomic_int_set(&self->enabled, enable);
  if (!enable) {
    fl_presentation_tracker_reset(self);
  }
}

void fl_presentation_tracker_reset(FlPresentationTracker* self) {
  g_return_if_fail(FL_IS_PRESENTATION_TRACKER(self));

  g_mutex_lock(&self->mutex);
  GHashTableIter iter;
  gpointer key;
  gpointer value;
  g_hash_table_iter_init(&iter, self->pending);
  while (g_hash_table_iter_next(&iter, &key, &value)) {
    wl_callback_destroy(static_cast<struct wl_callback*>(key));
  }
  g_hash_table_remove_all(self->pending);
  g_mutex_unlock(&self->mutex);
}
