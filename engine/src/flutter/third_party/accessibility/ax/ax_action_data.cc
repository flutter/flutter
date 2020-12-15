// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/ax_action_data.h"

#include "ui/accessibility/ax_enums.mojom.h"

namespace ui {

// Mojo enums are initialized here so the header can include the much smaller
// mojom-forward.h header.
AXActionData::AXActionData()
    : action(ax::mojom::Action::kNone),
      hit_test_event_to_fire(ax::mojom::Event::kNone),
      horizontal_scroll_alignment(ax::mojom::ScrollAlignment::kNone),
      vertical_scroll_alignment(ax::mojom::ScrollAlignment::kNone),
      scroll_behavior(ax::mojom::ScrollBehavior::kNone) {}

AXActionData::AXActionData(const AXActionData& other) = default;
AXActionData::~AXActionData() = default;

}  // namespace ui
