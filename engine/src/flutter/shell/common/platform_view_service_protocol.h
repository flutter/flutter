// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_COMMON_VIEW_SERVICE_PROTOCOL_H_
#define SHELL_COMMON_VIEW_SERVICE_PROTOCOL_H_

#include <memory>

#include "dart/runtime/include/dart_tools_api.h"
#include "flutter/shell/common/platform_view.h"
#include "lib/fxl/synchronization/waitable_event.h"
#include "third_party/skia/include/core/SkBitmap.h"

namespace shell {

class PlatformViewServiceProtocol {
 public:
  static void RegisterHook(bool running_precompiled_code);

 private:
  static const char* kRunInViewExtensionName;
  // It should be invoked from the VM Service and and blocks it until previous
  // UI thread tasks are processed.
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
  // It should be invoked from the VM Service and and blocks it until previous
  // GPU thread tasks are processed.
  static bool Screenshot(const char* method,
                         const char** param_keys,
                         const char** param_values,
                         intptr_t num_params,
                         void* user_data,
                         const char** json_object);
  static void ScreenshotGpuTask(SkBitmap* bitmap);

  // This API should not be invoked by production code.
  // It can potentially starve the service isolate if the main isolate pauses
  // at a breakpoint or is in an infinite loop.
  //
  // It should be invoked from the VM Service and and blocks it until previous
  // GPU thread tasks are processed.
  static const char* kFlushUIThreadTasksExtensionName;
  static bool FlushUIThreadTasks(const char* method,
                                 const char** param_keys,
                                 const char** param_values,
                                 intptr_t num_params,
                                 void* user_data,
                                 const char** json_object);
};

}  // namespace shell

#endif  // SHELL_COMMON_VIEW_SERVICE_PROTOCOL_H_
