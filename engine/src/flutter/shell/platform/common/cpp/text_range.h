// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>

#include "flutter/fml/logging.h"

// A directional range of text.
//
// A |TextRange| describes a range of text with |base| and |extent| positions.
// In the case where |base| == |extent|, the range is said to be collapsed, and
// when |base| > |extent|, the range is said to be reversed.
class TextRange {
 public:
  explicit TextRange(size_t position) : base_(position), extent_(position) {}
  explicit TextRange(size_t base, size_t extent)
      : base_(base), extent_(extent) {}
  TextRange(const TextRange&) = default;
  TextRange& operator=(const TextRange&) = default;

  virtual ~TextRange() = default;

  // Returns the base position of the range.
  size_t base() const { return base_; }

  // Returns the extent position of the range.
  size_t extent() const { return extent_; }

  // Returns the lesser of the base and extent positions.
  size_t start() const { return std::min(base_, extent_); }

  // Returns the greater of the base and extent positions.
  size_t end() const { return std::max(base_, extent_); }

  // Returns the position of a collapsed range.
  //
  // Asserts that the range is of length 0.
  size_t position() const {
    FML_DCHECK(base_ == extent_);
    return extent_;
  }

  // Returns the length of the range.
  size_t length() const { return end() - start(); }

  // Returns true if the range is of length 0.
  bool collapsed() const { return base_ == extent_; }

 private:
  size_t base_;
  size_t extent_;
};
