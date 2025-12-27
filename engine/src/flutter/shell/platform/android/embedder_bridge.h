// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_BRIDGE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_BRIDGE_H_

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

class EmbedderBridge {
 public:
  EmbedderBridge(const flutter::TaskRunners& task_runners,
                 const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
                 const flutter::Settings& settings);

  ~EmbedderBridge();

  bool IsValid() const;

  void Run(const std::string& entrypoint);

  // Called from the platform to notify the engine of a vsync event.
  void OnVsync(int64_t baton,
               fml::TimePoint frame_start_time,
               fml::TimePoint frame_target_time);

  Shell& GetShell();

 private:
  EmbedderFlutterEngine engine_ = nullptr;
  flutter::TaskRunners task_runners_;
  std::shared_ptr<PlatformViewAndroidJNI> jni_facade_;
  flutter::Settings settings_;

  // Embedder API callbacks
  static bool MakeCurrent(void* user_data);
  static bool ClearCurrent(void* user_data);
  static bool Present(void* user_data);
  static uint32_t GetFBO(void* user_data);
  static void OnPlatformMessage(const FlutterPlatformMessage* message,
                                void* user_data);
  static void VsyncCallback(void* user_data, intptr_t baton);

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderBridge);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_BRIDGE_H_
