// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/gradient.h"

#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

namespace flutter {

typedef CanvasGradient
    Gradient;  // Because the C++ name doesn't match the Dart name.

IMPLEMENT_WRAPPERTYPEINFO(ui, Gradient);

void CanvasGradient::Create(Dart_Handle wrapper) {
  UIDartState::ThrowIfUIOperationsProhibited();
  auto res = fml::MakeRefCounted<CanvasGradient>();
  res->AssociateWithDartWrapper(wrapper);
}

void CanvasGradient::initLinear(const tonic::Float32List& end_points,
                                const tonic::Int32List& colors,
                                const tonic::Float32List& color_stops,
                                SkTileMode tile_mode,
                                const tonic::Float64List& matrix4) {
  FML_DCHECK(end_points.num_elements() == 4);
  FML_DCHECK(colors.num_elements() == color_stops.num_elements() ||
             color_stops.data() == nullptr);

  static_assert(sizeof(SkPoint) == sizeof(float) * 2,
                "SkPoint doesn't use floats.");
  static_assert(sizeof(SkColor) == sizeof(int32_t),
                "SkColor doesn't use int32_t.");

  SkMatrix sk_matrix;
  bool has_matrix = matrix4.data() != nullptr;
  if (has_matrix) {
    sk_matrix = ToSkMatrix(matrix4);
  }

  SkPoint p0 = SkPoint::Make(end_points[0], end_points[1]);
  SkPoint p1 = SkPoint::Make(end_points[2], end_points[3]);
  const DlColor* colors_array = reinterpret_cast<const DlColor*>(colors.data());

  dl_shader_ = DlColorSource::MakeLinear(
      p0, p1, colors.num_elements(), colors_array, color_stops.data(),
      ToDl(tile_mode), has_matrix ? &sk_matrix : nullptr);
}

void CanvasGradient::initRadial(double center_x,
                                double center_y,
                                double radius,
                                const tonic::Int32List& colors,
                                const tonic::Float32List& color_stops,
                                SkTileMode tile_mode,
                                const tonic::Float64List& matrix4) {
  FML_DCHECK(colors.num_elements() == color_stops.num_elements() ||
             color_stops.data() == nullptr);

  static_assert(sizeof(SkColor) == sizeof(int32_t),
                "SkColor doesn't use int32_t.");

  SkMatrix sk_matrix;
  bool has_matrix = matrix4.data() != nullptr;
  if (has_matrix) {
    sk_matrix = ToSkMatrix(matrix4);
  }

  const DlColor* colors_array = reinterpret_cast<const DlColor*>(colors.data());

  dl_shader_ = DlColorSource::MakeRadial(
      SkPoint::Make(center_x, center_y), radius, colors.num_elements(),
      colors_array, color_stops.data(), ToDl(tile_mode),
      has_matrix ? &sk_matrix : nullptr);
}

void CanvasGradient::initSweep(double center_x,
                               double center_y,
                               const tonic::Int32List& colors,
                               const tonic::Float32List& color_stops,
                               SkTileMode tile_mode,
                               double start_angle,
                               double end_angle,
                               const tonic::Float64List& matrix4) {
  FML_DCHECK(colors.num_elements() == color_stops.num_elements() ||
             color_stops.data() == nullptr);

  static_assert(sizeof(SkColor) == sizeof(int32_t),
                "SkColor doesn't use int32_t.");

  SkMatrix sk_matrix;
  bool has_matrix = matrix4.data() != nullptr;
  if (has_matrix) {
    sk_matrix = ToSkMatrix(matrix4);
  }

  const DlColor* colors_array = reinterpret_cast<const DlColor*>(colors.data());

  dl_shader_ = DlColorSource::MakeSweep(
      SkPoint::Make(center_x, center_y), start_angle * 180.0 / M_PI,
      end_angle * 180.0 / M_PI, colors.num_elements(), colors_array,
      color_stops.data(), ToDl(tile_mode), has_matrix ? &sk_matrix : nullptr);
}

void CanvasGradient::initTwoPointConical(double start_x,
                                         double start_y,
                                         double start_radius,
                                         double end_x,
                                         double end_y,
                                         double end_radius,
                                         const tonic::Int32List& colors,
                                         const tonic::Float32List& color_stops,
                                         SkTileMode tile_mode,
                                         const tonic::Float64List& matrix4) {
  FML_DCHECK(colors.num_elements() == color_stops.num_elements() ||
             color_stops.data() == nullptr);

  static_assert(sizeof(SkColor) == sizeof(int32_t),
                "SkColor doesn't use int32_t.");

  SkMatrix sk_matrix;
  bool has_matrix = matrix4.data() != nullptr;
  if (has_matrix) {
    sk_matrix = ToSkMatrix(matrix4);
  }

  const DlColor* colors_array = reinterpret_cast<const DlColor*>(colors.data());

  dl_shader_ = DlColorSource::MakeConical(
      SkPoint::Make(start_x, start_y), start_radius,            //
      SkPoint::Make(end_x, end_y), end_radius,                  //
      colors.num_elements(), colors_array, color_stops.data(),  //
      ToDl(tile_mode), has_matrix ? &sk_matrix : nullptr);
}

CanvasGradient::CanvasGradient() = default;

CanvasGradient::~CanvasGradient() = default;

}  // namespace flutter
