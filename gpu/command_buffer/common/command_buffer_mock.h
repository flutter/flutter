// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_COMMON_COMMAND_BUFFER_MOCK_H_
#define GPU_COMMAND_BUFFER_COMMON_COMMAND_BUFFER_MOCK_H_

#include "gpu/command_buffer/service/command_buffer_service.h"
#include "testing/gmock/include/gmock/gmock.h"

namespace base {
class SharedMemory;
}

namespace gpu {

// An NPObject that implements a shared memory command buffer and a synchronous
// API to manage the put and get pointers.
class MockCommandBuffer : public CommandBufferServiceBase {
 public:
  MockCommandBuffer();
  virtual ~MockCommandBuffer();

  MOCK_METHOD0(Initialize, bool());
  MOCK_METHOD0(GetLastState, State());
  MOCK_METHOD0(GetLastToken, int32());
  MOCK_METHOD1(Flush, void(int32 put_offset));
  MOCK_METHOD1(OrderingBarrier, void(int32 put_offset));
  MOCK_METHOD2(WaitForTokenInRange, void(int32 start, int32 end));
  MOCK_METHOD2(WaitForGetOffsetInRange, void(int32 start, int32 end));
  MOCK_METHOD1(SetGetBuffer, void(int32 transfer_buffer_id));
  MOCK_METHOD1(SetGetOffset, void(int32 get_offset));
  MOCK_METHOD2(CreateTransferBuffer,
               scoped_refptr<gpu::Buffer>(size_t size, int32* id));
  MOCK_METHOD1(DestroyTransferBuffer, void(int32 id));
  MOCK_METHOD1(GetTransferBuffer, scoped_refptr<gpu::Buffer>(int32 id));
  MOCK_METHOD1(SetToken, void(int32 token));
  MOCK_METHOD1(SetParseError, void(error::Error error));
  MOCK_METHOD1(SetContextLostReason,
               void(error::ContextLostReason context_lost_reason));
  MOCK_METHOD0(InsertSyncPoint, uint32());
  MOCK_METHOD0(GetPutOffset, int32());

 private:
  DISALLOW_COPY_AND_ASSIGN(MockCommandBuffer);
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_COMMON_COMMAND_BUFFER_MOCK_H_
