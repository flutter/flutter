// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_
#define SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "base/android/jni_android.h"
#include "base/android/jni_weak_ref.h"
#include "flutter/lib/ui/window/platform_message.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/platform/android/android_native_window.h"
#include "flutter/shell/platform/android/android_surface.h"
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

  void RunBundleAndSnapshot(JNIEnv* env,
                            jobject obj,
                            jstring bundle_path,
                            jstring snapshot_override);

  void RunBundleAndSource(JNIEnv* env,
                          jobject obj,
                          jstring bundle_path,
                          jstring main,
                          jstring packages);

  void SurfaceDestroyed(JNIEnv* env, jobject obj);

  void SetViewportMetrics(JNIEnv* env,
                          jobject obj,
                          jfloat device_pixel_ratio,
                          jint physical_width,
                          jint physical_height,
                          jint physical_padding_top,
                          jint physical_padding_right,
                          jint physical_padding_bottom,
                          jint physical_padding_left);

  void DispatchPlatformMessage(JNIEnv* env,
                               jobject obj,
                               jstring name,
                               jstring message,
                               jint response_id);

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

  VsyncWaiter* GetVsyncWaiter() override;

  bool ResourceContextMakeCurrent() override;

  void UpdateSemantics(std::vector<blink::SemanticsNode> update) override;

  void HandlePlatformMessage(
      ftl::RefPtr<blink::PlatformMessage> message) override;

  void HandlePlatformMessageResponse(int response_id,
                                     std::vector<uint8_t> data);

  void RunFromSource(const std::string& assets_directory,
                     const std::string& main,
                     const std::string& packages) override;

  void set_flutter_view(const JavaObjectWeakGlobalRef& flutter_view) {
    flutter_view_ = flutter_view;
  }

 private:
  const std::unique_ptr<AndroidSurface> android_surface_;
  JavaObjectWeakGlobalRef flutter_view_;
  // We use id 0 to mean that no response is expected.
  int next_response_id_ = 1;
  std::unordered_map<int, ftl::RefPtr<blink::PlatformMessageResponse>>
      pending_responses_;

  void UpdateThreadPriorities();

  void ReleaseSurface();

  void GetBitmapGpuTask(jobject* pixels_out,
                        SkISize* size_out);

  FTL_DISALLOW_COPY_AND_ASSIGN(PlatformViewAndroid);
};

}  // namespace shell

#endif  // SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_
