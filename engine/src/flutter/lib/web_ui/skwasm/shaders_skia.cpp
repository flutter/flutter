// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/effects/dl_runtime_effect_skia.h"
#include "third_party/skia/include/effects/SkRuntimeEffect.h"

namespace Skwasm {
sk_sp<flutter::DlRuntimeEffect> createRuntimeEffect(SkString* source) {
  auto result = SkRuntimeEffect::MakeForShader(*source);
  if (result.effect == nullptr) {
    printf("Failed to compile shader. Error text:\n%s",
           result.errorText.data());
    return nullptr;
  } else {
    return flutter::DlRuntimeEffectSkia::Make(result.effect);
  }
}
}  // namespace Skwasm
