// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_CLOSURE_H_
#define FLUTTER_FML_CLOSURE_H_

#include <functional>

namespace fml {

using closure = std::function<void()>;

}  // namespace fml

#endif  // FLUTTER_FML_CLOSURE_H_
