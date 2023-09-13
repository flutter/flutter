// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <stdint.h>

#include "flutter/impeller/core/allocator.h"
#include "flutter/impeller/core/device_buffer.h"
#include "flutter/impeller/core/formats.h"
#include "flutter/impeller/geometry/size.h"
#include "flutter/lib/ui/painting/image_decoder.h"
#include "flutter/lib/ui/painting/image_decoder_impeller.h"
#include "flutter/testing/testing.h"

namespace impeller {

class TestImpellerTexture : public Texture {
 public:
  explicit TestImpellerTexture(TextureDescriptor desc) : Texture(desc) {}

  void SetLabel(std::string_view label) override {}
  bool IsValid() const override { return true; }
  ISize GetSize() const { return GetTextureDescriptor().size; }

  bool OnSetContents(const uint8_t* contents, size_t length, size_t slice) {
    return true;
  }
  bool OnSetContents(std::shared_ptr<const fml::Mapping> mapping,
                     size_t slice) {
    return true;
  }
};

class TestImpellerDeviceBuffer : public DeviceBuffer {
 public:
  explicit TestImpellerDeviceBuffer(DeviceBufferDescriptor desc)
      : DeviceBuffer(desc) {
    bytes_ = static_cast<uint8_t*>(malloc(desc.size));
  }

  ~TestImpellerDeviceBuffer() { free(bytes_); }

 private:
  std::shared_ptr<Texture> AsTexture(Allocator& allocator,
                                     const TextureDescriptor& descriptor,
                                     uint16_t row_bytes) const override {
    return nullptr;
  }

  bool SetLabel(const std::string& label) override { return true; }

  bool SetLabel(const std::string& label, Range range) override { return true; }

  uint8_t* OnGetContents() const override { return bytes_; }

  bool OnCopyHostBuffer(const uint8_t* source,
                        Range source_range,
                        size_t offset) override {
    for (auto i = source_range.offset; i < source_range.length; i++, offset++) {
      bytes_[offset] = source[i];
    }
    return true;
  }

  uint8_t* bytes_;
};

class TestImpellerAllocator : public impeller::Allocator {
 public:
  TestImpellerAllocator() {}

  ~TestImpellerAllocator() = default;

 private:
  uint16_t MinimumBytesPerRow(PixelFormat format) const override { return 0; }

  ISize GetMaxTextureSizeSupported() const override {
    return ISize{2048, 2048};
  }

  std::shared_ptr<DeviceBuffer> OnCreateBuffer(
      const DeviceBufferDescriptor& desc) override {
    return std::make_shared<TestImpellerDeviceBuffer>(desc);
  }

  std::shared_ptr<Texture> OnCreateTexture(
      const TextureDescriptor& desc) override {
    return std::make_shared<TestImpellerTexture>(desc);
  }
};

}  // namespace impeller

namespace flutter {
namespace testing {

float HalfToFloat(uint16_t half);
float DecodeBGR10(uint32_t x);
sk_sp<SkData> OpenFixtureAsSkData(const char* name);

}  // namespace testing
}  // namespace flutter
