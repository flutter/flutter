// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SHELL_HOLDER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SHELL_HOLDER_H_

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/fml/unique_fd.h"
#include "flutter/lib/ui/window/viewport_metrics.h"
#include "flutter/runtime/platform_data.h"
#include "flutter/shell/common/run_configuration.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/android/platform_view_android.h"

namespace flutter {

class AndroidShellHolder {
 public:
  // Whether the application sets to use embedded_view view
  // `io.flutter.embedded_views_preview` flag. This can be static because it is
  // determined by the application and it is safe when there are multiple
  // `AndroidSurface`s.
  // TODO(cyanglaz): remove this when dynamic thread merging is enabled on
  // android. https://github.com/flutter/flutter/issues/59930
  static bool use_embedded_view;

  AndroidShellHolder(flutter::Settings settings,
                     std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
                     bool is_background_view);

  ~AndroidShellHolder();

  bool IsValid() const;

  void Launch(RunConfiguration configuration);

  const flutter::Settings& GetSettings() const;

  fml::WeakPtr<PlatformViewAndroid> GetPlatformView();

  Rasterizer::Screenshot Screenshot(Rasterizer::ScreenshotType type,
                                    bool base64_encode);

  void UpdateAssetManager(fml::RefPtr<flutter::AssetManager> asset_manager);

  void NotifyLowMemoryWarning();

 private:
  const flutter::Settings settings_;
  const std::shared_ptr<PlatformViewAndroidJNI> jni_facade_;
  fml::WeakPtr<PlatformViewAndroid> platform_view_;
  ThreadHost thread_host_;
  std::unique_ptr<Shell> shell_;
  bool is_valid_ = false;
  pthread_key_t thread_destruct_key_;
  uint64_t next_pointer_flow_id_ = 0;

  static void ThreadDestructCallback(void* value);

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidShellHolder);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SHELL_HOLDER_H_
