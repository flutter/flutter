// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SERVICES_DYNAMIC_DYNAMIC_SERVICE_H_
#define FLUTTER_SERVICES_DYNAMIC_DYNAMIC_SERVICE_H_

#include <stdbool.h>

#include "mojo/public/c/environment/async_waiter.h"
#include "mojo/public/c/environment/logger.h"
#include "mojo/public/c/system/handle.h"
#include "flutter/services/dynamic/dynamic_service_macros.h"

FLUTTER_C_API_START

/// ============================================================================
/// The definitions in this file (and this file alone) form the stable Flutter
/// dynamic services ABI.
/// ============================================================================

#pragma pack(push, 8)
/// The dynamic Flutter service version is responsible for deciding if services
/// built with older or newer versions of Flutter will work with the current
/// embedder. This struct is stable and will never change. The version check
/// is the first thing performed by the embedder, and, in case of breaking
/// changes (as decribed below), no other service calls are made.
struct FlutterServiceVersion {
  /// If major versions of the embedder and the service differ, it indicates
  /// a completely breaking change. The embedder will refuse to load a service
  /// with any mismatch.
  uint32_t major;
  /// If minor versions of the embedder and the service differ, it indicates
  /// that parts of the ABI were augmented but the exisiting components have
  /// remained stable. The embedder will only attempt to load the service if
  /// its minor version is greater than or equal to that of the service.
  uint32_t minor;
  /// The patch version is used to indicate trivial non-ABI breaking updates.
  /// The embedder does not use this to accept or reject services being loaded.
  /// This field may be used to check if certain bug fixes are present in either
  /// the embedder or service runtimes.
  uint32_t patch;
};
#pragma pack(pop)

/// Gets the version of the Flutter dynamic services. This is basically the
/// only method guaranteed to be stable across major, minor and patch revisions.
FLUTTER_EXPORT const struct FlutterServiceVersion* FlutterServiceGetVersion(
    void);

bool FlutterServiceVersionsCompatible(
    const struct FlutterServiceVersion* embedder_version,
    const struct FlutterServiceVersion* service_version);

FLUTTER_EXPORT
void FlutterServiceOnLoad(const struct MojoAsyncWaiter* waiter,
                          const struct MojoLogger* logger);

FLUTTER_EXPORT void FlutterServiceInvoke(MojoHandle client_handle,
                                         const char* service_name);

FLUTTER_EXPORT void FlutterServiceOnUnload(void);

FLUTTER_C_API_END

#endif  // FLUTTER_SERVICES_DYNAMIC_DYNAMIC_SERVICE_H_
