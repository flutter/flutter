// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/display_list/dl_runtime_effect_impeller.h"
#include "flutter/impeller/runtime_stage/runtime_stage.h"
#include "third_party/skia/include/core/SkString.h"

#include <emscripten/console.h>

using namespace flutter;

namespace Skwasm {
sk_sp<DlRuntimeEffect> createRuntimeEffect(SkString* source) {
  // TODO(jacksongardner): Implement runtime effect for wimp
  // https://github.com/flutter/flutter/issues/175431
  return DlRuntimeEffectImpeller::Make(nullptr);
}
}  // namespace Skwasm
