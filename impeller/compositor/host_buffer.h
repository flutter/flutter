// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/compositor/buffer.h"
#include "impeller/compositor/host_buffer.h"

namespace impeller {

class HostBuffer : public std::enable_shared_from_this<HostBuffer>,
                   public BufferBase {
 public:
  std::shared_ptr<HostBuffer> Create();

  std::shared_ptr<BufferView> Emplace(size_t length);

  virtual ~HostBuffer();

  // |BufferBase|
  uint8_t* GetMapping() const override { return buffer_; }

  // |BufferBase|
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
