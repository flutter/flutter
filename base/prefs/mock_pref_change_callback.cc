// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/prefs/mock_pref_change_callback.h"

#include "base/bind.h"

MockPrefChangeCallback::MockPrefChangeCallback(PrefService* prefs)
    : prefs_(prefs) {
}

MockPrefChangeCallback::~MockPrefChangeCallback() {}

PrefChangeRegistrar::NamedChangeCallback MockPrefChangeCallback::GetCallback() {
  return base::Bind(&MockPrefChangeCallback::OnPreferenceChanged,
                    base::Unretained(this));
}

void MockPrefChangeCallback::Expect(const std::string& pref_name,
                                    const base::Value* value) {
  EXPECT_CALL(*this, OnPreferenceChanged(pref_name))
      .With(PrefValueMatches(prefs_, pref_name, value));
}
