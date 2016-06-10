// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/ImageShader.h"

#include "sky/engine/tonic/dart_args.h"
#include "sky/engine/tonic/dart_binding_macros.h"
#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_library_natives.h"

namespace blink {

static void ImageShader_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&ImageShader::create, args);
}

static void ImageShader_initWithImage(Dart_NativeArguments args) {
  DartArgIterator it(args);
  CanvasImage* image = it.GetNext<CanvasImage*>();
  SkShader::TileMode tmx = it.GetNext<SkShader::TileMode>();
  SkShader::TileMode tmy = it.GetNext<SkShader::TileMode>();
  Float64List matrix4 = it.GetNext<Float64List>();
  if (it.had_exception())
    return;
  ExceptionState es;
  GetReceiver<ImageShader>(args)->initWithImage(image, tmx, tmy, matrix4, es);
  if (es.had_exception())
    Dart_ThrowException(es.GetDartException(args, true));
}

IMPLEMENT_WRAPPERTYPEINFO(ui, ImageShader);

void ImageShader::RegisterNatives(DartLibraryNatives* natives) {
  natives->Register({
    { "ImageShader_constructor", ImageShader_constructor, 1, true },
    { "ImageShader_initWithImage", ImageShader_initWithImage, 5, true },
  });
}

scoped_refptr<ImageShader> ImageShader::create() {
  return new ImageShader();
}

void ImageShader::initWithImage(CanvasImage* image,
                                SkShader::TileMode tmx,
                                SkShader::TileMode tmy,
                                const Float64List& matrix4,
                                ExceptionState& es) {
  ASSERT(image != NULL);

  SkMatrix sk_matrix = toSkMatrix(matrix4, es);
  if (es.had_exception())
      return;

  SkBitmap bitmap;
  image->image()->asLegacyBitmap(&bitmap, SkImage::kRO_LegacyBitmapMode);

  set_shader(SkShader::MakeBitmapShader(bitmap, tmx, tmy, &sk_matrix));
}

ImageShader::ImageShader() : Shader(nullptr) {
}

ImageShader::~ImageShader() {
}

}  // namespace blink
