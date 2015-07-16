// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/common/debug_marker_manager.h"

namespace gpu {
namespace gles2 {

DebugMarkerManager::Group::Group(const std::string& name)
    : name_(name),
      marker_(name) {
}

DebugMarkerManager::Group::~Group() {
}

void DebugMarkerManager::Group::SetMarker(const std::string& marker) {
  marker_ = name_ + "." + marker;
}

DebugMarkerManager::DebugMarkerManager() {
  // Push root group.
  group_stack_.push(Group(std::string()));
}

DebugMarkerManager::~DebugMarkerManager() {
}

void DebugMarkerManager::SetMarker(const std::string& marker) {
  group_stack_.top().SetMarker(marker);
}

const std::string& DebugMarkerManager::GetMarker() const {
  return group_stack_.top().marker();
}

void DebugMarkerManager::PushGroup(const std::string& name) {
  group_stack_.push(Group(group_stack_.top().name() + "." + name));
}

void DebugMarkerManager::PopGroup(void) {
  if (group_stack_.size() > 1) {
    group_stack_.pop();
  }
}

}  // namespace gles2
}  // namespace gpu


