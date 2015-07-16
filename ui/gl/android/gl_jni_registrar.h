// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_ANDROID_GL_JNI_REGISTRAR_H_
#define UI_GL_ANDROID_GL_JNI_REGISTRAR_H_

#include <jni.h>

#include "ui/gl/gl_export.h"

namespace ui {
namespace gl {
namespace android {

// Register all JNI bindings necessary for chrome.
GL_EXPORT bool RegisterJni(JNIEnv* env);

}  // namespace android
}  // namespace gl
}  // namespace ui

#endif  // UI_GL_ANDROID_GL_JNI_REGISTRAR_H_
