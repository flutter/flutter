// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_MOJOM_AX_EVENT_INTENT_MOJOM_TRAITS_H_
#define UI_ACCESSIBILITY_MOJOM_AX_EVENT_INTENT_MOJOM_TRAITS_H_

#include "ui/accessibility/ax_event_intent.h"
#include "ui/accessibility/mojom/ax_event_intent.mojom.h"

namespace mojo {

template <>
struct StructTraits<ax::mojom::EventIntentDataView, ui::AXEventIntent> {
  static ax::mojom::Command command(const ui::AXEventIntent& p) {
    return p.command;
  }
  static ax::mojom::TextBoundary text_boundary(const ui::AXEventIntent& p) {
    return p.text_boundary;
  }
  static ax::mojom::MoveDirection move_direction(const ui::AXEventIntent& p) {
    return p.move_direction;
  }
  static bool Read(ax::mojom::EventIntentDataView data, ui::AXEventIntent* out);
};

}  // namespace mojo

#endif  // UI_ACCESSIBILITY_MOJOM_AX_EVENT_INTENT_MOJOM_TRAITS_H_
