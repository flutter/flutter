// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_context.h"
#include "flutter/shell/platform/darwin/ios/rendering_api_selection.h"

#include "flutter/fml/logging.h"
#include "flutter/shell/platform/darwin/ios/ios_context_software.h"

#if SHELL_ENABLE_METAL
#include "flutter/shell/platform/darwin/ios/ios_context_metal_impeller.h"
#include "flutter/shell/platform/darwin/ios/ios_context_metal_skia.h"
#endif  // SHELL_ENABLE_METAL

namespace flutter {

IOSContext::IOSContext(MsaaSampleCount msaa_samples) : msaa_samples_(msaa_samples) {}

IOSContext::~IOSContext() = default;

std::unique_ptr<IOSContext> IOSContext::Create(
    IOSRenderingAPI api,
    IOSRenderingBackend backend,
    MsaaSampleCount msaa_samples,
    const std::shared_ptr<const fml::SyncSwitch>& is_gpu_disabled_sync_switch) {
  switch (api) {
    case IOSRenderingAPI::kSoftware:
      FML_CHECK(backend != IOSRenderingBackend::kImpeller)
          << "Software rendering is incompatible with Impeller.\n"
             "Software rendering may have been automatically selected when running on a simulator "
             "in an environment that does not support Metal. Enabling GPU pass through in your "
             "environment may fix this. If that is not possible, then disable Impeller.";
      return std::make_unique<IOSContextSoftware>();
#if SHELL_ENABLE_METAL
    case IOSRenderingAPI::kMetal:
      switch (backend) {
        case IOSRenderingBackend::kSkia:
          return std::make_unique<IOSContextMetalSkia>(msaa_samples);
        case IOSRenderingBackend::kImpeller:
          return std::make_unique<IOSContextMetalImpeller>(is_gpu_disabled_sync_switch);
      }
#endif  // SHELL_ENABLE_METAL
    default:
      break;
  }
  FML_CHECK(false);
  return nullptr;
}

IOSRenderingBackend IOSContext::GetBackend() const {
  return IOSRenderingBackend::kSkia;
}

std::shared_ptr<impeller::Context> IOSContext::GetImpellerContext() const {
  return nullptr;
}

}  // namespace flutter
