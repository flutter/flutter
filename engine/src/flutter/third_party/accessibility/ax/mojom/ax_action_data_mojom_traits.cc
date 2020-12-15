// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/mojom/ax_action_data_mojom_traits.h"

namespace mojo {

// static
bool StructTraits<ax::mojom::AXActionDataDataView, ui::AXActionData>::Read(
    ax::mojom::AXActionDataDataView data,
    ui::AXActionData* out) {
  if (!data.ReadAction(&out->action))
    return false;
  if (!data.ReadTargetTreeId(&out->target_tree_id))
    return false;
  if (!data.ReadSourceExtensionId(&out->source_extension_id))
    return false;
  out->target_node_id = data.target_node_id();
  out->request_id = data.request_id();
  out->flags = data.flags();
  out->anchor_node_id = data.anchor_node_id();
  out->anchor_offset = data.anchor_offset();
  out->focus_node_id = data.focus_node_id();
  out->focus_offset = data.focus_offset();
  out->custom_action_id = data.custom_action_id();
  out->horizontal_scroll_alignment = data.horizontal_scroll_alignment();
  out->vertical_scroll_alignment = data.vertical_scroll_alignment();
  out->scroll_behavior = data.scroll_behavior();
  return data.ReadTargetRect(&out->target_rect) &&
         data.ReadTargetPoint(&out->target_point) &&
         data.ReadValue(&out->value) &&
         data.ReadHitTestEventToFire(&out->hit_test_event_to_fire);
}

}  // namespace mojo
