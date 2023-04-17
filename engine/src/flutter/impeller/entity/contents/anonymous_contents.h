// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/contents.h"

namespace impeller {

class AnonymousContents final : public Contents {
 public:
  static std::shared_ptr<Contents> Make(RenderProc render_proc,
                                        CoverageProc coverage_proc);

  // |Contents|
  ~AnonymousContents() override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

 private:
  RenderProc render_proc_;
  CoverageProc coverage_proc_;

  AnonymousContents(RenderProc render_proc, CoverageProc coverage_proc);

  FML_DISALLOW_COPY_AND_ASSIGN(AnonymousContents);
};

}  // namespace impeller
