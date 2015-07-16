// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Helper classes for implementing gpu client side unit tests.

#ifndef GPU_COMMAND_BUFFER_CLIENT_CLIENT_TEST_HELPER_H_
#define GPU_COMMAND_BUFFER_CLIENT_CLIENT_TEST_HELPER_H_

#include "base/compiler_specific.h"
#include "base/memory/scoped_ptr.h"
#include "gpu/command_buffer/client/gpu_control.h"
#include "gpu/command_buffer/common/cmd_buffer_common.h"
#include "gpu/command_buffer/common/gpu_memory_allocation.h"
#include "gpu/command_buffer/service/command_buffer_service.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace gpu {

class CommandBufferHelper;

class MockCommandBufferBase : public CommandBufferServiceBase {
 public:
  static const int32 kTransferBufferBaseId = 0x123;
  static const int32 kMaxTransferBuffers = 6;

  MockCommandBufferBase();
  ~MockCommandBufferBase() override;

  bool Initialize() override;
  State GetLastState() override;
  int32 GetLastToken() override;
  void WaitForTokenInRange(int32 start, int32 end) override;
  void WaitForGetOffsetInRange(int32 start, int32 end) override;
  void SetGetBuffer(int transfer_buffer_id) override;
  void SetGetOffset(int32 get_offset) override;
  scoped_refptr<gpu::Buffer> CreateTransferBuffer(size_t size,
                                                  int32* id) override;
  scoped_refptr<gpu::Buffer> GetTransferBuffer(int32 id) override;
  void SetToken(int32 token) override;
  void SetParseError(error::Error error) override;
  void SetContextLostReason(error::ContextLostReason reason) override;
  int32 GetPutOffset() override;

  // Get's the Id of the next transfer buffer that will be returned
  // by CreateTransferBuffer. This is useful for testing expected ids.
  int32 GetNextFreeTransferBufferId();

  void FlushHelper(int32 put_offset);
  void DestroyTransferBufferHelper(int32 id);

  virtual void OnFlush() = 0;

 private:
  scoped_refptr<Buffer> transfer_buffer_buffers_[kMaxTransferBuffers];
  CommandBufferEntry* ring_buffer_;
  scoped_refptr<Buffer> ring_buffer_buffer_;
  State state_;
  int32 put_offset_;
};

class MockClientCommandBuffer : public MockCommandBufferBase {
 public:
  MockClientCommandBuffer();
  ~MockClientCommandBuffer() override;

  // This is so we can use all the gmock functions when Flush is called.
  MOCK_METHOD0(OnFlush, void());
  MOCK_METHOD1(DestroyTransferBuffer, void(int32 id));

  void Flush(int32 put_offset) override;
  void OrderingBarrier(int32 put_offset) override;

  void DelegateToFake();
};

class MockClientCommandBufferMockFlush : public MockClientCommandBuffer {
 public:
  MockClientCommandBufferMockFlush();
  virtual ~MockClientCommandBufferMockFlush();

  MOCK_METHOD1(Flush, void(int32 put_offset));
  MOCK_METHOD1(OrderingBarrier, void(int32 put_offset));

  void DelegateToFake();
};

class MockClientGpuControl : public GpuControl {
 public:
  MockClientGpuControl();
  virtual ~MockClientGpuControl();

  MOCK_METHOD0(GetCapabilities, Capabilities());
  MOCK_METHOD4(CreateImage,
               int32(ClientBuffer buffer,
                     size_t width,
                     size_t height,
                     unsigned internalformat));
  MOCK_METHOD1(DestroyImage, void(int32 id));
  MOCK_METHOD4(CreateGpuMemoryBufferImage,
               int32(size_t width,
                     size_t height,
                     unsigned internalformat,
                     unsigned usage));
  MOCK_METHOD0(InsertSyncPoint, uint32());
  MOCK_METHOD0(InsertFutureSyncPoint, uint32());
  MOCK_METHOD1(RetireSyncPoint, void(uint32 id));
  MOCK_METHOD2(SignalSyncPoint, void(uint32 id, const base::Closure& callback));
  MOCK_METHOD2(SignalQuery, void(uint32 query, const base::Closure& callback));
  MOCK_METHOD1(SetSurfaceVisible, void(bool visible));
  MOCK_METHOD1(CreateStreamTexture, uint32(uint32));
  MOCK_METHOD1(SetLock, void(base::Lock*));

 private:
  DISALLOW_COPY_AND_ASSIGN(MockClientGpuControl);
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_CLIENT_CLIENT_TEST_HELPER_H_

