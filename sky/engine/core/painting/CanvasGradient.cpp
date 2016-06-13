// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/CanvasGradient.h"

#include "flutter/tonic/dart_args.h"
#include "flutter/tonic/dart_binding_macros.h"
#include "flutter/tonic/dart_converter.h"
#include "flutter/tonic/dart_library_natives.h"

namespace blink {

typedef CanvasGradient Gradient; // Because the C++ name doesn't match the Dart name.

static void Gradient_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&CanvasGradient::create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, Gradient);

#define FOR_EACH_BINDING(V) \
  V(Gradient, initLinear) \
  V(Gradient, initRadial)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void CanvasGradient::RegisterNatives(DartLibraryNatives* natives) {
  natives->Register({
    { "Gradient_constructor", Gradient_constructor, 1, true },
FOR_EACH_BINDING(DART_REGISTER_NATIVE)
  });
}

scoped_refptr<CanvasGradient> CanvasGradient::create() {
  return new CanvasGradient();
}

void CanvasGradient::initLinear(const Float32List& end_points,
                                const Int32List& colors,
                                const Float32List& color_stops,
                                SkShader::TileMode tile_mode) {
  DCHECK(end_points.num_elements() == 4);
  DCHECK(colors.num_elements() == color_stops.num_elements() || color_stops.data() == nullptr);

  static_assert(sizeof(SkPoint) == sizeof(float) * 2, "SkPoint doesn't use floats.");
  static_assert(sizeof(SkColor) == sizeof(int32_t), "SkColor doesn't use int32_t.");

  set_shader(SkGradientShader::MakeLinear(
      reinterpret_cast<const SkPoint*>(end_points.data()),
      reinterpret_cast<const SkColor*>(colors.data()),
      color_stops.data(),
      colors.num_elements(),
      tile_mode));
}

void CanvasGradient::initRadial(double centerX,
                                double centerY,
                                double radius,
                                const Int32List& colors,
                                const Float32List& color_stops,
                                SkShader::TileMode tile_mode) {
  DCHECK(colors.num_elements() * 2 == color_stops.num_elements() || color_stops.data() == nullptr);

  static_assert(sizeof(SkColor) == sizeof(int32_t), "SkColor doesn't use int32_t.");

  set_shader(SkGradientShader::MakeRadial(
      SkPoint::Make(centerX, centerY),
      radius,
      reinterpret_cast<const SkColor*>(colors.data()),
      color_stops.data(),
      colors.num_elements(),
      tile_mode));
}

CanvasGradient::CanvasGradient()
    : Shader(nullptr)
{
}

CanvasGradient::~CanvasGradient()
{
}

}  // namespace blink
