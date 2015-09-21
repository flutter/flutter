// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_PICTURE_SERIALIZER_H_
#define SKY_COMPOSITOR_PICTURE_SERIALIZER_H_

#include "third_party/skia/include/core/SkPicture.h"

namespace sky {

void SerializePicture(const char* file_name, SkPicture*);

}  // namespace sky

#endif  // SKY_COMPOSITOR_PICTURE_SERIALIZER_H_
