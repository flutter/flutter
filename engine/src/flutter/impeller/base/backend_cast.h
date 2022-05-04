// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"

namespace impeller {

template <class Sub, class Base>
class BackendCast {
 public:
  static Sub& Cast(Base& base) { return reinterpret_cast<Sub&>(base); }

  static const Sub& Cast(const Base& base) {
    return reinterpret_cast<const Sub&>(base);
  }

  static Sub* Cast(Base* base) { return reinterpret_cast<Sub*>(base); }

  static const Sub* Cast(const Base* base) {
    return reinterpret_cast<const Sub*>(base);
  }
};

}  // namespace impeller
