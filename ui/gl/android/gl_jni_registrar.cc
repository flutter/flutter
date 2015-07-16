// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/android/gl_jni_registrar.h"

#include "base/android/jni_android.h"
#include "base/android/jni_registrar.h"
#include "ui/gl/android/surface_texture.h"
#include "ui/gl/android/surface_texture_listener.h"

namespace ui {
namespace gl {
namespace android {

static base::android::RegistrationMethod kGLRegisteredMethods[] = {
  { "SurfaceTexture",
    gfx::SurfaceTexture::RegisterSurfaceTexture },
  { "SurfaceTextureListener",
    gfx::SurfaceTextureListener::RegisterSurfaceTextureListener },
};

bool RegisterJni(JNIEnv* env) {
  return RegisterNativeMethods(env, kGLRegisteredMethods,
                               arraysize(kGLRegisteredMethods));
}

}  // namespace android
}  // namespace gl
}  // namespace ui
