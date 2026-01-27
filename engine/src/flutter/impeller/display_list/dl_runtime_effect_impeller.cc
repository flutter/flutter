// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/display_list/dl_runtime_effect_impeller.h"
#include "flutter/impeller/runtime_stage/runtime_stage.h"

namespace flutter {

//------------------------------------------------------------------------------
/// DlRuntimeEffectImpeller
///

sk_sp<DlRuntimeEffect> DlRuntimeEffectImpeller::Make(
    std::shared_ptr<impeller::RuntimeStage> runtime_stage) {
  return sk_make_sp<DlRuntimeEffectImpeller>(std::move(runtime_stage));
}

DlRuntimeEffectImpeller::~DlRuntimeEffectImpeller() = default;

DlRuntimeEffectImpeller::DlRuntimeEffectImpeller(
    std::shared_ptr<impeller::RuntimeStage> runtime_stage)
    : runtime_stage_(std::move(runtime_stage)) {};

sk_sp<SkRuntimeEffect> DlRuntimeEffectImpeller::skia_runtime_effect() const {
  return nullptr;
}

std::shared_ptr<impeller::RuntimeStage> DlRuntimeEffectImpeller::runtime_stage()
    const {
  return runtime_stage_;
}

size_t DlRuntimeEffectImpeller::uniform_size() const {
  if (!runtime_stage_) {
    return 0;
  }

  size_t total = 0;
  for (const auto& uniform : runtime_stage_->GetUniforms()) {
    total += uniform.GetSize();
  }
  return total;
}

}  // namespace flutter
