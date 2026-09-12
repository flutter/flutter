// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/pointer_data_dispatcher.h"

#include "flutter/fml/trace_event.h"

namespace flutter {

PointerDataDispatcher::~PointerDataDispatcher() = default;
DefaultPointerDataDispatcher::~DefaultPointerDataDispatcher() = default;

void DefaultPointerDataDispatcher::DispatchPacket(
    std::unique_ptr<PointerDataPacket> packet,
    uint64_t trace_flow_id) {
  TRACE_EVENT0_WITH_FLOW_IDS("flutter",
                             "DefaultPointerDataDispatcher::DispatchPacket",
                             /*flow_id_count=*/1, &trace_flow_id);
  TRACE_FLOW_STEP("flutter", "PointerEvent", trace_flow_id);
  delegate_.DoDispatchPacket(std::move(packet), trace_flow_id);
}

}  // namespace flutter
