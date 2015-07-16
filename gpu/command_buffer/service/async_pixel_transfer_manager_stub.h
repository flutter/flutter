// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_ASYNC_PIXEL_TRANSFER_MANAGER_STUB_H_
#define GPU_COMMAND_BUFFER_SERVICE_ASYNC_PIXEL_TRANSFER_MANAGER_STUB_H_

#include "gpu/command_buffer/service/async_pixel_transfer_manager.h"

namespace gpu {

class AsyncPixelTransferManagerStub : public AsyncPixelTransferManager {
 public:
  AsyncPixelTransferManagerStub();
  ~AsyncPixelTransferManagerStub() override;

  // AsyncPixelTransferManager implementation:
  void BindCompletedAsyncTransfers() override;
  void AsyncNotifyCompletion(
      const AsyncMemoryParams& mem_params,
      AsyncPixelTransferCompletionObserver* observer) override;
  uint32 GetTextureUploadCount() override;
  base::TimeDelta GetTotalTextureUploadTime() override;
  void ProcessMorePendingTransfers() override;
  bool NeedsProcessMorePendingTransfers() override;
  void WaitAllAsyncTexImage2D() override;

 private:
  // AsyncPixelTransferManager implementation:
  AsyncPixelTransferDelegate* CreatePixelTransferDelegateImpl(
      gles2::TextureRef* ref,
      const AsyncTexImage2DParams& define_params) override;

  DISALLOW_COPY_AND_ASSIGN(AsyncPixelTransferManagerStub);
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_ASYNC_PIXEL_TRANSFER_MANAGER_STUB_H_
