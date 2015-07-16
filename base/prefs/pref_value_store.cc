// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/prefs/pref_value_store.h"

#include "base/logging.h"
#include "base/prefs/pref_notifier.h"
#include "base/prefs/pref_observer.h"

PrefValueStore::PrefStoreKeeper::PrefStoreKeeper()
    : pref_value_store_(NULL),
      type_(PrefValueStore::INVALID_STORE) {
}

PrefValueStore::PrefStoreKeeper::~PrefStoreKeeper() {
  if (pref_store_.get()) {
    pref_store_->RemoveObserver(this);
    pref_store_ = NULL;
  }
  pref_value_store_ = NULL;
}

void PrefValueStore::PrefStoreKeeper::Initialize(
    PrefValueStore* store,
    PrefStore* pref_store,
    PrefValueStore::PrefStoreType type) {
  if (pref_store_.get()) {
    pref_store_->RemoveObserver(this);
    DCHECK(!pref_store_->HasObservers());
  }
  type_ = type;
  pref_value_store_ = store;
  pref_store_ = pref_store;
  if (pref_store_.get())
    pref_store_->AddObserver(this);
}

void PrefValueStore::PrefStoreKeeper::OnPrefValueChanged(
    const std::string& key) {
  pref_value_store_->OnPrefValueChanged(type_, key);
}

void PrefValueStore::PrefStoreKeeper::OnInitializationCompleted(
    bool succeeded) {
  pref_value_store_->OnInitializationCompleted(type_, succeeded);
}

PrefValueStore::PrefValueStore(PrefStore* managed_prefs,
                               PrefStore* supervised_user_prefs,
                               PrefStore* extension_prefs,
                               PrefStore* command_line_prefs,
                               PrefStore* user_prefs,
                               PrefStore* recommended_prefs,
                               PrefStore* default_prefs,
                               PrefNotifier* pref_notifier)
    : pref_notifier_(pref_notifier),
      initialization_failed_(false) {
  InitPrefStore(MANAGED_STORE, managed_prefs);
  InitPrefStore(SUPERVISED_USER_STORE, supervised_user_prefs);
  InitPrefStore(EXTENSION_STORE, extension_prefs);
  InitPrefStore(COMMAND_LINE_STORE, command_line_prefs);
  InitPrefStore(USER_STORE, user_prefs);
  InitPrefStore(RECOMMENDED_STORE, recommended_prefs);
  InitPrefStore(DEFAULT_STORE, default_prefs);

  CheckInitializationCompleted();
}

PrefValueStore::~PrefValueStore() {}

PrefValueStore* PrefValueStore::CloneAndSpecialize(
    PrefStore* managed_prefs,
    PrefStore* supervised_user_prefs,
    PrefStore* extension_prefs,
    PrefStore* command_line_prefs,
    PrefStore* user_prefs,
    PrefStore* recommended_prefs,
    PrefStore* default_prefs,
    PrefNotifier* pref_notifier) {
  DCHECK(pref_notifier);
  if (!managed_prefs)
    managed_prefs = GetPrefStore(MANAGED_STORE);
  if (!supervised_user_prefs)
    supervised_user_prefs = GetPrefStore(SUPERVISED_USER_STORE);
  if (!extension_prefs)
    extension_prefs = GetPrefStore(EXTENSION_STORE);
  if (!command_line_prefs)
    command_line_prefs = GetPrefStore(COMMAND_LINE_STORE);
  if (!user_prefs)
    user_prefs = GetPrefStore(USER_STORE);
  if (!recommended_prefs)
    recommended_prefs = GetPrefStore(RECOMMENDED_STORE);
  if (!default_prefs)
    default_prefs = GetPrefStore(DEFAULT_STORE);

  return new PrefValueStore(
      managed_prefs, supervised_user_prefs, extension_prefs, command_line_prefs,
      user_prefs, recommended_prefs, default_prefs, pref_notifier);
}

void PrefValueStore::set_callback(const PrefChangedCallback& callback) {
  pref_changed_callback_ = callback;
}

bool PrefValueStore::GetValue(const std::string& name,
                              base::Value::Type type,
                              const base::Value** out_value) const {
  // Check the |PrefStore|s in order of their priority from highest to lowest,
  // looking for the first preference value with the given |name| and |type|.
  for (size_t i = 0; i <= PREF_STORE_TYPE_MAX; ++i) {
    if (GetValueFromStoreWithType(name, type, static_cast<PrefStoreType>(i),
                                  out_value))
      return true;
  }
  return false;
}

bool PrefValueStore::GetRecommendedValue(const std::string& name,
                                         base::Value::Type type,
                                         const base::Value** out_value) const {
  return GetValueFromStoreWithType(name, type, RECOMMENDED_STORE, out_value);
}

void PrefValueStore::NotifyPrefChanged(
    const std::string& path,
    PrefValueStore::PrefStoreType new_store) {
  DCHECK(new_store != INVALID_STORE);
  // A notification is sent when the pref value in any store changes. If this
  // store is currently being overridden by a higher-priority store, the
  // effective value of the pref will not have changed.
  pref_notifier_->OnPreferenceChanged(path);
  if (!pref_changed_callback_.is_null())
    pref_changed_callback_.Run(path);
}

bool PrefValueStore::PrefValueInManagedStore(const std::string& name) const {
  return PrefValueInStore(name, MANAGED_STORE);
}

bool PrefValueStore::PrefValueInSupervisedStore(const std::string& name) const {
  return PrefValueInStore(name, SUPERVISED_USER_STORE);
}

bool PrefValueStore::PrefValueInExtensionStore(const std::string& name) const {
  return PrefValueInStore(name, EXTENSION_STORE);
}

bool PrefValueStore::PrefValueInUserStore(const std::string& name) const {
  return PrefValueInStore(name, USER_STORE);
}

bool PrefValueStore::PrefValueFromExtensionStore(
    const std::string& name) const {
  return ControllingPrefStoreForPref(name) == EXTENSION_STORE;
}

bool PrefValueStore::PrefValueFromUserStore(const std::string& name) const {
  return ControllingPrefStoreForPref(name) == USER_STORE;
}

bool PrefValueStore::PrefValueFromRecommendedStore(
    const std::string& name) const {
  return ControllingPrefStoreForPref(name) == RECOMMENDED_STORE;
}

bool PrefValueStore::PrefValueFromDefaultStore(const std::string& name) const {
  return ControllingPrefStoreForPref(name) == DEFAULT_STORE;
}

bool PrefValueStore::PrefValueUserModifiable(const std::string& name) const {
  PrefStoreType effective_store = ControllingPrefStoreForPref(name);
  return effective_store >= USER_STORE ||
         effective_store == INVALID_STORE;
}

bool PrefValueStore::PrefValueExtensionModifiable(
    const std::string& name) const {
  PrefStoreType effective_store = ControllingPrefStoreForPref(name);
  return effective_store >= EXTENSION_STORE ||
         effective_store == INVALID_STORE;
}

void PrefValueStore::UpdateCommandLinePrefStore(PrefStore* command_line_prefs) {
  InitPrefStore(COMMAND_LINE_STORE, command_line_prefs);
}

bool PrefValueStore::PrefValueInStore(
    const std::string& name,
    PrefValueStore::PrefStoreType store) const {
  // Declare a temp Value* and call GetValueFromStore,
  // ignoring the output value.
  const base::Value* tmp_value = NULL;
  return GetValueFromStore(name, store, &tmp_value);
}

bool PrefValueStore::PrefValueInStoreRange(
    const std::string& name,
    PrefValueStore::PrefStoreType first_checked_store,
    PrefValueStore::PrefStoreType last_checked_store) const {
  if (first_checked_store > last_checked_store) {
    NOTREACHED();
    return false;
  }

  for (size_t i = first_checked_store;
       i <= static_cast<size_t>(last_checked_store); ++i) {
    if (PrefValueInStore(name, static_cast<PrefStoreType>(i)))
      return true;
  }
  return false;
}

PrefValueStore::PrefStoreType PrefValueStore::ControllingPrefStoreForPref(
    const std::string& name) const {
  for (size_t i = 0; i <= PREF_STORE_TYPE_MAX; ++i) {
    if (PrefValueInStore(name, static_cast<PrefStoreType>(i)))
      return static_cast<PrefStoreType>(i);
  }
  return INVALID_STORE;
}

bool PrefValueStore::GetValueFromStore(const std::string& name,
                                       PrefValueStore::PrefStoreType store_type,
                                       const base::Value** out_value) const {
  // Only return true if we find a value and it is the correct type, so stale
  // values with the incorrect type will be ignored.
  const PrefStore* store = GetPrefStore(static_cast<PrefStoreType>(store_type));
  if (store && store->GetValue(name, out_value))
    return true;

  // No valid value found for the given preference name: set the return value
  // to false.
  *out_value = NULL;
  return false;
}

bool PrefValueStore::GetValueFromStoreWithType(
    const std::string& name,
    base::Value::Type type,
    PrefStoreType store,
    const base::Value** out_value) const {
  if (GetValueFromStore(name, store, out_value)) {
    if ((*out_value)->IsType(type))
      return true;

    LOG(WARNING) << "Expected type for " << name << " is " << type
                 << " but got " << (*out_value)->GetType()
                 << " in store " << store;
  }

  *out_value = NULL;
  return false;
}

void PrefValueStore::OnPrefValueChanged(PrefValueStore::PrefStoreType type,
                                        const std::string& key) {
  NotifyPrefChanged(key, type);
}

void PrefValueStore::OnInitializationCompleted(
    PrefValueStore::PrefStoreType type, bool succeeded) {
  if (initialization_failed_)
    return;
  if (!succeeded) {
    initialization_failed_ = true;
    pref_notifier_->OnInitializationCompleted(false);
    return;
  }
  CheckInitializationCompleted();
}

void PrefValueStore::InitPrefStore(PrefValueStore::PrefStoreType type,
                                   PrefStore* pref_store) {
  pref_stores_[type].Initialize(this, pref_store, type);
}

void PrefValueStore::CheckInitializationCompleted() {
  if (initialization_failed_)
    return;
  for (size_t i = 0; i <= PREF_STORE_TYPE_MAX; ++i) {
    scoped_refptr<PrefStore> store =
        GetPrefStore(static_cast<PrefStoreType>(i));
    if (store.get() && !store->IsInitializationComplete())
      return;
  }
  pref_notifier_->OnInitializationCompleted(true);
}
