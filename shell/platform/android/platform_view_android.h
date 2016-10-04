// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_
#define SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_

#include <string>

#include "base/android/jni_android.h"
#include "base/android/jni_weak_ref.h"
#include "lib/ftl/memory/weak_ptr.h"
#include "lib/ftl/synchronization/waitable_event.h"
#include "flutter/shell/common/platform_view.h"

namespace shell {

class AndroidGLContext;

class PlatformViewAndroid : public PlatformView {
 public:
  static bool Register(JNIEnv* env);

  PlatformViewAndroid();

  ~PlatformViewAndroid() override;

  void Detach(JNIEnv* env, jobject obj);

  void SurfaceCreated(JNIEnv* env, jobject obj, jobject jsurface);

  void SurfaceChanged(JNIEnv* env, jobject obj, jint backgroundColor);

  void SurfaceDestroyed(JNIEnv* env, jobject obj);

  void DispatchPointerDataPacket(JNIEnv* env, jobject obj, jobject buffer,
                                 jint position);

  base::android::ScopedJavaLocalRef<jobject> GetBitmap(JNIEnv* env,
                                                       jobject obj);

  ftl::WeakPtr<shell::PlatformView> GetWeakViewPtr() override;

  uint64_t DefaultFramebuffer() const override;

  bool ContextMakeCurrent() override;

  bool ResourceContextMakeCurrent() override;

  bool SwapBuffers() override;

  virtual SkISize GetSize();

  virtual void Resize(const SkISize& size);

  virtual void RunFromSource(const std::string& main,
                             const std::string& packages,
                             const std::string& assets_directory);

  void set_flutter_view(const JavaObjectWeakGlobalRef& flutter_view) {
    flutter_view_ = flutter_view;
  }

 private:
  void ReleaseSurface();

  void GetBitmapGpuTask(ftl::AutoResetWaitableEvent* latch,
                        jobject* pixels_out,
                        SkISize* size_out);

  std::unique_ptr<AndroidGLContext> context_;
  ftl::WeakPtrFactory<PlatformViewAndroid> weak_factory_;
  JavaObjectWeakGlobalRef flutter_view_;

  void UpdateThreadPriorities();

  FTL_DISALLOW_COPY_AND_ASSIGN(PlatformViewAndroid);
};

}  // namespace shell

#endif  // SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_
