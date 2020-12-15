// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_AX_EVENT_BUNDLE_SINK_H_
#define UI_ACCESSIBILITY_AX_EVENT_BUNDLE_SINK_H_

#include <vector>

#include "ui/accessibility/ax_export.h"
#include "ui/accessibility/ax_tree_update.h"

namespace gfx {
class Point;
}  // namespace gfx

namespace ui {

struct AXEvent;
class AXTreeID;

// Interface for a consumer of groups of AXEvents.
class AX_EXPORT AXEventBundleSink {
 public:
  // |tree_id|: ID of the accessibility tree that the events apply to.
  // |updates|: Zero or more updates to the accessibility tree to apply first.
  // |mouse location|: Current mouse location in screen coordinates.
  // |events|: Zero or more events to fire after the updates have been applied.
  // Callers may wish to std::move() into the vector params to avoid copies.
  virtual void DispatchAccessibilityEvents(const AXTreeID& tree_id,
                                           std::vector<AXTreeUpdate> updates,
                                           const gfx::Point& mouse_location,
                                           std::vector<AXEvent> events) = 0;

 protected:
  virtual ~AXEventBundleSink() {}
};

}  // namespace ui

#endif  // UI_ACCESSIBILITY_AX_EVENT_BUNDLE_SINK_H_
