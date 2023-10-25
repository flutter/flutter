// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <limits>
#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"

namespace impeller {

class Allocation {
 public:
  Allocation();

  ~Allocation();

  uint8_t* GetBuffer() const;

  size_t GetLength() const;

  size_t GetReservedLength() const;

  [[nodiscard]] bool Truncate(size_t length, bool npot = true);

  static uint32_t NextPowerOfTwoSize(uint32_t x);

 private:
  uint8_t* buffer_ = nullptr;
  size_t length_ = 0;
  size_t reserved_ = 0;

  [[nodiscard]] bool Reserve(size_t reserved);

  [[nodiscard]] bool ReserveNPOT(size_t reserved);

  Allocation(const Allocation&) = delete;

  Allocation& operator=(const Allocation&) = delete;
};

std::shared_ptr<fml::Mapping> CreateMappingWithCopy(const uint8_t* contents,
                                                    size_t length);

std::shared_ptr<fml::Mapping> CreateMappingFromAllocation(
    const std::shared_ptr<Allocation>& allocation);

std::shared_ptr<fml::Mapping> CreateMappingWithString(
    std::shared_ptr<const std::string> string);

std::shared_ptr<fml::Mapping> CreateMappingWithString(std::string string);

}  // namespace impeller
