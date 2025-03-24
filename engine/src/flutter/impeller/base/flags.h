// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_BASE_FLAGS_H_
#define FLUTTER_IMPELLER_BASE_FLAGS_H_

namespace impeller {
struct Flags {
  /// Whether to defer PSO construction until first use. Usage Will introduce
  /// raster jank.
  bool lazy_shader_mode = false;
};
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_BASE_FLAGS_H_
