// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_AX_EVENT_H_
#define UI_ACCESSIBILITY_AX_EVENT_H_

#include <string>
#include <vector>

#include "ui/accessibility/ax_base_export.h"
#include "ui/accessibility/ax_enums.mojom.h"
#include "ui/accessibility/ax_event_intent.h"
#include "ui/accessibility/ax_node_data.h"

namespace ui {

struct AX_BASE_EXPORT AXEvent final {
  AXEvent();
  AXEvent(AXNodeData::AXID id,
          ax::mojom::Event event_type,
          ax::mojom::EventFrom event_from = ax::mojom::EventFrom::kNone,
          const std::vector<AXEventIntent>& event_intents = {},
          int action_request_id = -1);
  virtual ~AXEvent();
  AXEvent(const AXEvent& event);
  AXEvent& operator=(const AXEvent& event);

  // The id of the node in the AXTree that the event should be fired on.
  AXNodeData::AXID id = AXNodeData::kInvalidAXID;

  // The type of event.
  ax::mojom::Event event_type = ax::mojom::Event::kNone;

  // The source of the event.
  ax::mojom::EventFrom event_from = ax::mojom::EventFrom::kNone;

  // Describes what caused an accessibility event to be raised. For example, in
  // the case of a selection changed event, the selection could have been
  // extended to the beginning of the previous word, or it could have been moved
  // to the end of the next line. Note that there could be multiple causes that
  // resulted in an event.
  std::vector<AXEventIntent> event_intents;

  // The action request ID that was passed in if this event was fired in
  // direct response to a ax::mojom::Action.
  int action_request_id = -1;

  // Returns a string representation of this data, for debugging.
  std::string ToString() const;
};

}  // namespace ui

#endif  // UI_ACCESSIBILITY_AX_EVENT_H_
