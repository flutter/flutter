// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_GPU_SCHEDULER_MOCK_H_
#define GPU_COMMAND_BUFFER_SERVICE_GPU_SCHEDULER_MOCK_H_

#include "gpu/command_buffer/service/gpu_scheduler.h"
#include "testing/gmock/include/gmock/gmock.h"

namespace gpu {

class MockGpuScheduler : public GpuScheduler {
 public:
  explicit MockGpuScheduler(CommandBuffer* command_buffer)
      : GpuScheduler(command_buffer) {
  }

  MOCK_METHOD1(GetSharedMemoryBuffer, Buffer(int32 shm_id));
  MOCK_METHOD1(set_token, void(int32 token));

 private:
  DISALLOW_COPY_AND_ASSIGN(MockGpuScheduler);
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_GPU_SCHEDULER_MOCK_H_
