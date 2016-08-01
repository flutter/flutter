// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_
#define SKY_SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_

#include "base/macros.h"
#include "base/android/jni_android.h"
#include "base/synchronization/waitable_event.h"
#include "sky/shell/platform_view.h"

namespace sky {
namespace shell {

class AndroidGLContext;

class PlatformViewAndroid : public PlatformView {
 public:
  static bool Register(JNIEnv* env);

  explicit PlatformViewAndroid();

  ~PlatformViewAndroid() override;

  // Called from Java
  void Detach(JNIEnv* env, jobject obj);

  // Called from Java
  void SurfaceCreated(JNIEnv* env, jobject obj, jobject jsurface);

  // Called from Java
  void SurfaceDestroyed(JNIEnv* env, jobject obj);

  // sky::shell::PlatformView override
  base::WeakPtr<sky::shell::PlatformView> GetWeakViewPtr() override;

  // sky::shell::PlatformView override
  uint64_t DefaultFramebuffer() const override;

  // sky::shell::PlatformView override
  bool ContextMakeCurrent() override;

  // sky::shell::PlatformView override
  bool ResourceContextMakeCurrent() override;

  // sky::shell::PlatformView override
  bool SwapBuffers() override;

  // sky::shell::PlatformView override
  virtual SkISize GetSize();

  // sky::shell::PlatformView override
  virtual void Resize(const SkISize& size);

 private:
  std::unique_ptr<AndroidGLContext> context_;
  base::WeakPtrFactory<PlatformViewAndroid> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(PlatformViewAndroid);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_
