// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK_FRAME_PACER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK_FRAME_PACER_H_

#include <gtk/gtk.h>
#include <stdint.h>

G_BEGIN_DECLS

#define FL_TYPE_GTK_FRAME_PACER fl_gtk_frame_pacer_get_type()
G_DECLARE_FINAL_TYPE(FlGtkFramePacer,
                     fl_gtk_frame_pacer,
                     FL,
                     GTK_FRAME_PACER,
                     GObject)

typedef void (*FlGtkFramePacerCallback)(intptr_t baton,
                                        uint64_t frame_start_ns,
                                        uint64_t frame_target_ns,
                                        gpointer user_data);

// Create on the GTK platform thread. Scheduling uses the default main context.
FlGtkFramePacer* fl_gtk_frame_pacer_new();

// May be called from an engine worker. The callback runs on the GTK thread.
// Retains widget (which may be null) until delivery, then observes it weakly.
// Takes ownership of user_data through
// destroy_notify, called immediately after delivery. The caller must keep the
// callback recipient alive until then. Do not issue requests after stop.
void fl_gtk_frame_pacer_request(FlGtkFramePacer* self,
                                GtkWidget* widget,
                                intptr_t baton,
                                FlGtkFramePacerCallback callback,
                                gpointer user_data,
                                GDestroyNotify destroy_notify);

// Call on the GTK thread before shutting down the callback recipient. Returns
// every pending baton and removes all subscriptions, including retained idle
// ticks. Stop issuing requests before calling this. Safe to call repeatedly or
// from a delivery callback.
void fl_gtk_frame_pacer_stop(FlGtkFramePacer* self);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK_FRAME_PACER_H_
