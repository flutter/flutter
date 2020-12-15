// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_MOJOM_AX_TREE_UPDATE_MOJOM_TRAITS_H_
#define UI_ACCESSIBILITY_MOJOM_AX_TREE_UPDATE_MOJOM_TRAITS_H_

#include "ui/accessibility/ax_event_intent.h"
#include "ui/accessibility/ax_tree_update.h"
#include "ui/accessibility/mojom/ax_event_intent.mojom.h"
#include "ui/accessibility/mojom/ax_event_intent_mojom_traits.h"
#include "ui/accessibility/mojom/ax_node_data_mojom_traits.h"
#include "ui/accessibility/mojom/ax_tree_data_mojom_traits.h"
#include "ui/accessibility/mojom/ax_tree_update.mojom-shared.h"

namespace mojo {

template <>
struct StructTraits<ax::mojom::AXTreeUpdateDataView, ui::AXTreeUpdate> {
  static bool has_tree_data(const ui::AXTreeUpdate& p) {
    return p.has_tree_data;
  }
  static const ui::AXTreeData& tree_data(const ui::AXTreeUpdate& p) {
    return p.tree_data;
  }
  static int32_t node_id_to_clear(const ui::AXTreeUpdate& p) {
    return p.node_id_to_clear;
  }
  static int32_t root_id(const ui::AXTreeUpdate& p) { return p.root_id; }
  static const std::vector<ui::AXNodeData>& nodes(const ui::AXTreeUpdate& p) {
    return p.nodes;
  }
  static ax::mojom::EventFrom event_from(const ui::AXTreeUpdate& p) {
    return p.event_from;
  }
  static std::vector<ui::AXEventIntent> event_intents(
      const ui::AXTreeUpdate& p) {
    return p.event_intents;
  }

  static bool Read(ax::mojom::AXTreeUpdateDataView data, ui::AXTreeUpdate* out);
};

}  // namespace mojo

#endif  // UI_ACCESSIBILITY_MOJOM_AX_TREE_UPDATE_MOJOM_TRAITS_H_
