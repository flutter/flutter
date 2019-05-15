// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_SIZE_H_
#define FLUTTER_FML_SIZE_H_

#include <cstddef>

namespace fml {

template <typename T, std::size_t N>
constexpr std::size_t size(T (&array)[N]) {
  return N;
}

}  // namespace fml

#endif  // FLUTTER_FML_SIZE_H_
