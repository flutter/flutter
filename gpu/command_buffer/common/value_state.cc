// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/common/value_state.h"

namespace gpu {

ValueStateMap::ValueStateMap() {
}

ValueStateMap::~ValueStateMap() {
}

const ValueState* ValueStateMap::GetState(unsigned int target) const {
  Map::const_iterator it = state_map_.find(target);
  return it != state_map_.end() ? &it->second : NULL;
}

void ValueStateMap::UpdateState(unsigned int target, const ValueState& state) {
  state_map_[target] = state;
}

}  // namespace gpu
