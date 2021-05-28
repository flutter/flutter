// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/compositor/allocator.h"
#include "impeller/compositor/range.h"

namespace impeller {

class BufferBase {
 public:
  virtual uint8_t* GetMapping() const = 0;

  virtual size_t GetLength() const = 0;
};

class BufferView : public BufferBase {
 public:
  uint8_t* GetMapping() const {
    return parent_->GetMapping() + range_in_parent_.offset;
  }

  size_t GetLength() const { return range_in_parent_.length; }

 private:
  std::shared_ptr<BufferBase> parent_;
  Range range_in_parent_;

  FML_DISALLOW_COPY_AND_ASSIGN(BufferView);
};

class Buffer {
 public:
  ~Buffer();

 private:
  friend class Allocator;

  const id<MTLBuffer> buffer_;
  const size_t size_;
  const StorageMode mode_;
  const std::string label_;

  Buffer(id<MTLBuffer> buffer,
         size_t size,
         StorageMode mode,
         std::string label);

  FML_DISALLOW_COPY_AND_ASSIGN(Buffer);
};

class HostBuffer : public std::enable_shared_from_this<HostBuffer>,
                   public BufferBase {
 public:
  std::shared_ptr<HostBuffer> Create();

  std::shared_ptr<BufferView> Emplace(size_t length);

  ~HostBuffer();

  uint8_t* GetMapping() const override { return buffer_; }

  size_t GetLength() const override { return length_; }

  [[nodiscard]] bool Truncate(size_t length);

 private:
  uint8_t* buffer_ = nullptr;
  size_t length_ = 0;
  size_t reserved_ = 0;

  [[nodiscard]] bool Reserve(size_t reserved);

  [[nodiscard]] bool ReserveNPOT(size_t reserved);

  HostBuffer();

  FML_DISALLOW_COPY_AND_ASSIGN(HostBuffer);
};

}  // namespace impeller
