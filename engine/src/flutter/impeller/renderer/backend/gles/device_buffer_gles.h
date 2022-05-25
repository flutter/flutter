// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/base/allocation.h"
#include "impeller/base/backend_cast.h"
#include "impeller/renderer/backend/gles/reactor_gles.h"
#include "impeller/renderer/device_buffer.h"

namespace impeller {

class DeviceBufferGLES final
    : public DeviceBuffer,
      public BackendCast<DeviceBufferGLES, DeviceBuffer> {
 public:
  DeviceBufferGLES(ReactorGLES::Ref reactor,
                   std::shared_ptr<Allocation> buffer,
                   size_t size,
                   StorageMode mode);

  // |DeviceBuffer|
  ~DeviceBufferGLES() override;

  const uint8_t* GetBufferData() const;

  enum class BindingType {
    kArrayBuffer,
    kElementArrayBuffer,
  };

  [[nodiscard]] bool BindAndUploadDataIfNecessary(BindingType type) const;

 private:
  ReactorGLES::Ref reactor_;
  HandleGLES handle_;
  mutable std::shared_ptr<Allocation> backing_store_;
  mutable uint32_t generation_ = 0;
  mutable uint32_t upload_generation_ = 0;

  // |DeviceBuffer|
  bool CopyHostBuffer(const uint8_t* source,
                      Range source_range,
                      size_t offset) override;

  // |DeviceBuffer|
  bool SetLabel(const std::string& label) override;

  // |DeviceBuffer|
  bool SetLabel(const std::string& label, Range range) override;

  FML_DISALLOW_COPY_AND_ASSIGN(DeviceBufferGLES);
};

}  // namespace impeller
