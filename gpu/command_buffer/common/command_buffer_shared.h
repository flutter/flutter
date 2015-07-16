// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_COMMON_COMMAND_BUFFER_SHARED_H_
#define GPU_COMMAND_BUFFER_COMMON_COMMAND_BUFFER_SHARED_H_

#include "command_buffer.h"
#include "base/atomicops.h"

namespace gpu {

// This is a standard 4-slot asynchronous communication mechanism, used to
// ensure that the reader gets a consistent copy of what the writer wrote.
template<typename T>
class SharedState {
  T states_[2][2];
  base::subtle::Atomic32 reading_;
  base::subtle::Atomic32 latest_;
  base::subtle::Atomic32 slots_[2];

public:

  void Initialize() {
    for (int i = 0; i < 2; ++i) {
      for (int j = 0; j < 2; ++j) {
        states_[i][j] = T();
      }
    }
    base::subtle::NoBarrier_Store(&reading_, 0);
    base::subtle::NoBarrier_Store(&latest_, 0);
    base::subtle::NoBarrier_Store(&slots_[0], 0);
    base::subtle::Release_Store(&slots_[1], 0);
    base::subtle::MemoryBarrier();
  }

  void Write(const T& state) {
    int towrite = !base::subtle::Acquire_Load(&reading_);
    int index = !base::subtle::Acquire_Load(&slots_[towrite]);
    states_[towrite][index] = state;
    base::subtle::Release_Store(&slots_[towrite], index);
    base::subtle::Release_Store(&latest_, towrite);
    base::subtle::MemoryBarrier();
  }

  // Attempt to update the state, updating only if the generation counter is
  // newer.
  void Read(T* state) {
    base::subtle::MemoryBarrier();
    int toread = !!base::subtle::Acquire_Load(&latest_);
    base::subtle::Release_Store(&reading_, toread);
    base::subtle::MemoryBarrier();
    int index = !!base::subtle::Acquire_Load(&slots_[toread]);
    if (states_[toread][index].generation - state->generation < 0x80000000U)
      *state = states_[toread][index];
  }
};

typedef SharedState<CommandBuffer::State> CommandBufferSharedState;

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_COMMON_COMMAND_BUFFER_SHARED_H_
