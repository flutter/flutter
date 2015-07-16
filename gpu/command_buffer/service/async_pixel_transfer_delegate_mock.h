// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_ASYNC_PIXEL_TRANSFER_DELEGATE_MOCK
#define GPU_COMMAND_BUFFER_SERVICE_ASYNC_PIXEL_TRANSFER_DELEGATE_MOCK

#include "base/basictypes.h"
#include "gpu/command_buffer/service/async_pixel_transfer_delegate.h"
#include "testing/gmock/include/gmock/gmock.h"

namespace gpu {

class MockAsyncPixelTransferDelegate : public AsyncPixelTransferDelegate {
 public:
  MockAsyncPixelTransferDelegate();
  virtual ~MockAsyncPixelTransferDelegate();

  // Called in ~MockAsyncPixelTransferDelegate.
  MOCK_METHOD0(Destroy, void());

  // Implement AsyncPixelTransferDelegate.
  MOCK_METHOD3(AsyncTexImage2D,
               void(const AsyncTexImage2DParams& tex_params,
                    const AsyncMemoryParams& mem_params,
                    const base::Closure& bind_callback));
  MOCK_METHOD2(AsyncTexSubImage2D,
               void(const AsyncTexSubImage2DParams& tex_params,
                    const AsyncMemoryParams& mem_params));
  MOCK_METHOD0(TransferIsInProgress, bool());
  MOCK_METHOD0(WaitForTransferCompletion, void());

 private:
  DISALLOW_COPY_AND_ASSIGN(MockAsyncPixelTransferDelegate);
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_ASYNC_PIXEL_TRANSFER_DELEGATE_MOCK
