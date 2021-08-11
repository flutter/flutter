// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/picture.h"

#include "impeller/aiks/picture_operation.h"

namespace impeller {

Picture::Picture(std::vector<std::unique_ptr<PictureOperation>> operations)
    : ops_(std::move(operations)) {}

Picture::~Picture() = default;

}  // namespace impeller
