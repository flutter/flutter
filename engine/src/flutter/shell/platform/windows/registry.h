// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_REGISTRY_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_REGISTRY_H_

#include <Windows.h>
#include <Winreg.h>

#include <string>
#include <vector>

namespace flutter {

// A Windows Registry key.
//
// The Windows registry is structured as a hierarchy of named keys, each of
// which may contain a set of named values of various datatypes. RegistryKey
// objects own the underlying HKEY handle and ensure cleanup at or prior to
// destruction.
class RegistryKey {
 public:
  // Opens the specified key.
  RegistryKey(HKEY key, REGSAM access);

  // Opens a key relative to the specified parent key.
  RegistryKey(HKEY parent_key, const std::wstring_view subkey, REGSAM access);

  // Opens a key relative to the specified parent key.
  RegistryKey(const RegistryKey& parent_key,
              const std::wstring_view subkey,
              REGSAM access);

  ~RegistryKey();

  // Prevent copying.
  RegistryKey(const RegistryKey& other) = delete;
  RegistryKey& operator=(const RegistryKey& other) = delete;

  // Closes the registry key and releases resources.
  void Close();

  // Returns true if the key is valid.
  bool IsValid() const { return key_ != nullptr; }

  // Returns a list of all direct subkey names for this key.
  std::vector<std::wstring> GetSubKeyNames() const;

  // Reads a string value from the key.
  //
  // Returns ERROR_SUCCESS on success.
  LONG ReadValue(const std::wstring_view name, std::wstring* out_value) const;

 private:
  HKEY key_ = nullptr;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_REGISTRY_H_
