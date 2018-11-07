// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_BASE32_H_
#define FLUTTER_FML_BASE32_H_

#include <string>
#include <utility>

#include "flutter/fml/string_view.h"

namespace fml {

std::pair<bool, std::string> Base32Encode(StringView input);

}  // namespace fml

#endif  // FLUTTER_FML_BASE32_H_
