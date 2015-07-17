// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/prefs/value_map_pref_store.h"

#include <algorithm>

#include "base/stl_util.h"
#include "base/values.h"

ValueMapPrefStore::ValueMapPrefStore() {}

bool ValueMapPrefStore::GetValue(const std::string& key,
                                 const base::Value** value) const {
  return prefs_.GetValue(key, value);
}

void ValueMapPrefStore::AddObserver(PrefStore::Observer* observer) {
  observers_.AddObserver(observer);
}

void ValueMapPrefStore::RemoveObserver(PrefStore::Observer* observer) {
  observers_.RemoveObserver(observer);
}

bool ValueMapPrefStore::HasObservers() const {
  return observers_.might_have_observers();
}

void ValueMapPrefStore::SetValue(const std::string& key,
                                 scoped_ptr<base::Value> value,
                                 uint32 flags) {
  if (prefs_.SetValue(key, value.Pass()))
    FOR_EACH_OBSERVER(Observer, observers_, OnPrefValueChanged(key));
}

void ValueMapPrefStore::RemoveValue(const std::string& key, uint32 flags) {
  if (prefs_.RemoveValue(key))
    FOR_EACH_OBSERVER(Observer, observers_, OnPrefValueChanged(key));
}

bool ValueMapPrefStore::GetMutableValue(const std::string& key,
                                        base::Value** value) {
  return prefs_.GetValue(key, value);
}

void ValueMapPrefStore::ReportValueChanged(const std::string& key,
                                           uint32 flags) {
  FOR_EACH_OBSERVER(Observer, observers_, OnPrefValueChanged(key));
}

void ValueMapPrefStore::SetValueSilently(const std::string& key,
                                         scoped_ptr<base::Value> value,
                                         uint32 flags) {
  prefs_.SetValue(key, value.Pass());
}

ValueMapPrefStore::~ValueMapPrefStore() {}

void ValueMapPrefStore::NotifyInitializationCompleted() {
  FOR_EACH_OBSERVER(Observer, observers_, OnInitializationCompleted(true));
}
