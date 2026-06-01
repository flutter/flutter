// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/context/android_context.h"

#if defined(__ANDROID__)
#include <sys/system_properties.h>
#endif

namespace flutter {

AndroidContext::AndroidContext(AndroidRenderingAPI rendering_api)
    : rendering_api_(rendering_api) {}

bool AndroidContext::ShouldClearContextBetweenFrames() const {
#if defined(__ANDROID__)
  auto is_bad_platform = [](const char* name) -> bool {
    char value[PROP_VALUE_MAX];
    if (__system_property_get(name, value) > 0) {
      std::string_view platform(value);
      if (platform.starts_with("mt6762") || platform.starts_with("mt6765") ||
          platform.starts_with("MT6762") || platform.starts_with("MT6765")) {
        return true;
      }
    }
    return false;
  };

  return is_bad_platform("ro.board.platform") ||
         is_bad_platform("ro.vendor.mediatek.platform");
#else
  return false;
#endif
}

AndroidContext::~AndroidContext() {
#if !SLIMPELLER
  if (main_context_) {
    main_context_->releaseResourcesAndAbandonContext();
  }
#endif  // !SLIMPELLER
  if (impeller_context_) {
    impeller_context_->Shutdown();
  }
};

AndroidRenderingAPI AndroidContext::RenderingApi() const {
  return rendering_api_;
}

bool AndroidContext::IsValid() const {
  return true;
}

void AndroidContext::SetMainSkiaContext(
    const sk_sp<GrDirectContext>& main_context) {
  NOT_SLIMPELLER(main_context_ = main_context);
}

sk_sp<GrDirectContext> AndroidContext::GetMainSkiaContext() const {
#if !SLIMPELLER
  return main_context_;
#else
  return nullptr;
#endif  // !SLIMPELLER
}

void AndroidContext::SetImpellerContext(
    const std::shared_ptr<impeller::Context>& impeller_context) {
  impeller_context_ = impeller_context;
}

std::shared_ptr<impeller::Context> AndroidContext::GetImpellerContext() const {
  return impeller_context_;
}

bool AndroidContext::IsDynamicSelection() const {
  return false;
}

}  // namespace flutter
