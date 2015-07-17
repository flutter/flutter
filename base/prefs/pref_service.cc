// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/prefs/pref_service.h"

#include <algorithm>

#include "base/bind.h"
#include "base/files/file_path.h"
#include "base/location.h"
#include "base/logging.h"
#include "base/metrics/histogram.h"
#include "base/prefs/default_pref_store.h"
#include "base/prefs/pref_notifier_impl.h"
#include "base/prefs/pref_registry.h"
#include "base/prefs/pref_value_store.h"
#include "base/single_thread_task_runner.h"
#include "base/stl_util.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_util.h"
#include "base/thread_task_runner_handle.h"
#include "base/value_conversions.h"
#include "build/build_config.h"

namespace {

class ReadErrorHandler : public PersistentPrefStore::ReadErrorDelegate {
 public:
  ReadErrorHandler(base::Callback<void(PersistentPrefStore::PrefReadError)> cb)
      : callback_(cb) {}

  void OnError(PersistentPrefStore::PrefReadError error) override {
    callback_.Run(error);
  }

 private:
  base::Callback<void(PersistentPrefStore::PrefReadError)> callback_;
};

// Returns the WriteablePrefStore::PrefWriteFlags for the pref with the given
// |path|.
uint32 GetWriteFlags(const PrefService::Preference* pref) {
  uint32 write_flags = WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS;

  if (!pref)
    return write_flags;

  if (pref->registration_flags() & PrefRegistry::LOSSY_PREF)
    write_flags |= WriteablePrefStore::LOSSY_PREF_WRITE_FLAG;
  return write_flags;
}

}  // namespace

PrefService::PrefService(
    PrefNotifierImpl* pref_notifier,
    PrefValueStore* pref_value_store,
    PersistentPrefStore* user_prefs,
    PrefRegistry* pref_registry,
    base::Callback<void(PersistentPrefStore::PrefReadError)>
        read_error_callback,
    bool async)
    : pref_notifier_(pref_notifier),
      pref_value_store_(pref_value_store),
      pref_registry_(pref_registry),
      user_pref_store_(user_prefs),
      read_error_callback_(read_error_callback) {
  pref_notifier_->SetPrefService(this);

  // TODO(battre): This is a check for crbug.com/435208 to make sure that
  // access violations are caused by a use-after-free bug and not by an
  // initialization bug.
  CHECK(pref_registry_);
  CHECK(pref_value_store_);

  InitFromStorage(async);
}

PrefService::~PrefService() {
  DCHECK(CalledOnValidThread());

  // Reset pointers so accesses after destruction reliably crash.
  pref_value_store_.reset();
  pref_registry_ = NULL;
  user_pref_store_ = NULL;
  pref_notifier_.reset();
}

void PrefService::InitFromStorage(bool async) {
  if (user_pref_store_->IsInitializationComplete()) {
    read_error_callback_.Run(user_pref_store_->GetReadError());
  } else if (!async) {
    read_error_callback_.Run(user_pref_store_->ReadPrefs());
  } else {
    // Guarantee that initialization happens after this function returned.
    base::ThreadTaskRunnerHandle::Get()->PostTask(
        FROM_HERE,
        base::Bind(&PersistentPrefStore::ReadPrefsAsync, user_pref_store_.get(),
                   new ReadErrorHandler(read_error_callback_)));
  }
}

void PrefService::CommitPendingWrite() {
  DCHECK(CalledOnValidThread());
  user_pref_store_->CommitPendingWrite();
}

void PrefService::SchedulePendingLossyWrites() {
  DCHECK(CalledOnValidThread());
  user_pref_store_->SchedulePendingLossyWrites();
}

bool PrefService::GetBoolean(const std::string& path) const {
  DCHECK(CalledOnValidThread());

  bool result = false;

  const base::Value* value = GetPreferenceValue(path);
  if (!value) {
    NOTREACHED() << "Trying to read an unregistered pref: " << path;
    return result;
  }
  bool rv = value->GetAsBoolean(&result);
  DCHECK(rv);
  return result;
}

int PrefService::GetInteger(const std::string& path) const {
  DCHECK(CalledOnValidThread());

  int result = 0;

  const base::Value* value = GetPreferenceValue(path);
  if (!value) {
    NOTREACHED() << "Trying to read an unregistered pref: " << path;
    return result;
  }
  bool rv = value->GetAsInteger(&result);
  DCHECK(rv);
  return result;
}

double PrefService::GetDouble(const std::string& path) const {
  DCHECK(CalledOnValidThread());

  double result = 0.0;

  const base::Value* value = GetPreferenceValue(path);
  if (!value) {
    NOTREACHED() << "Trying to read an unregistered pref: " << path;
    return result;
  }
  bool rv = value->GetAsDouble(&result);
  DCHECK(rv);
  return result;
}

std::string PrefService::GetString(const std::string& path) const {
  DCHECK(CalledOnValidThread());

  std::string result;

  const base::Value* value = GetPreferenceValue(path);
  if (!value) {
    NOTREACHED() << "Trying to read an unregistered pref: " << path;
    return result;
  }
  bool rv = value->GetAsString(&result);
  DCHECK(rv);
  return result;
}

base::FilePath PrefService::GetFilePath(const std::string& path) const {
  DCHECK(CalledOnValidThread());

  base::FilePath result;

  const base::Value* value = GetPreferenceValue(path);
  if (!value) {
    NOTREACHED() << "Trying to read an unregistered pref: " << path;
    return base::FilePath(result);
  }
  bool rv = base::GetValueAsFilePath(*value, &result);
  DCHECK(rv);
  return result;
}

bool PrefService::HasPrefPath(const std::string& path) const {
  const Preference* pref = FindPreference(path);
  return pref && !pref->IsDefaultValue();
}

scoped_ptr<base::DictionaryValue> PrefService::GetPreferenceValues() const {
  DCHECK(CalledOnValidThread());
  scoped_ptr<base::DictionaryValue> out(new base::DictionaryValue);
  for (const auto& it : *pref_registry_) {
    out->Set(it.first, GetPreferenceValue(it.first)->CreateDeepCopy());
  }
  return out.Pass();
}

scoped_ptr<base::DictionaryValue> PrefService::GetPreferenceValuesOmitDefaults()
    const {
  DCHECK(CalledOnValidThread());
  scoped_ptr<base::DictionaryValue> out(new base::DictionaryValue);
  for (const auto& it : *pref_registry_) {
    const Preference* pref = FindPreference(it.first);
    if (pref->IsDefaultValue())
      continue;
    out->Set(it.first, pref->GetValue()->CreateDeepCopy());
  }
  return out.Pass();
}

scoped_ptr<base::DictionaryValue>
PrefService::GetPreferenceValuesWithoutPathExpansion() const {
  DCHECK(CalledOnValidThread());
  scoped_ptr<base::DictionaryValue> out(new base::DictionaryValue);
  for (const auto& it : *pref_registry_) {
    const base::Value* value = GetPreferenceValue(it.first);
    DCHECK(value);
    out->SetWithoutPathExpansion(it.first, value->CreateDeepCopy());
  }
  return out.Pass();
}

const PrefService::Preference* PrefService::FindPreference(
    const std::string& pref_name) const {
  DCHECK(CalledOnValidThread());
  PreferenceMap::iterator it = prefs_map_.find(pref_name);
  if (it != prefs_map_.end())
    return &(it->second);
  const base::Value* default_value = NULL;
  if (!pref_registry_->defaults()->GetValue(pref_name, &default_value))
    return NULL;
  it = prefs_map_.insert(
      std::make_pair(pref_name, Preference(
          this, pref_name, default_value->GetType()))).first;
  return &(it->second);
}

bool PrefService::ReadOnly() const {
  return user_pref_store_->ReadOnly();
}

PrefService::PrefInitializationStatus PrefService::GetInitializationStatus()
    const {
  if (!user_pref_store_->IsInitializationComplete())
    return INITIALIZATION_STATUS_WAITING;

  switch (user_pref_store_->GetReadError()) {
    case PersistentPrefStore::PREF_READ_ERROR_NONE:
      return INITIALIZATION_STATUS_SUCCESS;
    case PersistentPrefStore::PREF_READ_ERROR_NO_FILE:
      return INITIALIZATION_STATUS_CREATED_NEW_PREF_STORE;
    default:
      return INITIALIZATION_STATUS_ERROR;
  }
}

bool PrefService::IsManagedPreference(const std::string& pref_name) const {
  const Preference* pref = FindPreference(pref_name);
  return pref && pref->IsManaged();
}

bool PrefService::IsPreferenceManagedByCustodian(
    const std::string& pref_name) const {
  const Preference* pref = FindPreference(pref_name);
  return pref && pref->IsManagedByCustodian();
}

bool PrefService::IsUserModifiablePreference(
    const std::string& pref_name) const {
  const Preference* pref = FindPreference(pref_name);
  return pref && pref->IsUserModifiable();
}

const base::DictionaryValue* PrefService::GetDictionary(
    const std::string& path) const {
  DCHECK(CalledOnValidThread());

  const base::Value* value = GetPreferenceValue(path);
  if (!value) {
    NOTREACHED() << "Trying to read an unregistered pref: " << path;
    return NULL;
  }
  if (value->GetType() != base::Value::TYPE_DICTIONARY) {
    NOTREACHED();
    return NULL;
  }
  return static_cast<const base::DictionaryValue*>(value);
}

const base::Value* PrefService::GetUserPrefValue(
    const std::string& path) const {
  DCHECK(CalledOnValidThread());

  const Preference* pref = FindPreference(path);
  if (!pref) {
    NOTREACHED() << "Trying to get an unregistered pref: " << path;
    return NULL;
  }

  // Look for an existing preference in the user store. If it doesn't
  // exist, return NULL.
  base::Value* value = NULL;
  if (!user_pref_store_->GetMutableValue(path, &value))
    return NULL;

  if (!value->IsType(pref->GetType())) {
    NOTREACHED() << "Pref value type doesn't match registered type.";
    return NULL;
  }

  return value;
}

void PrefService::SetDefaultPrefValue(const std::string& path,
                                      base::Value* value) {
  DCHECK(CalledOnValidThread());
  pref_registry_->SetDefaultPrefValue(path, value);
}

const base::Value* PrefService::GetDefaultPrefValue(
    const std::string& path) const {
  DCHECK(CalledOnValidThread());
  // Lookup the preference in the default store.
  const base::Value* value = NULL;
  if (!pref_registry_->defaults()->GetValue(path, &value)) {
    NOTREACHED() << "Default value missing for pref: " << path;
    return NULL;
  }
  return value;
}

const base::ListValue* PrefService::GetList(const std::string& path) const {
  DCHECK(CalledOnValidThread());

  const base::Value* value = GetPreferenceValue(path);
  if (!value) {
    NOTREACHED() << "Trying to read an unregistered pref: " << path;
    return NULL;
  }
  if (value->GetType() != base::Value::TYPE_LIST) {
    NOTREACHED();
    return NULL;
  }
  return static_cast<const base::ListValue*>(value);
}

void PrefService::AddPrefObserver(const std::string& path, PrefObserver* obs) {
  pref_notifier_->AddPrefObserver(path, obs);
}

void PrefService::RemovePrefObserver(const std::string& path,
                                     PrefObserver* obs) {
  pref_notifier_->RemovePrefObserver(path, obs);
}

void PrefService::AddPrefInitObserver(base::Callback<void(bool)> obs) {
  pref_notifier_->AddInitObserver(obs);
}

PrefRegistry* PrefService::DeprecatedGetPrefRegistry() {
  return pref_registry_.get();
}

void PrefService::ClearPref(const std::string& path) {
  DCHECK(CalledOnValidThread());

  const Preference* pref = FindPreference(path);
  if (!pref) {
    NOTREACHED() << "Trying to clear an unregistered pref: " << path;
    return;
  }
  user_pref_store_->RemoveValue(path, GetWriteFlags(pref));
}

void PrefService::Set(const std::string& path, const base::Value& value) {
  SetUserPrefValue(path, value.DeepCopy());
}

void PrefService::SetBoolean(const std::string& path, bool value) {
  SetUserPrefValue(path, new base::FundamentalValue(value));
}

void PrefService::SetInteger(const std::string& path, int value) {
  SetUserPrefValue(path, new base::FundamentalValue(value));
}

void PrefService::SetDouble(const std::string& path, double value) {
  SetUserPrefValue(path, new base::FundamentalValue(value));
}

void PrefService::SetString(const std::string& path, const std::string& value) {
  SetUserPrefValue(path, new base::StringValue(value));
}

void PrefService::SetFilePath(const std::string& path,
                              const base::FilePath& value) {
  SetUserPrefValue(path, base::CreateFilePathValue(value));
}

void PrefService::SetInt64(const std::string& path, int64 value) {
  SetUserPrefValue(path, new base::StringValue(base::Int64ToString(value)));
}

int64 PrefService::GetInt64(const std::string& path) const {
  DCHECK(CalledOnValidThread());

  const base::Value* value = GetPreferenceValue(path);
  if (!value) {
    NOTREACHED() << "Trying to read an unregistered pref: " << path;
    return 0;
  }
  std::string result("0");
  bool rv = value->GetAsString(&result);
  DCHECK(rv);

  int64 val;
  base::StringToInt64(result, &val);
  return val;
}

void PrefService::SetUint64(const std::string& path, uint64 value) {
  SetUserPrefValue(path, new base::StringValue(base::Uint64ToString(value)));
}

uint64 PrefService::GetUint64(const std::string& path) const {
  DCHECK(CalledOnValidThread());

  const base::Value* value = GetPreferenceValue(path);
  if (!value) {
    NOTREACHED() << "Trying to read an unregistered pref: " << path;
    return 0;
  }
  std::string result("0");
  bool rv = value->GetAsString(&result);
  DCHECK(rv);

  uint64 val;
  base::StringToUint64(result, &val);
  return val;
}

base::Value* PrefService::GetMutableUserPref(const std::string& path,
                                             base::Value::Type type) {
  CHECK(type == base::Value::TYPE_DICTIONARY || type == base::Value::TYPE_LIST);
  DCHECK(CalledOnValidThread());

  const Preference* pref = FindPreference(path);
  if (!pref) {
    NOTREACHED() << "Trying to get an unregistered pref: " << path;
    return NULL;
  }
  if (pref->GetType() != type) {
    NOTREACHED() << "Wrong type for GetMutableValue: " << path;
    return NULL;
  }

  // Look for an existing preference in the user store. If it doesn't
  // exist or isn't the correct type, create a new user preference.
  base::Value* value = NULL;
  if (!user_pref_store_->GetMutableValue(path, &value) ||
      !value->IsType(type)) {
    if (type == base::Value::TYPE_DICTIONARY) {
      value = new base::DictionaryValue;
    } else if (type == base::Value::TYPE_LIST) {
      value = new base::ListValue;
    } else {
      NOTREACHED();
    }
    user_pref_store_->SetValueSilently(path, make_scoped_ptr(value),
                                       GetWriteFlags(pref));
  }
  return value;
}

void PrefService::ReportUserPrefChanged(const std::string& key) {
  DCHECK(CalledOnValidThread());
  user_pref_store_->ReportValueChanged(key, GetWriteFlags(FindPreference(key)));
}

void PrefService::SetUserPrefValue(const std::string& path,
                                   base::Value* new_value) {
  scoped_ptr<base::Value> owned_value(new_value);
  DCHECK(CalledOnValidThread());

  const Preference* pref = FindPreference(path);
  if (!pref) {
    NOTREACHED() << "Trying to write an unregistered pref: " << path;
    return;
  }
  if (pref->GetType() != new_value->GetType()) {
    NOTREACHED() << "Trying to set pref " << path
                 << " of type " << pref->GetType()
                 << " to value of type " << new_value->GetType();
    return;
  }

  user_pref_store_->SetValue(path, owned_value.Pass(), GetWriteFlags(pref));
}

void PrefService::UpdateCommandLinePrefStore(PrefStore* command_line_store) {
  pref_value_store_->UpdateCommandLinePrefStore(command_line_store);
}

///////////////////////////////////////////////////////////////////////////////
// PrefService::Preference

PrefService::Preference::Preference(const PrefService* service,
                                    const std::string& name,
                                    base::Value::Type type)
    : name_(name), type_(type), pref_service_(service) {
  DCHECK(service);
  // Cache the registration flags at creation time to avoid multiple map lookups
  // later.
  registration_flags_ = service->pref_registry_->GetRegistrationFlags(name_);
}

const std::string PrefService::Preference::name() const {
  return name_;
}

base::Value::Type PrefService::Preference::GetType() const {
  return type_;
}

const base::Value* PrefService::Preference::GetValue() const {
  const base::Value* result= pref_service_->GetPreferenceValue(name_);
  DCHECK(result) << "Must register pref before getting its value";
  return result;
}

const base::Value* PrefService::Preference::GetRecommendedValue() const {
  DCHECK(pref_service_->FindPreference(name_))
      << "Must register pref before getting its value";

  const base::Value* found_value = NULL;
  if (pref_value_store()->GetRecommendedValue(name_, type_, &found_value)) {
    DCHECK(found_value->IsType(type_));
    return found_value;
  }

  // The pref has no recommended value.
  return NULL;
}

bool PrefService::Preference::IsManaged() const {
  return pref_value_store()->PrefValueInManagedStore(name_);
}

bool PrefService::Preference::IsManagedByCustodian() const {
  return pref_value_store()->PrefValueInSupervisedStore(name_.c_str());
}

bool PrefService::Preference::IsRecommended() const {
  return pref_value_store()->PrefValueFromRecommendedStore(name_);
}

bool PrefService::Preference::HasExtensionSetting() const {
  return pref_value_store()->PrefValueInExtensionStore(name_);
}

bool PrefService::Preference::HasUserSetting() const {
  return pref_value_store()->PrefValueInUserStore(name_);
}

bool PrefService::Preference::IsExtensionControlled() const {
  return pref_value_store()->PrefValueFromExtensionStore(name_);
}

bool PrefService::Preference::IsUserControlled() const {
  return pref_value_store()->PrefValueFromUserStore(name_);
}

bool PrefService::Preference::IsDefaultValue() const {
  return pref_value_store()->PrefValueFromDefaultStore(name_);
}

bool PrefService::Preference::IsUserModifiable() const {
  return pref_value_store()->PrefValueUserModifiable(name_);
}

bool PrefService::Preference::IsExtensionModifiable() const {
  return pref_value_store()->PrefValueExtensionModifiable(name_);
}

const base::Value* PrefService::GetPreferenceValue(
    const std::string& path) const {
  DCHECK(CalledOnValidThread());

  // TODO(battre): This is a check for crbug.com/435208. After analyzing some
  // crash dumps it looks like the PrefService is accessed even though it has
  // been cleared already.
  CHECK(pref_registry_);
  CHECK(pref_registry_->defaults());
  CHECK(pref_value_store_);

  const base::Value* default_value = NULL;
  if (pref_registry_->defaults()->GetValue(path, &default_value)) {
    const base::Value* found_value = NULL;
    base::Value::Type default_type = default_value->GetType();
    if (pref_value_store_->GetValue(path, default_type, &found_value)) {
      DCHECK(found_value->IsType(default_type));
      return found_value;
    } else {
      // Every registered preference has at least a default value.
      NOTREACHED() << "no valid value found for registered pref " << path;
    }
  }

  return NULL;
}
