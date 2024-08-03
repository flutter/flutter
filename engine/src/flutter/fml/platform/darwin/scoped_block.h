// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_PLATFORM_DARWIN_SCOPED_BLOCK_H_
#define FLUTTER_FML_PLATFORM_DARWIN_SCOPED_BLOCK_H_

#include <Block.h>

#include "flutter/fml/platform/darwin/scoped_typeref.h"

#if defined(__has_feature) && __has_feature(objc_arc)
#define BASE_MAC_BRIDGE_CAST(TYPE, VALUE) (__bridge TYPE)(VALUE)
#else
#define BASE_MAC_BRIDGE_CAST(TYPE, VALUE) VALUE
#endif

namespace fml {

namespace internal {

template <typename B>
struct ScopedBlockTraits {
  static B InvalidValue() { return nullptr; }
  static B Retain(B block) {
    return BASE_MAC_BRIDGE_CAST(
        B, Block_copy(BASE_MAC_BRIDGE_CAST(const void*, block)));
  }
  static void Release(B block) {
    Block_release(BASE_MAC_BRIDGE_CAST(const void*, block));
  }
};

}  // namespace internal

// ScopedBlock<> is patterned after ScopedCFTypeRef<>, but uses Block_copy() and
// Block_release() instead of CFRetain() and CFRelease().

template <typename B>
using ScopedBlock = ScopedTypeRef<B, internal::ScopedBlockTraits<B>>;

}  // namespace fml

#undef BASE_MAC_BRIDGE_CAST

#endif  // FLUTTER_FML_PLATFORM_DARWIN_SCOPED_BLOCK_H_
