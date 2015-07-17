// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_PREFS_VALUE_MAP_PREF_STORE_H_
#define BASE_PREFS_VALUE_MAP_PREF_STORE_H_

#include <map>
#include <string>

#include "base/basictypes.h"
#include "base/observer_list.h"
#include "base/prefs/base_prefs_export.h"
#include "base/prefs/pref_value_map.h"
#include "base/prefs/writeable_pref_store.h"

// A basic PrefStore implementation that uses a simple name-value map for
// storing the preference values.
class BASE_PREFS_EXPORT ValueMapPrefStore : public WriteablePrefStore {
 public:
  ValueMapPrefStore();

  // PrefStore overrides:
  bool GetValue(const std::string& key,
                const base::Value** value) const override;
  void AddObserver(PrefStore::Observer* observer) override;
  void RemoveObserver(PrefStore::Observer* observer) override;
  bool HasObservers() const override;

  // WriteablePrefStore overrides:
  void SetValue(const std::string& key,
                scoped_ptr<base::Value> value,
                uint32 flags) override;
  void RemoveValue(const std::string& key, uint32 flags) override;
  bool GetMutableValue(const std::string& key, base::Value** value) override;
  void ReportValueChanged(const std::string& key, uint32 flags) override;
  void SetValueSilently(const std::string& key,
                        scoped_ptr<base::Value> value,
                        uint32 flags) override;

 protected:
  ~ValueMapPrefStore() override;

  // Notify observers about the initialization completed event.
  void NotifyInitializationCompleted();

 private:
  PrefValueMap prefs_;

  base::ObserverList<PrefStore::Observer, true> observers_;

  DISALLOW_COPY_AND_ASSIGN(ValueMapPrefStore);
};

#endif  // BASE_PREFS_VALUE_MAP_PREF_STORE_H_
