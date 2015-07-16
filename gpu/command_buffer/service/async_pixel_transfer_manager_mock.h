// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_ASYNC_PIXEL_TRANSFER_MANAGER_TEST_H_
#define GPU_COMMAND_BUFFER_SERVICE_ASYNC_PIXEL_TRANSFER_MANAGER_TEST_H_

#include "gpu/command_buffer/service/async_pixel_transfer_manager.h"
#include "testing/gmock/include/gmock/gmock.h"

namespace gpu {

class MockAsyncPixelTransferManager : public AsyncPixelTransferManager {
 public:
  MockAsyncPixelTransferManager();
  virtual ~MockAsyncPixelTransferManager();

  // AsyncPixelTransferManager implementation:
  MOCK_METHOD0(BindCompletedAsyncTransfers, void());
  MOCK_METHOD2(AsyncNotifyCompletion,
      void(const AsyncMemoryParams& mem_params,
           AsyncPixelTransferCompletionObserver* observer));
  MOCK_METHOD0(GetTextureUploadCount, uint32());
  MOCK_METHOD0(GetTotalTextureUploadTime, base::TimeDelta());
  MOCK_METHOD0(ProcessMorePendingTransfers, void());
  MOCK_METHOD0(NeedsProcessMorePendingTransfers, bool());
  MOCK_METHOD0(WaitAllAsyncTexImage2D, void());
  MOCK_METHOD2(
      CreatePixelTransferDelegateImpl,
      AsyncPixelTransferDelegate*(gles2::TextureRef* ref,
                                  const AsyncTexImage2DParams& define_params));

 private:
  DISALLOW_COPY_AND_ASSIGN(MockAsyncPixelTransferManager);
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_ASYNC_PIXEL_TRANSFER_MANAGER_TEST_H_
