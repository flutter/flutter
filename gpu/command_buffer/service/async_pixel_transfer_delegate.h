// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_ASYNC_PIXEL_TRANSFER_DELEGATE_H_
#define GPU_COMMAND_BUFFER_SERVICE_ASYNC_PIXEL_TRANSFER_DELEGATE_H_

#include "base/basictypes.h"
#include "base/callback.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "base/synchronization/lock.h"
#include "base/time/time.h"
#include "gpu/command_buffer/common/buffer.h"
#include "gpu/gpu_export.h"
#include "ui/gl/gl_bindings.h"

namespace base {
class SharedMemory;
}

namespace gpu {

struct AsyncTexImage2DParams {
  GLenum target;
  GLint level;
  GLenum internal_format;
  GLsizei width;
  GLsizei height;
  GLint border;
  GLenum format;
  GLenum type;
};

struct AsyncTexSubImage2DParams {
  GLenum target;
  GLint level;
  GLint xoffset;
  GLint yoffset;
  GLsizei width;
  GLsizei height;
  GLenum format;
  GLenum type;
};

class AsyncMemoryParams {
 public:
  AsyncMemoryParams(scoped_refptr<Buffer> buffer,
                    uint32 data_offset,
                    uint32 data_size);
  ~AsyncMemoryParams();

  scoped_refptr<Buffer> buffer() const { return buffer_; }
  uint32 data_size() const { return data_size_; }
  uint32 data_offset() const { return data_offset_; }
  void* GetDataAddress() const {
    return buffer_->GetDataAddress(data_offset_, data_size_);
  }

 private:
  scoped_refptr<Buffer> buffer_;
  uint32 data_offset_;
  uint32 data_size_;
};

class AsyncPixelTransferUploadStats
    : public base::RefCountedThreadSafe<AsyncPixelTransferUploadStats> {
 public:
  AsyncPixelTransferUploadStats();

  void AddUpload(base::TimeDelta transfer_time);
  int GetStats(base::TimeDelta* total_texture_upload_time);

 private:
  friend class base::RefCountedThreadSafe<AsyncPixelTransferUploadStats>;

  ~AsyncPixelTransferUploadStats();

  int texture_upload_count_;
  base::TimeDelta total_texture_upload_time_;
  base::Lock lock_;

  DISALLOW_COPY_AND_ASSIGN(AsyncPixelTransferUploadStats);
};

class GPU_EXPORT AsyncPixelTransferDelegate {
 public:
  virtual ~AsyncPixelTransferDelegate();

  // The callback occurs on the caller thread, once the texture is
  // safe/ready to be used.
  virtual void AsyncTexImage2D(
      const AsyncTexImage2DParams& tex_params,
      const AsyncMemoryParams& mem_params,
      const base::Closure& bind_callback) = 0;

  virtual void AsyncTexSubImage2D(
      const AsyncTexSubImage2DParams& tex_params,
      const AsyncMemoryParams& mem_params) = 0;

  // Returns true if there is a transfer in progress.
  virtual bool TransferIsInProgress() = 0;

  // Block until the specified transfer completes.
  virtual void WaitForTransferCompletion() = 0;

 protected:
  AsyncPixelTransferDelegate();

 private:
  DISALLOW_COPY_AND_ASSIGN(AsyncPixelTransferDelegate);
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_ASYNC_PIXEL_TRANSFER_DELEGATE_H_

