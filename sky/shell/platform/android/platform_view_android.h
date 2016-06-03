// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_
#define SKY_SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_

#include "base/synchronization/waitable_event.h"
#include "sky/shell/platform_view.h"

struct ANativeWindow;

namespace sky {
namespace shell {
class ShellView;

class PlatformViewAndroid : public PlatformView {
 public:
  static bool Register(JNIEnv* env);

  PlatformViewAndroid(const Config& config);
  ~PlatformViewAndroid() override;

  // Called from Java
  void Detach(JNIEnv* env, jobject obj);
  void SurfaceCreated(JNIEnv* env, jobject obj, jobject jsurface);
  void SurfaceDestroyed(JNIEnv* env, jobject obj);

  void SetShellView(std::unique_ptr<ShellView> shell_view);

 private:
  void ReleaseWindow();

  // In principle, the ShellView should own the PlatformView, but because our
  // lifetime is controlled by the Android view hierarchy, we flip around the
  // ownership and have the shell_view owned by Java. We reset this pointer in
  // |Detach|, which will eventually cause |~PlatformViewAndroid|.
  std::unique_ptr<ShellView> shell_view_;
  gfx::AcceleratedWidget window_;
  base::WaitableEvent did_draw_;

  DISALLOW_COPY_AND_ASSIGN(PlatformViewAndroid);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_
