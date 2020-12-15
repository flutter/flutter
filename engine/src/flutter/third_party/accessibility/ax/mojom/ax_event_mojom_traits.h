// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_MOJOM_AX_EVENT_MOJOM_TRAITS_H_
#define UI_ACCESSIBILITY_MOJOM_AX_EVENT_MOJOM_TRAITS_H_

#include <vector>

#include "ui/accessibility/ax_event.h"
#include "ui/accessibility/ax_event_intent.h"
#include "ui/accessibility/mojom/ax_event.mojom.h"
#include "ui/accessibility/mojom/ax_event_intent.mojom.h"
#include "ui/accessibility/mojom/ax_event_intent_mojom_traits.h"

namespace mojo {

template <>
struct StructTraits<ax::mojom::AXEventDataView, ui::AXEvent> {
  static ax::mojom::Event event_type(const ui::AXEvent& p) {
    return p.event_type;
  }
  static int32_t id(const ui::AXEvent& p) { return p.id; }
  static ax::mojom::EventFrom event_from(const ui::AXEvent& p) {
    return p.event_from;
  }
  static std::vector<ui::AXEventIntent> event_intents(const ui::AXEvent& p) {
    return p.event_intents;
  }
  static int32_t action_request_id(const ui::AXEvent& p) {
    return p.action_request_id;
  }
  static bool Read(ax::mojom::AXEventDataView data, ui::AXEvent* out);
};

}  // namespace mojo

#endif  // UI_ACCESSIBILITY_MOJOM_AX_EVENT_MOJOM_TRAITS_H_
