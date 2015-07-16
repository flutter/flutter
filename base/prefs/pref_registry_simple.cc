// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/prefs/pref_registry_simple.h"

#include "base/files/file_path.h"
#include "base/strings/string_number_conversions.h"
#include "base/values.h"

PrefRegistrySimple::PrefRegistrySimple() {
}

PrefRegistrySimple::~PrefRegistrySimple() {
}

void PrefRegistrySimple::RegisterBooleanPref(const std::string& path,
                                             bool default_value) {
  RegisterPrefAndNotify(path, new base::FundamentalValue(default_value),
                        NO_REGISTRATION_FLAGS);
}

void PrefRegistrySimple::RegisterIntegerPref(const std::string& path,
                                             int default_value) {
  RegisterPrefAndNotify(path, new base::FundamentalValue(default_value),
                        NO_REGISTRATION_FLAGS);
}

void PrefRegistrySimple::RegisterDoublePref(const std::string& path,
                                            double default_value) {
  RegisterPrefAndNotify(path, new base::FundamentalValue(default_value),
                        NO_REGISTRATION_FLAGS);
}

void PrefRegistrySimple::RegisterStringPref(const std::string& path,
                                            const std::string& default_value) {
  RegisterPrefAndNotify(path, new base::StringValue(default_value),
                        NO_REGISTRATION_FLAGS);
}

void PrefRegistrySimple::RegisterFilePathPref(
    const std::string& path,
    const base::FilePath& default_value) {
  RegisterPrefAndNotify(path, new base::StringValue(default_value.value()),
                        NO_REGISTRATION_FLAGS);
}

void PrefRegistrySimple::RegisterListPref(const std::string& path) {
  RegisterPrefAndNotify(path, new base::ListValue(), NO_REGISTRATION_FLAGS);
}

void PrefRegistrySimple::RegisterListPref(const std::string& path,
                                          base::ListValue* default_value) {
  RegisterPrefAndNotify(path, default_value, NO_REGISTRATION_FLAGS);
}

void PrefRegistrySimple::RegisterDictionaryPref(const std::string& path) {
  RegisterPrefAndNotify(path, new base::DictionaryValue(),
                        NO_REGISTRATION_FLAGS);
}

void PrefRegistrySimple::RegisterDictionaryPref(
    const std::string& path,
    base::DictionaryValue* default_value) {
  RegisterPrefAndNotify(path, default_value, NO_REGISTRATION_FLAGS);
}

void PrefRegistrySimple::RegisterInt64Pref(const std::string& path,
                                           int64 default_value) {
  RegisterPrefAndNotify(
      path, new base::StringValue(base::Int64ToString(default_value)),
      NO_REGISTRATION_FLAGS);
}

void PrefRegistrySimple::RegisterUint64Pref(const std::string& path,
                                            uint64 default_value) {
  RegisterPrefAndNotify(
      path, new base::StringValue(base::Uint64ToString(default_value)),
      NO_REGISTRATION_FLAGS);
}

void PrefRegistrySimple::RegisterBooleanPref(const std::string& path,
                                             bool default_value,
                                             uint32 flags) {
  RegisterPrefAndNotify(path, new base::FundamentalValue(default_value), flags);
}

void PrefRegistrySimple::RegisterIntegerPref(const std::string& path,
                                             int default_value,
                                             uint32 flags) {
  RegisterPrefAndNotify(path, new base::FundamentalValue(default_value), flags);
}

void PrefRegistrySimple::RegisterDoublePref(const std::string& path,
                                            double default_value,
                                            uint32 flags) {
  RegisterPrefAndNotify(path, new base::FundamentalValue(default_value), flags);
}

void PrefRegistrySimple::RegisterStringPref(const std::string& path,
                                            const std::string& default_value,
                                            uint32 flags) {
  RegisterPrefAndNotify(path, new base::StringValue(default_value), flags);
}

void PrefRegistrySimple::RegisterFilePathPref(
    const std::string& path,
    const base::FilePath& default_value,
    uint32 flags) {
  RegisterPrefAndNotify(path, new base::StringValue(default_value.value()),
                        flags);
}

void PrefRegistrySimple::RegisterListPref(const std::string& path,
                                          uint32 flags) {
  RegisterPrefAndNotify(path, new base::ListValue(), flags);
}

void PrefRegistrySimple::RegisterListPref(const std::string& path,
                                          base::ListValue* default_value,
                                          uint32 flags) {
  RegisterPrefAndNotify(path, default_value, flags);
}

void PrefRegistrySimple::RegisterDictionaryPref(const std::string& path,
                                                uint32 flags) {
  RegisterPrefAndNotify(path, new base::DictionaryValue(), flags);
}

void PrefRegistrySimple::RegisterDictionaryPref(
    const std::string& path,
    base::DictionaryValue* default_value,
    uint32 flags) {
  RegisterPrefAndNotify(path, default_value, flags);
}

void PrefRegistrySimple::RegisterInt64Pref(const std::string& path,
                                           int64 default_value,
                                           uint32 flags) {
  RegisterPrefAndNotify(
      path, new base::StringValue(base::Int64ToString(default_value)), flags);
}

void PrefRegistrySimple::RegisterUint64Pref(const std::string& path,
                                            uint64 default_value,
                                            uint32 flags) {
  RegisterPrefAndNotify(
      path, new base::StringValue(base::Uint64ToString(default_value)), flags);
}

void PrefRegistrySimple::OnPrefRegistered(const std::string& path,
                                          base::Value* default_value,
                                          uint32 flags) {
}

void PrefRegistrySimple::RegisterPrefAndNotify(const std::string& path,
                                               base::Value* default_value,
                                               uint32 flags) {
  RegisterPreference(path, default_value, flags);
  OnPrefRegistered(path, default_value, flags);
}
