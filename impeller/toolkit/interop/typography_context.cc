// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/toolkit/interop/typography_context.h"

#include <mutex>

#include "flutter/fml/icu_util.h"
#include "impeller/toolkit/interop/embedded_icu_data.h"

namespace impeller::interop {

TypographyContext::TypographyContext()
    : collection_(std::make_shared<txt::FontCollection>()) {
  static std::once_flag sICUInitOnceFlag;
  std::call_once(sICUInitOnceFlag, []() {
    auto icu_data = std::make_unique<fml::NonOwnedMapping>(
        impeller_embedded_icu_data_data, impeller_embedded_icu_data_length);
    fml::icu::InitializeICUFromMapping(std::move(icu_data));
  });
  collection_->SetupDefaultFontManager(0u);
}

TypographyContext::~TypographyContext() = default;

bool TypographyContext::IsValid() const {
  return !!collection_;
}

const std::shared_ptr<txt::FontCollection>&
TypographyContext::GetFontCollection() const {
  return collection_;
}

}  // namespace impeller::interop
