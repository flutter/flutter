// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_EFFECTS_DL_RUNTIME_EFFECT_SKIA_H_
#define FLUTTER_DISPLAY_LIST_EFFECTS_DL_RUNTIME_EFFECT_SKIA_H_

#include "flutter/display_list/effects/dl_runtime_effect.h"

namespace flutter {

class DlRuntimeEffectSkia final : public DlRuntimeEffect {
 public:
  // |DlRuntimeEffect|
  ~DlRuntimeEffectSkia() override;

  static sk_sp<DlRuntimeEffect> Make(
      const sk_sp<SkRuntimeEffect>& runtime_effect);

  explicit DlRuntimeEffectSkia(const sk_sp<SkRuntimeEffect>& runtime_effect);

  // |DlRuntimeEffect|
  sk_sp<SkRuntimeEffect> skia_runtime_effect() const override;

  // |DlRuntimeEffect|
  std::shared_ptr<impeller::RuntimeStage> runtime_stage() const override;

 private:
  DlRuntimeEffectSkia() = delete;

  sk_sp<SkRuntimeEffect> skia_runtime_effect_;

  FML_DISALLOW_COPY_AND_ASSIGN(DlRuntimeEffectSkia);

  friend DlRuntimeEffect;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_EFFECTS_DL_RUNTIME_EFFECT_SKIA_H_
