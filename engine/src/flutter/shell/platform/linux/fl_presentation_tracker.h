// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_PRESENTATION_TRACKER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_PRESENTATION_TRACKER_H_

#include <gtk/gtk.h>

struct wl_surface;

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlPresentationTracker,
                     fl_presentation_tracker,
                     FL,
                     PRESENTATION_TRACKER,
                     GObject)

typedef struct _FlEngine FlEngine;

/**
 * FlPresentationTracker:
 *
 * #FlPresentationTracker requests a `wl_surface.frame` callback for each
 * committed frame and reports the resulting commit-to-repaint latency to an
 * #FlEngine.
 *
 * `wl_surface.frame` is part of the core Wayland protocol, so this uses the
 * system Wayland client directly. No protocol code is generated or bundled and
 * no optional compositor global is required; any Wayland compositor implements
 * it.
 *
 * The core protocol does not define the clock used for the `done` event, so the
 * tracker measures the time the event arrives on the GTK thread instead. That
 * time includes the compositor's repaint lead and the main loop dispatch
 * latency, but both are stable from frame to frame and the phase controller
 * only needs the shape of the commit-to-repaint latency, not an absolute
 * timestamp.
 *
 * The tracker is inert (the engine keeps its natural frame grid) when the
 * surface is %NULL, after fl_presentation_tracker_reset(), or while feedback is
 * paused for a synchronized resize.
 */

/**
 * fl_presentation_tracker_new:
 * @engine: the #FlEngine to report samples to.
 *
 * Creates a tracker that reports commit-to-repaint latency to @engine. The
 * tracker holds a weak reference to @engine.
 *
 * Returns: a new #FlPresentationTracker.
 */
FlPresentationTracker* fl_presentation_tracker_new(FlEngine* engine);

/**
 * fl_presentation_tracker_record_commit:
 * @tracker: an #FlPresentationTracker.
 * @surface: the Wayland surface that is about to be committed.
 *
 * Requests a frame callback for the next commit of @surface. Must be called
 * immediately before the commit, from the thread making the commit.
 */
void fl_presentation_tracker_record_commit(FlPresentationTracker* tracker,
                                           struct wl_surface* surface);

/**
 * fl_presentation_tracker_set_enabled:
 * @tracker: an #FlPresentationTracker.
 * @enabled: whether feedback should be used.
 *
 * Disables feedback while the subsurface is synchronized with its parent
 * surface, when the parent commit determines when the frame is shown.
 */
void fl_presentation_tracker_set_enabled(FlPresentationTracker* tracker,
                                         gboolean enabled);

/**
 * fl_presentation_tracker_reset:
 * @tracker: an #FlPresentationTracker.
 *
 * Cancels pending frame callbacks and forgets the current run. Called when the
 * surface is hidden, recreated, or resized.
 */
void fl_presentation_tracker_reset(FlPresentationTracker* tracker);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_PRESENTATION_TRACKER_H_
