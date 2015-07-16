// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/async_pixel_transfer_manager_sync.h"

#include "gpu/command_buffer/service/async_pixel_transfer_delegate.h"

namespace gpu {

// Class which handles async pixel transfers synchronously.
class AsyncPixelTransferDelegateSync : public AsyncPixelTransferDelegate {
 public:
  explicit AsyncPixelTransferDelegateSync(
      AsyncPixelTransferManagerSync::SharedState* shared_state);
  ~AsyncPixelTransferDelegateSync() override;

  // Implement AsyncPixelTransferDelegate:
  void AsyncTexImage2D(const AsyncTexImage2DParams& tex_params,
                       const AsyncMemoryParams& mem_params,
                       const base::Closure& bind_callback) override;
  void AsyncTexSubImage2D(const AsyncTexSubImage2DParams& tex_params,
                          const AsyncMemoryParams& mem_params) override;
  bool TransferIsInProgress() override;
  void WaitForTransferCompletion() override;

 private:
  // Safe to hold a raw pointer because SharedState is owned by the Manager
  // which owns the Delegate.
  AsyncPixelTransferManagerSync::SharedState* shared_state_;

  DISALLOW_COPY_AND_ASSIGN(AsyncPixelTransferDelegateSync);
};

AsyncPixelTransferDelegateSync::AsyncPixelTransferDelegateSync(
    AsyncPixelTransferManagerSync::SharedState* shared_state)
    : shared_state_(shared_state) {}

AsyncPixelTransferDelegateSync::~AsyncPixelTransferDelegateSync() {}

void AsyncPixelTransferDelegateSync::AsyncTexImage2D(
    const AsyncTexImage2DParams& tex_params,
    const AsyncMemoryParams& mem_params,
    const base::Closure& bind_callback) {
  // Save the define params to return later during deferred
  // binding of the transfer texture.
  void* data = mem_params.GetDataAddress();
  base::TimeTicks begin_time(base::TimeTicks::Now());
  glTexImage2D(
      tex_params.target,
      tex_params.level,
      tex_params.internal_format,
      tex_params.width,
      tex_params.height,
      tex_params.border,
      tex_params.format,
      tex_params.type,
      data);
  shared_state_->texture_upload_count++;
  shared_state_->total_texture_upload_time +=
      base::TimeTicks::Now() - begin_time;
  // The texture is already fully bound so just call it now.
  bind_callback.Run();
}

void AsyncPixelTransferDelegateSync::AsyncTexSubImage2D(
    const AsyncTexSubImage2DParams& tex_params,
    const AsyncMemoryParams& mem_params) {
  void* data = mem_params.GetDataAddress();
  base::TimeTicks begin_time(base::TimeTicks::Now());
  glTexSubImage2D(
      tex_params.target,
      tex_params.level,
      tex_params.xoffset,
      tex_params.yoffset,
      tex_params.width,
      tex_params.height,
      tex_params.format,
      tex_params.type,
      data);
  shared_state_->texture_upload_count++;
  shared_state_->total_texture_upload_time +=
      base::TimeTicks::Now() - begin_time;
}

bool AsyncPixelTransferDelegateSync::TransferIsInProgress() {
  // Already done.
  return false;
}

void AsyncPixelTransferDelegateSync::WaitForTransferCompletion() {
  // Already done.
}

AsyncPixelTransferManagerSync::SharedState::SharedState()
    : texture_upload_count(0) {}

AsyncPixelTransferManagerSync::SharedState::~SharedState() {}

AsyncPixelTransferManagerSync::AsyncPixelTransferManagerSync() {}

AsyncPixelTransferManagerSync::~AsyncPixelTransferManagerSync() {}

void AsyncPixelTransferManagerSync::BindCompletedAsyncTransfers() {
  // Everything is already bound.
}

void AsyncPixelTransferManagerSync::AsyncNotifyCompletion(
    const AsyncMemoryParams& mem_params,
    AsyncPixelTransferCompletionObserver* observer) {
  observer->DidComplete(mem_params);
}

uint32 AsyncPixelTransferManagerSync::GetTextureUploadCount() {
  return shared_state_.texture_upload_count;
}

base::TimeDelta AsyncPixelTransferManagerSync::GetTotalTextureUploadTime() {
  return shared_state_.total_texture_upload_time;
}

void AsyncPixelTransferManagerSync::ProcessMorePendingTransfers() {
}

bool AsyncPixelTransferManagerSync::NeedsProcessMorePendingTransfers() {
  return false;
}

void AsyncPixelTransferManagerSync::WaitAllAsyncTexImage2D() {
}

AsyncPixelTransferDelegate*
AsyncPixelTransferManagerSync::CreatePixelTransferDelegateImpl(
    gles2::TextureRef* ref,
    const AsyncTexImage2DParams& define_params) {
  return new AsyncPixelTransferDelegateSync(&shared_state_);
}

}  // namespace gpu
