// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDERER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDERER_H_

#include <gtk/gtk.h>

#include "flutter/shell/platform/embedder/embedder.h"

#include "flutter/shell/platform/linux/fl_renderable.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_engine.h"

G_BEGIN_DECLS

/**
 * FlRendererError:
 * Errors for #FlRenderer objects to set on failures.
 */

typedef enum {
  FL_RENDERER_ERROR_FAILED,
} FlRendererError;

GQuark fl_renderer_error_quark(void) G_GNUC_CONST;

G_DECLARE_FINAL_TYPE(FlRenderer, fl_renderer, FL, RENDERER, GObject)

/**
 * FlRenderer:
 *
 * #FlRenderer is an abstract class that allows Flutter to draw pixels.
 */

/**
 * fl_renderer_new:
 * @engine: an #FlEngine.
 *
 * Creates a new renderer.
 *
 * Returns: a new #FlRenderer.
 */
FlRenderer* fl_renderer_new(FlEngine* engine);

/**
 * fl_renderer_create_backing_store:
 * @renderer: an #FlRenderer.
 * @config: backing store config.
 * @backing_store_out: saves created backing store.
 *
 * Obtain a backing store for a specific #FlutterLayer.
 *
 * Returns %TRUE if successful.
 */
gboolean fl_renderer_create_backing_store(
    FlRenderer* renderer,
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out);

/**
 * fl_renderer_collect_backing_store:
 * @renderer: an #FlRenderer.
 * @backing_store: backing store to be released.
 *
 * A callback invoked by the engine to release the backing store. The
 * embedder may collect any resources associated with the backing store.
 *
 * Returns %TRUE if successful.
 */
gboolean fl_renderer_collect_backing_store(
    FlRenderer* renderer,
    const FlutterBackingStore* backing_store);

/**
 * fl_renderer_present_layers:
 * @renderer: an #FlRenderer.
 * @view_id: view to present.
 * @layers: layers to be composited.
 * @layers_count: number of layers.
 *
 * Callback invoked by the engine to composite the contents of each layer
 * onto the screen.
 *
 * Returns %TRUE if successful.
 */
gboolean fl_renderer_present_layers(FlRenderer* renderer,
                                    FlutterViewId view_id,
                                    const FlutterLayer** layers,
                                    size_t layers_count);

/**
 * fl_renderer_wait_for_frame:
 * @renderer: an #FlRenderer.
 * @target_width: width of frame being waited for
 * @target_height: height of frame being waited for
 *
 * Holds the thread until frame with requested dimensions is presented.
 * While waiting for frame Flutter platform and raster tasks are being
 * processed.
 */
void fl_renderer_wait_for_frame(FlRenderer* renderer,
                                int target_width,
                                int target_height);

/**
 * fl_renderer_setup:
 * @renderer: an #FlRenderer.
 *
 * Creates OpenGL resources required before rendering. Requires an active OpenGL
 * context.
 */
void fl_renderer_setup(FlRenderer* renderer);

/**
 * fl_renderer_render:
 * @renderer: an #FlRenderer.
 * @view_id: view to render.
 * @width: width of the window in pixels.
 * @height: height of the window in pixels.
 * @background_color: color to use for background.
 *
 * Performs OpenGL commands to render current Flutter view.
 */
void fl_renderer_render(FlRenderer* renderer,
                        FlutterViewId view_id,
                        int width,
                        int height,
                        const GdkRGBA* background_color);

/**
 * fl_renderer_cleanup:
 *
 * Removes OpenGL resources used for rendering. Requires an active OpenGL
 * context.
 */
void fl_renderer_cleanup(FlRenderer* renderer);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDERER_H_
