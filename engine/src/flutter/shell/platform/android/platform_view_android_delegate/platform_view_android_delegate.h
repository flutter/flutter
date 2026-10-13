// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_DELEGATE_PLATFORM_VIEW_ANDROID_DELEGATE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_DELEGATE_PLATFORM_VIEW_ANDROID_DELEGATE_H_

#include <memory>
#include <string>
#include <vector>

#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

class PlatformViewAndroidDelegate {
 public:
  static constexpr size_t kBytesPerNode =
      73 * sizeof(int32_t);  // The # fields of each encoded node
  static constexpr size_t kBytesPerChild = sizeof(int32_t);
  static constexpr size_t kBytesPerCustomAction = sizeof(int32_t);
  static constexpr size_t kBytesPerAction = 4 * sizeof(int32_t);
  static constexpr size_t kBytesPerStringAttribute = 4 * sizeof(int32_t);
  static constexpr int kEmptyStringIndex = -1;
  explicit PlatformViewAndroidDelegate(
      std::shared_ptr<PlatformViewAndroidJNI> jni_facade);

  //----------------------------------------------------------------------------
  /// @brief      Encodes `update` for AccessibilityBridge.java and sends it
  ///             through the JNI facade.
  ///
  void UpdateSemantics(const FlutterSemanticsUpdate2& update);

 private:
  const std::shared_ptr<PlatformViewAndroidJNI> jni_facade_;
};
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_DELEGATE_PLATFORM_VIEW_ANDROID_DELEGATE_H_
