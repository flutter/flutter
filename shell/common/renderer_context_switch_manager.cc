// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "renderer_context_switch_manager.h"

namespace flutter {

RendererContextSwitchManager::RendererContextSwitchManager() = default;

RendererContextSwitchManager::~RendererContextSwitchManager() = default;

RendererContextSwitchManager::RendererContextSwitch::RendererContextSwitch() =
    default;

RendererContextSwitchManager::RendererContextSwitch::~RendererContextSwitch(){};

RendererContextSwitchManager::RendererContextSwitchPureResult::
    RendererContextSwitchPureResult(bool switch_result)
    : switch_result_(switch_result){};

RendererContextSwitchManager::RendererContextSwitchPureResult::
    ~RendererContextSwitchPureResult() = default;

bool RendererContextSwitchManager::RendererContextSwitchPureResult::
    GetSwitchResult() {
  return switch_result_;
}

}  // namespace flutter
