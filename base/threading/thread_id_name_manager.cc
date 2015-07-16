// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/threading/thread_id_name_manager.h"

#include <stdlib.h>
#include <string.h>

#include "base/logging.h"
#include "base/memory/singleton.h"
#include "base/strings/string_util.h"

namespace base {
namespace {

static const char kDefaultName[] = "";
static std::string* g_default_name;

}

ThreadIdNameManager::ThreadIdNameManager()
    : main_process_name_(NULL),
      main_process_id_(kInvalidThreadId) {
  g_default_name = new std::string(kDefaultName);

  AutoLock locked(lock_);
  name_to_interned_name_[kDefaultName] = g_default_name;
}

ThreadIdNameManager::~ThreadIdNameManager() {
}

ThreadIdNameManager* ThreadIdNameManager::GetInstance() {
  return Singleton<ThreadIdNameManager,
      LeakySingletonTraits<ThreadIdNameManager> >::get();
}

const char* ThreadIdNameManager::GetDefaultInternedString() {
  return g_default_name->c_str();
}

void ThreadIdNameManager::RegisterThread(PlatformThreadHandle::Handle handle,
                                         PlatformThreadId id) {
  AutoLock locked(lock_);
  thread_id_to_handle_[id] = handle;
  thread_handle_to_interned_name_[handle] =
      name_to_interned_name_[kDefaultName];
}

void ThreadIdNameManager::SetName(PlatformThreadId id,
                                  const std::string& name) {
  AutoLock locked(lock_);
  NameToInternedNameMap::iterator iter = name_to_interned_name_.find(name);
  std::string* leaked_str = NULL;
  if (iter != name_to_interned_name_.end()) {
    leaked_str = iter->second;
  } else {
    leaked_str = new std::string(name);
    name_to_interned_name_[name] = leaked_str;
  }

  ThreadIdToHandleMap::iterator id_to_handle_iter =
      thread_id_to_handle_.find(id);

  // The main thread of a process will not be created as a Thread object which
  // means there is no PlatformThreadHandler registered.
  if (id_to_handle_iter == thread_id_to_handle_.end()) {
    main_process_name_ = leaked_str;
    main_process_id_ = id;
    return;
  }
  thread_handle_to_interned_name_[id_to_handle_iter->second] = leaked_str;
}

const char* ThreadIdNameManager::GetName(PlatformThreadId id) {
  AutoLock locked(lock_);

  if (id == main_process_id_)
    return main_process_name_->c_str();

  ThreadIdToHandleMap::iterator id_to_handle_iter =
      thread_id_to_handle_.find(id);
  if (id_to_handle_iter == thread_id_to_handle_.end())
    return name_to_interned_name_[kDefaultName]->c_str();

  ThreadHandleToInternedNameMap::iterator handle_to_name_iter =
      thread_handle_to_interned_name_.find(id_to_handle_iter->second);
  return handle_to_name_iter->second->c_str();
}

void ThreadIdNameManager::RemoveName(PlatformThreadHandle::Handle handle,
                                     PlatformThreadId id) {
  AutoLock locked(lock_);
  ThreadHandleToInternedNameMap::iterator handle_to_name_iter =
      thread_handle_to_interned_name_.find(handle);

  DCHECK(handle_to_name_iter != thread_handle_to_interned_name_.end());
  thread_handle_to_interned_name_.erase(handle_to_name_iter);

  ThreadIdToHandleMap::iterator id_to_handle_iter =
      thread_id_to_handle_.find(id);
  DCHECK((id_to_handle_iter!= thread_id_to_handle_.end()));
  // The given |id| may have been re-used by the system. Make sure the
  // mapping points to the provided |handle| before removal.
  if (id_to_handle_iter->second != handle)
    return;

  thread_id_to_handle_.erase(id_to_handle_iter);
}

}  // namespace base
