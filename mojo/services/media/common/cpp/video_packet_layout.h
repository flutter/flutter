// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_MEDIA_COMMON_CPP_VIDEO_PACKET_LAYOUT_H_
#define MOJO_SERVICES_MEDIA_COMMON_CPP_VIDEO_PACKET_LAYOUT_H_

#include <memory>

#include "mojo/services/media/common/interfaces/media_transport.mojom.h"

namespace mojo {
namespace media {

// Describes the layout of a video packet.
class VideoPacketLayout {
 public:
  static const size_t kFrameSizeAlignment = 16;
  static const size_t kFrameSizePadding = 16;
  static const size_t kYPlaneIndex = 0;
  static const size_t kARGBPlaneIndex = 0;
  static const size_t kUPlaneIndex = 1;
  static const size_t kUVPlaneIndex = 1;
  static const size_t kVPlaneIndex = 2;
  static const size_t kAPlaneIndex = 3;
  static const size_t kMaxPlaneIndex = 3;

  // Width and height.
  struct Extent {
    Extent() : width_(0), height_(0) {}
    Extent(int width, int height) : width_(width), height_(height) {}
    size_t width() const { return width_; }
    size_t height() const { return height_; }

   private:
    size_t width_;
    size_t height_;
  };

  // Information regarding a pixel format.
  struct PixelFormatInfo {
    // Returns the number of bytes per element for the specified plane.
    size_t bytes_per_element_for_plane(size_t plane) const {
      MOJO_DCHECK(plane < plane_count_);
      return bytes_per_element_[plane];
    }

    // Returns the sample size of the specified plane.
    const Extent& sample_size_for_plane(size_t plane) const {
      MOJO_DCHECK(plane < plane_count_);
      return sample_size_[plane];
    }

    // Returns the row count for the specified plane.
    size_t RowCount(size_t plane, size_t height) const;

    // Returns the column count for the specified plane.
    size_t ColumnCount(size_t plane, size_t width) const;

    // Returns the number of bytes per row for the specified plane.
    size_t BytesPerRow(size_t plane, size_t width) const;

    // Calculates an aligned size from an unaligned size.
    Extent AlignedSize(const Extent& unaligned_size) const;

    // Determines a common alignment for all planes.
    Extent CommonAlignment() const;

    const size_t plane_count_;
    const size_t bytes_per_element_[kMaxPlaneIndex + 1];
    const Extent sample_size_[kMaxPlaneIndex + 1];
  };

  // Gets information for the specified pixel format.
  static const PixelFormatInfo& InfoForPixelFormat(PixelFormat pixel_format);

  VideoPacketLayout();

  VideoPacketLayout(PixelFormat pixel_format,
                    uint32_t width,
                    uint32_t height,
                    uint32_t coded_width,
                    uint32_t coded_height);

  ~VideoPacketLayout();

  PixelFormat pixel_format() const { return pixel_format_; }

  uint32_t width() const { return width_; }

  uint32_t height() const { return height_; }

  uint32_t coded_width() const { return coded_width_; }

  uint32_t coded_height() const { return coded_height_; }

  size_t plane_count() const { return plane_count_; }

  size_t size() const { return size_; }

  size_t line_stride_for_plane(size_t plane) {
    MOJO_DCHECK(plane < plane_count_);
    return line_stride_[plane];
  }

  size_t plane_offset_for_plane(size_t plane) {
    MOJO_DCHECK(plane < plane_count_);
    return plane_offset_[plane];
  }

  const PixelFormatInfo& GetPixelFormatInfo() const {
    return InfoForPixelFormat(pixel_format_);
  }

 private:
  PixelFormat pixel_format_;
  uint32_t width_;
  uint32_t height_;
  uint32_t coded_width_;
  uint32_t coded_height_;
  size_t plane_count_;
  size_t line_stride_[kMaxPlaneIndex + 1];
  size_t plane_offset_[kMaxPlaneIndex + 1];
  size_t size_;
};

}  // namespace media
}  // namespace mojo

#endif  // MOJO_SERVICES_MEDIA_COMMON_CPP_VIDEO_PACKET_LAYOUT_H_
