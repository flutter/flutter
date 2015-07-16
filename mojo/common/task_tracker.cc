// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/common/task_tracker.h"

#include <vector>

#include "base/location.h"
#include "base/logging.h"
#include "base/macros.h"
#include "base/threading/thread_local.h"
#include "base/tracked_objects.h"

namespace mojo {
namespace common {

namespace {

class TrackingActivation {
 public:
  TrackingActivation() : birth_(nullptr) {}

  bool Start(const char* function_name,
             const char* file_name,
             int line_number,
             const void* program_counter);
  void End();
  bool IsAlive() const { return birth_ != nullptr; }

 private:
  tracked_objects::TaskStopwatch* stopwatch() {
    return reinterpret_cast<tracked_objects::TaskStopwatch*>(stopwatch_heap_);
  }

  tracked_objects::Births* birth_;
  // TaskStopwatch isn't copyable, but we don't want to allocate it on the heap
  // so as not to slow things down, hence replacement new.
  char stopwatch_heap_[sizeof(tracked_objects::TaskStopwatch)];

  DISALLOW_COPY_AND_ASSIGN(TrackingActivation);
};

bool TrackingActivation::Start(const char* function_name,
                               const char* file_name,
                               int line_number,
                               const void* program_counter) {
  // So far we don't track nested invocations.
  if (IsAlive())
    return false;
  birth_ = tracked_objects::ThreadData::TallyABirthIfActive(
      tracked_objects::Location(function_name, file_name, line_number,
                                program_counter));
  if (!birth_)
    return false;

  (new (stopwatch()) tracked_objects::TaskStopwatch())->Start();
  return true;
}

void TrackingActivation::End() {
  DCHECK(IsAlive());
  stopwatch()->Stop();
  tracked_objects::ThreadData::TallyRunInAScopedRegionIfTracking(birth_,
                                                                 *stopwatch());
  stopwatch()->tracked_objects::TaskStopwatch::~TaskStopwatch();
  birth_ = nullptr;
}

base::ThreadLocalPointer<TrackingActivation> g_activation;

}  // namespace

// static
intptr_t TaskTracker::StartTracking(const char* function_name,
                                    const char* file_name,
                                    int line_number,
                                    const void* program_counter) {
  TrackingActivation* activation = g_activation.Get();
  if (!activation) {
    // Leak this.
    activation = new TrackingActivation();
    g_activation.Set(activation);
  }

  if (!activation->Start(function_name, file_name, line_number,
                         program_counter))
    return 0;
  return reinterpret_cast<intptr_t>(activation);
}

// static
void TaskTracker::EndTracking(intptr_t id) {
  if (0 == id)
    return;
  // |EndTracking()| must be called from the same thread of |StartTracking()|.
  DCHECK_EQ(reinterpret_cast<TrackingActivation*>(id), g_activation.Get());
  reinterpret_cast<TrackingActivation*>(id)->End();
}

}  // namespace common
}  // namespace mojo
