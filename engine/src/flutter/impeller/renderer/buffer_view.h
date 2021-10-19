// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/renderer/buffer.h"
#include "impeller/renderer/range.h"

namespace impeller {

struct BufferView {
  std::shared_ptr<const Buffer> buffer;
  Range range;

  constexpr operator bool() const { return static_cast<bool>(buffer); }
};

}  // namespace impeller
