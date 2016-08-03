// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/picture.h"

#include "flutter/lib/ui/painting/canvas.h"
#include "flutter/tonic/dart_args.h"
#include "flutter/tonic/dart_binding_macros.h"
#include "lib/tonic/converter/dart_converter.h"
#include "flutter/tonic/dart_library_natives.h"

namespace blink {

IMPLEMENT_WRAPPERTYPEINFO(ui, Picture);

#define FOR_EACH_BINDING(V) \
  V(Picture, dispose)

DART_BIND_ALL(Picture, FOR_EACH_BINDING)

scoped_refptr<Picture> Picture::Create(sk_sp<SkPicture> picture) {
  return new Picture(std::move(picture));
}

Picture::Picture(sk_sp<SkPicture> picture) : picture_(std::move(picture)) {
}

Picture::~Picture() {
}

void Picture::dispose() {
  ClearDartWrapper();
}

} // namespace blink
