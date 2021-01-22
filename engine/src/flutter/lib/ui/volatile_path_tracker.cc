// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/volatile_path_tracker.h"

namespace flutter {

VolatilePathTracker::VolatilePathTracker(
    fml::RefPtr<fml::TaskRunner> ui_task_runner,
    bool enabled)
    : ui_task_runner_(ui_task_runner), enabled_(enabled) {}

void VolatilePathTracker::Insert(std::shared_ptr<TrackedPath> path) {
  FML_DCHECK(ui_task_runner_->RunsTasksOnCurrentThread());
  FML_DCHECK(path);
  FML_DCHECK(path->path.isVolatile());
  if (!enabled_) {
    path->path.setIsVolatile(false);
    return;
  }
  paths_.insert(path);
}

void VolatilePathTracker::Erase(std::shared_ptr<TrackedPath> path) {
  if (!enabled_) {
    return;
  }
  FML_DCHECK(path);
  if (ui_task_runner_->RunsTasksOnCurrentThread()) {
    paths_.erase(path);
    return;
  }

  std::scoped_lock lock(paths_to_remove_mutex_);
  needs_drain_ = true;
  paths_to_remove_.push_back(path);
}

void VolatilePathTracker::OnFrame() {
  FML_DCHECK(ui_task_runner_->RunsTasksOnCurrentThread());
  if (!enabled_) {
    return;
  }
  std::string total_count = std::to_string(paths_.size());
  TRACE_EVENT1("flutter", "VolatilePathTracker::OnFrame", "total_count",
               total_count.c_str());

  Drain();

  std::set<std::shared_ptr<TrackedPath>> surviving_paths_;
  for (const std::shared_ptr<TrackedPath>& path : paths_) {
    path->frame_count++;
    if (path->frame_count >= kFramesOfVolatility) {
      path->path.setIsVolatile(false);
      path->tracking_volatility = false;
    } else {
      surviving_paths_.insert(path);
    }
  }
  paths_.swap(surviving_paths_);
  std::string post_removal_count = std::to_string(paths_.size());
  TRACE_EVENT_INSTANT1("flutter", "VolatilePathTracker::OnFrame",
                       "remaining_count", post_removal_count.c_str());
}

void VolatilePathTracker::Drain() {
  if (needs_drain_) {
    TRACE_EVENT0("flutter", "VolatilePathTracker::Drain");
    std::deque<std::shared_ptr<TrackedPath>> paths_to_remove;
    {
      std::scoped_lock lock(paths_to_remove_mutex_);
      paths_to_remove.swap(paths_to_remove_);
      needs_drain_ = false;
    }
    std::string count = std::to_string(paths_to_remove.size());
    TRACE_EVENT_INSTANT1("flutter", "VolatilePathTracker::Drain", "count",
                         count.c_str());
    for (auto& path : paths_to_remove) {
      paths_.erase(path);
    }
  }
}

}  // namespace flutter
