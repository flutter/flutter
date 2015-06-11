// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_VIEW_ANDROID_H_
#define SKY_SHELL_PLATFORM_VIEW_ANDROID_H_

#include "sky/shell/platform_view.h"

struct ANativeWindow;

namespace sky {
namespace shell {

class PlatformViewAndroid : public PlatformView {
 public:
  static bool Register(JNIEnv* env);
  ~PlatformViewAndroid() override;

  // Called from Java
  void Detach(JNIEnv* env, jobject obj);
  void SurfaceCreated(JNIEnv* env, jobject obj, jobject jsurface);
  void SurfaceDestroyed(JNIEnv* env, jobject obj);

 private:
  void ReleaseWindow();

  DISALLOW_COPY_AND_ASSIGN(PlatformViewAndroid);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_VIEW_ANDROID_H_
