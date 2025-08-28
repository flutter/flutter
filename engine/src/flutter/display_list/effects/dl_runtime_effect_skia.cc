// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/effects/dl_runtime_effect_skia.h"
#include "third_party/skia/include/effects/SkRuntimeEffect.h"

namespace flutter {
//------------------------------------------------------------------------------
/// DlRuntimeEffectSkia
///

sk_sp<DlRuntimeEffect> DlRuntimeEffectSkia::Make(
    const sk_sp<SkRuntimeEffect>& runtime_effect) {
  return sk_make_sp<DlRuntimeEffectSkia>(runtime_effect);
}

DlRuntimeEffectSkia::~DlRuntimeEffectSkia() = default;

DlRuntimeEffectSkia::DlRuntimeEffectSkia(
    const sk_sp<SkRuntimeEffect>& runtime_effect)
    : skia_runtime_effect_(runtime_effect) {}

sk_sp<SkRuntimeEffect> DlRuntimeEffectSkia::skia_runtime_effect() const {
  return skia_runtime_effect_;
}

std::shared_ptr<impeller::RuntimeStage> DlRuntimeEffectSkia::runtime_stage()
    const {
  return nullptr;
}

}  // namespace flutter
