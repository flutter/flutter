// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/registry.h"

#include <Windows.h>
#include <Winreg.h>

#include <vector>

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

// TODO(cbracken): write registry values to be tested, then cleanup.
// https://github.com/flutter/flutter/issues/82095

// Verify that a registry key is marked invalid after close.
TEST(RegistryKey, CloseInvalidates) {
  RegistryKey key(HKEY_USERS, L".DEFAULT\\Environment", KEY_READ);
  ASSERT_TRUE(key.IsValid());
  key.Close();
  ASSERT_FALSE(key.IsValid());
}

// Verify that subkeys can be read.
TEST(RegistryKey, GetSubKeyNames) {
  RegistryKey key(HKEY_USERS, L".DEFAULT", KEY_READ);
  ASSERT_TRUE(key.IsValid());

  std::vector<std::wstring> subkey_names = key.GetSubKeyNames();
  EXPECT_GE(subkey_names.size(), 1);
  EXPECT_TRUE(std::find(subkey_names.begin(), subkey_names.end(),
                        L"Environment") != subkey_names.end());
}

// Verify that values can be read.
TEST(RegistryKey, GetValue) {
  RegistryKey key(HKEY_USERS, L".DEFAULT\\Environment", KEY_READ);
  ASSERT_TRUE(key.IsValid());

  std::wstring path;
  ASSERT_EQ(key.ReadValue(L"Path", &path), ERROR_SUCCESS);
  EXPECT_FALSE(path.empty());
}

}  // namespace testing
}  // namespace flutter
