// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_SKY_VIEW_H_
#define SKY_SHELL_SKY_VIEW_H_

#include "base/android/jni_weak_ref.h"
#include "base/android/scoped_java_ref.h"
#include "base/macros.h"
#include "base/memory/weak_ptr.h"
#include "base/single_thread_task_runner.h"
#include "sky/shell/gpu_delegate.h"
#include "sky/shell/ui_delegate.h"

struct ANativeWindow;

namespace sky {
namespace shell {

class PlatformView {
 public:
  struct Config {
    base::WeakPtr<GPUDelegate> gpu_delegate;
    scoped_refptr<base::SingleThreadTaskRunner> gpu_task_runner;

    base::WeakPtr<UIDelegate> ui_delegate;
    scoped_refptr<base::SingleThreadTaskRunner> ui_task_runner;
  };

  static bool Register(JNIEnv* env);

  explicit PlatformView(const Config& config);
  ~PlatformView();

  // Called from Java
  void Detach(JNIEnv* env, jobject obj);
  void SurfaceCreated(JNIEnv* env, jobject obj, jobject jsurface);
  void SurfaceDestroyed(JNIEnv* env, jobject obj);
  void SurfaceSetSize(JNIEnv* env,
                      jobject obj,
                      jint width,
                      jint height,
                      jfloat density);

 private:
  void ReleaseWindow();

  Config config_;
  ANativeWindow* window_;

  DISALLOW_COPY_AND_ASSIGN(PlatformView);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_SKY_VIEW_H_
