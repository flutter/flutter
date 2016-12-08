// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/picture.h"

#include "flutter/common/threads.h"
#include "flutter/lib/ui/painting/canvas.h"
#include "flutter/lib/ui/painting/utils.h"
#include "lib/tonic/dart_args.h"
#include "lib/tonic/dart_binding_macros.h"
#include "lib/tonic/converter/dart_converter.h"
#include "lib/tonic/dart_library_natives.h"

namespace blink {

IMPLEMENT_WRAPPERTYPEINFO(ui, Picture);

#define FOR_EACH_BINDING(V) V(Picture, dispose)

DART_BIND_ALL(Picture, FOR_EACH_BINDING)

ftl::RefPtr<Picture> Picture::Create(sk_sp<SkPicture> picture) {
  return ftl::MakeRefCounted<Picture>(std::move(picture));
}

Picture::Picture(sk_sp<SkPicture> picture) : picture_(std::move(picture)) {}

Picture::~Picture() {
  // Skia objects must be deleted on the IO thread so that any associated GL
  // objects will be cleaned up through the IO thread's GL context.
  SkiaUnrefOnIOThread(&picture_);
}

void Picture::dispose() {
  ClearDartWrapper();
}

}  // namespace blink
