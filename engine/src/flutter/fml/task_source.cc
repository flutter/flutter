// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/fml/task_source.h"

#include <algorithm>
#include <functional>
#include <utility>

namespace fml {

namespace {

void PushTask(std::vector<DelayedTask>& heap, DelayedTask task) {
  heap.push_back(std::move(task));
  std::push_heap(heap.begin(), heap.end(), std::greater<DelayedTask>{});
}

fml::closure PopHeapTask(std::vector<DelayedTask>& heap) {
  FML_DCHECK(!heap.empty());
  std::pop_heap(heap.begin(), heap.end(), std::greater<DelayedTask>{});
  fml::closure task = heap.back().TakeTask();
  heap.pop_back();
  return task;
}

}  // namespace

TaskSource::TaskSource(TaskQueueId task_queue_id)
    : task_queue_id_(task_queue_id) {}

TaskSource::~TaskSource() {
  ShutDown();
}

void TaskSource::ShutDown() {
  std::vector<DelayedTask>().swap(primary_task_queue_);
  std::vector<DelayedTask>().swap(secondary_task_queue_);
}

void TaskSource::RegisterTask(DelayedTask task) {
  switch (task.GetTaskSourceGrade()) {
    case TaskSourceGrade::kUserInteraction:
    case TaskSourceGrade::kUnspecified:
      PushTask(primary_task_queue_, std::move(task));
      break;
    case TaskSourceGrade::kDartEventLoop:
      PushTask(secondary_task_queue_, std::move(task));
      break;
  }
}

fml::closure TaskSource::PopTask(TaskSourceGrade grade) {
  switch (grade) {
    case TaskSourceGrade::kUserInteraction:
    case TaskSourceGrade::kUnspecified:
      return PopHeapTask(primary_task_queue_);
    case TaskSourceGrade::kDartEventLoop:
      return PopHeapTask(secondary_task_queue_);
  }
  FML_UNREACHABLE();
}

size_t TaskSource::GetNumPendingTasks() const {
  size_t size = primary_task_queue_.size();
  if (secondary_pause_requests_ == 0) {
    size += secondary_task_queue_.size();
  }
  return size;
}

bool TaskSource::IsEmpty() const {
  return GetNumPendingTasks() == 0;
}

TaskSource::TopTask TaskSource::Top() const {
  FML_CHECK(!IsEmpty());
  if (secondary_pause_requests_ > 0 || secondary_task_queue_.empty()) {
    const auto& primary_top = primary_task_queue_.front();
    return {
        .task_queue_id = task_queue_id_,
        .task = primary_top,
    };
  } else if (primary_task_queue_.empty()) {
    const auto& secondary_top = secondary_task_queue_.front();
    return {
        .task_queue_id = task_queue_id_,
        .task = secondary_top,
    };
  } else {
    const auto& primary_top = primary_task_queue_.front();
    const auto& secondary_top = secondary_task_queue_.front();
    if (primary_top > secondary_top) {
      return {
          .task_queue_id = task_queue_id_,
          .task = secondary_top,
      };
    } else {
      return {
          .task_queue_id = task_queue_id_,
          .task = primary_top,
      };
    }
  }
}

void TaskSource::PauseSecondary() {
  secondary_pause_requests_++;
}

void TaskSource::ResumeSecondary() {
  secondary_pause_requests_--;
  FML_DCHECK(secondary_pause_requests_ >= 0);
}

}  // namespace fml
