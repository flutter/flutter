// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <functional>
#include <memory>

#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/runtime_stage/runtime_stage.h"

namespace impeller {

class RuntimeEffectContents final : public ColorSourceContents {
 public:
  void SetRuntimeStage(std::shared_ptr<RuntimeStage> runtime_stage);

  void SetUniformData(std::vector<uint8_t> uniform_data);

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

 private:
  std::shared_ptr<RuntimeStage> runtime_stage_;
  std::vector<uint8_t> uniform_data_;
};

}  // namespace impeller
