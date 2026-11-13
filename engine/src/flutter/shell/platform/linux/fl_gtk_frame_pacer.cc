// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_gtk_frame_pacer.h"

#include <string>

#include "flutter/fml/trace_event.h"
#include "flutter/shell/platform/linux/fl_vsync_timing.h"

struct _FlGtkFramePacer {
  GObject parent_instance;
  GThread* thread;
  // Registration may run on an engine worker; delivery and stop run on GTK.
  GMutex mutex;
  GQueue requests;
  gboolean stopped;
};

G_DEFINE_TYPE(FlGtkFramePacer, fl_gtk_frame_pacer, G_TYPE_OBJECT)

struct VsyncRequest {
  gatomicrefcount refs;
  GList link;
  FlGtkFramePacer* pacer;
  GtkWidget* widget;
  GtkWidget* widget_lease;
  intptr_t baton;
  FlGtkFramePacerCallback callback;
  gpointer user_data;
  GDestroyNotify destroy_notify;
  guint dispatch_source_id;
  guint timer_source_id;
  guint tick_callback_id;
  guint watchdog_source_id;
  gulong unmap_handler_id;
  gboolean delivered;
};

static VsyncRequest* request_ref(VsyncRequest* request) {
  g_atomic_ref_count_inc(&request->refs);
  return request;
}

static void request_unref(gpointer data) {
  auto* request = static_cast<VsyncRequest*>(data);
  if (!g_atomic_ref_count_dec(&request->refs)) {
    return;
  }
  g_assert(request->delivered);
  if (request->widget != nullptr && request->unmap_handler_id != 0) {
    g_signal_handler_disconnect(request->widget, request->unmap_handler_id);
  }
  {
    g_autoptr(GMutexLocker) lock = g_mutex_locker_new(&request->pacer->mutex);
    g_queue_unlink(&request->pacer->requests, &request->link);
  }
  if (request->widget != nullptr) {
    g_object_remove_weak_pointer(G_OBJECT(request->widget),
                                 reinterpret_cast<gpointer*>(&request->widget));
  }
  g_assert(request->widget_lease == nullptr);
  g_object_unref(request->pacer);
  g_free(request);
}

G_DEFINE_AUTOPTR_CLEANUP_FUNC(VsyncRequest, request_unref)

static void complete(VsyncRequest* request, uint64_t start, uint64_t target) {
  // Delivery may synchronously stop the pacer, including removing this tick.
  g_autoptr(VsyncRequest) retained = request_ref(request);
  if (request->delivered) {
    return;
  }
  request->delivered = TRUE;
  g_clear_handle_id(&request->watchdog_source_id, g_source_remove);
  gpointer user_data = request->user_data;
  GDestroyNotify destroy_notify = request->destroy_notify;
  request->user_data = nullptr;
  request->destroy_notify = nullptr;
  request->callback(request->baton, start, target, user_data);
  // The view itself can own an engine. Retained idle ticks must not keep either
  // the recipient or the widget alive after delivery. Widget destruction
  // removes its tick; request references protect reentrant destruction in this
  // callback.
  g_clear_object(&request->widget_lease);
  if (destroy_notify != nullptr) {
    destroy_notify(user_data);
  }
}

static void complete_on_wall_time(VsyncRequest* request) {
  const uint64_t start = static_cast<uint64_t>(g_get_monotonic_time()) * 1000;
  complete(request, start, start + 16666667);
}

static void remove_tick(VsyncRequest* request) {
  const guint id = request->tick_callback_id;
  request->tick_callback_id = 0;
  if (id != 0) {
    gtk_widget_remove_tick_callback(request->widget, id);
  }
}

static void tick_destroy(gpointer data) {
  auto* request = static_cast<VsyncRequest*>(data);
  request->tick_callback_id = 0;
  complete_on_wall_time(request);
  request_unref(request);
}

static gboolean frame_tick(GtkWidget*, GdkFrameClock* clock, gpointer data) {
  g_autoptr(VsyncRequest) request =
      request_ref(static_cast<VsyncRequest*>(data));
  if (request->delivered) {
    return G_SOURCE_REMOVE;
  }
  const FlVsyncTiming timing = fl_vsync_timing_for_clock(clock);
  TRACE_EVENT_INSTANT2(
      "flutter", "LinuxVsyncTick", "baton",
      std::to_string(request->baton).c_str(), "frame_counter",
      std::to_string(gdk_frame_clock_get_frame_counter(clock)).c_str());
  TRACE_EVENT_INSTANT2("flutter", "LinuxVsyncTiming", "frame_start_ns",
                       std::to_string(timing.frame_start_ns).c_str(),
                       "frame_target_ns",
                       std::to_string(timing.frame_target_ns).c_str());
  TRACE_EVENT_INSTANT1("flutter", "LinuxVsyncRefresh", "interval_us",
                       std::to_string(timing.refresh_interval_us).c_str());
  complete(request, timing.frame_start_ns, timing.frame_target_ns);
  // One idle tick preserves animation-clock phase between consecutive requests.
  return G_SOURCE_CONTINUE;
}

static gboolean timeout(gpointer data) {
  g_autoptr(VsyncRequest) request =
      request_ref(static_cast<VsyncRequest*>(data));
  request->timer_source_id = 0;
  complete_on_wall_time(request);
  return G_SOURCE_REMOVE;
}

static gboolean watchdog(gpointer data) {
  g_autoptr(VsyncRequest) request =
      request_ref(static_cast<VsyncRequest*>(data));
  request->watchdog_source_id = 0;
  TRACE_EVENT_INSTANT1("flutter", "LinuxVsyncClockTimeout", "baton",
                       std::to_string(request->baton).c_str());
  remove_tick(request);
  return G_SOURCE_REMOVE;
}

static void unmap(GtkWidget*, gpointer data) {
  g_autoptr(VsyncRequest) request =
      request_ref(static_cast<VsyncRequest*>(data));
  complete_on_wall_time(request);
  remove_tick(request);
}

static gboolean schedule(gpointer data) {
  g_autoptr(VsyncRequest) request =
      request_ref(static_cast<VsyncRequest*>(data));
  {
    g_autoptr(GMutexLocker) lock = g_mutex_locker_new(&request->pacer->mutex);
    request->dispatch_source_id = 0;
  }
  if (request->widget != nullptr && gtk_widget_get_mapped(request->widget)) {
    request->unmap_handler_id =
        g_signal_connect(request->widget, "unmap", G_CALLBACK(unmap), request);
    request->tick_callback_id = gtk_widget_add_tick_callback(
        request->widget, frame_tick, request_ref(request), tick_destroy);
    GdkFrameClock* clock = gtk_widget_get_frame_clock(request->widget);
    const gint64 interval =
        clock ? fl_vsync_timing_for_clock(clock).refresh_interval_us : 16667;
    const guint timeout_ms =
        static_cast<guint>(MAX((interval * 4 + 999) / 1000, 20));
    request->watchdog_source_id =
        g_timeout_add_full(G_PRIORITY_HIGH, timeout_ms, watchdog,
                           request_ref(request), request_unref);
  } else {
    request->timer_source_id = g_timeout_add_full(
        G_PRIORITY_HIGH, 16, timeout, request_ref(request), request_unref);
  }
  return G_SOURCE_REMOVE;
}

static void fl_gtk_frame_pacer_finalize(GObject* object) {
  auto* self = FL_GTK_FRAME_PACER(object);
  g_assert(g_queue_is_empty(&self->requests));
  g_mutex_clear(&self->mutex);
  G_OBJECT_CLASS(fl_gtk_frame_pacer_parent_class)->finalize(object);
}

static void fl_gtk_frame_pacer_class_init(FlGtkFramePacerClass* klass) {
  G_OBJECT_CLASS(klass)->finalize = fl_gtk_frame_pacer_finalize;
}

static void fl_gtk_frame_pacer_init(FlGtkFramePacer* self) {
  self->thread = g_thread_self();
  g_mutex_init(&self->mutex);
  g_queue_init(&self->requests);
}

FlGtkFramePacer* fl_gtk_frame_pacer_new() {
  return FL_GTK_FRAME_PACER(
      g_object_new(fl_gtk_frame_pacer_get_type(), nullptr));
}

void fl_gtk_frame_pacer_request(FlGtkFramePacer* self,
                                GtkWidget* widget,
                                intptr_t baton,
                                FlGtkFramePacerCallback callback,
                                gpointer user_data,
                                GDestroyNotify destroy_notify) {
  g_return_if_fail(FL_IS_GTK_FRAME_PACER(self));
  g_return_if_fail(callback != nullptr);
  auto* request = g_new0(VsyncRequest, 1);
  g_atomic_ref_count_init(&request->refs);
  request->link.data = request;
  request->pacer = FL_GTK_FRAME_PACER(g_object_ref(self));
  request->widget = widget;
  request->widget_lease =
      widget == nullptr ? nullptr : GTK_WIDGET(g_object_ref(widget));
  if (widget != nullptr) {
    g_object_add_weak_pointer(G_OBJECT(widget),
                              reinterpret_cast<gpointer*>(&request->widget));
  }
  request->baton = baton;
  request->callback = callback;
  request->user_data = user_data;
  request->destroy_notify = destroy_notify;
  const bool direct = self->thread == g_thread_self() &&
                      g_main_context_is_owner(g_main_context_default());
  {
    g_autoptr(GMutexLocker) lock = g_mutex_locker_new(&self->mutex);
    // The owner must stop issuing requests before stopping the pacer.
    g_assert(!self->stopped);
    g_queue_push_tail_link(&self->requests, &request->link);
    if (!direct) {
      GSource* source = g_idle_source_new();
      g_source_set_priority(source, G_PRIORITY_HIGH);
      g_source_set_callback(source, schedule, request, request_unref);
      request->dispatch_source_id =
          g_source_attach(source, g_main_context_default());
      g_source_unref(source);
    }
  }
  if (direct) {
    schedule(request);
    request_unref(request);
  }
}

void fl_gtk_frame_pacer_stop(FlGtkFramePacer* self) {
  g_return_if_fail(self->thread == g_thread_self());
  g_autoptr(FlGtkFramePacer) retained = FL_GTK_FRAME_PACER(g_object_ref(self));
  g_autoptr(GPtrArray) requests = g_ptr_array_new_with_free_func(request_unref);
  {
    g_autoptr(GMutexLocker) lock = g_mutex_locker_new(&self->mutex);
    self->stopped = TRUE;
    for (GList* link = self->requests.head; link != nullptr;
         link = link->next) {
      g_ptr_array_add(requests,
                      request_ref(static_cast<VsyncRequest*>(link->data)));
    }
  }
  for (guint i = 0; i < requests->len; i++) {
    auto* request = static_cast<VsyncRequest*>(g_ptr_array_index(requests, i));
    complete_on_wall_time(request);
    remove_tick(request);
    g_clear_handle_id(&request->timer_source_id, g_source_remove);
    g_clear_handle_id(&request->dispatch_source_id, g_source_remove);
  }
}
