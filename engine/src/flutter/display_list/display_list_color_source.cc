// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_color_source.h"

namespace flutter {

static constexpr int kGradientStaticRecaptureCount = 24;

std::shared_ptr<DlColorSource> DlColorSource::From(SkShader* sk_shader) {
  if (sk_shader == nullptr) {
    return nullptr;
  }
  {
    SkMatrix local_matrix;
    SkTileMode xy[2];
    SkImage* image = sk_shader->isAImage(&local_matrix, xy);
    if (image) {
      return std::make_shared<DlImageColorSource>(
          sk_ref_sp(image), ToDl(xy[0]), ToDl(xy[1]),
          DisplayList::LinearSampling, &local_matrix);
    }
  }
  // Skia provides |SkShader->asAGradient(&info)| method to access the
  // parameters of a gradient, but the info object being filled has a number
  // of parameters which are missing, including the local matrix in every
  // gradient, and the sweep angles in the sweep gradients.
  //
  // Since the matrix is a rarely used property and since most sweep
  // gradients swing full circle, we will simply assume an Identity matrix
  // and 0,360 for the Sweep gradient.
  // Possibly the most likely "missing attribute" that might be different
  // would be the sweep gradients which might be a full circle, but might
  // have their starting angle in a custom direction.
  SkColor colors[kGradientStaticRecaptureCount];
  SkScalar stops[kGradientStaticRecaptureCount];
  SkShader::GradientInfo info = {};
  info.fColorCount = kGradientStaticRecaptureCount;
  info.fColors = colors;
  info.fColorOffsets = stops;
  SkShader::GradientType type = sk_shader->asAGradient(&info);
  if (type != SkShader::kNone_GradientType &&
      info.fColorCount > kGradientStaticRecaptureCount) {
    int count = info.fColorCount;
    info.fColors = new SkColor[count];
    info.fColorOffsets = new SkScalar[count];
    sk_shader->asAGradient(&info);
    FML_DCHECK(count == info.fColorCount);
  }
  DlTileMode mode = ToDl(info.fTileMode);
  std::shared_ptr<DlColorSource> source;
  switch (type) {
    case SkShader::kNone_GradientType:
      source = std::make_shared<DlUnknownColorSource>(sk_ref_sp(sk_shader));
      break;
    case SkShader::kColor_GradientType:
      source = std::make_shared<DlColorColorSource>(info.fColors[0]);
      break;
    case SkShader::kLinear_GradientType:
      source = MakeLinear(info.fPoint[0], info.fPoint[1], info.fColorCount,
                          info.fColors, info.fColorOffsets, mode);
      break;
    case SkShader::kRadial_GradientType:
      source = MakeRadial(info.fPoint[0], info.fRadius[0], info.fColorCount,
                          info.fColors, info.fColorOffsets, mode);
      break;
    case SkShader::kConical_GradientType:
      source = MakeConical(info.fPoint[0], info.fRadius[0], info.fPoint[1],
                           info.fRadius[1], info.fColorCount, info.fColors,
                           info.fColorOffsets, mode);
      break;
    case SkShader::kSweep_GradientType:
      source = MakeSweep(info.fPoint[0], 0, 360, info.fColorCount, info.fColors,
                         info.fColorOffsets, mode);
      break;
  }
  if (info.fColors != colors) {
    delete info.fColors;
  }
  if (info.fColorOffsets != stops) {
    delete info.fColorOffsets;
  }
  return source;
}

static void DlGradientDeleter(void* p) {
  // Some of our target environments would prefer a sized delete,
  // but other target environments do not have that operator.
  // Use an unsized delete until we get better agreement in the
  // environments.
  // See https://github.com/flutter/flutter/issues/100327
  ::operator delete(p);
}

std::shared_ptr<DlColorSource> DlColorSource::MakeLinear(
    const SkPoint start_point,
    const SkPoint end_point,
    uint32_t stop_count,
    const uint32_t* colors,
    const float* stops,
    DlTileMode tile_mode,
    const SkMatrix* matrix) {
  size_t needed = sizeof(DlLinearGradientColorSource) +
                  (stop_count * (sizeof(uint32_t) + sizeof(float)));

  void* storage = ::operator new(needed);

  std::shared_ptr<DlLinearGradientColorSource> ret;
  ret.reset(new (storage)
                DlLinearGradientColorSource(start_point, end_point, stop_count,
                                            colors, stops, tile_mode, matrix),
            DlGradientDeleter);
  return std::move(ret);
}

std::shared_ptr<DlColorSource> DlColorSource::MakeRadial(
    SkPoint center,
    SkScalar radius,
    uint32_t stop_count,
    const uint32_t* colors,
    const float* stops,
    DlTileMode tile_mode,
    const SkMatrix* matrix) {
  size_t needed = sizeof(DlRadialGradientColorSource) +
                  (stop_count * (sizeof(uint32_t) + sizeof(float)));

  void* storage = ::operator new(needed);

  std::shared_ptr<DlRadialGradientColorSource> ret;
  ret.reset(new (storage) DlRadialGradientColorSource(
                center, radius, stop_count, colors, stops, tile_mode, matrix),
            DlGradientDeleter);
  return std::move(ret);
}

std::shared_ptr<DlColorSource> DlColorSource::MakeConical(
    SkPoint start_center,
    SkScalar start_radius,
    SkPoint end_center,
    SkScalar end_radius,
    uint32_t stop_count,
    const uint32_t* colors,
    const float* stops,
    DlTileMode tile_mode,
    const SkMatrix* matrix) {
  size_t needed = sizeof(DlConicalGradientColorSource) +
                  (stop_count * (sizeof(uint32_t) + sizeof(float)));

  void* storage = ::operator new(needed);

  std::shared_ptr<DlConicalGradientColorSource> ret;
  ret.reset(new (storage) DlConicalGradientColorSource(
                start_center, start_radius, end_center, end_radius, stop_count,
                colors, stops, tile_mode, matrix),
            DlGradientDeleter);
  return std::move(ret);
}

std::shared_ptr<DlColorSource> DlColorSource::MakeSweep(
    SkPoint center,
    SkScalar start,
    SkScalar end,
    uint32_t stop_count,
    const uint32_t* colors,
    const float* stops,
    DlTileMode tile_mode,
    const SkMatrix* matrix) {
  size_t needed = sizeof(DlSweepGradientColorSource) +
                  (stop_count * (sizeof(uint32_t) + sizeof(float)));

  void* storage = ::operator new(needed);

  std::shared_ptr<DlSweepGradientColorSource> ret;
  ret.reset(new (storage)
                DlSweepGradientColorSource(center, start, end, stop_count,
                                           colors, stops, tile_mode, matrix),
            DlGradientDeleter);
  return std::move(ret);
}

}  // namespace flutter
