// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/mojom/ax_event_mojom_traits.h"

namespace mojo {

// static
bool StructTraits<ax::mojom::AXEventDataView, ui::AXEvent>::Read(
    ax::mojom::AXEventDataView data,
    ui::AXEvent* out) {
  out->event_type = data.event_type();
  out->id = data.id();
  out->event_from = data.event_from();
  out->action_request_id = data.action_request_id();
  return data.ReadEventIntents(&out->event_intents);
}

}  // namespace mojo
