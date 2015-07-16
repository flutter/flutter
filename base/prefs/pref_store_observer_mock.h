// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_PREFS_PREF_STORE_OBSERVER_MOCK_H_
#define BASE_PREFS_PREF_STORE_OBSERVER_MOCK_H_

#include <string>
#include <vector>

#include "base/compiler_specific.h"
#include "base/macros.h"
#include "base/prefs/pref_store.h"

// A mock implementation of PrefStore::Observer.
class PrefStoreObserverMock : public PrefStore::Observer {
 public:
  PrefStoreObserverMock();
  ~PrefStoreObserverMock() override;

  void VerifyAndResetChangedKey(const std::string& expected);

  // PrefStore::Observer implementation
  void OnPrefValueChanged(const std::string& key) override;
  void OnInitializationCompleted(bool success) override;

  std::vector<std::string> changed_keys;
  bool initialized;
  bool initialization_success;  // Only valid if |initialized|.

 private:
  DISALLOW_COPY_AND_ASSIGN(PrefStoreObserverMock);
};

#endif  // BASE_PREFS_PREF_STORE_OBSERVER_MOCK_H_
