// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_ENVIRONMENT_GL_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_ENVIRONMENT_GL_H_

#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_counted.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/time/time_point.h"

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <KHR/khrplatform.h>

namespace flutter {
namespace testing::android {
class InterceptingAndroidEnvironmentGL;
}
class AndroidEnvironmentGL
    : public fml::RefCountedThreadSafe<AndroidEnvironmentGL> {
 public:
  bool IsValid() const;

  EGLDisplay Display() const;

  // Sets the presentation time for the surface.
  //
  // Returns false if there was a GL error or if eglPresentationTimeANDROID is
  // unavailable.
  virtual bool SetPresentationTime(EGLSurface surface,
                                   fml::TimePoint time) const;

 protected:
  // MakeRefCounted
  AndroidEnvironmentGL();
  // MakeRefCounted
  virtual ~AndroidEnvironmentGL();

 private:
  PFNEGLPRESENTATIONTIMEANDROIDPROC presentation_time_proc_;
  EGLDisplay display_;
  bool valid_;

  friend class InterceptingAndroidEnvironmentGL;

  FML_FRIEND_MAKE_REF_COUNTED(AndroidEnvironmentGL);
  FML_FRIEND_REF_COUNTED_THREAD_SAFE(AndroidEnvironmentGL);
  FML_DISALLOW_COPY_AND_ASSIGN(AndroidEnvironmentGL);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_ENVIRONMENT_GL_H_
