// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_PREFS_PREF_VALUE_MAP_H_
#define BASE_PREFS_PREF_VALUE_MAP_H_

#include <string>
#include <vector>

#include "base/basictypes.h"
#include "base/containers/scoped_ptr_hash_map.h"
#include "base/memory/scoped_ptr.h"
#include "base/prefs/base_prefs_export.h"

namespace base {
class Value;
}

// A generic string to value map used by the PrefStore implementations.
class BASE_PREFS_EXPORT PrefValueMap {
 public:
  using Map = base::ScopedPtrHashMap<std::string, scoped_ptr<base::Value>>;
  using iterator = Map::iterator;
  using const_iterator = Map::const_iterator;

  PrefValueMap();
  virtual ~PrefValueMap();

  // Gets the value for |key| and stores it in |value|. Ownership remains with
  // the map. Returns true if a value is present. If not, |value| is not
  // touched.
  bool GetValue(const std::string& key, const base::Value** value) const;
  bool GetValue(const std::string& key, base::Value** value);

  // Sets a new |value| for |key|. |value| must be non-null. Returns true if the
  // value changed.
  bool SetValue(const std::string& key, scoped_ptr<base::Value> value);

  // Removes the value for |key| from the map. Returns true if a value was
  // removed.
  bool RemoveValue(const std::string& key);

  // Clears the map.
  void Clear();

  // Swaps the contents of two maps.
  void Swap(PrefValueMap* other);

  iterator begin();
  iterator end();
  const_iterator begin() const;
  const_iterator end() const;

  // Gets a boolean value for |key| and stores it in |value|. Returns true if
  // the value was found and of the proper type.
  bool GetBoolean(const std::string& key, bool* value) const;

  // Sets the value for |key| to the boolean |value|.
  void SetBoolean(const std::string& key, bool value);

  // Gets a string value for |key| and stores it in |value|. Returns true if
  // the value was found and of the proper type.
  bool GetString(const std::string& key, std::string* value) const;

  // Sets the value for |key| to the string |value|.
  void SetString(const std::string& key, const std::string& value);

  // Gets an int value for |key| and stores it in |value|. Returns true if
  // the value was found and of the proper type.
  bool GetInteger(const std::string& key, int* value) const;

  // Sets the value for |key| to the int |value|.
  void SetInteger(const std::string& key, const int value);

  // Sets the value for |key| to the double |value|.
  void SetDouble(const std::string& key, const double value);

  // Compares this value map against |other| and stores all key names that have
  // different values in |differing_keys|. This includes keys that are present
  // only in one of the maps.
  void GetDifferingKeys(const PrefValueMap* other,
                        std::vector<std::string>* differing_keys) const;

 private:
  Map prefs_;

  DISALLOW_COPY_AND_ASSIGN(PrefValueMap);
};

#endif  // BASE_PREFS_PREF_VALUE_MAP_H_
