// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_GPU_HOST_BUFFER_H_
#define FLUTTER_LIB_GPU_HOST_BUFFER_H_

#include "flutter/lib/gpu/export.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "impeller/core/buffer_view.h"
#include "impeller/core/host_buffer.h"
#include "lib/gpu/context.h"
#include "third_party/tonic/typed_data/dart_byte_data.h"

namespace flutter {
namespace gpu {

class HostBuffer : public RefCountedDartWrappable<HostBuffer> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(HostBuffer);

 public:
  explicit HostBuffer(Context* context);

  ~HostBuffer() override;

  std::shared_ptr<impeller::HostBuffer> GetBuffer();

  size_t EmplaceBytes(const tonic::DartByteData& byte_data);

  std::optional<impeller::BufferView> GetBufferViewForOffset(size_t offset);

 private:
  size_t current_offset_ = 0;
  std::shared_ptr<impeller::HostBuffer> host_buffer_;
  std::unordered_map<size_t, impeller::BufferView> emplacements_;

  FML_DISALLOW_COPY_AND_ASSIGN(HostBuffer);
};

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

extern "C" {

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_HostBuffer_Initialize(
    Dart_Handle wrapper,
    flutter::gpu::Context* context);

FLUTTER_GPU_EXPORT
extern size_t InternalFlutterGpu_HostBuffer_EmplaceBytes(
    flutter::gpu::HostBuffer* wrapper,
    Dart_Handle byte_data);

}  // extern "C"

#endif  // FLUTTER_LIB_GPU_HOST_BUFFER_H_
