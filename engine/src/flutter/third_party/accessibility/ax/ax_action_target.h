// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_AX_ACTION_TARGET_H_
#define UI_ACCESSIBILITY_AX_ACTION_TARGET_H_

#include "ui/accessibility/ax_enums.mojom-forward.h"
#include "ui/gfx/geometry/point.h"
#include "ui/gfx/geometry/rect.h"

namespace ui {

// AXActionTarget is an abstract interface that can be used to carry out
// accessibility actions on nodes from an AXTreeSource without knowing the
// concrete class of that AXTreeSource.
class AXActionTarget {
 public:
  virtual ~AXActionTarget() = default;

  enum class Type { kNull, kBlink, kPdf };
  virtual Type GetType() const = 0;

  virtual bool ClearAccessibilityFocus() const = 0;
  virtual bool Click() const = 0;
  virtual bool Decrement() const = 0;
  virtual bool Increment() const = 0;
  virtual bool Focus() const = 0;
  virtual gfx::Rect GetRelativeBounds() const = 0;
  virtual gfx::Point GetScrollOffset() const = 0;
  virtual gfx::Point MinimumScrollOffset() const = 0;
  virtual gfx::Point MaximumScrollOffset() const = 0;
  virtual bool SetAccessibilityFocus() const = 0;
  virtual void SetScrollOffset(const gfx::Point& point) const = 0;
  virtual bool SetSelected(bool selected) const = 0;
  virtual bool SetSelection(const AXActionTarget* anchor_object,
                            int anchor_offset,
                            const AXActionTarget* focus_object,
                            int focus_offset) const = 0;
  virtual bool SetSequentialFocusNavigationStartingPoint() const = 0;
  virtual bool SetValue(const std::string& value) const = 0;
  virtual bool ShowContextMenu() const = 0;
  // Make this object visible by scrolling as many nested scrollable views as
  // needed.
  virtual bool ScrollToMakeVisible() const = 0;
  // Same, but if the whole object can't be made visible, try for this subrect,
  // in local coordinates.
  virtual bool ScrollToMakeVisibleWithSubFocus(
      const gfx::Rect& rect,
      ax::mojom::ScrollAlignment horizontal_scroll_alignment,
      ax::mojom::ScrollAlignment vertical_scroll_alignment,
      ax::mojom::ScrollBehavior scroll_behavior) const = 0;
  // Scroll this object to a given point in global coordinates of the top-level
  // window.
  virtual bool ScrollToGlobalPoint(const gfx::Point& point) const = 0;

 protected:
  AXActionTarget() = default;
};

}  // namespace ui

#endif  // UI_ACCESSIBILITY_AX_ACTION_TARGET_H_
