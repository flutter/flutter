// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GL_IMAGE_LINUX_DMA_BUFFER_H_
#define UI_GL_GL_IMAGE_LINUX_DMA_BUFFER_H_

#include "ui/gfx/gpu_memory_buffer.h"
#include "ui/gl/gl_image_egl.h"

namespace gfx {

class GL_EXPORT GLImageLinuxDMABuffer : public GLImageEGL {
 public:
  GLImageLinuxDMABuffer(const gfx::Size& size, unsigned internalformat);

  // Returns true on success and the file descriptor can be closed as the
  // implementation will take a reference to the dma_buf.
  bool Initialize(const base::FileDescriptor& handle,
                  gfx::GpuMemoryBuffer::Format format,
                  int pitch);

 protected:
  ~GLImageLinuxDMABuffer() override;

 private:
  unsigned internalformat_;

  DISALLOW_COPY_AND_ASSIGN(GLImageLinuxDMABuffer);
};

}  // namespace gfx

#endif  // UI_GL_GL_IMAGE_LINUX_DMA_BUFFER_H_
