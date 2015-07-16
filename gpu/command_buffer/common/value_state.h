// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_COMMON_VALUE_STATE_H_
#define GPU_COMMAND_BUFFER_COMMON_VALUE_STATE_H_

#include "base/containers/hash_tables.h"
#include "base/memory/ref_counted.h"
#include "gpu/gpu_export.h"

namespace gpu {

// Used to maintain Valuebuffer state, exposed to browser to
// support passing ValueStates via IPC.
union GPU_EXPORT ValueState {
  float float_value[4];
  int int_value[4];
};

// Refcounted wrapper for a hash_map of subscription targets to ValueStates
class GPU_EXPORT ValueStateMap : public base::RefCounted<ValueStateMap> {
 public:
  ValueStateMap();

  // Returns NULL if there is not ValueState for the target
  const ValueState* GetState(unsigned int target) const;

  void UpdateState(unsigned int target, const ValueState& state);

 protected:
  virtual ~ValueStateMap();

 private:
  friend class base::RefCounted<ValueStateMap>;

  typedef base::hash_map<unsigned int, ValueState> Map;

  Map state_map_;

  DISALLOW_COPY_AND_ASSIGN(ValueStateMap);
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_COMMON_VALUE_STATE_H_
