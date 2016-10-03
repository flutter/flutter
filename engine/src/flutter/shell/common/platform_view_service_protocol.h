// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_COMMON_VIEW_SERVICE_PROTOCOL_H_
#define SHELL_COMMON_VIEW_SERVICE_PROTOCOL_H_

#include <memory>

#include "dart/runtime/include/dart_tools_api.h"
#include "flutter/shell/common/platform_view.h"
#include "lib/ftl/synchronization/waitable_event.h"
#include "third_party/skia/include/core/SkBitmap.h"

namespace shell {

class PlatformViewServiceProtocol {
 public:
  static void RegisterHook(bool running_precompiled_code);

 private:
  static const char* kRunInViewExtensionName;
  static bool RunInView(const char* method,
                        const char** param_keys,
                        const char** param_values,
                        intptr_t num_params,
                        void* user_data,
                        const char** json_object);

  static const char* kListViewsExtensionName;
  static bool ListViews(const char* method,
                        const char** param_keys,
                        const char** param_values,
                        intptr_t num_params,
                        void* user_data,
                        const char** json_object);

  static const char* kScreenshotExtensionName;
  static bool Screenshot(const char* method,
                         const char** param_keys,
                         const char** param_values,
                         intptr_t num_params,
                         void* user_data,
                         const char** json_object);
  static void ScreenshotGpuTask(SkBitmap* bitmap);
};

}  // namespace shell

#endif  // SHELL_COMMON_VIEW_SERVICE_PROTOCOL_H_
