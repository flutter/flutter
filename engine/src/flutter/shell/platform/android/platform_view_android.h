// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_

#include <memory>
#include <string>
#include <vector>

#include "flutter/fml/platform/android/scoped_java_ref.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/embedder/android/android_renderer.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/platform_view_embedder.h"

namespace flutter {

// Renders on its own (Android surfaces and contexts) and takes the remaining
// platform callbacks from the PlatformViewEmbedder dispatch table. An override
// that is deleted falls back to the embedder API callback for it, which the
// holder puts in the table.
class PlatformViewAndroid final : public PlatformViewEmbedder {
 public:
  static bool Register(JNIEnv* env);

  PlatformViewAndroid(PlatformView::Delegate& delegate,
                      const flutter::TaskRunners& task_runners,
                      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
                      FlutterNativeWindowBackend rendering_backend,
                      PlatformDispatchTable platform_dispatch_table);

  //----------------------------------------------------------------------------
  /// @brief      Creates a new PlatformViewAndroid but using an existing
  ///             Android GPU context to create new surfaces. This maximizes
  ///             resource sharing between 2 PlatformViewAndroids of 2 Shells.
  ///
  PlatformViewAndroid(
      PlatformView::Delegate& delegate,
      const flutter::TaskRunners& task_runners,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
      const std::shared_ptr<flutter::AndroidContext>& android_context,
      PlatformDispatchTable platform_dispatch_table);

  ~PlatformViewAndroid() override;

  const std::shared_ptr<AndroidContext>& GetAndroidContext() {
    return renderer_->GetAndroidContext();
  }

  const std::shared_ptr<AndroidRenderer>& GetRenderer() const {
    return renderer_;
  }

 private:
  static PlatformDispatchTable WithAndroidCallbacks(
      PlatformViewAndroid* self,
      PlatformDispatchTable platform_dispatch_table);

  static CreateSurfaceTransaction MakeCreateSurfaceTransaction(
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade);

  const std::shared_ptr<PlatformViewAndroidJNI> jni_facade_;
  const std::shared_ptr<AndroidRenderer> renderer_;

  FML_DISALLOW_COPY_AND_ASSIGN(PlatformViewAndroid);
};
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_
