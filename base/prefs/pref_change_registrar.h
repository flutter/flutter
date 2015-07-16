// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_PREFS_PREF_CHANGE_REGISTRAR_H_
#define BASE_PREFS_PREF_CHANGE_REGISTRAR_H_

#include <map>
#include <string>

#include "base/basictypes.h"
#include "base/callback.h"
#include "base/prefs/base_prefs_export.h"
#include "base/prefs/pref_observer.h"

class PrefService;

// Automatically manages the registration of one or more pref change observers
// with a PrefStore. Functions much like NotificationRegistrar, but specifically
// manages observers of preference changes. When the Registrar is destroyed,
// all registered observers are automatically unregistered with the PrefStore.
class BASE_PREFS_EXPORT PrefChangeRegistrar : public PrefObserver {
 public:
  // You can register this type of callback if you need to know the
  // path of the preference that is changing.
  typedef base::Callback<void(const std::string&)> NamedChangeCallback;

  PrefChangeRegistrar();
  virtual ~PrefChangeRegistrar();

  // Must be called before adding or removing observers. Can be called more
  // than once as long as the value of |service| doesn't change.
  void Init(PrefService* service);

  // Adds a pref observer for the specified pref |path| and |obs| observer
  // object. All registered observers will be automatically unregistered
  // when the registrar's destructor is called.
  //
  // The second version binds a callback that will receive the path of
  // the preference that is changing as its parameter.
  //
  // Only one observer may be registered per path.
  void Add(const std::string& path, const base::Closure& obs);
  void Add(const std::string& path, const NamedChangeCallback& obs);

  // Removes the pref observer registered for |path|.
  void Remove(const std::string& path);

  // Removes all observers that have been previously added with a call to Add.
  void RemoveAll();

  // Returns true if no pref observers are registered.
  bool IsEmpty() const;

  // Check whether |pref| is in the set of preferences being observed.
  bool IsObserved(const std::string& pref);

  // Check whether any of the observed preferences has the managed bit set.
  bool IsManaged();

  // Return the PrefService for this registrar.
  PrefService* prefs();
  const PrefService* prefs() const;

 private:
  // PrefObserver:
  void OnPreferenceChanged(PrefService* service,
                           const std::string& pref_name) override;

  static void InvokeUnnamedCallback(const base::Closure& callback,
                                    const std::string& pref_name);

  typedef std::map<std::string, NamedChangeCallback> ObserverMap;

  ObserverMap observers_;
  PrefService* service_;

  DISALLOW_COPY_AND_ASSIGN(PrefChangeRegistrar);
};

#endif  // BASE_PREFS_PREF_CHANGE_REGISTRAR_H_
