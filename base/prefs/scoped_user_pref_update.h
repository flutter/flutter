// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// A helper class that assists preferences in firing notifications when lists
// or dictionaries are changed.

#ifndef BASE_PREFS_SCOPED_USER_PREF_UPDATE_H_
#define BASE_PREFS_SCOPED_USER_PREF_UPDATE_H_

#include <string>

#include "base/basictypes.h"
#include "base/prefs/base_prefs_export.h"
#include "base/prefs/pref_service.h"
#include "base/threading/non_thread_safe.h"
#include "base/values.h"

class PrefService;

namespace base {
class DictionaryValue;
class ListValue;
}

namespace subtle {

// Base class for ScopedUserPrefUpdateTemplate that contains the parts
// that do not depend on ScopedUserPrefUpdateTemplate's template parameter.
//
// We need this base class mostly for making it a friend of PrefService
// and getting access to PrefService::GetMutableUserPref and
// PrefService::ReportUserPrefChanged.
class BASE_PREFS_EXPORT ScopedUserPrefUpdateBase : public base::NonThreadSafe {
 protected:
  ScopedUserPrefUpdateBase(PrefService* service, const std::string& path);

  // Calls Notify().
  ~ScopedUserPrefUpdateBase();

  // Sets |value_| to |service_|->GetMutableUserPref and returns it.
  base::Value* GetValueOfType(base::Value::Type type);

 private:
  // If |value_| is not null, triggers a notification of PrefObservers and
  // resets |value_|.
  void Notify();

  // Weak pointer.
  PrefService* service_;
  // Path of the preference being updated.
  std::string path_;
  // Cache of value from user pref store (set between Get() and Notify() calls).
  base::Value* value_;

  DISALLOW_COPY_AND_ASSIGN(ScopedUserPrefUpdateBase);
};

}  // namespace subtle

// Class to support modifications to DictionaryValues and ListValues while
// guaranteeing that PrefObservers are notified of changed values.
//
// This class may only be used on the UI thread as it requires access to the
// PrefService.
template <typename T, base::Value::Type type_enum_value>
class ScopedUserPrefUpdate : public subtle::ScopedUserPrefUpdateBase {
 public:
  ScopedUserPrefUpdate(PrefService* service, const std::string& path)
      : ScopedUserPrefUpdateBase(service, path) {}

  // Triggers an update notification if Get() was called.
  virtual ~ScopedUserPrefUpdate() {}

  // Returns a mutable |T| instance that
  // - is already in the user pref store, or
  // - is (silently) created and written to the user pref store if none existed
  //   before.
  //
  // Calling Get() implies that an update notification is necessary at
  // destruction time.
  //
  // The ownership of the return value remains with the user pref store.
  // Virtual so it can be overriden in subclasses that transform the value
  // before returning it (for example to return a subelement of a dictionary).
  virtual T* Get() {
    return static_cast<T*>(GetValueOfType(type_enum_value));
  }

  T& operator*() {
    return *Get();
  }

  T* operator->() {
    return Get();
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(ScopedUserPrefUpdate);
};

typedef ScopedUserPrefUpdate<base::DictionaryValue,
                             base::Value::TYPE_DICTIONARY>
    DictionaryPrefUpdate;
typedef ScopedUserPrefUpdate<base::ListValue, base::Value::TYPE_LIST>
    ListPrefUpdate;

#endif  // BASE_PREFS_SCOPED_USER_PREF_UPDATE_H_
