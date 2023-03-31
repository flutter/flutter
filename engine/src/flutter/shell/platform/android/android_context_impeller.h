// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_android_context_impeller_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_android_context_impeller_H_

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/context/android_context.h"

namespace flutter {

class AndroidContextImpeller : public AndroidContext {
 public:
  AndroidContextImpeller();

  ~AndroidContextImpeller();

  // |AndroidContext|
  bool IsValid() const override;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(AndroidContextImpeller);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_android_context_impeller_H_
