// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_MEDIA_COMMON_CPP_VIDEO_CONVERTER_H_
#define MOJO_SERVICES_MEDIA_COMMON_CPP_VIDEO_CONVERTER_H_

#include <memory>

#include "mojo/services/geometry/interfaces/geometry.mojom.h"
#include "mojo/services/media/common/cpp/video_packet_layout.h"

namespace mojo {
namespace media {

class VideoConverter {
 public:
  VideoConverter();

  ~VideoConverter();

  // Sets the media type of the frames to be converted. 8-bit interleaved
  // RGBA output is assumed.
  void SetMediaType(const MediaTypePtr& media_type);

  // Get the size of the video.
  Size GetSize();

  // Converts the frame in the payload into the provided RGBA buffer.
  void ConvertFrame(uint8_t* rgba_buffer,
                    uint32_t view_width,
                    uint32_t view_height,
                    void* payload,
                    uint64_t payload_size);

 private:
  // Builds the YUV-RGBA colorspace table.
  void BuildColorspaceTable();

  // Converts one line.
  void ConvertLine(uint32_t* dest_pixel,
                   uint8_t* y_pixel,
                   uint8_t* u_pixel,
                   uint8_t* v_pixel,
                   uint32_t width);

  bool media_type_set_ = false;
  VideoPacketLayout layout_;
  std::unique_ptr<uint32_t[]> colorspace_table_;
};

}  // namespace media
}  // namespace moj

#endif  // MOJO_SERVICES_MEDIA_COMMON_CPP_VIDEO_CONVERTER_H_
