// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/async_pixel_transfer_delegate.h"

namespace gpu {

AsyncMemoryParams::AsyncMemoryParams(scoped_refptr<Buffer> buffer,
                    uint32 data_offset,
                    uint32 data_size)
    : buffer_(buffer), data_offset_(data_offset), data_size_(data_size) {
  DCHECK(buffer_.get());
  DCHECK(buffer_->memory());
}

AsyncMemoryParams::~AsyncMemoryParams() {
}

AsyncPixelTransferUploadStats::AsyncPixelTransferUploadStats()
    : texture_upload_count_(0) {}

AsyncPixelTransferUploadStats::~AsyncPixelTransferUploadStats() {}

void AsyncPixelTransferUploadStats::AddUpload(base::TimeDelta transfer_time) {
  base::AutoLock scoped_lock(lock_);
  texture_upload_count_++;
  total_texture_upload_time_ += transfer_time;
}

int AsyncPixelTransferUploadStats::GetStats(
    base::TimeDelta* total_texture_upload_time) {
  base::AutoLock scoped_lock(lock_);
  if (total_texture_upload_time)
    *total_texture_upload_time = total_texture_upload_time_;
  return texture_upload_count_;
}

AsyncPixelTransferDelegate::AsyncPixelTransferDelegate() {}

AsyncPixelTransferDelegate::~AsyncPixelTransferDelegate() {}

}  // namespace gpu
