// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/image/dl_image.h"

namespace flutter {

DlImage::DlImage() = default;

DlImage::~DlImage() = default;

int DlImage::width() const {
  return GetSize().width;
};

int DlImage::height() const {
  return GetSize().height;
};

DlIRect DlImage::GetBounds() const {
  return DlIRect::MakeSize(GetSize());
}

std::optional<std::string> DlImage::get_error() const {
  return std::nullopt;
}

}  // namespace flutter
