// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_PLATFORM_DARWIN_SCOPED_BLOCK_H_
#define FLUTTER_FML_PLATFORM_DARWIN_SCOPED_BLOCK_H_

#include <Block.h>

#include "flutter/fml/compiler_specific.h"

namespace fml {

// ScopedBlock<> is patterned after ScopedCFTypeRef<>, but uses Block_copy() and
// Block_release() instead of CFRetain() and CFRelease().

enum class OwnershipPolicy {
  // The scoped object takes ownership of an object by taking over an existing
  // ownership claim.
  Assume,

  // The scoped object will retain the object and any initial ownership is
  // not changed.
  Retain,
};

template <typename B>
class ScopedBlock {
 public:
  explicit ScopedBlock(B block = nullptr,
                       OwnershipPolicy policy = OwnershipPolicy::Assume)
      : block_(block) {
    if (block_ && policy == OwnershipPolicy::Retain)
      block_ = Block_copy(block);
  }

  ScopedBlock(const ScopedBlock<B>& that) : block_(that.block_) {
    if (block_)
      block_ = Block_copy(block_);
  }

  ~ScopedBlock() {
    if (block_)
      Block_release(block_);
  }

  ScopedBlock& operator=(const ScopedBlock<B>& that) {
    reset(that.get(), OwnershipPolicy::Retain);
    return *this;
  }

  void reset(B block = nullptr,
             OwnershipPolicy policy = OwnershipPolicy::Assume) {
    if (block && policy == OwnershipPolicy::Retain)
      block = Block_copy(block);
    if (block_)
      Block_release(block_);
    block_ = block;
  }

  bool operator==(B that) const { return block_ == that; }

  bool operator!=(B that) const { return block_ != that; }

  operator B() const { return block_; }

  B get() const { return block_; }

  void swap(ScopedBlock& that) {
    B temp = that.block_;
    that.block_ = block_;
    block_ = temp;
  }

  [[nodiscard]] B release() {
    B temp = block_;
    block_ = nullptr;
    return temp;
  }

 private:
  B block_;
};

}  // namespace fml

#endif  // FLUTTER_FML_PLATFORM_DARWIN_SCOPED_BLOCK_H_
