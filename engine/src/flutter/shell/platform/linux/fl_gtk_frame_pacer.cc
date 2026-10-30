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
};

G_DEFINE_TYPE(FlGtkFramePacer, fl_gtk_frame_pacer, G_TYPE_OBJECT)

struct VsyncRequest {
  FlGtkFramePacer* pacer;
  GtkWidget* widget;
  intptr_t baton;
  FlGtkFramePacerCallback callback;
  gpointer user_data;
  GDestroyNotify destroy_notify;
  guint tick_callback_id;
  guint watchdog_source_id;
  gulong unmap_handler_id;
  gboolean delivered;
};

static void fl_gtk_frame_pacer_complete_vsync(VsyncRequest* request,
                                              uint64_t frame_start_ns,
                                              uint64_t frame_target_ns) {
  if (request->delivered) {
    return;
  }
  request->delivered = TRUE;
  g_clear_handle_id(&request->watchdog_source_id, g_source_remove);
  request->callback(request->baton, frame_start_ns, frame_target_ns,
                    request->user_data);
}

static gboolean fl_gtk_frame_pacer_frame_tick(GtkWidget* widget,
                                              GdkFrameClock* frame_clock,
                                              gpointer user_data) {
  auto* request = static_cast<VsyncRequest*>(user_data);
  if (request->delivered) {
    return G_SOURCE_REMOVE;
  }
  const FlVsyncTiming timing = fl_vsync_timing_for_clock(frame_clock);
  TRACE_EVENT_INSTANT2(
      "flutter", "LinuxVsyncTick", "baton",
      std::to_string(request->baton).c_str(), "frame_counter",
      std::to_string(gdk_frame_clock_get_frame_counter(frame_clock)).c_str());
  TRACE_EVENT_INSTANT2("flutter", "LinuxVsyncTiming", "frame_start_ns",
                       std::to_string(timing.frame_start_ns).c_str(),
                       "frame_target_ns",
                       std::to_string(timing.frame_target_ns).c_str());
  TRACE_EVENT_INSTANT1("flutter", "LinuxVsyncRefresh", "interval_us",
                       std::to_string(timing.refresh_interval_us).c_str());
  fl_gtk_frame_pacer_complete_vsync(request, timing.frame_start_ns,
                                    timing.frame_target_ns);
  // Keep GTK updating until the next tick, allowing the engine's next request
  // to overlap this callback. Removing the last callback immediately ends
  // updating; adding it again resets GTK's animation-clock phase each frame.
  // If animation stops, this callback removes itself after one idle tick.
  return G_SOURCE_CONTINUE;
}

static gboolean fl_gtk_frame_pacer_vsync_timeout(gpointer user_data) {
  auto* request = static_cast<VsyncRequest*>(user_data);
  const uint64_t start_ns =
      static_cast<uint64_t>(g_get_monotonic_time()) * 1000;
  fl_gtk_frame_pacer_complete_vsync(request, start_ns, start_ns + 16666667);
  return G_SOURCE_REMOVE;
}

static gboolean fl_gtk_frame_pacer_vsync_watchdog(gpointer user_data) {
  auto* request = static_cast<VsyncRequest*>(user_data);
  request->watchdog_source_id = 0;
  TRACE_EVENT_INSTANT1("flutter", "LinuxVsyncClockTimeout", "baton",
                       std::to_string(request->baton).c_str());
  // Removing the tick runs its destroy notifier, which returns an undelivered
  // baton on wall time. A mapped but occluded/frozen clock may never tick.
  // Do not access request after removal: the notifier owns and frees it.
  gtk_widget_remove_tick_callback(request->widget, request->tick_callback_id);
  return G_SOURCE_REMOVE;
}

static void fl_gtk_frame_pacer_vsync_request_free(gpointer user_data) {
  auto* request = static_cast<VsyncRequest*>(user_data);
  // A widget can disappear between scheduling and its next clock tick. Return
  // that baton before releasing the engine so shutdown cannot strand it.
  if (!request->delivered) {
    const uint64_t start_ns =
        static_cast<uint64_t>(g_get_monotonic_time()) * 1000;
    fl_gtk_frame_pacer_complete_vsync(request, start_ns, start_ns + 16666667);
  }
  if (request->widget != nullptr && request->unmap_handler_id != 0) {
    g_signal_handler_disconnect(request->widget, request->unmap_handler_id);
  }
  g_clear_object(&request->widget);
  if (request->destroy_notify != nullptr) {
    request->destroy_notify(request->user_data);
  }
  g_object_unref(request->pacer);
  g_free(request);
}

static gboolean fl_gtk_frame_pacer_schedule_vsync(gpointer user_data) {
  auto* request = static_cast<VsyncRequest*>(user_data);
  if (request->widget != nullptr && gtk_widget_get_mapped(request->widget)) {
    request->unmap_handler_id = g_signal_connect(
        request->widget, "unmap",
        G_CALLBACK(+[](GtkWidget* widget, gpointer user_data) {
          auto* request = static_cast<VsyncRequest*>(user_data);
          const uint64_t start_ns =
              static_cast<uint64_t>(g_get_monotonic_time()) * 1000;
          fl_gtk_frame_pacer_complete_vsync(request, start_ns,
                                            start_ns + 16666667);
          if (request->tick_callback_id != 0) {
            gtk_widget_remove_tick_callback(widget, request->tick_callback_id);
          }
        }),
        request);
    request->tick_callback_id = gtk_widget_add_tick_callback(
        request->widget, fl_gtk_frame_pacer_frame_tick, request,
        fl_gtk_frame_pacer_vsync_request_free);
    GdkFrameClock* clock = gtk_widget_get_frame_clock(request->widget);
    const gint64 interval_us =
        clock ? fl_vsync_timing_for_clock(clock).refresh_interval_us : 16667;
    // Give normal frame-clock scheduling four refresh intervals. This is a
    // progress guard, not a second continuous vsync timer.
    const guint timeout_ms =
        static_cast<guint>(MAX((interval_us * 4 + 999) / 1000, 20));
    request->watchdog_source_id =
        g_timeout_add_full(G_PRIORITY_HIGH, timeout_ms,
                           fl_gtk_frame_pacer_vsync_watchdog, request, nullptr);
  } else {
    g_timeout_add_full(G_PRIORITY_HIGH, 16, fl_gtk_frame_pacer_vsync_timeout,
                       request, fl_gtk_frame_pacer_vsync_request_free);
  }
  return G_SOURCE_REMOVE;
}

static void fl_gtk_frame_pacer_class_init(FlGtkFramePacerClass* klass) {}

static void fl_gtk_frame_pacer_init(FlGtkFramePacer* self) {
  self->thread = g_thread_self();
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
  auto* request = g_new0(VsyncRequest, 1);
  request->pacer = FL_GTK_FRAME_PACER(g_object_ref(self));
  request->widget =
      widget == nullptr ? nullptr : GTK_WIDGET(g_object_ref(widget));
  request->baton = baton;
  request->callback = callback;
  request->user_data = user_data;
  request->destroy_notify = destroy_notify;
  // Context ownership alone does not make an engine worker a GTK thread.
  if (self->thread == g_thread_self() &&
      g_main_context_is_owner(g_main_context_default())) {
    fl_gtk_frame_pacer_schedule_vsync(request);
    return;
  }
  GSource* source = g_idle_source_new();
  g_source_set_priority(source, G_PRIORITY_HIGH);
  g_source_set_callback(source, fl_gtk_frame_pacer_schedule_vsync, request,
                        nullptr);
  g_source_attach(source, g_main_context_default());
  g_source_unref(source);
}
