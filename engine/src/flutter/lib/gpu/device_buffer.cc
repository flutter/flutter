// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/device_buffer.h"

#include "dart_api.h"
#include "flutter/lib/gpu/formats.h"
#include "fml/mapping.h"
#include "impeller/core/device_buffer.h"
#include "impeller/core/device_buffer_descriptor.h"
#include "impeller/core/formats.h"
#include "impeller/core/range.h"
#include "third_party/tonic/typed_data/dart_byte_data.h"
#include "tonic/converter/dart_converter.h"

namespace flutter {
namespace gpu {

IMPLEMENT_WRAPPERTYPEINFO(flutter_gpu, DeviceBuffer);

DeviceBuffer::DeviceBuffer(
    std::shared_ptr<impeller::DeviceBuffer> device_buffer)
    : device_buffer_(std::move(device_buffer)) {}

DeviceBuffer::~DeviceBuffer() = default;

std::shared_ptr<impeller::DeviceBuffer> DeviceBuffer::GetBuffer() {
  return device_buffer_;
}

bool DeviceBuffer::Overwrite(const tonic::DartByteData& source_bytes,
                             size_t destination_offset_in_bytes) {
  if (!device_buffer_->CopyHostBuffer(
          reinterpret_cast<const uint8_t*>(source_bytes.data()),
          impeller::Range(0, source_bytes.length_in_bytes()),
          destination_offset_in_bytes)) {
    return false;
  }
  return true;
}

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

bool InternalFlutterGpu_DeviceBuffer_Initialize(
    Dart_Handle wrapper,
    flutter::gpu::Context* gpu_context,
    int storage_mode,
    int size_in_bytes) {
  impeller::DeviceBufferDescriptor desc;
  desc.storage_mode = flutter::gpu::ToImpellerStorageMode(storage_mode);
  desc.size = size_in_bytes;
  auto device_buffer =
      gpu_context->GetContext().GetResourceAllocator()->CreateBuffer(desc);
  if (!device_buffer) {
    FML_LOG(ERROR) << "Failed to create device buffer.";
    return false;
  }

  auto res =
      fml::MakeRefCounted<flutter::gpu::DeviceBuffer>(std::move(device_buffer));
  res->AssociateWithDartWrapper(wrapper);

  return true;
}

bool InternalFlutterGpu_DeviceBuffer_InitializeWithHostData(
    Dart_Handle wrapper,
    flutter::gpu::Context* gpu_context,
    Dart_Handle byte_data) {
  std::shared_ptr<impeller::DeviceBuffer> device_buffer = nullptr;
  {
    // `DartByteData` gets raw pointers into the Dart heap via
    // `Dart_TypedDataAcquireData`. So it must be destructed before
    // `AssociateWithDartWrapper` is called, which mutates the heap.
    auto data = tonic::DartByteData(byte_data);
    auto mapping = fml::NonOwnedMapping(reinterpret_cast<uint8_t*>(data.data()),
                                        data.length_in_bytes());
    device_buffer =
        gpu_context->GetContext().GetResourceAllocator()->CreateBufferWithCopy(
            mapping);
  }
  if (!device_buffer) {
    FML_LOG(ERROR) << "Failed to create device buffer with copy.";
    return false;
  }

  auto res =
      fml::MakeRefCounted<flutter::gpu::DeviceBuffer>(std::move(device_buffer));
  res->AssociateWithDartWrapper(wrapper);

  return true;
}

bool InternalFlutterGpu_DeviceBuffer_Overwrite(
    flutter::gpu::DeviceBuffer* device_buffer,
    Dart_Handle source_byte_data,
    int destination_offset_in_bytes) {
  return device_buffer->Overwrite(tonic::DartByteData(source_byte_data),
                                  destination_offset_in_bytes);
}

bool InternalFlutterGpu_DeviceBuffer_Flush(
    flutter::gpu::DeviceBuffer* device_buffer,
    int offset_in_bytes,
    int size_in_bytes) {
  const size_t buffer_size =
      device_buffer->GetBuffer()->GetDeviceBufferDescriptor().size;
  // Same bounds as DeviceBuffer.flush in Dart: the offset must be inside the
  // buffer.
  if (offset_in_bytes < 0 ||
      static_cast<size_t>(offset_in_bytes) >= buffer_size) {
    return false;
  }
  const size_t offset = static_cast<size_t>(offset_in_bytes);
  // A negative length (the Dart default is -1) flushes to the end of the
  // buffer. Passing it through would make a range of SIZE_MAX bytes.
  const size_t length = size_in_bytes < 0 ? buffer_size - offset
                                          : static_cast<size_t>(size_in_bytes);
  if (length > buffer_size - offset) {
    return false;
  }
  device_buffer->GetBuffer()->Flush(impeller::Range(offset, length));
  return true;
}
