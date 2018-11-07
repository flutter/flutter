// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CONTEXT_GL_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CONTEXT_GL_H_

#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_counted.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/platform/android/android_environment_gl.h"
#include "flutter/shell/platform/android/android_native_window.h"
#include "third_party/skia/include/core/SkSize.h"

namespace shell {

class AndroidContextGL : public fml::RefCountedThreadSafe<AndroidContextGL> {
 public:
  bool CreateWindowSurface(fml::RefPtr<AndroidNativeWindow> window);

  bool CreatePBufferSurface();

  fml::RefPtr<AndroidEnvironmentGL> Environment() const;

  bool IsValid() const;

  bool MakeCurrent();

  bool ClearCurrent();

  bool SwapBuffers();

  SkISize GetSize();

  bool Resize(const SkISize& size);

 private:
  fml::RefPtr<AndroidEnvironmentGL> environment_;
  fml::RefPtr<AndroidNativeWindow> window_;
  EGLConfig config_;
  EGLSurface surface_;
  EGLContext context_;
  bool valid_;

  AndroidContextGL(fml::RefPtr<AndroidEnvironmentGL> env,
                   const AndroidContextGL* share_context = nullptr);

  ~AndroidContextGL();

  FML_FRIEND_MAKE_REF_COUNTED(AndroidContextGL);
  FML_FRIEND_REF_COUNTED_THREAD_SAFE(AndroidContextGL);
  FML_DISALLOW_COPY_AND_ASSIGN(AndroidContextGL);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CONTEXT_GL_H_
