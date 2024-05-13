// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_context.h"
#include "flutter/shell/platform/darwin/ios/rendering_api_selection.h"

#include "flutter/fml/logging.h"
#include "flutter/shell/platform/darwin/ios/ios_context_metal_impeller.h"
#include "flutter/shell/platform/darwin/ios/ios_context_metal_skia.h"
#include "flutter/shell/platform/darwin/ios/ios_context_software.h"

FLUTTER_ASSERT_ARC

namespace flutter {

IOSContext::IOSContext() = default;

IOSContext::~IOSContext() = default;

std::unique_ptr<IOSContext> IOSContext::Create(
    IOSRenderingAPI api,
    IOSRenderingBackend backend,
    const std::shared_ptr<const fml::SyncSwitch>& is_gpu_disabled_sync_switch) {
  switch (api) {
    case IOSRenderingAPI::kSoftware:
      FML_CHECK(backend != IOSRenderingBackend::kImpeller)
          << "Software rendering is incompatible with Impeller.\n"
             "Software rendering may have been automatically selected when running on a simulator "
             "in an environment that does not support Metal. Enabling GPU pass through in your "
             "environment may fix this. If that is not possible, then disable Impeller.";
      return std::make_unique<IOSContextSoftware>();
    case IOSRenderingAPI::kMetal:
      switch (backend) {
        case IOSRenderingBackend::kSkia:
#if !SLIMPELLER
          return std::make_unique<IOSContextMetalSkia>();
#else   //  !SLIMPELLER
          FML_LOG(FATAL) << "Impeller opt-out unavailable.";
          return nullptr;
#endif  //  !SLIMPELLER
        case IOSRenderingBackend::kImpeller:
          return std::make_unique<IOSContextMetalImpeller>(is_gpu_disabled_sync_switch);
      }
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
