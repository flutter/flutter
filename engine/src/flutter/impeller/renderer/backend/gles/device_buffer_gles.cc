// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/device_buffer_gles.h"

#include <cstring>
#include <memory>

#include "flutter/fml/trace_event.h"
#include "impeller/base/allocation.h"
#include "impeller/base/config.h"
#include "impeller/base/validation.h"

namespace impeller {

DeviceBufferGLES::DeviceBufferGLES(ReactorGLES::Ref reactor,
                                   std::shared_ptr<Allocation> backing_store,
                                   size_t size,
                                   StorageMode mode)
    : DeviceBuffer(size, mode),
      reactor_(std::move(reactor)),
      handle_(reactor_ ? reactor_->CreateHandle(HandleType::kBuffer)
                       : HandleGLES::DeadHandle()),
      backing_store_(std::move(backing_store)) {}

// |DeviceBuffer|
DeviceBufferGLES::~DeviceBufferGLES() {
  if (!handle_.IsDead()) {
    reactor_->CollectHandle(handle_);
  }
}

// |DeviceBuffer|
bool DeviceBufferGLES::CopyHostBuffer(const uint8_t* source,
                                      Range source_range,
                                      size_t offset) {
  if (mode_ != StorageMode::kHostVisible) {
    // One of the storage modes where a transfer queue must be used.
    return false;
  }

  if (!reactor_) {
    return false;
  }

  if (offset + source_range.length > size_) {
    // Out of bounds of this buffer.
    return false;
  }

  if (offset + source_range.length > backing_store_->GetLength()) {
    return false;
  }

  std::memmove(backing_store_->GetBuffer() + offset,
               source + source_range.offset, source_range.length);
  ++generation_;

  return true;
}

static GLenum ToTarget(DeviceBufferGLES::BindingType type) {
  switch (type) {
    case DeviceBufferGLES::BindingType::kArrayBuffer:
      return GL_ARRAY_BUFFER;
    case DeviceBufferGLES::BindingType::kElementArrayBuffer:
      return GL_ELEMENT_ARRAY_BUFFER;
  }
  FML_UNREACHABLE();
}

bool DeviceBufferGLES::BindAndUploadDataIfNecessary(BindingType type) const {
  if (!reactor_) {
    return false;
  }

  auto buffer = reactor_->GetGLHandle(handle_);
  if (!buffer.has_value()) {
    return false;
  }

  const auto target_type = ToTarget(type);
  const auto& gl = reactor_->GetProcTable();

  gl.BindBuffer(target_type, buffer.value());

  if (upload_generation_ != generation_) {
    TRACE_EVENT1("impeller", "BufferData", "Bytes",
                 std::to_string(backing_store_->GetLength()).c_str());
    gl.BufferData(target_type, backing_store_->GetLength(),
                  backing_store_->GetBuffer(), GL_STATIC_DRAW);
    upload_generation_ = generation_;
  }

  return true;
}

// |DeviceBuffer|
bool DeviceBufferGLES::SetLabel(const std::string& label) {
  reactor_->SetDebugLabel(handle_, label);
  return true;
}

// |DeviceBuffer|
bool DeviceBufferGLES::SetLabel(const std::string& label, Range range) {
  // Cannot support debug label on the range. Set the label for the entire
  // range.
  return SetLabel(label);
}

const uint8_t* DeviceBufferGLES::GetBufferData() const {
  return backing_store_->GetBuffer();
}
}  // namespace impeller
