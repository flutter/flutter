// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_PREFS_WRITEABLE_PREF_STORE_H_
#define BASE_PREFS_WRITEABLE_PREF_STORE_H_

#include <string>

#include "base/basictypes.h"
#include "base/memory/scoped_ptr.h"
#include "base/prefs/pref_store.h"

namespace base {
class Value;
}

// A pref store that can be written to as well as read from.
class BASE_PREFS_EXPORT WriteablePrefStore : public PrefStore {
 public:
  // PrefWriteFlags can be used to change the way a pref will be written to
  // storage.
  enum PrefWriteFlags : uint32 {
    // No flags are specified.
    DEFAULT_PREF_WRITE_FLAGS = 0,

    // This marks the pref as "lossy". There is no strict time guarantee on when
    // a lossy pref will be persisted to permanent storage when it is modified.
    LOSSY_PREF_WRITE_FLAG = 1 << 1
  };

  WriteablePrefStore() {}

  // Sets a |value| for |key| in the store. |value| must be non-NULL. |flags| is
  // a bitmask of PrefWriteFlags.
  virtual void SetValue(const std::string& key,
                        scoped_ptr<base::Value> value,
                        uint32 flags) = 0;

  // Removes the value for |key|.
  virtual void RemoveValue(const std::string& key, uint32 flags) = 0;

  // Equivalent to PrefStore::GetValue but returns a mutable value.
  virtual bool GetMutableValue(const std::string& key,
                               base::Value** result) = 0;

  // Triggers a value changed notification. This function needs to be called
  // if one retrieves a list or dictionary with GetMutableValue and change its
  // value. SetValue takes care of notifications itself. Note that
  // ReportValueChanged will trigger notifications even if nothing has changed.
  // |flags| is a bitmask of PrefWriteFlags.
  virtual void ReportValueChanged(const std::string& key, uint32 flags) = 0;

  // Same as SetValue, but doesn't generate notifications. This is used by
  // PrefService::GetMutableUserPref() in order to put empty entries
  // into the user pref store. Using SetValue is not an option since existing
  // tests rely on the number of notifications generated. |flags| is a bitmask
  // of PrefWriteFlags.
  virtual void SetValueSilently(const std::string& key,
                                scoped_ptr<base::Value> value,
                                uint32 flags) = 0;

 protected:
  ~WriteablePrefStore() override {}

 private:
  DISALLOW_COPY_AND_ASSIGN(WriteablePrefStore);
};

#endif  // BASE_PREFS_WRITEABLE_PREF_STORE_H_
