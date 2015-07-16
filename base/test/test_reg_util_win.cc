// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/test_reg_util_win.h"

#include "base/guid.h"
#include "base/logging.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_util.h"
#include "base/strings/utf_string_conversions.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace registry_util {

namespace {

const wchar_t kTimestampDelimiter[] = L"$";
const wchar_t kTempTestKeyPath[] = L"Software\\Chromium\\TempTestKeys";

void DeleteStaleTestKeys(const base::Time& now,
                         const base::string16& test_key_root) {
  base::win::RegKey test_root_key;
  if (test_root_key.Open(HKEY_CURRENT_USER,
                         test_key_root.c_str(),
                         KEY_ALL_ACCESS) != ERROR_SUCCESS) {
    // This will occur on first-run, but is harmless.
    return;
  }

  base::win::RegistryKeyIterator iterator_test_root_key(HKEY_CURRENT_USER,
                                                        test_key_root.c_str());
  for (; iterator_test_root_key.Valid(); ++iterator_test_root_key) {
    base::string16 key_name = iterator_test_root_key.Name();
    std::vector<base::string16> tokens;
    if (!Tokenize(key_name, base::string16(kTimestampDelimiter), &tokens))
      continue;
    int64 key_name_as_number = 0;

    if (!base::StringToInt64(tokens[0], &key_name_as_number)) {
      test_root_key.DeleteKey(key_name.c_str());
      continue;
    }

    base::Time key_time = base::Time::FromInternalValue(key_name_as_number);
    base::TimeDelta age = now - key_time;

    if (age > base::TimeDelta::FromHours(24))
      test_root_key.DeleteKey(key_name.c_str());
  }
}

base::string16 GenerateTempKeyPath(const base::string16& test_key_root,
                                   const base::Time& timestamp) {
  base::string16 key_path = test_key_root;
  key_path += L"\\" + base::Int64ToString16(timestamp.ToInternalValue());
  key_path += kTimestampDelimiter + base::ASCIIToUTF16(base::GenerateGUID());

  return key_path;
}

}  // namespace

RegistryOverrideManager::ScopedRegistryKeyOverride::ScopedRegistryKeyOverride(
    HKEY override,
    const base::string16& key_path)
    : override_(override) {
  EXPECT_EQ(
      ERROR_SUCCESS,
      temp_key_.Create(HKEY_CURRENT_USER, key_path.c_str(), KEY_ALL_ACCESS));
  EXPECT_EQ(ERROR_SUCCESS,
            ::RegOverridePredefKey(override_, temp_key_.Handle()));
}

RegistryOverrideManager::
    ScopedRegistryKeyOverride::~ScopedRegistryKeyOverride() {
  ::RegOverridePredefKey(override_, NULL);
  temp_key_.DeleteKey(L"");
}

RegistryOverrideManager::RegistryOverrideManager()
    : timestamp_(base::Time::Now()), test_key_root_(kTempTestKeyPath) {
  DeleteStaleTestKeys(timestamp_, test_key_root_);
}

RegistryOverrideManager::RegistryOverrideManager(
    const base::Time& timestamp,
    const base::string16& test_key_root)
    : timestamp_(timestamp), test_key_root_(test_key_root) {
  DeleteStaleTestKeys(timestamp_, test_key_root_);
}

RegistryOverrideManager::~RegistryOverrideManager() {}

void RegistryOverrideManager::OverrideRegistry(HKEY override) {
  base::string16 key_path = GenerateTempKeyPath(test_key_root_, timestamp_);
  overrides_.push_back(new ScopedRegistryKeyOverride(override, key_path));
}

base::string16 GenerateTempKeyPath() {
  return GenerateTempKeyPath(base::string16(kTempTestKeyPath),
                             base::Time::Now());
}

}  // namespace registry_util
