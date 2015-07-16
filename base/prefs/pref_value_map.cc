// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/prefs/pref_value_map.h"

#include <map>

#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/stl_util.h"
#include "base/values.h"

PrefValueMap::PrefValueMap() {}

PrefValueMap::~PrefValueMap() {
  Clear();
}

bool PrefValueMap::GetValue(const std::string& key,
                            const base::Value** value) const {
  const Map::const_iterator entry = prefs_.find(key);
  if (entry == prefs_.end())
    return false;

  if (value)
    *value = entry->second;
  return true;
}

bool PrefValueMap::GetValue(const std::string& key, base::Value** value) {
  const Map::const_iterator entry = prefs_.find(key);
  if (entry == prefs_.end())
    return false;

  if (value)
    *value = entry->second;
  return true;
}

bool PrefValueMap::SetValue(const std::string& key, base::Value* value) {
  DCHECK(value);
  auto result = prefs_.insert(std::make_pair(key, value));
  if (result.second)
    return true;

  scoped_ptr<base::Value> value_ptr(value);
  const Map::iterator& entry = result.first;
  if (base::Value::Equals(entry->second, value))
    return false;

  delete entry->second;
  entry->second = value_ptr.release();

  return true;
}

bool PrefValueMap::RemoveValue(const std::string& key) {
  const Map::iterator entry = prefs_.find(key);
  if (entry == prefs_.end())
    return false;

  delete entry->second;
  prefs_.erase(entry);
  return true;
}

void PrefValueMap::Clear() {
  STLDeleteValues(&prefs_);
}

void PrefValueMap::Swap(PrefValueMap* other) {
  prefs_.swap(other->prefs_);
}

PrefValueMap::iterator PrefValueMap::begin() {
  return prefs_.begin();
}

PrefValueMap::iterator PrefValueMap::end() {
  return prefs_.end();
}

PrefValueMap::const_iterator PrefValueMap::begin() const {
  return prefs_.begin();
}

PrefValueMap::const_iterator PrefValueMap::end() const {
  return prefs_.end();
}

bool PrefValueMap::GetBoolean(const std::string& key,
                              bool* value) const {
  const base::Value* stored_value = nullptr;
  return GetValue(key, &stored_value) && stored_value->GetAsBoolean(value);
}

void PrefValueMap::SetBoolean(const std::string& key, bool value) {
  SetValue(key, new base::FundamentalValue(value));
}

bool PrefValueMap::GetString(const std::string& key,
                             std::string* value) const {
  const base::Value* stored_value = nullptr;
  return GetValue(key, &stored_value) && stored_value->GetAsString(value);
}

void PrefValueMap::SetString(const std::string& key,
                             const std::string& value) {
  SetValue(key, new base::StringValue(value));
}

bool PrefValueMap::GetInteger(const std::string& key, int* value) const {
  const base::Value* stored_value = nullptr;
  return GetValue(key, &stored_value) && stored_value->GetAsInteger(value);
}

void PrefValueMap::SetInteger(const std::string& key, const int value) {
  SetValue(key, new base::FundamentalValue(value));
}

void PrefValueMap::SetDouble(const std::string& key, const double value) {
  SetValue(key, new base::FundamentalValue(value));
}

void PrefValueMap::GetDifferingKeys(
    const PrefValueMap* other,
    std::vector<std::string>* differing_keys) const {
  differing_keys->clear();

  // Put everything into ordered maps.
  std::map<std::string, base::Value*> this_prefs(prefs_.begin(), prefs_.end());
  std::map<std::string, base::Value*> other_prefs(other->prefs_.begin(),
                                                  other->prefs_.end());

  // Walk over the maps in lockstep, adding everything that is different.
  auto this_pref(this_prefs.begin());
  auto other_pref(other_prefs.begin());
  while (this_pref != this_prefs.end() && other_pref != other_prefs.end()) {
    const int diff = this_pref->first.compare(other_pref->first);
    if (diff == 0) {
      if (!this_pref->second->Equals(other_pref->second))
        differing_keys->push_back(this_pref->first);
      ++this_pref;
      ++other_pref;
    } else if (diff < 0) {
      differing_keys->push_back(this_pref->first);
      ++this_pref;
    } else if (diff > 0) {
      differing_keys->push_back(other_pref->first);
      ++other_pref;
    }
  }

  // Add the remaining entries.
  for ( ; this_pref != this_prefs.end(); ++this_pref)
      differing_keys->push_back(this_pref->first);
  for ( ; other_pref != other_prefs.end(); ++other_pref)
      differing_keys->push_back(other_pref->first);
}
