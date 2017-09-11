// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/service_protocol_hooks.h"

#include <string.h>

#include <string>
#include <vector>

#include "flutter/common/threads.h"
#include "flutter/content_handler/app.h"
#include "lib/fxl/memory/weak_ptr.h"

namespace flutter_runner {
namespace {

constexpr char kViewIdPrefx[] = "_flutterView/";

static void AppendIsolateRef(std::stringstream* stream,
                             int64_t main_port,
                             const std::string name) {
  *stream << "{\"type\":\"@Isolate\",\"fixedId\":true,\"id\":\"isolates/";
  *stream << main_port << "\",\"name\":\"" << name << "\",";
  *stream << "\"number\":\"" << main_port << "\"}";
}

static void AppendFlutterView(std::stringstream* stream,
                              uintptr_t view_id,
                              int64_t isolate_id,
                              const std::string isolate_name) {
  *stream << "{\"type\":\"FlutterView\", \"id\": \"" << kViewIdPrefx << "0x"
          << std::hex << view_id << std::dec << "\"";
  if (isolate_id != ILLEGAL_PORT) {
    // Append the isolate (if it exists).
    *stream << ","
            << "\"isolate\":";
    AppendIsolateRef(stream, isolate_id, isolate_name);
  }
  *stream << "}";
}

}  // namespace

void ServiceProtocolHooks::RegisterHooks(bool running_precompiled_code) {
  // Listing of FlutterViews.
  Dart_RegisterRootServiceRequestCallback(kListViewsExtensionName, &ListViews,
                                          nullptr);
}


const char* ServiceProtocolHooks::kListViewsExtensionName =
    "_flutter.listViews";

bool ServiceProtocolHooks::ListViews(const char* method,
                                            const char** param_keys,
                                            const char** param_values,
                                            intptr_t num_params,
                                            void* user_data,
                                            const char** json_object) {
  // Ask the App for the list of platform views. This will run a task on
  // the UI thread before returning.
  App& app = App::Shared();
  std::vector<App::PlatformViewInfo> platform_views;
  app.WaitForPlatformViewIds(&platform_views);

  std::stringstream response;

  response << "{\"type\":\"FlutterViewList\",\"views\":[";
  bool prefix_comma = false;
  for (auto it = platform_views.begin(); it != platform_views.end(); it++) {
    uintptr_t view_id = it->view_id;
    int64_t isolate_id = it->isolate_id;
    const std::string& isolate_name = it->isolate_name;
    if (!view_id) {
      continue;
    }
    if (prefix_comma) {
      response << ',';
    } else {
      prefix_comma = true;
    }
    AppendFlutterView(&response, view_id, isolate_id, isolate_name);
  }
  response << "]}";
  // Copy the response.
  *json_object = strdup(response.str().c_str());
  return true;
}

}  // namespace flutter_runner
