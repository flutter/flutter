// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/mojom/ax_tree_update_mojom_traits.h"

namespace mojo {

// static
bool StructTraits<ax::mojom::AXTreeUpdateDataView, ui::AXTreeUpdate>::Read(
    ax::mojom::AXTreeUpdateDataView data,
    ui::AXTreeUpdate* out) {
  out->has_tree_data = data.has_tree_data();
  if (!data.ReadTreeData(&out->tree_data))
    return false;
  out->node_id_to_clear = data.node_id_to_clear();
  out->root_id = data.root_id();
  if (!data.ReadNodes(&out->nodes))
    return false;
  out->event_from = data.event_from();
  return data.ReadEventIntents(&out->event_intents);
}

}  // namespace mojo
