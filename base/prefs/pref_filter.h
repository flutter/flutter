// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_PREFS_PREF_FILTER_H_
#define BASE_PREFS_PREF_FILTER_H_

#include <string>

#include "base/callback_forward.h"
#include "base/memory/scoped_ptr.h"
#include "base/prefs/base_prefs_export.h"

namespace base {
class DictionaryValue;
class Value;
}  // namespace base

// Filters preferences as they are loaded from disk or updated at runtime.
// Currently supported only by JsonPrefStore.
class BASE_PREFS_EXPORT PrefFilter {
 public:
  // A callback to be invoked when |prefs| have been read (and possibly
  // pre-modified) and are now ready to be handed back to this callback's
  // builder. |schedule_write| indicates whether a write should be immediately
  // scheduled (typically because the |prefs| were pre-modified).
  typedef base::Callback<void(scoped_ptr<base::DictionaryValue> prefs,
                              bool schedule_write)> PostFilterOnLoadCallback;

  virtual ~PrefFilter() {}

  // This method is given ownership of the |pref_store_contents| read from disk
  // before the underlying PersistentPrefStore gets to use them. It must hand
  // them back via |post_filter_on_load_callback|, but may modify them first.
  // Note: This method is asynchronous, which may make calls like
  // PersistentPrefStore::ReadPrefs() asynchronous. The owner of filtered
  // PersistentPrefStores should handle this to make the reads look synchronous
  // to external users (see SegregatedPrefStore::ReadPrefs() for an example).
  virtual void FilterOnLoad(
      const PostFilterOnLoadCallback& post_filter_on_load_callback,
      scoped_ptr<base::DictionaryValue> pref_store_contents) = 0;

  // Receives notification when a pref store value is changed, before Observers
  // are notified.
  virtual void FilterUpdate(const std::string& path) = 0;

  // Receives notification when the pref store is about to serialize data
  // contained in |pref_store_contents| to a string. Modifications to
  // |pref_store_contents| will be persisted to disk and also affect the
  // in-memory state.
  virtual void FilterSerializeData(
      base::DictionaryValue* pref_store_contents) = 0;
};

#endif  // BASE_PREFS_PREF_FILTER_H_
