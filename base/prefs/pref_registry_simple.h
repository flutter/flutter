// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_PREFS_PREF_REGISTRY_SIMPLE_H_
#define BASE_PREFS_PREF_REGISTRY_SIMPLE_H_

#include <string>

#include "base/prefs/base_prefs_export.h"
#include "base/prefs/pref_registry.h"

namespace base {
class DictionaryValue;
class FilePath;
class ListValue;
}

// A simple implementation of PrefRegistry.
class BASE_PREFS_EXPORT PrefRegistrySimple : public PrefRegistry {
 public:
  PrefRegistrySimple();

  void RegisterBooleanPref(const std::string& path, bool default_value);
  void RegisterIntegerPref(const std::string& path, int default_value);
  void RegisterDoublePref(const std::string& path, double default_value);
  void RegisterStringPref(const std::string& path,
                          const std::string& default_value);
  void RegisterFilePathPref(const std::string& path,
                            const base::FilePath& default_value);
  void RegisterListPref(const std::string& path);
  void RegisterDictionaryPref(const std::string& path);
  void RegisterListPref(const std::string& path,
                        base::ListValue* default_value);
  void RegisterDictionaryPref(const std::string& path,
                              base::DictionaryValue* default_value);
  void RegisterInt64Pref(const std::string& path, int64 default_value);
  void RegisterUint64Pref(const std::string&, uint64 default_value);

  // Versions of registration functions that accept PrefRegistrationFlags.
  // |flags| is a bitmask of PrefRegistrationFlags.
  void RegisterBooleanPref(const std::string&,
                           bool default_value,
                           uint32 flags);
  void RegisterIntegerPref(const std::string&, int default_value, uint32 flags);
  void RegisterDoublePref(const std::string&,
                          double default_value,
                          uint32 flags);
  void RegisterStringPref(const std::string&,
                          const std::string& default_value,
                          uint32 flags);
  void RegisterFilePathPref(const std::string&,
                            const base::FilePath& default_value,
                            uint32 flags);
  void RegisterListPref(const std::string&, uint32 flags);
  void RegisterDictionaryPref(const std::string&, uint32 flags);
  void RegisterListPref(const std::string&,
                        base::ListValue* default_value,
                        uint32 flags);
  void RegisterDictionaryPref(const std::string&,
                              base::DictionaryValue* default_value,
                              uint32 flags);
  void RegisterInt64Pref(const std::string&, int64 default_value, uint32 flags);
  void RegisterUint64Pref(const std::string&,
                          uint64 default_value,
                          uint32 flags);

 protected:
  ~PrefRegistrySimple() override;

  // Allows subclasses to hook into pref registration.
  virtual void OnPrefRegistered(const std::string&,
                                base::Value* default_value,
                                uint32 flags);

 private:
  void RegisterPrefAndNotify(const std::string&,
                             base::Value* default_value,
                             uint32 flags);

  DISALLOW_COPY_AND_ASSIGN(PrefRegistrySimple);
};

#endif  // BASE_PREFS_PREF_REGISTRY_SIMPLE_H_
