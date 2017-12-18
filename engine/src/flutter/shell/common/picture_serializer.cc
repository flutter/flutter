// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/picture_serializer.h"

#include "third_party/skia/include/core/SkStream.h"

namespace shell {

void SerializePicture(const std::string& path, SkPicture* picture) {
  SkFILEWStream stream(path.c_str());
  picture->serialize(&stream);
}

}  // namespace shell
