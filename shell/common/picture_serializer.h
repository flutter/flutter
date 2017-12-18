// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_GPU_PICTURE_SERIALIZER_H_
#define SHELL_GPU_PICTURE_SERIALIZER_H_

#include <string>

#include "third_party/skia/include/core/SkPicture.h"

namespace shell {

void SerializePicture(const std::string& path, SkPicture* picture);

}  // namespace shell

#endif  // SHELL_GPU_PICTURE_SERIALIZER_H_
