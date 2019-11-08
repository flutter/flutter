// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gl_context_switch_manager.h"

namespace flutter {

GLContextSwitchManager::GLContextSwitchManager() = default;

GLContextSwitchManager::~GLContextSwitchManager() = default;

GLContextSwitchManager::GLContextSwitch::GLContextSwitch() = default;

GLContextSwitchManager::GLContextSwitch::~GLContextSwitch(){};

GLContextSwitchManager::GLContextSwitchPureResult::GLContextSwitchPureResult(
    bool switch_result)
    : switch_result_(switch_result){};

GLContextSwitchManager::GLContextSwitchPureResult::
    ~GLContextSwitchPureResult() = default;

bool GLContextSwitchManager::GLContextSwitchPureResult::GetSwitchResult() {
  return switch_result_;
}

}  // namespace flutter
