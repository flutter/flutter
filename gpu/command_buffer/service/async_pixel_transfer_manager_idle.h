// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_ASYNC_PIXEL_TRANSFER_MANAGER_IDLE_H_
#define GPU_COMMAND_BUFFER_SERVICE_ASYNC_PIXEL_TRANSFER_MANAGER_IDLE_H_

#include <list>

#include "gpu/command_buffer/service/async_pixel_transfer_manager.h"

namespace gpu {

class AsyncPixelTransferManagerIdle : public AsyncPixelTransferManager {
 public:
  explicit AsyncPixelTransferManagerIdle(
      bool use_teximage2d_over_texsubimage2d);
  ~AsyncPixelTransferManagerIdle() override;

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

  struct Task {
    Task(uint64 transfer_id,
         AsyncPixelTransferDelegate* delegate,
         const base::Closure& task);
    ~Task();

    // This is non-zero if pixel transfer task.
    uint64 transfer_id;

    AsyncPixelTransferDelegate* delegate;

    base::Closure task;
  };

  // State shared between Managers and Delegates.
  struct SharedState {
    explicit SharedState(bool use_teximage2d_over_texsubimage2d);
    ~SharedState();
    void ProcessNotificationTasks();

    const bool use_teximage2d_over_texsubimage2d;
    int texture_upload_count;
    base::TimeDelta total_texture_upload_time;
    std::list<Task> tasks;
  };

 private:
  // AsyncPixelTransferManager implementation:
  AsyncPixelTransferDelegate* CreatePixelTransferDelegateImpl(
      gles2::TextureRef* ref,
      const AsyncTexImage2DParams& define_params) override;

  SharedState shared_state_;

  DISALLOW_COPY_AND_ASSIGN(AsyncPixelTransferManagerIdle);
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_ASYNC_PIXEL_TRANSFER_MANAGER_IDLE_H_
