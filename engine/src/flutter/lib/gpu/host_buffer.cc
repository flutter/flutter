// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/host_buffer.h"

#include <optional>

#include "dart_api.h"
#include "impeller/core/host_buffer.h"
#include "impeller/core/platform.h"
#include "third_party/tonic/typed_data/dart_byte_data.h"

namespace flutter {
namespace gpu {

IMPLEMENT_WRAPPERTYPEINFO(flutter_gpu, HostBuffer);

HostBuffer::HostBuffer(Context* context)
    : host_buffer_(impeller::HostBuffer::Create(
          context->GetContext()->GetResourceAllocator())) {}

HostBuffer::~HostBuffer() = default;

std::shared_ptr<impeller::HostBuffer> HostBuffer::GetBuffer() {
  return host_buffer_;
}

size_t HostBuffer::EmplaceBytes(const tonic::DartByteData& byte_data) {
  auto view =
      host_buffer_->Emplace(byte_data.data(), byte_data.length_in_bytes(),
                            impeller::DefaultUniformAlignment());
  emplacements_[current_offset_] = view;
  size_t previous_offset = current_offset_;
  current_offset_ += view.range.length;
  return previous_offset;
}

std::optional<impeller::BufferView> HostBuffer::GetBufferViewForOffset(
    size_t offset) {
  return emplacements_[offset];
}

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

void InternalFlutterGpu_HostBuffer_Initialize(Dart_Handle wrapper,
                                              flutter::gpu::Context* context) {
  auto res = fml::MakeRefCounted<flutter::gpu::HostBuffer>(context);
  res->AssociateWithDartWrapper(wrapper);
}

size_t InternalFlutterGpu_HostBuffer_EmplaceBytes(
    flutter::gpu::HostBuffer* wrapper,
    Dart_Handle byte_data) {
  return wrapper->EmplaceBytes(tonic::DartByteData(byte_data));
}
