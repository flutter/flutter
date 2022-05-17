// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CONTEXT_GL_IMPELLER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CONTEXT_GL_IMPELLER_H_

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/context/android_context.h"

namespace flutter {

class AndroidContextGLImpeller : public AndroidContext {
 public:
  AndroidContextGLImpeller();

  ~AndroidContextGLImpeller();

  // |AndroidContext|
  bool IsValid() const override;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(AndroidContextGLImpeller);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CONTEXT_GL_IMPELLER_H_
