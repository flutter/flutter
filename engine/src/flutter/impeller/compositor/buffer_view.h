// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/compositor/buffer.h"
#include "impeller/compositor/range.h"

namespace impeller {

struct BufferView {
  std::shared_ptr<Buffer> buffer;
  Range range;

  constexpr operator bool() const { return static_cast<bool>(buffer); }
};

}  // namespace impeller
