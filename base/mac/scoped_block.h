// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MAC_SCOPED_BLOCK_H_
#define BASE_MAC_SCOPED_BLOCK_H_

#include <Block.h>

#include "base/basictypes.h"
#include "base/compiler_specific.h"
#include "base/memory/scoped_policy.h"

namespace base {
namespace mac {

// ScopedBlock<> is patterned after ScopedCFTypeRef<>, but uses Block_copy() and
// Block_release() instead of CFRetain() and CFRelease().

template<typename B>
class ScopedBlock {
 public:
  explicit ScopedBlock(
      B block = NULL,
      base::scoped_policy::OwnershipPolicy policy = base::scoped_policy::ASSUME)
      : block_(block) {
    if (block_ && policy == base::scoped_policy::RETAIN)
      block_ = Block_copy(block);
  }

  ScopedBlock(const ScopedBlock<B>& that)
      : block_(that.block_) {
    if (block_)
      block_ = Block_copy(block_);
  }

  ~ScopedBlock() {
    if (block_)
      Block_release(block_);
  }

  ScopedBlock& operator=(const ScopedBlock<B>& that) {
    reset(that.get(), base::scoped_policy::RETAIN);
    return *this;
  }

  void reset(B block = NULL,
             base::scoped_policy::OwnershipPolicy policy =
                 base::scoped_policy::ASSUME) {
    if (block && policy == base::scoped_policy::RETAIN)
      block = Block_copy(block);
    if (block_)
      Block_release(block_);
    block_ = block;
  }

  bool operator==(B that) const {
    return block_ == that;
  }

  bool operator!=(B that) const {
    return block_ != that;
  }

  operator B() const {
    return block_;
  }

  B get() const {
    return block_;
  }

  void swap(ScopedBlock& that) {
    B temp = that.block_;
    that.block_ = block_;
    block_ = temp;
  }

  B release() WARN_UNUSED_RESULT {
    B temp = block_;
    block_ = NULL;
    return temp;
  }

 private:
  B block_;
};

}  // namespace mac
}  // namespace base

#endif  // BASE_MAC_SCOPED_BLOCK_H_
