// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/async_pixel_transfer_manager_stub.h"

#include "gpu/command_buffer/service/async_pixel_transfer_delegate.h"

namespace gpu {

class AsyncPixelTransferDelegateStub : public AsyncPixelTransferDelegate {
 public:
  AsyncPixelTransferDelegateStub();
  ~AsyncPixelTransferDelegateStub() override;

  // Implement AsyncPixelTransferDelegate:
  void AsyncTexImage2D(const AsyncTexImage2DParams& tex_params,
                       const AsyncMemoryParams& mem_params,
                       const base::Closure& bind_callback) override;
  void AsyncTexSubImage2D(const AsyncTexSubImage2DParams& tex_params,
                          const AsyncMemoryParams& mem_params) override;
  bool TransferIsInProgress() override;
  void WaitForTransferCompletion() override;

 private:
  DISALLOW_COPY_AND_ASSIGN(AsyncPixelTransferDelegateStub);
};

AsyncPixelTransferDelegateStub::AsyncPixelTransferDelegateStub() {}

AsyncPixelTransferDelegateStub::~AsyncPixelTransferDelegateStub() {}

void AsyncPixelTransferDelegateStub::AsyncTexImage2D(
    const AsyncTexImage2DParams& tex_params,
    const AsyncMemoryParams& mem_params,
    const base::Closure& bind_callback) {
  bind_callback.Run();
}

void AsyncPixelTransferDelegateStub::AsyncTexSubImage2D(
    const AsyncTexSubImage2DParams& tex_params,
    const AsyncMemoryParams& mem_params) {
}

bool AsyncPixelTransferDelegateStub::TransferIsInProgress() {
  return false;
}

void AsyncPixelTransferDelegateStub::WaitForTransferCompletion() {}

AsyncPixelTransferManagerStub::AsyncPixelTransferManagerStub() {}

AsyncPixelTransferManagerStub::~AsyncPixelTransferManagerStub() {}

void AsyncPixelTransferManagerStub::BindCompletedAsyncTransfers() {
}

void AsyncPixelTransferManagerStub::AsyncNotifyCompletion(
    const AsyncMemoryParams& mem_params,
    AsyncPixelTransferCompletionObserver* observer) {
  observer->DidComplete(mem_params);
}

uint32 AsyncPixelTransferManagerStub::GetTextureUploadCount() {
  return 0;
}

base::TimeDelta AsyncPixelTransferManagerStub::GetTotalTextureUploadTime() {
  return base::TimeDelta();
}

void AsyncPixelTransferManagerStub::ProcessMorePendingTransfers() {
}

bool AsyncPixelTransferManagerStub::NeedsProcessMorePendingTransfers() {
  return false;
}

void AsyncPixelTransferManagerStub::WaitAllAsyncTexImage2D() {
}

AsyncPixelTransferDelegate*
AsyncPixelTransferManagerStub::CreatePixelTransferDelegateImpl(
    gles2::TextureRef* ref,
    const AsyncTexImage2DParams& define_params) {
  return new AsyncPixelTransferDelegateStub();
}

}  // namespace gpu
