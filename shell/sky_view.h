// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_SKY_VIEW_H_
#define SKY_SHELL_SKY_VIEW_H_

#include "base/android/jni_weak_ref.h"
#include "base/android/scoped_java_ref.h"
#include "base/macros.h"
#include "ui/gfx/native_widget_types.h"

struct ANativeWindow;

namespace sky {
namespace shell {

class SkyView {
 public:
  static bool Register(JNIEnv* env);

  class Delegate {
   public:
    virtual void OnAcceleratedWidgetAvailable(
        gfx::AcceleratedWidget widget) = 0;
    virtual void OnDestroyed() = 0;

   protected:
    virtual ~Delegate();
  };

  explicit SkyView(Delegate* delegate);
  ~SkyView();

  void Init();

  // Called from Java
  void Destroy(JNIEnv* env, jobject obj);
  void SurfaceCreated(JNIEnv* env, jobject obj, jobject jsurface);
  void SurfaceDestroyed(JNIEnv* env, jobject obj);
  void SurfaceSetSize(JNIEnv* env,
                      jobject obj,
                      jint width,
                      jint height,
                      jfloat density);

 private:
  void ReleaseWindow();

  Delegate* delegate_;
  ANativeWindow* window_;

  DISALLOW_COPY_AND_ASSIGN(SkyView);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_SKY_VIEW_H_
