// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/lib/gpu/export.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "impeller/core/host_buffer.h"
#include "third_party/tonic/typed_data/dart_byte_data.h"

namespace flutter {

class HostBuffer : public RefCountedDartWrappable<HostBuffer> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(HostBuffer);

 public:
  explicit HostBuffer();

  ~HostBuffer() override;

  size_t EmplaceBytes(const tonic::DartByteData& byte_data);

 private:
  std::shared_ptr<impeller::HostBuffer> host_buffer_;

  FML_DISALLOW_COPY_AND_ASSIGN(HostBuffer);
};

}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

extern "C" {

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_HostBuffer_Initialize(Dart_Handle wrapper);

FLUTTER_GPU_EXPORT
extern size_t InternalFlutterGpu_HostBuffer_EmplaceBytes(
    flutter::HostBuffer* wrapper,
    Dart_Handle byte_data);

}  // extern "C"
