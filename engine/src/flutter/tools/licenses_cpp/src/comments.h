// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TOOLS_LICENSES_CPP_SRC_COMMENTS_H_
#define FLUTTER_TOOLS_LICENSES_CPP_SRC_COMMENTS_H_

#include <cstdlib>
#include <functional>
#include <string_view>

void IterateComments(const char* buffer,
                     size_t size,
                     std::function<void(std::string_view)> callback);

#endif  // FLUTTER_TOOLS_LICENSES_CPP_SRC_COMMENTS_H_
