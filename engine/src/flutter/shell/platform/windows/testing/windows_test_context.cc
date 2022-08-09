// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/testing/windows_test_context.h"

#include "flutter/fml/platform/win/wstring_conversion.h"

namespace flutter {
namespace testing {

WindowsTestContext::WindowsTestContext(std::string_view assets_path)
    : assets_path_(fml::Utf8ToWideString(assets_path)) {}

WindowsTestContext::~WindowsTestContext() = default;

const std::wstring& WindowsTestContext::GetAssetsPath() const {
  return assets_path_;
}

const std::wstring& WindowsTestContext::GetIcuDataPath() const {
  return icu_data_path_;
}

}  // namespace testing
}  // namespace flutter
