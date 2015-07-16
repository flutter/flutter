// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/supports_user_data.h"

namespace base {

SupportsUserData::SupportsUserData() {
  // Harmless to construct on a different thread to subsequent usage.
  thread_checker_.DetachFromThread();
}

SupportsUserData::Data* SupportsUserData::GetUserData(const void* key) const {
  DCHECK(thread_checker_.CalledOnValidThread());
  DataMap::const_iterator found = user_data_.find(key);
  if (found != user_data_.end())
    return found->second.get();
  return NULL;
}

void SupportsUserData::SetUserData(const void* key, Data* data) {
  DCHECK(thread_checker_.CalledOnValidThread());
  user_data_[key] = linked_ptr<Data>(data);
}

void SupportsUserData::RemoveUserData(const void* key) {
  DCHECK(thread_checker_.CalledOnValidThread());
  user_data_.erase(key);
}

void SupportsUserData::DetachUserDataThread() {
  thread_checker_.DetachFromThread();
}

SupportsUserData::~SupportsUserData() {
  DCHECK(thread_checker_.CalledOnValidThread() || user_data_.empty());
  DataMap local_user_data;
  user_data_.swap(local_user_data);
  // Now this->user_data_ is empty, and any destructors called transitively from
  // the destruction of |local_user_data| will see it that way instead of
  // examining a being-destroyed object.
}

}  // namespace base
