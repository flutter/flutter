// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/prefs/pref_registry.h"

#include "base/logging.h"
#include "base/prefs/default_pref_store.h"
#include "base/prefs/pref_store.h"
#include "base/stl_util.h"
#include "base/values.h"

PrefRegistry::PrefRegistry()
    : defaults_(new DefaultPrefStore()) {
}

PrefRegistry::~PrefRegistry() {
}

uint32 PrefRegistry::GetRegistrationFlags(const std::string& pref_name) const {
  const auto& it = registration_flags_.find(pref_name);
  if (it == registration_flags_.end())
    return NO_REGISTRATION_FLAGS;
  return it->second;
}

scoped_refptr<PrefStore> PrefRegistry::defaults() {
  return defaults_.get();
}

PrefRegistry::const_iterator PrefRegistry::begin() const {
  return defaults_->begin();
}

PrefRegistry::const_iterator PrefRegistry::end() const {
  return defaults_->end();
}

void PrefRegistry::SetDefaultPrefValue(const std::string& pref_name,
                                       base::Value* value) {
  DCHECK(value);
  const base::Value* current_value = NULL;
  DCHECK(defaults_->GetValue(pref_name, &current_value))
      << "Setting default for unregistered pref: " << pref_name;
  DCHECK(value->IsType(current_value->GetType()))
      << "Wrong type for new default: " << pref_name;

  defaults_->ReplaceDefaultValue(pref_name, make_scoped_ptr(value));
}

void PrefRegistry::RegisterPreference(const std::string& path,
                                      base::Value* default_value,
                                      uint32 flags) {
  base::Value::Type orig_type = default_value->GetType();
  DCHECK(orig_type != base::Value::TYPE_NULL &&
         orig_type != base::Value::TYPE_BINARY) <<
         "invalid preference type: " << orig_type;
  DCHECK(!defaults_->GetValue(path, NULL)) <<
      "Trying to register a previously registered pref: " << path;
  DCHECK(!ContainsKey(registration_flags_, path)) <<
      "Trying to register a previously registered pref: " << path;

  defaults_->SetDefaultValue(path, make_scoped_ptr(default_value));
  if (flags != NO_REGISTRATION_FLAGS)
    registration_flags_[path] = flags;
}
