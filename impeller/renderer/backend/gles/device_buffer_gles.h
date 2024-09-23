// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_DEVICE_BUFFER_GLES_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_DEVICE_BUFFER_GLES_H_

#include <cstdint>
#include <memory>

#include "impeller/base/allocation.h"
#include "impeller/base/backend_cast.h"
#include "impeller/core/device_buffer.h"
#include "impeller/renderer/backend/gles/reactor_gles.h"

namespace impeller {

class DeviceBufferGLES final
    : public DeviceBuffer,
      public BackendCast<DeviceBufferGLES, DeviceBuffer> {
 public:
  DeviceBufferGLES(DeviceBufferDescriptor desc,
                   ReactorGLES::Ref reactor,
                   std::shared_ptr<Allocation> backing_store);

  // |DeviceBuffer|
  ~DeviceBufferGLES() override;

  const uint8_t* GetBufferData() const;

  void UpdateBufferData(
      const std::function<void(uint8_t*, size_t length)>& update_buffer_data);

  enum class BindingType {
    kArrayBuffer,
    kElementArrayBuffer,
  };

  [[nodiscard]] bool BindAndUploadDataIfNecessary(BindingType type) const;

  void Flush(std::optional<Range> range = std::nullopt) const override;

 private:
  ReactorGLES::Ref reactor_;
  HandleGLES handle_;
  mutable std::shared_ptr<Allocation> backing_store_;
  mutable std::optional<Range> dirty_range_ = std::nullopt;
  mutable bool initialized_ = false;

  // |DeviceBuffer|
  uint8_t* OnGetContents() const override;

  // |DeviceBuffer|
  bool OnCopyHostBuffer(const uint8_t* source,
                        Range source_range,
                        size_t offset) override;

  // |DeviceBuffer|
  bool SetLabel(const std::string& label) override;

  // |DeviceBuffer|
  bool SetLabel(const std::string& label, Range range) override;

  DeviceBufferGLES(const DeviceBufferGLES&) = delete;

  DeviceBufferGLES& operator=(const DeviceBufferGLES&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_DEVICE_BUFFER_GLES_H_
