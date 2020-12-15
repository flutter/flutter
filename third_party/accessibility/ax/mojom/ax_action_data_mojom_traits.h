// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_MOJOM_AX_ACTION_DATA_MOJOM_TRAITS_H_
#define UI_ACCESSIBILITY_MOJOM_AX_ACTION_DATA_MOJOM_TRAITS_H_

#include "ui/accessibility/ax_action_data.h"
#include "ui/accessibility/mojom/ax_action_data.mojom-shared.h"
#include "ui/accessibility/mojom/ax_tree_id_mojom_traits.h"
#include "ui/gfx/geometry/mojom/geometry_mojom_traits.h"

namespace mojo {

template <>
struct StructTraits<ax::mojom::AXActionDataDataView, ui::AXActionData> {
  static ax::mojom::Action action(const ui::AXActionData& a) {
    return a.action;
  }
  static const ui::AXTreeID& target_tree_id(const ui::AXActionData& a) {
    return a.target_tree_id;
  }
  static const std::string& source_extension_id(const ui::AXActionData& a) {
    return a.source_extension_id;
  }
  static int32_t target_node_id(const ui::AXActionData& a) {
    return a.target_node_id;
  }
  static int32_t request_id(const ui::AXActionData& a) { return a.request_id; }
  static int32_t flags(const ui::AXActionData& a) { return a.flags; }
  static int32_t anchor_node_id(const ui::AXActionData& a) {
    return a.anchor_node_id;
  }
  static int32_t anchor_offset(const ui::AXActionData& a) {
    return a.anchor_offset;
  }
  static int32_t focus_node_id(const ui::AXActionData& a) {
    return a.focus_node_id;
  }
  static int32_t focus_offset(const ui::AXActionData& a) {
    return a.focus_offset;
  }
  static int32_t custom_action_id(const ui::AXActionData& a) {
    return a.custom_action_id;
  }
  static const gfx::Rect& target_rect(const ui::AXActionData& a) {
    return a.target_rect;
  }
  static const gfx::Point& target_point(const ui::AXActionData& a) {
    return a.target_point;
  }
  static const std::string& value(const ui::AXActionData& a) { return a.value; }
  static ax::mojom::Event hit_test_event_to_fire(const ui::AXActionData& a) {
    return a.hit_test_event_to_fire;
  }
  static ax::mojom::ScrollAlignment horizontal_scroll_alignment(
      const ui::AXActionData& a) {
    return a.horizontal_scroll_alignment;
  }
  static ax::mojom::ScrollAlignment vertical_scroll_alignment(
      const ui::AXActionData& a) {
    return a.vertical_scroll_alignment;
  }
  static ax::mojom::ScrollBehavior scroll_behavior(const ui::AXActionData& a) {
    return a.scroll_behavior;
  }

  static bool Read(ax::mojom::AXActionDataDataView data, ui::AXActionData* out);
};

}  // namespace mojo

#endif  // UI_ACCESSIBILITY_MOJOM_AX_ACTION_DATA_MOJOM_TRAITS_H_
