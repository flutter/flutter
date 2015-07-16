// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_IMAGE_FACTORY_H_
#define GPU_COMMAND_BUFFER_SERVICE_IMAGE_FACTORY_H_

#include "base/memory/ref_counted.h"
#include "gpu/gpu_export.h"
#include "ui/gfx/geometry/size.h"
#include "ui/gfx/gpu_memory_buffer.h"

namespace gfx {
class GLImage;
}

namespace gpu {
struct Capabilities;

class GPU_EXPORT ImageFactory {
 public:
  ImageFactory();

  // Returns a valid GpuMemoryBuffer format given a valid internalformat as
  // defined by CHROMIUM_gpu_memory_buffer_image.
  static gfx::GpuMemoryBuffer::Format ImageFormatToGpuMemoryBufferFormat(
      unsigned internalformat);

  // Returns a valid GpuMemoryBuffer usage given a valid usage as defined by
  // CHROMIUM_gpu_memory_buffer_image.
  static gfx::GpuMemoryBuffer::Usage ImageUsageToGpuMemoryBufferUsage(
      unsigned usage);

  // Returns true if |internalformat| is compatible with |format|.
  static bool IsImageFormatCompatibleWithGpuMemoryBufferFormat(
      unsigned internalformat,
      gfx::GpuMemoryBuffer::Format format);

  // Returns true if |format| is supported by |capabilities|.
  static bool IsGpuMemoryBufferFormatSupported(
      gfx::GpuMemoryBuffer::Format format,
      const Capabilities& capabilities);

  // Returns true if |size| is valid for |format|.
  static bool IsImageSizeValidForGpuMemoryBufferFormat(
      const gfx::Size& size,
      gfx::GpuMemoryBuffer::Format format);

  // Creates a GLImage instance for GPU memory buffer identified by |handle|.
  // |client_id| should be set to the client requesting the creation of instance
  // and can be used by factory implementation to verify access rights.
  virtual scoped_refptr<gfx::GLImage> CreateImageForGpuMemoryBuffer(
      const gfx::GpuMemoryBufferHandle& handle,
      const gfx::Size& size,
      gfx::GpuMemoryBuffer::Format format,
      unsigned internalformat,
      int client_id) = 0;

 protected:
  virtual ~ImageFactory();
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_IMAGE_FACTORY_H_
