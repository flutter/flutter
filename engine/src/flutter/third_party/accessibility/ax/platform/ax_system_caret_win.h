// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_PLATFORM_AX_SYSTEM_CARET_WIN_H_
#define UI_ACCESSIBILITY_PLATFORM_AX_SYSTEM_CARET_WIN_H_

#include <oleacc.h>
#include <wrl/client.h>

#include "base/macros.h"
#include "ui/accessibility/ax_export.h"
#include "ui/accessibility/ax_node_data.h"
#include "ui/accessibility/ax_tree_data.h"
#include "ui/accessibility/platform/ax_platform_node_delegate_base.h"
#include "ui/gfx/geometry/rect.h"
#include "ui/gfx/native_widget_types.h"

namespace ui {

class AXPlatformNodeWin;

// A class representing the position of the caret to assistive software on
// Windows. This is required because Chrome doesn't use the standard system
// caret and because some assistive software still relies on specific
// accessibility APIs to retrieve the caret position.
class AX_EXPORT AXSystemCaretWin : private AXPlatformNodeDelegateBase {
 public:
  explicit AXSystemCaretWin(gfx::AcceleratedWidget event_target);
  ~AXSystemCaretWin() override;

  Microsoft::WRL::ComPtr<IAccessible> GetCaret() const;
  void MoveCaretTo(const gfx::Rect& bounds_physical_pixels);
  void Hide();

 private:
  // |AXPlatformNodeDelegate| members.
  const AXNodeData& GetData() const override;
  gfx::NativeViewAccessible GetParent() override;
  gfx::Rect GetBoundsRect(const AXCoordinateSystem coordinate_system,
                          const AXClippingBehavior clipping_behavior,
                          AXOffscreenResult* offscreen_result) const override;
  gfx::AcceleratedWidget GetTargetForNativeAccessibilityEvent() override;
  bool ShouldIgnoreHoveredStateForTesting() override;
  const ui::AXUniqueId& GetUniqueId() const override;

  AXPlatformNodeWin* caret_;
  gfx::AcceleratedWidget event_target_;
  AXNodeData data_;
  ui::AXUniqueId unique_id_;

  friend class AXPlatformNodeWin;

  DISALLOW_COPY_AND_ASSIGN(AXSystemCaretWin);
};

}  // namespace ui

#endif  // UI_ACCESSIBILITY_PLATFORM_AX_SYSTEM_CARET_WIN_H_
