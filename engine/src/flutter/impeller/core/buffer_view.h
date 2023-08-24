// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/core/buffer.h"
#include "impeller/core/range.h"

namespace impeller {

struct BufferView {
  std::shared_ptr<const Buffer> buffer;
  uint8_t* contents;
  Range range;

  constexpr explicit operator bool() const { return static_cast<bool>(buffer); }
};

}  // namespace impeller
