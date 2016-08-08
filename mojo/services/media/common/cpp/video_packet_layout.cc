// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <unordered_map>

#include "mojo/services/media/common/cpp/video_packet_layout.h"

namespace mojo {
namespace media {

namespace {

static inline size_t RoundUpToAlign(size_t value, size_t alignment) {
  return ((value + (alignment - 1)) & ~(alignment - 1));
}

}  // namespace

// static
const VideoPacketLayout::PixelFormatInfo& VideoPacketLayout::InfoForPixelFormat(
    PixelFormat pixel_format) {
  struct Hash {
    std::size_t operator()(PixelFormat const& pixel_format) const {
      return static_cast<size_t>(pixel_format);
    }
  };
  static const std::unordered_map<PixelFormat, PixelFormatInfo, Hash> table = {
      {PixelFormat::I420,
       {3, {1, 1, 1}, {Extent(1, 1), Extent(2, 2), Extent(2, 2)}}},
      {PixelFormat::YV12,
       {3, {1, 1, 1}, {Extent(1, 1), Extent(2, 2), Extent(2, 2)}}},
      {PixelFormat::YV16,
       {3, {1, 1, 1}, {Extent(1, 1), Extent(2, 1), Extent(2, 1)}}},
      {PixelFormat::YV12A,
       {4,
        {1, 1, 1, 1},
        {Extent(1, 1), Extent(2, 2), Extent(2, 2), Extent(1, 1)}}},
      {PixelFormat::YV24,
       {3, {1, 1, 1}, {Extent(1, 1), Extent(1, 1), Extent(1, 1)}}},
      {PixelFormat::NV12, {2, {1, 2}, {Extent(1, 1), Extent(2, 2)}}},
      {PixelFormat::NV21, {2, {1, 2}, {Extent(1, 1), Extent(2, 2)}}},
      {PixelFormat::UYVY, {1, {2}, {Extent(1, 1)}}},
      {PixelFormat::YUY2, {1, {2}, {Extent(1, 1)}}},
      {PixelFormat::ARGB, {1, {4}, {Extent(1, 1)}}},
      {PixelFormat::XRGB, {1, {4}, {Extent(1, 1)}}},
      {PixelFormat::RGB24, {1, {3}, {Extent(1, 1)}}},
      {PixelFormat::RGB32, {1, {4}, {Extent(1, 1)}}},
      {PixelFormat::MJPEG, {1, {0}, {Extent(1, 1)}}},
      {PixelFormat::MT21, {2, {1, 2}, {Extent(1, 1), Extent(2, 2)}}}};

  MOJO_DCHECK(table.find(pixel_format) != table.end());
  return table.find(pixel_format)->second;
}

size_t VideoPacketLayout::PixelFormatInfo::RowCount(size_t plane,
                                                    size_t height) const {
  MOJO_DCHECK(plane < plane_count_);
  const int sample_height = sample_size_for_plane(plane).height();
  return RoundUpToAlign(height, sample_height) / sample_height;
}

size_t VideoPacketLayout::PixelFormatInfo::ColumnCount(size_t plane,
                                                       size_t width) const {
  MOJO_DCHECK(plane < plane_count_);
  const size_t sample_width = sample_size_for_plane(plane).width();
  return RoundUpToAlign(width, sample_width) / sample_width;
}

size_t VideoPacketLayout::PixelFormatInfo::BytesPerRow(size_t plane,
                                                       size_t width) const {
  MOJO_DCHECK(plane < plane_count_);
  return bytes_per_element_for_plane(plane) * ColumnCount(plane, width);
}

VideoPacketLayout::Extent VideoPacketLayout::PixelFormatInfo::AlignedSize(
    const Extent& unaligned_size) const {
  const Extent alignment = CommonAlignment();
  const Extent adjusted =
      Extent(RoundUpToAlign(unaligned_size.width(), alignment.width()),
             RoundUpToAlign(unaligned_size.height(), alignment.height()));
  MOJO_DCHECK((adjusted.width() % alignment.width() == 0) &&
              (adjusted.height() % alignment.height() == 0));
  return adjusted;
}

VideoPacketLayout::Extent VideoPacketLayout::PixelFormatInfo::CommonAlignment()
    const {
  size_t max_sample_width = 0;
  size_t max_sample_height = 0;
  for (size_t plane = 0; plane < plane_count_; ++plane) {
    const Extent sample_size = sample_size_for_plane(plane);
    max_sample_width = std::max(max_sample_width, sample_size.width());
    max_sample_height = std::max(max_sample_height, sample_size.height());
  }
  return Extent(max_sample_width, max_sample_height);
}

VideoPacketLayout::VideoPacketLayout() {}

VideoPacketLayout::VideoPacketLayout(PixelFormat pixel_format,
                                     uint32_t width,
                                     uint32_t height,
                                     uint32_t coded_width,
                                     uint32_t coded_height)
    : pixel_format_(pixel_format),
      width_(width),
      height_(height),
      coded_width_(coded_width),
      coded_height_(coded_height) {
  const PixelFormatInfo& info = GetPixelFormatInfo();

  Extent coded_size(coded_width, coded_height);
  plane_count_ = info.plane_count_;

  size_ = 0;
  Extent aligned_size = info.AlignedSize(coded_size);

  for (size_t plane = 0; plane < plane_count_; ++plane) {
    // The *2 in alignment for height is because some formats (e.g. h264)
    // allow interlaced coding, and then the size needs to be a multiple of two
    // macroblocks (vertically). See avcodec_align_dimensions2.
    const size_t height = RoundUpToAlign(
        info.RowCount(plane, aligned_size.height()), kFrameSizeAlignment * 2);
    line_stride_[plane] = RoundUpToAlign(
        info.BytesPerRow(plane, aligned_size.width()), kFrameSizeAlignment);
    plane_offset_[plane] = size_;
    size_ += height * line_stride_[plane];
  }

  // Adding an extra line due to overreads. See comment in BuildFrameLayout
  // in services/media/framework/types/video_stream_type.cc.
  MOJO_DCHECK(static_cast<size_t>(kUPlaneIndex) < plane_count_);
  size_ += line_stride_[kUPlaneIndex] + kFrameSizePadding;
}

VideoPacketLayout::~VideoPacketLayout() {}

}  // namespace media
}  // namespace mojo
