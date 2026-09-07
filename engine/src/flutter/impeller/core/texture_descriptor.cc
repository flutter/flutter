// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/core/texture_descriptor.h"

#include <sstream>

#include "third_party/abseil-cpp/absl/strings/str_cat.h"

namespace impeller {

absl::Status TextureDescriptor::Validate() const {
  if (format == PixelFormat::kUnknown) {
    return absl::InvalidArgumentError("A pixel format must be specified.");
  }
  if (size.IsEmpty()) {
    return absl::InvalidArgumentError(absl::StrCat(
        "The size ", size.width, "x", size.height, " must be nonempty."));
  }
  if (mip_count < 1u) {
    return absl::InvalidArgumentError("The mip count must be at least one.");
  }
  if (type == TextureType::kTexture2DArray && array_layer_count < 1u) {
    return absl::InvalidArgumentError(
        "A 2D array texture must have at least one layer.");
  }
  if (!SamplingOptionsAreValid()) {
    return absl::InvalidArgumentError(absl::StrCat(
        "The sample count ", static_cast<uint64_t>(sample_count),
        " is not valid for the texture type ", TextureTypeToString(type), "."));
  }
  return absl::OkStatus();
}

std::string TextureDescriptorToString(const TextureDescriptor& desc) {
  std::stringstream stream;
  stream << "StorageMode=" << StorageModeToString(desc.storage_mode) << ",";
  stream << "Type=" << TextureTypeToString(desc.type) << ",";
  stream << "Format=" << PixelFormatToString(desc.format) << ",";
  stream << "Size=" << desc.size << ",";
  stream << "MipCount=" << desc.mip_count << ",";
  stream << "SampleCount=" << static_cast<size_t>(desc.sample_count) << ",";
  stream << "Compression=" << CompressionTypeToString(desc.compression_type);
  return stream.str();
}

}  // namespace impeller
