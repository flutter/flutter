// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_
#define SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_

#include <memory>
#include <string>
#include <unordered_map>

#include "base/android/jni_android.h"
#include "base/android/jni_weak_ref.h"
#include "flutter/lib/ui/window/platform_message.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/platform/android/android_surface_gl.h"
#include "lib/ftl/memory/weak_ptr.h"

namespace shell {

class PlatformViewAndroid : public PlatformView {
 public:
  static bool Register(JNIEnv* env);

  PlatformViewAndroid();

  ~PlatformViewAndroid() override;

  void Detach(JNIEnv* env, jobject obj);

  void SurfaceCreated(JNIEnv* env,
                      jobject obj,
                      jobject jsurface,
                      jint backgroundColor);

  void SurfaceChanged(JNIEnv* env, jobject obj, jint width, jint height);

  void SurfaceDestroyed(JNIEnv* env, jobject obj);

  void DispatchPointerDataPacket(JNIEnv* env,
                                 jobject obj,
                                 jobject buffer,
                                 jint position);

  void InvokePlatformMessageResponseCallback(JNIEnv* env,
                                             jobject obj,
                                             jint response_id,
                                             jstring response);

  void DispatchSemanticsAction(JNIEnv* env, jobject obj, jint id, jint action);

  void SetSemanticsEnabled(JNIEnv* env, jobject obj, jboolean enabled);

  base::android::ScopedJavaLocalRef<jobject> GetBitmap(JNIEnv* env,
                                                       jobject obj);

  bool ResourceContextMakeCurrent() override;

  void UpdateSemantics(std::vector<blink::SemanticsNode> update) override;

  void HandlePlatformMessage(
      ftl::RefPtr<blink::PlatformMessage> message) override;

  void RunFromSource(const std::string& main,
                     const std::string& packages,
                     const std::string& assets_directory) override;

  void set_flutter_view(const JavaObjectWeakGlobalRef& flutter_view) {
    flutter_view_ = flutter_view;
  }

 private:
  std::unique_ptr<AndroidSurfaceGL> surface_gl_;
  JavaObjectWeakGlobalRef flutter_view_;

  // We use id 0 to mean that no response is expected.
  int next_response_id_ = 1;
  std::unordered_map<int, ftl::RefPtr<blink::PlatformMessageResponse>>
      pending_responses_;

  void UpdateThreadPriorities();

  void ReleaseSurface();

  void GetBitmapGpuTask(ftl::AutoResetWaitableEvent* latch,
                        jobject* pixels_out,
                        SkISize* size_out);

  FTL_DISALLOW_COPY_AND_ASSIGN(PlatformViewAndroid);
};

}  // namespace shell

#endif  // SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_
