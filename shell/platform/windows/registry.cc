// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/registry.h"

#include <cassert>
#include <memory>

namespace flutter {

RegistryKey::RegistryKey(HKEY key, REGSAM access)
    : RegistryKey(key, L"", access) {}

RegistryKey::RegistryKey(HKEY parent_key,
                         const std::wstring_view subkey,
                         REGSAM access) {
  LSTATUS result = ::RegOpenKeyEx(parent_key, subkey.data(), 0, access, &key_);
  if (result != ERROR_SUCCESS) {
    key_ = nullptr;
  }
}

RegistryKey::RegistryKey(const RegistryKey& parent_key,
                         const std::wstring_view subkey,
                         REGSAM access)
    : RegistryKey(parent_key.key_, subkey, access) {}

RegistryKey::~RegistryKey() {
  Close();
}

void RegistryKey::Close() {
  if (IsValid()) {
    ::RegCloseKey(key_);
    key_ = nullptr;
  }
}

std::vector<std::wstring> RegistryKey::GetSubKeyNames() const {
  if (!IsValid()) {
    return {};
  }

  // Get the count of subkeys, and maximum key size in wchar_t.
  DWORD max_key_buf_size;
  DWORD subkey_count;
  LSTATUS result = ::RegQueryInfoKey(
      key_, nullptr, nullptr, nullptr, &subkey_count, &max_key_buf_size,
      nullptr, nullptr, nullptr, nullptr, nullptr, nullptr);

  // Collect all subkey names.
  std::vector<std::wstring> subkey_names;
  for (int i = 0; i < subkey_count; ++i) {
    DWORD key_buf_size = max_key_buf_size;
    auto key_buf = std::make_unique<wchar_t[]>(max_key_buf_size);
    result = ::RegEnumKeyExW(key_, i, key_buf.get(), &key_buf_size, nullptr,
                             nullptr, nullptr, nullptr);
    if (result == ERROR_SUCCESS) {
      subkey_names.emplace_back(key_buf.get());
    }
  }
  return subkey_names;
}

LONG RegistryKey::ReadValue(const std::wstring_view name,
                            std::wstring* out_value) const {
  assert(out_value != nullptr);

  // Get the value size, in bytes.
  DWORD value_size;
  LSTATUS result = ::RegGetValueW(key_, L"", name.data(), RRF_RT_REG_SZ,
                                  nullptr, nullptr, &value_size);
  if (result != ERROR_SUCCESS) {
    return result;
  }

  auto value_buf = std::make_unique<wchar_t[]>(value_size / sizeof(wchar_t));
  result = ::RegGetValueW(key_, L"", name.data(), RRF_RT_REG_SZ, nullptr,
                          value_buf.get(), &value_size);
  if (result == ERROR_SUCCESS) {
    *out_value = value_buf.get();
  }
  return result;
}

}  // namespace flutter
