// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_GLES2_COMMAND_BUFFER_CLIENT_IMPL_H_
#define MOJO_GLES2_COMMAND_BUFFER_CLIENT_IMPL_H_

#include <map>

#include "base/macros.h"
#include "base/memory/scoped_ptr.h"
#include "gpu/command_buffer/client/gpu_control.h"
#include "gpu/command_buffer/common/command_buffer.h"
#include "gpu/command_buffer/common/command_buffer_shared.h"
#include "mojo/public/cpp/bindings/binding.h"
#include "mojo/services/gpu/public/interfaces/command_buffer.mojom.h"

namespace base {
class RunLoop;
}

namespace gles2 {
class CommandBufferClientImpl;

class CommandBufferDelegate {
 public:
  virtual ~CommandBufferDelegate();
  virtual void ContextLost();
};

class CommandBufferClientImpl : public mojo::CommandBufferLostContextObserver,
                                public gpu::CommandBuffer,
                                public gpu::GpuControl {
 public:
  explicit CommandBufferClientImpl(
      CommandBufferDelegate* delegate,
      const MojoAsyncWaiter* async_waiter,
      mojo::ScopedMessagePipeHandle command_buffer_handle);
  ~CommandBufferClientImpl() override;

  // CommandBuffer implementation:
  bool Initialize() override;
  State GetLastState() override;
  int32_t GetLastToken() override;
  void Flush(int32_t put_offset) override;
  void OrderingBarrier(int32_t put_offset) override;
  void WaitForTokenInRange(int32_t start, int32_t end) override;
  void WaitForGetOffsetInRange(int32_t start, int32_t end) override;
  void SetGetBuffer(int32_t shm_id) override;
  scoped_refptr<gpu::Buffer> CreateTransferBuffer(size_t size,
                                                  int32_t* id) override;
  void DestroyTransferBuffer(int32_t id) override;

  // gpu::GpuControl implementation:
  gpu::Capabilities GetCapabilities() override;
  int32_t CreateImage(ClientBuffer buffer,
                      size_t width,
                      size_t height,
                      unsigned internalformat) override;
  void DestroyImage(int32_t id) override;
  int32_t CreateGpuMemoryBufferImage(size_t width,
                                     size_t height,
                                     unsigned internalformat,
                                     unsigned usage) override;
  uint32 InsertSyncPoint() override;
  uint32 InsertFutureSyncPoint() override;
  void RetireSyncPoint(uint32 sync_point) override;
  void SignalSyncPoint(uint32 sync_point,
                       const base::Closure& callback) override;
  void SignalQuery(uint32 query, const base::Closure& callback) override;
  void SetSurfaceVisible(bool visible) override;
  uint32 CreateStreamTexture(uint32 texture_id) override;
  void SetLock(base::Lock*) override;

 private:
  class SyncClientImpl;
  class SyncPointClientImpl;

  // mojo::CommandBufferLostContextObserver implementation:
  void DidLoseContext(int32_t lost_reason) override;

  void TryUpdateState();
  void MakeProgressAndUpdateState();

  gpu::CommandBufferSharedState* shared_state() const { return shared_state_; }

  CommandBufferDelegate* delegate_;
  mojo::Binding<mojo::CommandBufferLostContextObserver> observer_binding_;
  mojo::CommandBufferPtr command_buffer_;
  scoped_ptr<SyncClientImpl> sync_client_impl_;
  scoped_ptr<SyncPointClientImpl> sync_point_client_impl_;

  gpu::Capabilities capabilities_;
  State last_state_;
  mojo::ScopedSharedBufferHandle shared_state_handle_;
  gpu::CommandBufferSharedState* shared_state_;
  int32_t last_put_offset_;
  int32_t next_transfer_buffer_id_;

  const MojoAsyncWaiter* async_waiter_;
};

}  // gles2

#endif  // MOJO_GLES2_COMMAND_BUFFER_CLIENT_IMPL_H_
