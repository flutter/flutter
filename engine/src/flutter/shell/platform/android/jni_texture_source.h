// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_JNI_TEXTURE_SOURCE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_JNI_TEXTURE_SOURCE_H_

#include <memory>

#include "flutter/fml/platform/android/scoped_java_ref.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      Describes an external texture fed by a Java
///             SurfaceTextureWrapper, for
///             FlutterEngineRegisterExternalTextureWithInfo.
///             `surface_texture` is the WeakReference to it that FlutterJNI
///             registers. If registration fails, the caller still owns the
///             info's `user_data` and passes it to `destruction_callback`.
///
FlutterExternalTextureInfo MakeJavaSurfaceTextureInfo(
    int64_t texture_id,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    const fml::jni::ScopedJavaGlobalRef<jobject>& surface_texture);

//------------------------------------------------------------------------------
/// @brief      Describes an external texture fed by a Java ImageTextureEntry,
///             for FlutterEngineRegisterExternalTextureWithInfo.
///             `image_texture_entry` is the WeakReference to it that FlutterJNI
///             registers. Each frame is the hardware buffer of the entry's
///             latest image; releasing the frame closes the Java
///             HardwareBuffer. If registration fails, the caller still owns the
///             info's `user_data` and passes it to `destruction_callback`.
///
FlutterExternalTextureInfo MakeJavaImageTextureInfo(
    int64_t texture_id,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    const fml::jni::ScopedJavaGlobalRef<jobject>& image_texture_entry,
    bool drop_frames_on_context_destroyed);

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_JNI_TEXTURE_SOURCE_H_
