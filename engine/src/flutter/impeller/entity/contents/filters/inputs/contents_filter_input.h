// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/entity/contents/filters/inputs/filter_input.h"

namespace impeller {

class ContentsFilterInput final : public FilterInput {
 public:
  ~ContentsFilterInput() override;

  // |FilterInput|
  Variant GetInput() const override;

  // |FilterInput|
  std::optional<Snapshot> GetSnapshot(
      const std::string& label,
      const ContentContext& renderer,
      const Entity& entity,
      std::optional<Rect> coverage_limit) const override;

  // |FilterInput|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

 private:
  ContentsFilterInput(std::shared_ptr<Contents> contents, bool msaa_enabled);

  std::shared_ptr<Contents> contents_;
  mutable std::optional<Snapshot> snapshot_;
  bool msaa_enabled_;

  friend FilterInput;
};

}  // namespace impeller
