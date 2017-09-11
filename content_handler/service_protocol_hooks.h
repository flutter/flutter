// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_SERVICE_PROTOCOL_HOOKS_H_
#define FLUTTER_CONTENT_HANDLER_SERVICE_PROTOCOL_HOOKS_H_

#include "dart/runtime/include/dart_tools_api.h"
#include "lib/fxl/synchronization/waitable_event.h"

namespace flutter_runner {

class ServiceProtocolHooks {
 public:
  static void RegisterHooks(bool running_precompiled_code);

 private:
  static const char* kListViewsExtensionName;
  static bool ListViews(const char* method,
                        const char** param_keys,
                        const char** param_values,
                        intptr_t num_params,
                        void* user_data,
                        const char** json_object);
};

}  // namespace flutter_runner

#endif  // FLUTTER_CONTENT_HANDLER_SERVICE_PROTOCOL_HOOKS_H_
