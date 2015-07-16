// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_PREFS_DEFAULT_PREF_STORE_H_
#define BASE_PREFS_DEFAULT_PREF_STORE_H_

#include <string>

#include "base/observer_list.h"
#include "base/prefs/base_prefs_export.h"
#include "base/prefs/pref_store.h"
#include "base/prefs/pref_value_map.h"
#include "base/values.h"

// Used within a PrefRegistry to keep track of default preference values.
class BASE_PREFS_EXPORT DefaultPrefStore : public PrefStore {
 public:
  typedef PrefValueMap::const_iterator const_iterator;

  DefaultPrefStore();

  // PrefStore implementation:
  bool GetValue(const std::string& key,
                const base::Value** result) const override;
  void AddObserver(PrefStore::Observer* observer) override;
  void RemoveObserver(PrefStore::Observer* observer) override;
  bool HasObservers() const override;

  // Sets a |value| for |key|. Should only be called if a value has not been
  // set yet; otherwise call ReplaceDefaultValue().
  void SetDefaultValue(const std::string& key, scoped_ptr<base::Value> value);

  // Replaces the the value for |key| with a new value. Should only be called
  // if a value has alreday been set; otherwise call SetDefaultValue().
  void ReplaceDefaultValue(const std::string& key,
                           scoped_ptr<base::Value> value);

  const_iterator begin() const;
  const_iterator end() const;

 private:
  ~DefaultPrefStore() override;

  PrefValueMap prefs_;

  base::ObserverList<PrefStore::Observer, true> observers_;

  DISALLOW_COPY_AND_ASSIGN(DefaultPrefStore);
};

#endif  // BASE_PREFS_DEFAULT_PREF_STORE_H_
