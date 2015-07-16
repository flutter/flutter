// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/prefs/pref_service_factory.h"

#include "base/bind.h"
#include "base/prefs/default_pref_store.h"
#include "base/prefs/json_pref_store.h"
#include "base/prefs/pref_filter.h"
#include "base/prefs/pref_notifier_impl.h"
#include "base/prefs/pref_service.h"
#include "base/prefs/pref_value_store.h"
#include "base/sequenced_task_runner.h"

namespace base {

namespace {

// Do-nothing default implementation.
void DoNothingHandleReadError(PersistentPrefStore::PrefReadError error) {
}

}  // namespace

PrefServiceFactory::PrefServiceFactory()
    : managed_prefs_(NULL),
      supervised_user_prefs_(NULL),
      extension_prefs_(NULL),
      command_line_prefs_(NULL),
      user_prefs_(NULL),
      recommended_prefs_(NULL),
      read_error_callback_(base::Bind(&DoNothingHandleReadError)),
      async_(false) {}

PrefServiceFactory::~PrefServiceFactory() {}

void PrefServiceFactory::SetUserPrefsFile(
    const base::FilePath& prefs_file,
    base::SequencedTaskRunner* task_runner) {
  user_prefs_ = new JsonPrefStore(
      prefs_file, task_runner, scoped_ptr<PrefFilter>());
}

scoped_ptr<PrefService> PrefServiceFactory::Create(
    PrefRegistry* pref_registry) {
  PrefNotifierImpl* pref_notifier = new PrefNotifierImpl();
  scoped_ptr<PrefService> pref_service(
      new PrefService(pref_notifier,
                      new PrefValueStore(managed_prefs_.get(),
                                         supervised_user_prefs_.get(),
                                         extension_prefs_.get(),
                                         command_line_prefs_.get(),
                                         user_prefs_.get(),
                                         recommended_prefs_.get(),
                                         pref_registry->defaults().get(),
                                         pref_notifier),
                      user_prefs_.get(),
                      pref_registry,
                      read_error_callback_,
                      async_));
  return pref_service.Pass();
}

}  // namespace base
