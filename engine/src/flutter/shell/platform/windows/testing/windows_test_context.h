// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_WINDOWS_TEST_CONTEXT_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_WINDOWS_TEST_CONTEXT_H_

#include <string>
#include <string_view>

#include "flutter/fml/macros.h"

namespace flutter {
namespace testing {

// Context associated with the current Windows test fixture.
//
// Context data includes global Flutter and Dart runtime context such as the
// path of Flutter's asset directory, ICU path, and resolvers for any
// registered native functions.
class WindowsTestContext {
 public:
  explicit WindowsTestContext(std::string_view assets_path = "");
  virtual ~WindowsTestContext();

  // Returns the path to assets required by the Flutter runtime.
  const std::wstring& GetAssetsPath() const;

  // Returns the path to the ICU library data file.
  const std::wstring& GetIcuDataPath() const;

 private:
  std::wstring assets_path_;
  std::wstring icu_data_path_ = L"icudtl.dat";

  FML_DISALLOW_COPY_AND_ASSIGN(WindowsTestContext);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_WINDOWS_TEST_CONTEXT_H_
