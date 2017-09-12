// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_DART_INIT_H_
#define FLUTTER_RUNTIME_DART_INIT_H_

#include "dart/runtime/include/dart_api.h"
#include "lib/fxl/build_config.h"
#include "lib/fxl/functional/closure.h"

#include <memory>
#include <string>

namespace blink {

// Name of the kernel blob asset within the FLX bundle.
extern const char kKernelAssetKey[];

// Name of the snapshot blob asset within the FLX bundle.
extern const char kSnapshotAssetKey[];

// Name of the platform kernel blob asset within the FLX bundle.
extern const char kPlatformKernelAssetKey[];

bool IsRunningPrecompiledCode();

using EmbedderTracingCallback = fxl::Closure;

typedef void (*ServiceIsolateHook)(bool);
typedef void (*RegisterNativeServiceProtocolExtensionHook)(bool);

struct EmbedderTracingCallbacks {
  EmbedderTracingCallback start_tracing_callback;
  EmbedderTracingCallback stop_tracing_callback;

  EmbedderTracingCallbacks(EmbedderTracingCallback start,
                           EmbedderTracingCallback stop);
};

void InitDartVM(const uint8_t* vm_snapshot_data,
                const uint8_t* vm_snapshot_instructions,
                const uint8_t* default_isolate_snapshot_data,
                const uint8_t* default_isolate_snapshot_instructions);

void SetEmbedderTracingCallbacks(
    std::unique_ptr<EmbedderTracingCallbacks> callbacks);

// Provide a function that will be called during initialization of the
// service isolate.
void SetServiceIsolateHook(ServiceIsolateHook hook);

// Provide a function that will be called to register native service protocol
// extensions.
void SetRegisterNativeServiceProtocolExtensionHook(
    RegisterNativeServiceProtocolExtensionHook hook);

}  // namespace blink

#endif  // FLUTTER_RUNTIME_DART_INIT_H_
