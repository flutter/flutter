// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/sync_point_manager.h"

#include <climits>

#include "base/logging.h"
#include "base/rand_util.h"
#include "base/sequence_checker.h"

namespace gpu {

static const int kMaxSyncBase = INT_MAX;

// static
SyncPointManager* SyncPointManager::Create(bool allow_threaded_calls) {
  return new SyncPointManager(allow_threaded_calls);
}

SyncPointManager::SyncPointManager(bool allow_threaded_calls)
    : next_sync_point_(base::RandInt(1, kMaxSyncBase)) {
  // To reduce the risk that a sync point created in a previous GPU process
  // will be in flight in the next GPU process, randomize the starting sync
  // point number. http://crbug.com/373452

  if (!allow_threaded_calls) {
    sequence_checker_.reset(new base::SequenceChecker);
  }
}

SyncPointManager::~SyncPointManager() {
}

uint32 SyncPointManager::GenerateSyncPoint() {
  base::AutoLock lock(lock_);
  uint32 sync_point = next_sync_point_++;
  // When an integer overflow occurs, don't return 0.
  if (!sync_point)
    sync_point = next_sync_point_++;

  // Note: wrapping would take days for a buggy/compromized renderer that would
  // insert sync points in a loop, but if that were to happen, better explicitly
  // crash the GPU process than risk worse.
  // For normal operation (at most a few per frame), it would take ~a year to
  // wrap.
  CHECK(sync_point_map_.find(sync_point) == sync_point_map_.end());
  sync_point_map_.insert(std::make_pair(sync_point, ClosureList()));
  return sync_point;
}

void SyncPointManager::RetireSyncPoint(uint32 sync_point) {
  CheckSequencedThread();
  ClosureList list;
  {
    base::AutoLock lock(lock_);
    SyncPointMap::iterator it = sync_point_map_.find(sync_point);
    if (it == sync_point_map_.end()) {
      LOG(ERROR) << "Attempted to retire sync point that"
                    " didn't exist or was already retired.";
      return;
    }
    list.swap(it->second);
    sync_point_map_.erase(it);
  }
  for (ClosureList::iterator i = list.begin(); i != list.end(); ++i)
    i->Run();
}

void SyncPointManager::AddSyncPointCallback(uint32 sync_point,
                                            const base::Closure& callback) {
  CheckSequencedThread();
  {
    base::AutoLock lock(lock_);
    SyncPointMap::iterator it = sync_point_map_.find(sync_point);
    if (it != sync_point_map_.end()) {
      it->second.push_back(callback);
      return;
    }
  }
  callback.Run();
}

bool SyncPointManager::IsSyncPointRetired(uint32 sync_point) {
  CheckSequencedThread();
  {
    base::AutoLock lock(lock_);
    SyncPointMap::iterator it = sync_point_map_.find(sync_point);
    return it == sync_point_map_.end();
  }
}

void SyncPointManager::CheckSequencedThread() {
  DCHECK(!sequence_checker_ ||
         sequence_checker_->CalledOnValidSequencedThread());
}

}  // namespace gpu
