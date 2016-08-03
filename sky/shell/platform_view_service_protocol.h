// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_VIEW_SERVICE_PROTOCOL_H_
#define SKY_SHELL_PLATFORM_VIEW_SERVICE_PROTOCOL_H_

#include <memory>

#include "sky/shell/platform_view.h"
#include "dart/runtime/include/dart_tools_api.h"

namespace sky {
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
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_VIEW_SERVICE_PROTOCOL_H_
