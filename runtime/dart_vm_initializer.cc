// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_vm_initializer.h"

#include <atomic>

#include "flutter/fml/logging.h"
#include "flutter/fml/synchronization/shared_mutex.h"
#include "flutter/fml/trace_event.h"

// Tracks whether Dart has been initialized and if it is safe to call Dart
// APIs.
static std::atomic<bool> gDartInitialized;

void DartVMInitializer::Initialize(Dart_InitializeParams* params) {
  FML_DCHECK(!gDartInitialized);

  char* error = Dart_Initialize(params);
  if (error) {
    FML_LOG(FATAL) << "Error while initializing the Dart VM: " << error;
    ::free(error);
  } else {
    gDartInitialized = true;
  }

  fml::tracing::TraceSetTimelineEventHandler(LogDartTimelineEvent);
}

void DartVMInitializer::Cleanup() {
  FML_DCHECK(gDartInitialized);

  // Dart_TimelineEvent is unsafe during a concurrent call to Dart_Cleanup
  // because Dart_Cleanup will destroy the timeline recorder.  Clear the
  // initialized flag so that future calls to LogDartTimelineEvent will not
  // call Dart_TimelineEvent.
  //
  // Note that this is inherently racy.  If a thread sees that gDartInitialized
  // is set and proceeds to call Dart_TimelineEvent shortly before another
  // thread calls Dart_Cleanup, then the Dart_TimelineEvent call may crash
  // if Dart_Cleanup deletes the timeline before Dart_TimelineEvent completes.
  // In practice this is unlikely because Dart_Cleanup does significant other
  // work before deleting the timeline.
  //
  // The engine can not safely guard Dart_Cleanup and LogDartTimelineEvent with
  // a lock due to the risk of deadlocks.  Dart_Cleanup waits for various
  // Dart-owned threads to shut down.  If one of those threads invokes an engine
  // callback that calls LogDartTimelineEvent while the Dart_Cleanup thread owns
  // the lock, then Dart_Cleanup would deadlock.
  gDartInitialized = false;

  char* error = Dart_Cleanup();
  if (error) {
    FML_LOG(FATAL) << "Error while cleaning up the Dart VM: " << error;
    ::free(error);
  }
}

void DartVMInitializer::LogDartTimelineEvent(const char* label,
                                             int64_t timestamp0,
                                             int64_t timestamp1_or_async_id,
                                             Dart_Timeline_Event_Type type,
                                             intptr_t argument_count,
                                             const char** argument_names,
                                             const char** argument_values) {
  if (gDartInitialized) {
    Dart_TimelineEvent(label, timestamp0, timestamp1_or_async_id, type,
                       argument_count, argument_names, argument_values);
  }
}
