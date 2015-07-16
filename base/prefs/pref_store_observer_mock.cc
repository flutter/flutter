// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/prefs/pref_store_observer_mock.h"

#include "testing/gtest/include/gtest/gtest.h"

PrefStoreObserverMock::PrefStoreObserverMock()
    : initialized(false), initialization_success(false) {}

PrefStoreObserverMock::~PrefStoreObserverMock() {}

void PrefStoreObserverMock::VerifyAndResetChangedKey(
    const std::string& expected) {
  EXPECT_EQ(1u, changed_keys.size());
  if (changed_keys.size() >= 1)
    EXPECT_EQ(expected, changed_keys.front());
  changed_keys.clear();
}

void PrefStoreObserverMock::OnPrefValueChanged(const std::string& key) {
  changed_keys.push_back(key);
}

void PrefStoreObserverMock::OnInitializationCompleted(bool success) {
  initialized = true;
  initialization_success = success;
}
