// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_SAFE_ACCESS_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_SAFE_ACCESS_H_

#include <type_traits>

#define SAFE_ACCESS(pointer, member, default_value)                      \
  ([=]() {                                                               \
    if (offsetof(std::remove_pointer<decltype(pointer)>::type, member) + \
            sizeof(pointer->member) <=                                   \
        pointer->struct_size) {                                          \
      return pointer->member;                                            \
    }                                                                    \
    return static_cast<decltype(pointer->member)>((default_value));      \
  })()

/// Checks if the member exists.
#define SAFE_EXISTS(pointer, member) \
  (SAFE_ACCESS(pointer, member, nullptr) != nullptr)

/// Checks if exactly one of member1 or member2 exists.
#define SAFE_EXISTS_ONE_OF(pointer, member1, member2) \
  (SAFE_EXISTS(pointer, member1) != SAFE_EXISTS(pointer, member2))

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_SAFE_ACCESS_H_
