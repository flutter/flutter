// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/prefs/pref_store.h"

bool PrefStore::HasObservers() const {
  return false;
}

bool PrefStore::IsInitializationComplete() const {
  return true;
}
