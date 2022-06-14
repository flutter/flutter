// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/playground/playground.h"
#include "impeller/runtime_stage/runtime_stage.h"

namespace impeller {

class RuntimeStagePlayground : public Playground {
 public:
  RuntimeStagePlayground();

  ~RuntimeStagePlayground();

  std::unique_ptr<RuntimeStage> CreateStageFromFixture(
      const std::string& fixture_name) const;

  bool RegisterStage(const RuntimeStage& stage);

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(RuntimeStagePlayground);
};

}  // namespace impeller
