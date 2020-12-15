// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/mojom/ax_event_intent_mojom_traits.h"

namespace mojo {

// static
bool StructTraits<ax::mojom::EventIntentDataView, ui::AXEventIntent>::Read(
    ax::mojom::EventIntentDataView data,
    ui::AXEventIntent* out) {
  out->command = data.command();
  out->text_boundary = data.text_boundary();
  out->move_direction = data.move_direction();
  return true;
}

}  // namespace mojo
