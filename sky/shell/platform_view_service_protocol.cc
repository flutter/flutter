// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/shell/platform_view_service_protocol.h"

#include <string.h>

#include <string>

#include "flutter/sky/shell/shell.h"

namespace sky {
namespace shell {
namespace {

constexpr char kViewIdPrefx[] = "_flutterView/";
constexpr size_t kViewIdPrefxLength = sizeof(kViewIdPrefx) - 1;

static intptr_t KeyIndex(const char** param_keys,
                         intptr_t num_params,
                         const char* key) {
  if (param_keys == NULL) {
    return -1;
  }
  for (intptr_t i = 0; i < num_params; i++) {
    if (strcmp(param_keys[i], key) == 0) {
      return i;
    }
  }
  return -1;
}

static const char* ValueForKey(const char** param_keys,
                               const char** param_values,
                               intptr_t num_params,
                               const char* key) {
  intptr_t index = KeyIndex(param_keys, num_params, key);
  if (index < 0) {
    return NULL;
  }
  return param_values[index];
}

static bool ErrorMissingParameter(const char** json_object, const char* name) {
  const intptr_t kInvalidParams = -32602;
  std::stringstream response;
  response << "{\"code\":" << std::to_string(kInvalidParams) << ",";
  response << "\"message\":\"Invalid params\",";
  response << "\"data\": {\"details\": \"" << name << "\"}}";
  *json_object = strdup(response.str().c_str());
  return false;
}

static bool ErrorBadParameter(const char** json_object,
                              const char* name,
                              const char* value) {
  const intptr_t kInvalidParams = -32602;
  std::stringstream response;
  response << "{\"code\":" << std::to_string(kInvalidParams) << ",";
  response << "\"message\":\"Invalid params\",";
  response << "\"data\": {\"details\": \"parameter: " << name << " has a bad ";
  response << "value: " << value << "\"}}";
  *json_object = strdup(response.str().c_str());
  return false;
}

static bool ErrorUnknownView(const char** json_object, const char* view_id) {
  const intptr_t kInvalidParams = -32602;
  std::stringstream response;
  response << "{\"code\":" << std::to_string(kInvalidParams) << ",";
  response << "\"message\":\"Invalid params\",";
  response << "\"data\": {\"details\": \"view not found: " << view_id << "\"}}";
  *json_object = strdup(response.str().c_str());
  return false;
}

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
          << std::hex << view_id << std::dec;
  if (isolate_id != ILLEGAL_PORT) {
      // Append the isolate (if it exists).
      *stream << "\"," << "\"isolate\":";
      AppendIsolateRef(stream, isolate_id, isolate_name);
  }
  *stream << "}";
}

}  // namespace

void PlatformViewServiceProtocol::RegisterHook(bool running_precompiled_code) {
  // Listing of FlutterViews.
  Dart_RegisterRootServiceRequestCallback(kListViewsExtensionName, &ListViews,
                                          nullptr);
  // The following set of service protocol extensions require debug build
  if (running_precompiled_code) {
    return;
  }
  Dart_RegisterRootServiceRequestCallback(kRunInViewExtensionName, &RunInView,
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
  const char* view_id =
      ValueForKey(param_keys, param_values, num_params, "viewId");
  const char* asset_directory =
      ValueForKey(param_keys, param_values, num_params, "assetDirectory");
  const char* main_script =
      ValueForKey(param_keys, param_values, num_params, "mainScript");
  const char* packages_file =
      ValueForKey(param_keys, param_values, num_params, "packagesFile");
  if (view_id == NULL) {
    return ErrorMissingParameter(json_object, "viewId");
  }
  if (strncmp(view_id, kViewIdPrefx, kViewIdPrefxLength) != 0) {
    return ErrorBadParameter(json_object, "viewId", view_id);
  }
  if (asset_directory == NULL) {
    return ErrorMissingParameter(json_object, "assetDirectory");
  }
  if (main_script == NULL) {
    return ErrorMissingParameter(json_object, "mainScript");
  }
  if (packages_file == NULL) {
    return ErrorMissingParameter(json_object, "packagesFile");
  }

  // Convert the actual flutter view hex id into a number.
  uintptr_t view_id_as_num =
      std::stoull((view_id + kViewIdPrefxLength), nullptr, 16);

  // Ask the Shell to run this script in the specified view. This will run a
  // task on the UI thread before returning.
  Shell& shell = Shell::Shared();
  bool view_existed = false;
  Dart_Port main_port = ILLEGAL_PORT;
  std::string isolate_name;
  shell.RunInPlatformView(view_id_as_num, main_script, packages_file,
                          asset_directory,
                          &view_existed,
                          &main_port,
                          &isolate_name);

  if (!view_existed) {
    // If the view did not exist this request has definitely failed.
    return ErrorUnknownView(json_object, view_id);
  } else {
    // The view existed and the isolate was created. Success.
    std::stringstream response;
    response << "{\"type\":\"Success\","
             << "\"view\":";
    AppendFlutterView(&response, view_id_as_num, main_port, isolate_name);
    response << "}";
    *json_object = strdup(response.str().c_str());
    return true;
  }
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
  std::vector<Shell::PlatformViewInfo> platform_views;
  shell.WaitForPlatformViewIds(&platform_views);

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

}  // namespace shell
}  // namespace sky
