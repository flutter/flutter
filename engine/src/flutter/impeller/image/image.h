// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "impeller/geometry/size.h"

namespace impeller {

class Image {
 public:
  enum class Format {
    Invalid,
    Grey,
    GreyAlpha,
    RGB,
    RGBA,
  };

  Image();

  Image(ISize size,
        Format components,
        std::shared_ptr<const fml::Mapping> allocation);

  ~Image();

  const ISize& GetSize() const;

  bool IsValid() const;

  Format GetComponents() const;

  const std::shared_ptr<const fml::Mapping>& GetAllocation() const;

 private:
  ISize size_;
  Format components_ = Format::Invalid;
  std::shared_ptr<const fml::Mapping> allocation_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(Image);
};

}  // namespace impeller
