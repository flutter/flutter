// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_TEST_REG_UTIL_WIN_H_
#define BASE_TEST_TEST_REG_UTIL_WIN_H_

// Registry utility functions used only by tests.

#include "base/basictypes.h"
#include "base/memory/scoped_vector.h"
#include "base/strings/string16.h"
#include "base/time/time.h"
#include "base/win/registry.h"

namespace registry_util {

// Allows a test to easily override registry hives so that it can start from a
// known good state, or make sure to not leave any side effects once the test
// completes. This supports parallel tests. All the overrides are scoped to the
// lifetime of the override manager. Destroy the manager to undo the overrides.
//
// Overridden hives use keys stored at, for instance:
//   HKCU\Software\Chromium\TempTestKeys\
//       13028145911617809$02AB211C-CF73-478D-8D91-618E11998AED
// The key path are comprises of:
//   - The test key root, HKCU\Software\Chromium\TempTestKeys\
//   - The base::Time::ToInternalValue of the creation time. This is used to
//     delete stale keys left over from crashed tests.
//   - A GUID used for preventing name collisions (although unlikely) between
//     two RegistryOverrideManagers created with the same timestamp.
class RegistryOverrideManager {
 public:
  RegistryOverrideManager();
  ~RegistryOverrideManager();

  // Override the given registry hive using a randomly generated temporary key.
  // Multiple overrides to the same hive are not supported and lead to undefined
  // behavior.
  void OverrideRegistry(HKEY override);

 private:
  friend class RegistryOverrideManagerTest;

  // Keeps track of one override.
  class ScopedRegistryKeyOverride {
   public:
    ScopedRegistryKeyOverride(HKEY override, const base::string16& key_path);
    ~ScopedRegistryKeyOverride();

   private:
    HKEY override_;
    base::win::RegKey temp_key_;

    DISALLOW_COPY_AND_ASSIGN(ScopedRegistryKeyOverride);
  };

  // Used for testing only.
  RegistryOverrideManager(const base::Time& timestamp,
                          const base::string16& test_key_root);

  base::Time timestamp_;
  base::string16 guid_;

  base::string16 test_key_root_;
  ScopedVector<ScopedRegistryKeyOverride> overrides_;

  DISALLOW_COPY_AND_ASSIGN(RegistryOverrideManager);
};

// Generates a temporary key path that will be eventually deleted
// automatically if the process crashes.
base::string16 GenerateTempKeyPath();

}  // namespace registry_util

#endif  // BASE_TEST_TEST_REG_UTIL_WIN_H_
