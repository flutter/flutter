// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/platform_view_service_protocol.h"

#include <string.h>

#include <string>
#include <vector>

#include "flutter/common/threads.h"
#include "flutter/shell/common/picture_serializer.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/shell.h"
#include "lib/fxl/memory/weak_ptr.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/src/utils/SkBase64.h"

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

static bool ErrorServer(const char** json_object, const char* message) {
  const intptr_t kServerError = -32000;
  std::stringstream response;
  response << "{\"code\":" << std::to_string(kServerError) << ",";
  response << "\"message\":\"" << message << "\"}";
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

void PlatformViewServiceProtocol::RegisterHook(bool running_precompiled_code) {
  // Listing of FlutterViews.
  Dart_RegisterRootServiceRequestCallback(kListViewsExtensionName, &ListViews,
                                          nullptr);
  // Screenshot.
  Dart_RegisterRootServiceRequestCallback(kScreenshotExtensionName, &Screenshot,
                                          nullptr);
  // The following set of service protocol extensions require debug build
  if (running_precompiled_code) {
    return;
  }
  Dart_RegisterRootServiceRequestCallback(kRunInViewExtensionName, &RunInView,
                                          nullptr);
  // [benchmark helper] Wait for the UI Thread to idle.
  Dart_RegisterRootServiceRequestCallback(kFlushUIThreadTasksExtensionName,
                                          &FlushUIThreadTasks, nullptr);
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
                          asset_directory, &view_existed, &main_port,
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
  // Ask the Shell for the list of platform views.
  Shell& shell = Shell::Shared();
  std::vector<Shell::PlatformViewInfo> platform_views;
  shell.GetPlatformViewIds(&platform_views);

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

const char* PlatformViewServiceProtocol::kScreenshotExtensionName =
    "_flutter.screenshot";

static sk_sp<SkData> EncodeBitmapAsPNG(const SkBitmap& bitmap) {
  if (bitmap.empty()) {
    return nullptr;
  }

  SkPixmap pixmap;
  if (!bitmap.peekPixels(&pixmap)) {
    return nullptr;
  }

  PngPixelSerializer serializer;
  sk_sp<SkData> data(serializer.encodeToData(pixmap));

  return data;
}

bool PlatformViewServiceProtocol::Screenshot(const char* method,
                                             const char** param_keys,
                                             const char** param_values,
                                             intptr_t num_params,
                                             void* user_data,
                                             const char** json_object) {
  fxl::AutoResetWaitableEvent latch;
  SkBitmap bitmap;
  blink::Threads::Gpu()->PostTask([&latch, &bitmap]() {
    ScreenshotGpuTask(&bitmap);
    latch.Signal();
  });

  latch.Wait();

  sk_sp<SkData> png(EncodeBitmapAsPNG(bitmap));

  if (!png)
    return ErrorServer(json_object, "can not encode screenshot");

  size_t b64_size = SkBase64::Encode(png->data(), png->size(), nullptr);
  SkAutoTMalloc<char> b64_data(b64_size);
  SkBase64::Encode(png->data(), png->size(), b64_data.get());

  std::stringstream response;
  response << "{\"type\":\"Screenshot\","
           << "\"screenshot\":\"" << std::string{b64_data.get(), b64_size}
           << "\"}";
  *json_object = strdup(response.str().c_str());
  return true;
}

void PlatformViewServiceProtocol::ScreenshotGpuTask(SkBitmap* bitmap) {
  std::vector<fxl::WeakPtr<Rasterizer>> rasterizers;
  Shell::Shared().GetRasterizers(&rasterizers);
  if (rasterizers.size() != 1)
    return;

  Rasterizer* rasterizer = rasterizers[0].get();
  if (rasterizer == nullptr)
    return;

  flow::LayerTree* layer_tree = rasterizer->GetLastLayerTree();
  if (layer_tree == nullptr)
    return;

  const SkISize& frame_size = layer_tree->frame_size();
  if (!bitmap->tryAllocN32Pixels(frame_size.width(), frame_size.height()))
    return;

  sk_sp<SkSurface> surface = SkSurface::MakeRasterDirect(
      bitmap->info(), bitmap->getPixels(), bitmap->rowBytes());

  flow::CompositorContext compositor_context(nullptr);
  SkCanvas* canvas = surface->getCanvas();
  flow::CompositorContext::ScopedFrame frame =
      compositor_context.AcquireFrame(nullptr, canvas, false);

  canvas->clear(SK_ColorBLACK);
  layer_tree->Raster(frame);
  canvas->flush();
}

const char* PlatformViewServiceProtocol::kFlushUIThreadTasksExtensionName =
    "_flutter.flushUIThreadTasks";

// This API should not be invoked by production code.
// It can potentially starve the service isolate if the main isolate pauses
// at a breakpoint or is in an infinite loop.
//
// It should be invoked from the VM Service and and blocks it until UI thread
// tasks are processed.
bool PlatformViewServiceProtocol::FlushUIThreadTasks(const char* method,
                                                   const char** param_keys,
                                                   const char** param_values,
                                                   intptr_t num_params,
                                                   void* user_data,
                                                   const char** json_object) {
  fxl::AutoResetWaitableEvent latch;
  blink::Threads::UI()->PostTask([&latch]() {
    // This task is empty because we just need to synchronize this RPC with the
    // UI Thread
    latch.Signal();
  });

  latch.Wait();

  *json_object = strdup("{\"type\":\"Success\"}");
  return true;
}

}  // namespace shell
