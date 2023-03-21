// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/blit_command_mtl.h"

#include "impeller/renderer/backend/metal/device_buffer_mtl.h"
#include "impeller/renderer/backend/metal/texture_mtl.h"

namespace impeller {

BlitEncodeMTL::~BlitEncodeMTL() = default;

BlitCopyTextureToTextureCommandMTL::~BlitCopyTextureToTextureCommandMTL() =
    default;

std::string BlitCopyTextureToTextureCommandMTL::GetLabel() const {
  return label;
}

bool BlitCopyTextureToTextureCommandMTL::Encode(
    id<MTLBlitCommandEncoder> encoder) const {
  auto source_mtl = TextureMTL::Cast(*source).GetMTLTexture();
  if (!source_mtl) {
    return false;
  }

  auto destination_mtl = TextureMTL::Cast(*destination).GetMTLTexture();
  if (!destination_mtl) {
    return false;
  }

  auto source_origin_mtl =
      MTLOriginMake(source_region.origin.x, source_region.origin.y, 0);
  auto source_size_mtl =
      MTLSizeMake(source_region.size.width, source_region.size.height, 1);
  auto destination_origin_mtl =
      MTLOriginMake(destination_origin.x, destination_origin.y, 0);

  [encoder copyFromTexture:source_mtl
               sourceSlice:0
               sourceLevel:0
              sourceOrigin:source_origin_mtl
                sourceSize:source_size_mtl
                 toTexture:destination_mtl
          destinationSlice:0
          destinationLevel:0
         destinationOrigin:destination_origin_mtl];

  return true;
};

BlitCopyTextureToBufferCommandMTL::~BlitCopyTextureToBufferCommandMTL() =
    default;

std::string BlitCopyTextureToBufferCommandMTL::GetLabel() const {
  return label;
}

bool BlitCopyTextureToBufferCommandMTL::Encode(
    id<MTLBlitCommandEncoder> encoder) const {
  auto source_mtl = TextureMTL::Cast(*source).GetMTLTexture();
  if (!source_mtl) {
    return false;
  }

  auto destination_mtl = DeviceBufferMTL::Cast(*destination).GetMTLBuffer();
  if (!destination_mtl) {
    return false;
  }

  auto source_origin_mtl =
      MTLOriginMake(source_region.origin.x, source_region.origin.y, 0);
  auto source_size_mtl =
      MTLSizeMake(source_region.size.width, source_region.size.height, 1);

  auto destination_bytes_per_pixel =
      BytesPerPixelForPixelFormat(source->GetTextureDescriptor().format);
  auto destination_bytes_per_row =
      source_size_mtl.width * destination_bytes_per_pixel;
  auto destination_bytes_per_image =
      source_size_mtl.height * destination_bytes_per_row;

  [encoder copyFromTexture:source_mtl
                   sourceSlice:0
                   sourceLevel:0
                  sourceOrigin:source_origin_mtl
                    sourceSize:source_size_mtl
                      toBuffer:destination_mtl
             destinationOffset:destination_offset
        destinationBytesPerRow:destination_bytes_per_row
      destinationBytesPerImage:destination_bytes_per_image];

  return true;
};

BlitCopyBufferToTextureCommandMTL::~BlitCopyBufferToTextureCommandMTL() =
    default;

std::string BlitCopyBufferToTextureCommandMTL::GetLabel() const {
  return label;
}

bool BlitCopyBufferToTextureCommandMTL::Encode(
    id<MTLBlitCommandEncoder> encoder) const {
  auto source_mtl = DeviceBufferMTL::Cast(*source.buffer).GetMTLBuffer();
  if (!source_mtl) {
    return false;
  }

  auto destination_mtl = TextureMTL::Cast(*destination).GetMTLTexture();
  if (!destination_mtl) {
    return false;
  }

  auto destination_origin_mtl =
      MTLOriginMake(destination_origin.x, destination_origin.y, 0);

  auto image_size = destination->GetTextureDescriptor().size;
  auto source_size_mtl = MTLSizeMake(image_size.width, image_size.height, 1);

  auto destination_bytes_per_pixel =
      BytesPerPixelForPixelFormat(destination->GetTextureDescriptor().format);
  auto destination_bytes_per_row =
      source_size_mtl.width * destination_bytes_per_pixel;
  auto destination_bytes_per_image =
      source_size_mtl.height * destination_bytes_per_row;

  [encoder copyFromBuffer:source_mtl
             sourceOffset:source.range.offset
        sourceBytesPerRow:destination_bytes_per_row
      sourceBytesPerImage:destination_bytes_per_image
               sourceSize:source_size_mtl
                toTexture:destination_mtl
         destinationSlice:0
         destinationLevel:0
        destinationOrigin:destination_origin_mtl];

  return true;
};

BlitGenerateMipmapCommandMTL::~BlitGenerateMipmapCommandMTL() = default;

std::string BlitGenerateMipmapCommandMTL::GetLabel() const {
  return label;
}

bool BlitGenerateMipmapCommandMTL::Encode(
    id<MTLBlitCommandEncoder> encoder) const {
  auto texture_mtl = TextureMTL::Cast(*texture).GetMTLTexture();
  if (!texture_mtl) {
    return false;
  }

  [encoder generateMipmapsForTexture:texture_mtl];

  return true;
};

}  // namespace impeller
