// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/host_buffer.h"

#include "impeller/core/host_buffer.h"
#include "impeller/core/platform.h"
#include "third_party/tonic/typed_data/dart_byte_data.h"

namespace flutter {

IMPLEMENT_WRAPPERTYPEINFO(gpu, HostBuffer);

HostBuffer::HostBuffer() : host_buffer_(impeller::HostBuffer::Create()) {}

HostBuffer::~HostBuffer() = default;

size_t HostBuffer::EmplaceBytes(const tonic::DartByteData& byte_data) {
  auto view =
      host_buffer_->Emplace(byte_data.data(), byte_data.length_in_bytes(),
                            impeller::DefaultUniformAlignment());
  return view.range.offset;
}

}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

void InternalFlutterGpu_HostBuffer_Initialize(Dart_Handle wrapper) {
  auto res = fml::MakeRefCounted<flutter::HostBuffer>();
  res->AssociateWithDartWrapper(wrapper);
}

size_t InternalFlutterGpu_HostBuffer_EmplaceBytes(flutter::HostBuffer* wrapper,
                                                  Dart_Handle byte_data) {
  return wrapper->EmplaceBytes(tonic::DartByteData(byte_data));
}
