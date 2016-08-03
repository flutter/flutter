// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform_view_service_protocol.h"

#include "sky/shell/shell.h"

namespace sky {
namespace shell {

void PlatformViewServiceProtocol::RegisterHook(bool running_precompiled_code) {
  if (running_precompiled_code) {
    return;
  }
  Dart_RegisterRootServiceRequestCallback(kRunInViewExtensionName,
                                          &RunInView,
                                          nullptr);
  Dart_RegisterRootServiceRequestCallback(kListViewsExtensionName,
                                          &ListViews,
                                          nullptr);
}

const char* PlatformViewServiceProtocol::kRunInViewExtensionName =
    "_flutter.runInView";

bool PlatformViewServiceProtocol::RunInView(const char* method,
                                            const char** param_keys,
                                            const char** param_values,
                                            intptr_t num_params,
                                            void* user_data,
                                            const char** json_object) {
  // TODO(johnmccutchan): Implement this.
  *json_object = strdup("{\"type\": \"Success\"}");
  return true;
}

const char* PlatformViewServiceProtocol::kListViewsExtensionName =
    "_flutter.listViews";

bool PlatformViewServiceProtocol::ListViews(const char* method,
                                            const char** param_keys,
                                            const char** param_values,
                                            intptr_t num_params,
                                            void* user_data,
                                            const char** json_object) {
  // Ask the Shell for the list of platform views. This will run a task on
  // the UI thread before returning.
  Shell& shell = Shell::Shared();
  std::vector<base::WeakPtr<PlatformView>> platform_views;
  shell.WaitForPlatformViews(&platform_views);

  std::stringstream response;

  response << "{\"type\":\"FlutterViewList\",\"views\":[";
  bool prefix_comma = false;
  for (auto it = platform_views.begin(); it != platform_views.end(); it++) {
    PlatformView* view = it->get();
    if (!view) {
      // Skip any platform views which have been deleted.
      continue;
    }
    if (prefix_comma) {
      response << ',';
    } else {
      prefix_comma = true;
    }
    response << "{\"type\":\"FlutterView\", \"id\": \"_flutterView/";
    response << "0x" << std::hex << reinterpret_cast<uintptr_t>(view);
    response << "\"}";
  }
  response << "]}";
  // Copy the response.
  *json_object = strdup(response.str().c_str());
  return true;
}

}  // namespace shell
}  // namespace sky
