// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/compositor/allocator.h"
#include "impeller/compositor/range.h"

namespace impeller {

class HostBuffer;

class BufferBase {
 public:
  ~BufferBase() = default;

  virtual uint8_t* GetMapping() const = 0;

  virtual size_t GetLength() const = 0;
};

class BufferView final : public BufferBase {
 public:
  // |BufferBase|
  ~BufferView() = default;

  // |BufferBase|
  uint8_t* GetMapping() const override {
    return parent_->GetMapping() + range_in_parent_.offset;
  }

  // |BufferBase|
  size_t GetLength() const override { return range_in_parent_.length; }

 private:
  friend HostBuffer;

  std::shared_ptr<BufferBase> parent_;
  Range range_in_parent_;

  BufferView(std::shared_ptr<BufferBase> parent, Range range_in_parent)
      : parent_(std::move(parent)), range_in_parent_(range_in_parent) {}
};

}  // namespace impeller
