// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_AT_SPI_MONITOR_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_AT_SPI_MONITOR_H_

#include <glib-object.h>

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlAtSpiMonitor,
                     fl_at_spi_monitor,
                     FL,
                     AT_SPI_MONITOR,
                     GObject);

/**
 * FlAtSpiMonitor:
 *
 * #FlAtSpiMonitor watches the AT-SPI registry for assistive technologies.
 *
 * An assistive technology, such as a screen reader or a dictation tool,
 * registers event listeners with the registry before it reads the tree of an
 * application. The ATK bridge uses the same registrations to decide when to
 * serve the tree.
 *
 * The "client-registered" signal is emitted once, when the registry has an
 * event listener for the first time. If the accessibility bus is not
 * available, the signal is never emitted, as no assistive technology can
 * connect.
 */

/**
 * fl_at_spi_monitor_new:
 *
 * Creates a new AT-SPI monitor.
 *
 * Returns: a new #FlAtSpiMonitor.
 */
FlAtSpiMonitor* fl_at_spi_monitor_new();

/**
 * fl_at_spi_monitor_start:
 * @monitor: an #FlAtSpiMonitor.
 *
 * Connects to the accessibility bus and starts to watch the registry.
 */
void fl_at_spi_monitor_start(FlAtSpiMonitor* monitor);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_AT_SPI_MONITOR_H_
