// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/picture.h"

#include "flutter/lib/ui/painting/canvas.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

namespace blink {

IMPLEMENT_WRAPPERTYPEINFO(ui, Picture);

#define FOR_EACH_BINDING(V) \
  V(Picture, toImage)       \
  V(Picture, dispose)       \
  V(Picture, GetAllocationSize)

DART_BIND_ALL(Picture, FOR_EACH_BINDING)

fml::RefPtr<Picture> Picture::Create(flow::SkiaGPUObject<SkPicture> picture) {
  return fml::MakeRefCounted<Picture>(std::move(picture));
}

Picture::Picture(flow::SkiaGPUObject<SkPicture> picture)
    : picture_(std::move(picture)) {}

Picture::~Picture() = default;

fml::RefPtr<CanvasImage> Picture::toImage(int width, int height) {
  fml::RefPtr<CanvasImage> image = CanvasImage::Create();
  image->set_image(UIDartState::CreateGPUObject(SkImage::MakeFromPicture(
      picture_.get(), SkISize::Make(width, height), nullptr, nullptr,
      SkImage::BitDepth::kU8, SkColorSpace::MakeSRGB())));
  return image;
}

void Picture::dispose() {
  ClearDartWrapper();
}

size_t Picture::GetAllocationSize() {
  if (auto picture = picture_.get()) {
    return picture->approximateBytesUsed();
  } else {
    return sizeof(Picture);
  }
}

}  // namespace blink
