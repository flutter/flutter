// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_EFFECTS_DL_RUNTIME_EFFECT_H_
#define FLUTTER_DISPLAY_LIST_EFFECTS_DL_RUNTIME_EFFECT_H_

#include <memory>

#include "flutter/fml/macros.h"
#include "third_party/skia/include/core/SkRefCnt.h"

class SkRuntimeEffect;
namespace impeller {
class RuntimeStage;
}

namespace flutter {

class DlRuntimeEffect : public SkRefCnt {
 public:
  virtual sk_sp<SkRuntimeEffect> skia_runtime_effect() const = 0;

  virtual std::shared_ptr<impeller::RuntimeStage> runtime_stage() const = 0;

  /// Returns the total combined size of all uniforms in bytes.
  virtual size_t uniform_size() const = 0;

 protected:
  DlRuntimeEffect();
  virtual ~DlRuntimeEffect();

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(DlRuntimeEffect);
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_EFFECTS_DL_RUNTIME_EFFECT_H_
