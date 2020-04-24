// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_ENGINE_PRIVATE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_ENGINE_PRIVATE_H_

#include <glib-object.h>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/linux/fl_renderer.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_dart_project.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_engine.h"

G_BEGIN_DECLS

/**
 * FlEngineError:
 * Errors for #FlEngine objects to set on failures.
 */

typedef enum {
  FL_ENGINE_ERROR_FAILED,
} FlEngineError;

GQuark fl_engine_error_quark(void) G_GNUC_CONST;

/**
 * fl_engine_new:
 * @project: a #FlDartProject
 * @renderer: a #FlRenderer
 *
 * Creates a new Flutter engine.
 *
 * Returns: a #FlEngine
 */
FlEngine* fl_engine_new(FlDartProject* project, FlRenderer* renderer);

/**
 * fl_engine_start:
 * @engine: a #FlEngine
 * @error: (allow-none): #GError location to store the error occurring, or %NULL
 * to ignore.
 *
 * Starts the Flutter engine.
 *
 * Returns: %TRUE on success
 */
gboolean fl_engine_start(FlEngine* engine, GError** error);

/**
 * fl_engine_send_window_metrics_event:
 * @engine: a #FlEngine
 * @width: width of the window in pixels.
 * @height: height of the window in pixels.
 * @pixel_ratio: scale factor for window.
 *
 * Sends a window metrics event to the engine.
 */
void fl_engine_send_window_metrics_event(FlEngine* engine,
                                         size_t width,
                                         size_t height,
                                         double pixel_ratio);

/**
 * fl_engine_send_mouse_pointer_event:
 * @engine: a #FlEngine
 * @phase: mouse phase.
 * @timestamp: time when event occurred in microseconds.
 * @x: x location of mouse cursor.
 * @y: y location of mouse cursor.
 * @buttons: buttons that are pressed.
 *
 * Sends a mouse pointer event to the engine.
 */
void fl_engine_send_mouse_pointer_event(FlEngine* engine,
                                        FlutterPointerPhase phase,
                                        size_t timestamp,
                                        double x,
                                        double y,
                                        int64_t buttons);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_ENGINE_PRIVATE_H_
