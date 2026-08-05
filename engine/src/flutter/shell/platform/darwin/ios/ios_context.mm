// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_context.h"

#include <memory>

#include "flutter/fml/logging.h"
#import "flutter/shell/platform/darwin/common/InternalFlutterSwiftCommon/InternalFlutterSwiftCommon.h"
#include "flutter/shell/platform/darwin/ios/ios_context_metal_impeller.h"
#include "flutter/shell/platform/darwin/ios/rendering_api_selection.h"

FLUTTER_ASSERT_ARC

namespace flutter {

IOSContext::IOSContext() = default;

IOSContext::~IOSContext() = default;

std::unique_ptr<IOSContext> IOSContext::Create(
    IOSRenderingAPI api,
    const std::shared_ptr<const fml::SyncSwitch>& is_gpu_disabled_sync_switch,
    const Settings& settings) {
  switch (api) {
    case IOSRenderingAPI::kMetal:
      return std::make_unique<IOSContextMetalImpeller>(settings, is_gpu_disabled_sync_switch);
  }
  FML_CHECK(false);
  return nullptr;
}

std::shared_ptr<impeller::Context> IOSContext::GetImpellerContext() const {
  return nullptr;
}

std::shared_ptr<impeller::AiksContext> IOSContext::GetAiksContext() const {
  return nullptr;
}

}  // namespace flutter
