// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_DISPLAY_LIST_DL_RUNTIME_EFFECT_IMPELLER_H_
#define FLUTTER_IMPELLER_DISPLAY_LIST_DL_RUNTIME_EFFECT_IMPELLER_H_

#include "flutter/display_list/effects/dl_runtime_effect.h"

namespace flutter {

class DlRuntimeEffectImpeller final : public DlRuntimeEffect {
 public:
  // |DlRuntimeEffect|
  ~DlRuntimeEffectImpeller() override;

  static sk_sp<DlRuntimeEffect> Make(
      std::shared_ptr<impeller::RuntimeStage> runtime_stage);

  explicit DlRuntimeEffectImpeller(
      std::shared_ptr<impeller::RuntimeStage> runtime_stage);

  // |DlRuntimeEffect|
  sk_sp<SkRuntimeEffect> skia_runtime_effect() const override;

  // |DlRuntimeEffect|
  std::shared_ptr<impeller::RuntimeStage> runtime_stage() const override;

 private:
  DlRuntimeEffectImpeller() = delete;

  std::shared_ptr<impeller::RuntimeStage> runtime_stage_;

  FML_DISALLOW_COPY_AND_ASSIGN(DlRuntimeEffectImpeller);

  friend DlRuntimeEffect;
};

}  // namespace flutter

#endif  // FLUTTER_IMPELLER_DISPLAY_LIST_DL_RUNTIME_EFFECT_IMPELLER_H_
