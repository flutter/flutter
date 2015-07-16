// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Test of classes in the tracked_objects.h classes.

#include "base/tracked_objects.h"

#include <stddef.h>

#include "base/memory/scoped_ptr.h"
#include "base/process/process_handle.h"
#include "base/time/time.h"
#include "base/tracking_info.h"
#include "testing/gtest/include/gtest/gtest.h"

const int kLineNumber = 1776;
const char kFile[] = "FixedUnitTestFileName";
const char kWorkerThreadName[] = "WorkerThread-1";
const char kMainThreadName[] = "SomeMainThreadName";
const char kStillAlive[] = "Still_Alive";

namespace tracked_objects {

class TrackedObjectsTest : public testing::Test {
 protected:
  TrackedObjectsTest() {
    // On entry, leak any database structures in case they are still in use by
    // prior threads.
    ThreadData::ShutdownSingleThreadedCleanup(true);

    test_time_ = 0;
    ThreadData::SetAlternateTimeSource(&TrackedObjectsTest::GetTestTime);
    ThreadData::now_function_is_time_ = true;
  }

  ~TrackedObjectsTest() override {
    // We should not need to leak any structures we create, since we are
    // single threaded, and carefully accounting for items.
    ThreadData::ShutdownSingleThreadedCleanup(false);
  }

  // Reset the profiler state.
  void Reset() {
    ThreadData::ShutdownSingleThreadedCleanup(false);
    test_time_ = 0;
  }

  // Simulate a birth on the thread named |thread_name|, at the given
  // |location|.
  void TallyABirth(const Location& location, const std::string& thread_name) {
    // If the |thread_name| is empty, we don't initialize system with a thread
    // name, so we're viewed as a worker thread.
    if (!thread_name.empty())
      ThreadData::InitializeThreadContext(kMainThreadName);

    // Do not delete |birth|.  We don't own it.
    Births* birth = ThreadData::TallyABirthIfActive(location);

    if (ThreadData::status() == ThreadData::DEACTIVATED)
      EXPECT_EQ(reinterpret_cast<Births*>(NULL), birth);
    else
      EXPECT_NE(reinterpret_cast<Births*>(NULL), birth);
  }

  // Helper function to verify the most common test expectations.
  void ExpectSimpleProcessData(const ProcessDataSnapshot& process_data,
                               const std::string& function_name,
                               const std::string& birth_thread,
                               const std::string& death_thread,
                               int count,
                               int run_ms,
                               int queue_ms) {
    ASSERT_EQ(1u, process_data.phased_snapshots.size());
    auto it = process_data.phased_snapshots.find(0);
    ASSERT_TRUE(it != process_data.phased_snapshots.end());
    const ProcessDataPhaseSnapshot& process_data_phase = it->second;

    ASSERT_EQ(1u, process_data_phase.tasks.size());

    EXPECT_EQ(kFile, process_data_phase.tasks[0].birth.location.file_name);
    EXPECT_EQ(function_name,
              process_data_phase.tasks[0].birth.location.function_name);
    EXPECT_EQ(kLineNumber,
              process_data_phase.tasks[0].birth.location.line_number);

    EXPECT_EQ(birth_thread, process_data_phase.tasks[0].birth.thread_name);

    EXPECT_EQ(count, process_data_phase.tasks[0].death_data.count);
    EXPECT_EQ(count * run_ms,
              process_data_phase.tasks[0].death_data.run_duration_sum);
    EXPECT_EQ(run_ms, process_data_phase.tasks[0].death_data.run_duration_max);
    EXPECT_EQ(run_ms,
              process_data_phase.tasks[0].death_data.run_duration_sample);
    EXPECT_EQ(count * queue_ms,
              process_data_phase.tasks[0].death_data.queue_duration_sum);
    EXPECT_EQ(queue_ms,
              process_data_phase.tasks[0].death_data.queue_duration_max);
    EXPECT_EQ(queue_ms,
              process_data_phase.tasks[0].death_data.queue_duration_sample);

    EXPECT_EQ(death_thread, process_data_phase.tasks[0].death_thread_name);

    EXPECT_EQ(base::GetCurrentProcId(), process_data.process_id);
  }

  // Sets time that will be returned by ThreadData::Now().
  static void SetTestTime(unsigned int test_time) { test_time_ = test_time; }

 private:
  // Returns test time in milliseconds.
  static unsigned int GetTestTime() { return test_time_; }

  // Test time in milliseconds.
  static unsigned int test_time_;
};

// static
unsigned int TrackedObjectsTest::test_time_;

TEST_F(TrackedObjectsTest, TaskStopwatchNoStartStop) {
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::PROFILING_ACTIVE);

  // Check that creating and destroying a stopwatch without starting it doesn't
  // crash.
  TaskStopwatch stopwatch;
}

TEST_F(TrackedObjectsTest, MinimalStartupShutdown) {
  // Minimal test doesn't even create any tasks.
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::PROFILING_ACTIVE);

  EXPECT_FALSE(ThreadData::first());  // No activity even on this thread.
  ThreadData* data = ThreadData::Get();
  EXPECT_TRUE(ThreadData::first());  // Now class was constructed.
  ASSERT_TRUE(data);
  EXPECT_FALSE(data->next());
  EXPECT_EQ(data, ThreadData::Get());
  ThreadData::BirthMap birth_map;
  ThreadData::DeathsSnapshot deaths;
  data->SnapshotMaps(0, &birth_map, &deaths);
  EXPECT_EQ(0u, birth_map.size());
  EXPECT_EQ(0u, deaths.size());

  // Clean up with no leaking.
  Reset();

  // Do it again, just to be sure we reset state completely.
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::PROFILING_ACTIVE);
  EXPECT_FALSE(ThreadData::first());  // No activity even on this thread.
  data = ThreadData::Get();
  EXPECT_TRUE(ThreadData::first());  // Now class was constructed.
  ASSERT_TRUE(data);
  EXPECT_FALSE(data->next());
  EXPECT_EQ(data, ThreadData::Get());
  birth_map.clear();
  deaths.clear();
  data->SnapshotMaps(0, &birth_map, &deaths);
  EXPECT_EQ(0u, birth_map.size());
  EXPECT_EQ(0u, deaths.size());
}

TEST_F(TrackedObjectsTest, TinyStartupShutdown) {
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::PROFILING_ACTIVE);

  // Instigate tracking on a single tracked object, on our thread.
  const char kFunction[] = "TinyStartupShutdown";
  Location location(kFunction, kFile, kLineNumber, NULL);
  ThreadData::TallyABirthIfActive(location);

  ThreadData* data = ThreadData::first();
  ASSERT_TRUE(data);
  EXPECT_FALSE(data->next());
  EXPECT_EQ(data, ThreadData::Get());
  ThreadData::BirthMap birth_map;
  ThreadData::DeathsSnapshot deaths;
  data->SnapshotMaps(0, &birth_map, &deaths);
  EXPECT_EQ(1u, birth_map.size());                         // 1 birth location.
  EXPECT_EQ(1, birth_map.begin()->second->birth_count());  // 1 birth.
  EXPECT_EQ(0u, deaths.size());                            // No deaths.


  // Now instigate another birth, while we are timing the run of the first
  // execution.
  // Create a child (using the same birth location).
  // TrackingInfo will call TallyABirth() during construction.
  const int32 start_time = 1;
  base::TimeTicks kBogusBirthTime = base::TimeTicks() +
      base::TimeDelta::FromMilliseconds(start_time);
  base::TrackingInfo pending_task(location, kBogusBirthTime);
  SetTestTime(1);
  TaskStopwatch stopwatch;
  stopwatch.Start();
  // Finally conclude the outer run.
  const int32 time_elapsed = 1000;
  SetTestTime(start_time + time_elapsed);
  stopwatch.Stop();

  ThreadData::TallyRunOnNamedThreadIfTracking(pending_task, stopwatch);

  birth_map.clear();
  deaths.clear();
  data->SnapshotMaps(0, &birth_map, &deaths);
  EXPECT_EQ(1u, birth_map.size());                         // 1 birth location.
  EXPECT_EQ(2, birth_map.begin()->second->birth_count());  // 2 births.
  EXPECT_EQ(1u, deaths.size());                            // 1 location.
  EXPECT_EQ(1, deaths.begin()->second.death_data.count);   // 1 death.

  // The births were at the same location as the one known death.
  EXPECT_EQ(birth_map.begin()->second, deaths.begin()->first);

  ProcessDataSnapshot process_data;
  ThreadData::Snapshot(0, &process_data);

  ASSERT_EQ(1u, process_data.phased_snapshots.size());
  auto it = process_data.phased_snapshots.find(0);
  ASSERT_TRUE(it != process_data.phased_snapshots.end());
  const ProcessDataPhaseSnapshot& process_data_phase = it->second;
  ASSERT_EQ(1u, process_data_phase.tasks.size());
  EXPECT_EQ(kFile, process_data_phase.tasks[0].birth.location.file_name);
  EXPECT_EQ(kFunction,
            process_data_phase.tasks[0].birth.location.function_name);
  EXPECT_EQ(kLineNumber,
            process_data_phase.tasks[0].birth.location.line_number);
  EXPECT_EQ(kWorkerThreadName, process_data_phase.tasks[0].birth.thread_name);
  EXPECT_EQ(1, process_data_phase.tasks[0].death_data.count);
  EXPECT_EQ(time_elapsed,
            process_data_phase.tasks[0].death_data.run_duration_sum);
  EXPECT_EQ(time_elapsed,
            process_data_phase.tasks[0].death_data.run_duration_max);
  EXPECT_EQ(time_elapsed,
            process_data_phase.tasks[0].death_data.run_duration_sample);
  EXPECT_EQ(0, process_data_phase.tasks[0].death_data.queue_duration_sum);
  EXPECT_EQ(0, process_data_phase.tasks[0].death_data.queue_duration_max);
  EXPECT_EQ(0, process_data_phase.tasks[0].death_data.queue_duration_sample);
  EXPECT_EQ(kWorkerThreadName, process_data_phase.tasks[0].death_thread_name);
}

TEST_F(TrackedObjectsTest, DeathDataTestRecordDeath) {
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::PROFILING_ACTIVE);

  scoped_ptr<DeathData> data(new DeathData());
  ASSERT_NE(data, reinterpret_cast<DeathData*>(NULL));
  EXPECT_EQ(data->run_duration_sum(), 0);
  EXPECT_EQ(data->run_duration_max(), 0);
  EXPECT_EQ(data->run_duration_sample(), 0);
  EXPECT_EQ(data->queue_duration_sum(), 0);
  EXPECT_EQ(data->queue_duration_max(), 0);
  EXPECT_EQ(data->queue_duration_sample(), 0);
  EXPECT_EQ(data->count(), 0);
  EXPECT_EQ(nullptr, data->last_phase_snapshot());

  int32 run_ms = 42;
  int32 queue_ms = 8;

  const int kUnrandomInt = 0;  // Fake random int that ensure we sample data.
  data->RecordDeath(queue_ms, run_ms, kUnrandomInt);
  EXPECT_EQ(data->run_duration_sum(), run_ms);
  EXPECT_EQ(data->run_duration_max(), run_ms);
  EXPECT_EQ(data->run_duration_sample(), run_ms);
  EXPECT_EQ(data->queue_duration_sum(), queue_ms);
  EXPECT_EQ(data->queue_duration_max(), queue_ms);
  EXPECT_EQ(data->queue_duration_sample(), queue_ms);
  EXPECT_EQ(data->count(), 1);
  EXPECT_EQ(nullptr, data->last_phase_snapshot());

  data->RecordDeath(queue_ms, run_ms, kUnrandomInt);
  EXPECT_EQ(data->run_duration_sum(), run_ms + run_ms);
  EXPECT_EQ(data->run_duration_max(), run_ms);
  EXPECT_EQ(data->run_duration_sample(), run_ms);
  EXPECT_EQ(data->queue_duration_sum(), queue_ms + queue_ms);
  EXPECT_EQ(data->queue_duration_max(), queue_ms);
  EXPECT_EQ(data->queue_duration_sample(), queue_ms);
  EXPECT_EQ(data->count(), 2);
  EXPECT_EQ(nullptr, data->last_phase_snapshot());
}

TEST_F(TrackedObjectsTest, DeathDataTest2Phases) {
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::PROFILING_ACTIVE);

  scoped_ptr<DeathData> data(new DeathData());
  ASSERT_NE(data, reinterpret_cast<DeathData*>(NULL));

  int32 run_ms = 42;
  int32 queue_ms = 8;

  const int kUnrandomInt = 0;  // Fake random int that ensure we sample data.
  data->RecordDeath(queue_ms, run_ms, kUnrandomInt);
  data->RecordDeath(queue_ms, run_ms, kUnrandomInt);

  data->OnProfilingPhaseCompleted(123);
  EXPECT_EQ(data->run_duration_sum(), run_ms + run_ms);
  EXPECT_EQ(data->run_duration_max(), 0);
  EXPECT_EQ(data->run_duration_sample(), run_ms);
  EXPECT_EQ(data->queue_duration_sum(), queue_ms + queue_ms);
  EXPECT_EQ(data->queue_duration_max(), 0);
  EXPECT_EQ(data->queue_duration_sample(), queue_ms);
  EXPECT_EQ(data->count(), 2);
  ASSERT_NE(nullptr, data->last_phase_snapshot());
  EXPECT_EQ(123, data->last_phase_snapshot()->profiling_phase);
  EXPECT_EQ(2, data->last_phase_snapshot()->death_data.count);
  EXPECT_EQ(2 * run_ms,
            data->last_phase_snapshot()->death_data.run_duration_sum);
  EXPECT_EQ(run_ms, data->last_phase_snapshot()->death_data.run_duration_max);
  EXPECT_EQ(run_ms,
            data->last_phase_snapshot()->death_data.run_duration_sample);
  EXPECT_EQ(2 * queue_ms,
            data->last_phase_snapshot()->death_data.queue_duration_sum);
  EXPECT_EQ(queue_ms,
            data->last_phase_snapshot()->death_data.queue_duration_max);
  EXPECT_EQ(queue_ms,
            data->last_phase_snapshot()->death_data.queue_duration_sample);
  EXPECT_EQ(nullptr, data->last_phase_snapshot()->prev);

  int32 run_ms1 = 21;
  int32 queue_ms1 = 4;

  data->RecordDeath(queue_ms1, run_ms1, kUnrandomInt);
  EXPECT_EQ(data->run_duration_sum(), run_ms + run_ms + run_ms1);
  EXPECT_EQ(data->run_duration_max(), run_ms1);
  EXPECT_EQ(data->run_duration_sample(), run_ms1);
  EXPECT_EQ(data->queue_duration_sum(), queue_ms + queue_ms + queue_ms1);
  EXPECT_EQ(data->queue_duration_max(), queue_ms1);
  EXPECT_EQ(data->queue_duration_sample(), queue_ms1);
  EXPECT_EQ(data->count(), 3);
  ASSERT_NE(nullptr, data->last_phase_snapshot());
  EXPECT_EQ(123, data->last_phase_snapshot()->profiling_phase);
  EXPECT_EQ(2, data->last_phase_snapshot()->death_data.count);
  EXPECT_EQ(2 * run_ms,
            data->last_phase_snapshot()->death_data.run_duration_sum);
  EXPECT_EQ(run_ms, data->last_phase_snapshot()->death_data.run_duration_max);
  EXPECT_EQ(run_ms,
            data->last_phase_snapshot()->death_data.run_duration_sample);
  EXPECT_EQ(2 * queue_ms,
            data->last_phase_snapshot()->death_data.queue_duration_sum);
  EXPECT_EQ(queue_ms,
            data->last_phase_snapshot()->death_data.queue_duration_max);
  EXPECT_EQ(queue_ms,
            data->last_phase_snapshot()->death_data.queue_duration_sample);
  EXPECT_EQ(nullptr, data->last_phase_snapshot()->prev);
}

TEST_F(TrackedObjectsTest, Delta) {
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::PROFILING_ACTIVE);

  DeathDataSnapshot snapshot;
  snapshot.count = 10;
  snapshot.run_duration_sum = 100;
  snapshot.run_duration_max = 50;
  snapshot.run_duration_sample = 25;
  snapshot.queue_duration_sum = 200;
  snapshot.queue_duration_max = 101;
  snapshot.queue_duration_sample = 26;

  DeathDataSnapshot older_snapshot;
  older_snapshot.count = 2;
  older_snapshot.run_duration_sum = 95;
  older_snapshot.run_duration_max = 48;
  older_snapshot.run_duration_sample = 22;
  older_snapshot.queue_duration_sum = 190;
  older_snapshot.queue_duration_max = 99;
  older_snapshot.queue_duration_sample = 21;

  const DeathDataSnapshot& delta = snapshot.Delta(older_snapshot);
  EXPECT_EQ(8, delta.count);
  EXPECT_EQ(5, delta.run_duration_sum);
  EXPECT_EQ(50, delta.run_duration_max);
  EXPECT_EQ(25, delta.run_duration_sample);
  EXPECT_EQ(10, delta.queue_duration_sum);
  EXPECT_EQ(101, delta.queue_duration_max);
  EXPECT_EQ(26, delta.queue_duration_sample);
}

TEST_F(TrackedObjectsTest, DeactivatedBirthOnlyToSnapshotWorkerThread) {
  // Start in the deactivated state.
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::DEACTIVATED);

  const char kFunction[] = "DeactivatedBirthOnlyToSnapshotWorkerThread";
  Location location(kFunction, kFile, kLineNumber, NULL);
  TallyABirth(location, std::string());

  ProcessDataSnapshot process_data;
  ThreadData::Snapshot(0, &process_data);

  ASSERT_EQ(1u, process_data.phased_snapshots.size());

  auto it = process_data.phased_snapshots.find(0);
  ASSERT_TRUE(it != process_data.phased_snapshots.end());
  const ProcessDataPhaseSnapshot& process_data_phase = it->second;

  ASSERT_EQ(0u, process_data_phase.tasks.size());

  EXPECT_EQ(base::GetCurrentProcId(), process_data.process_id);
}

TEST_F(TrackedObjectsTest, DeactivatedBirthOnlyToSnapshotMainThread) {
  // Start in the deactivated state.
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::DEACTIVATED);

  const char kFunction[] = "DeactivatedBirthOnlyToSnapshotMainThread";
  Location location(kFunction, kFile, kLineNumber, NULL);
  TallyABirth(location, kMainThreadName);

  ProcessDataSnapshot process_data;
  ThreadData::Snapshot(0, &process_data);

  ASSERT_EQ(1u, process_data.phased_snapshots.size());

  auto it = process_data.phased_snapshots.find(0);
  ASSERT_TRUE(it != process_data.phased_snapshots.end());
  const ProcessDataPhaseSnapshot& process_data_phase = it->second;

  ASSERT_EQ(0u, process_data_phase.tasks.size());

  EXPECT_EQ(base::GetCurrentProcId(), process_data.process_id);
}

TEST_F(TrackedObjectsTest, BirthOnlyToSnapshotWorkerThread) {
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::PROFILING_ACTIVE);

  const char kFunction[] = "BirthOnlyToSnapshotWorkerThread";
  Location location(kFunction, kFile, kLineNumber, NULL);
  TallyABirth(location, std::string());

  ProcessDataSnapshot process_data;
  ThreadData::Snapshot(0, &process_data);
  ExpectSimpleProcessData(process_data, kFunction, kWorkerThreadName,
                          kStillAlive, 1, 0, 0);
}

TEST_F(TrackedObjectsTest, BirthOnlyToSnapshotMainThread) {
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::PROFILING_ACTIVE);

  const char kFunction[] = "BirthOnlyToSnapshotMainThread";
  Location location(kFunction, kFile, kLineNumber, NULL);
  TallyABirth(location, kMainThreadName);

  ProcessDataSnapshot process_data;
  ThreadData::Snapshot(0, &process_data);
  ExpectSimpleProcessData(process_data, kFunction, kMainThreadName, kStillAlive,
                          1, 0, 0);
}

TEST_F(TrackedObjectsTest, LifeCycleToSnapshotMainThread) {
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::PROFILING_ACTIVE);

  const char kFunction[] = "LifeCycleToSnapshotMainThread";
  Location location(kFunction, kFile, kLineNumber, NULL);
  TallyABirth(location, kMainThreadName);

  const TrackedTime kTimePosted = TrackedTime::FromMilliseconds(1);
  const base::TimeTicks kDelayedStartTime = base::TimeTicks();
  // TrackingInfo will call TallyABirth() during construction.
  base::TrackingInfo pending_task(location, kDelayedStartTime);
  pending_task.time_posted = kTimePosted;  // Overwrite implied Now().

  const unsigned int kStartOfRun = 5;
  const unsigned int kEndOfRun = 7;
  SetTestTime(kStartOfRun);
  TaskStopwatch stopwatch;
  stopwatch.Start();
  SetTestTime(kEndOfRun);
  stopwatch.Stop();

  ThreadData::TallyRunOnNamedThreadIfTracking(pending_task, stopwatch);

  ProcessDataSnapshot process_data;
  ThreadData::Snapshot(0, &process_data);
  ExpectSimpleProcessData(process_data, kFunction, kMainThreadName,
                          kMainThreadName, 1, 2, 4);
}

TEST_F(TrackedObjectsTest, TwoPhases) {
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::PROFILING_ACTIVE);

  const char kFunction[] = "TwoPhases";
  Location location(kFunction, kFile, kLineNumber, NULL);
  TallyABirth(location, kMainThreadName);

  const TrackedTime kTimePosted = TrackedTime::FromMilliseconds(1);
  const base::TimeTicks kDelayedStartTime = base::TimeTicks();
  // TrackingInfo will call TallyABirth() during construction.
  base::TrackingInfo pending_task(location, kDelayedStartTime);
  pending_task.time_posted = kTimePosted;  // Overwrite implied Now().

  const unsigned int kStartOfRun = 5;
  const unsigned int kEndOfRun = 7;
  SetTestTime(kStartOfRun);
  TaskStopwatch stopwatch;
  stopwatch.Start();
  SetTestTime(kEndOfRun);
  stopwatch.Stop();

  ThreadData::TallyRunOnNamedThreadIfTracking(pending_task, stopwatch);

  ThreadData::OnProfilingPhaseCompleted(0);

  TallyABirth(location, kMainThreadName);

  const TrackedTime kTimePosted1 = TrackedTime::FromMilliseconds(9);
  const base::TimeTicks kDelayedStartTime1 = base::TimeTicks();
  // TrackingInfo will call TallyABirth() during construction.
  base::TrackingInfo pending_task1(location, kDelayedStartTime1);
  pending_task1.time_posted = kTimePosted1;  // Overwrite implied Now().

  const unsigned int kStartOfRun1 = 11;
  const unsigned int kEndOfRun1 = 21;
  SetTestTime(kStartOfRun1);
  TaskStopwatch stopwatch1;
  stopwatch1.Start();
  SetTestTime(kEndOfRun1);
  stopwatch1.Stop();

  ThreadData::TallyRunOnNamedThreadIfTracking(pending_task1, stopwatch1);

  ProcessDataSnapshot process_data;
  ThreadData::Snapshot(1, &process_data);

  ASSERT_EQ(2u, process_data.phased_snapshots.size());

  auto it0 = process_data.phased_snapshots.find(0);
  ASSERT_TRUE(it0 != process_data.phased_snapshots.end());
  const ProcessDataPhaseSnapshot& process_data_phase0 = it0->second;

  ASSERT_EQ(1u, process_data_phase0.tasks.size());

  EXPECT_EQ(kFile, process_data_phase0.tasks[0].birth.location.file_name);
  EXPECT_EQ(kFunction,
            process_data_phase0.tasks[0].birth.location.function_name);
  EXPECT_EQ(kLineNumber,
            process_data_phase0.tasks[0].birth.location.line_number);

  EXPECT_EQ(kMainThreadName, process_data_phase0.tasks[0].birth.thread_name);

  EXPECT_EQ(1, process_data_phase0.tasks[0].death_data.count);
  EXPECT_EQ(2, process_data_phase0.tasks[0].death_data.run_duration_sum);
  EXPECT_EQ(2, process_data_phase0.tasks[0].death_data.run_duration_max);
  EXPECT_EQ(2, process_data_phase0.tasks[0].death_data.run_duration_sample);
  EXPECT_EQ(4, process_data_phase0.tasks[0].death_data.queue_duration_sum);
  EXPECT_EQ(4, process_data_phase0.tasks[0].death_data.queue_duration_max);
  EXPECT_EQ(4, process_data_phase0.tasks[0].death_data.queue_duration_sample);

  EXPECT_EQ(kMainThreadName, process_data_phase0.tasks[0].death_thread_name);

  auto it1 = process_data.phased_snapshots.find(1);
  ASSERT_TRUE(it1 != process_data.phased_snapshots.end());
  const ProcessDataPhaseSnapshot& process_data_phase1 = it1->second;

  ASSERT_EQ(1u, process_data_phase1.tasks.size());

  EXPECT_EQ(kFile, process_data_phase1.tasks[0].birth.location.file_name);
  EXPECT_EQ(kFunction,
            process_data_phase1.tasks[0].birth.location.function_name);
  EXPECT_EQ(kLineNumber,
            process_data_phase1.tasks[0].birth.location.line_number);

  EXPECT_EQ(kMainThreadName, process_data_phase1.tasks[0].birth.thread_name);

  EXPECT_EQ(1, process_data_phase1.tasks[0].death_data.count);
  EXPECT_EQ(10, process_data_phase1.tasks[0].death_data.run_duration_sum);
  EXPECT_EQ(10, process_data_phase1.tasks[0].death_data.run_duration_max);
  EXPECT_EQ(10, process_data_phase1.tasks[0].death_data.run_duration_sample);
  EXPECT_EQ(2, process_data_phase1.tasks[0].death_data.queue_duration_sum);
  EXPECT_EQ(2, process_data_phase1.tasks[0].death_data.queue_duration_max);
  EXPECT_EQ(2, process_data_phase1.tasks[0].death_data.queue_duration_sample);

  EXPECT_EQ(kMainThreadName, process_data_phase1.tasks[0].death_thread_name);

  EXPECT_EQ(base::GetCurrentProcId(), process_data.process_id);
}

TEST_F(TrackedObjectsTest, ThreePhases) {
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::PROFILING_ACTIVE);

  const char kFunction[] = "ThreePhases";
  Location location(kFunction, kFile, kLineNumber, NULL);

  // Phase 0
  {
    TallyABirth(location, kMainThreadName);

    // TrackingInfo will call TallyABirth() during construction.
    SetTestTime(10);
    base::TrackingInfo pending_task(location, base::TimeTicks());

    SetTestTime(17);
    TaskStopwatch stopwatch;
    stopwatch.Start();
    SetTestTime(23);
    stopwatch.Stop();

    ThreadData::TallyRunOnNamedThreadIfTracking(pending_task, stopwatch);
  }

  ThreadData::OnProfilingPhaseCompleted(0);

  // Phase 1
  {
    TallyABirth(location, kMainThreadName);

    SetTestTime(30);
    base::TrackingInfo pending_task(location, base::TimeTicks());

    SetTestTime(35);
    TaskStopwatch stopwatch;
    stopwatch.Start();
    SetTestTime(39);
    stopwatch.Stop();

    ThreadData::TallyRunOnNamedThreadIfTracking(pending_task, stopwatch);
  }

  ThreadData::OnProfilingPhaseCompleted(1);

  // Phase 2
  {
    TallyABirth(location, kMainThreadName);

    // TrackingInfo will call TallyABirth() during construction.
    SetTestTime(40);
    base::TrackingInfo pending_task(location, base::TimeTicks());

    SetTestTime(43);
    TaskStopwatch stopwatch;
    stopwatch.Start();
    SetTestTime(45);
    stopwatch.Stop();

    ThreadData::TallyRunOnNamedThreadIfTracking(pending_task, stopwatch);
  }

  // Snapshot and check results.
  ProcessDataSnapshot process_data;
  ThreadData::Snapshot(2, &process_data);

  ASSERT_EQ(3u, process_data.phased_snapshots.size());

  auto it0 = process_data.phased_snapshots.find(0);
  ASSERT_TRUE(it0 != process_data.phased_snapshots.end());
  const ProcessDataPhaseSnapshot& process_data_phase0 = it0->second;

  ASSERT_EQ(1u, process_data_phase0.tasks.size());

  EXPECT_EQ(kFile, process_data_phase0.tasks[0].birth.location.file_name);
  EXPECT_EQ(kFunction,
            process_data_phase0.tasks[0].birth.location.function_name);
  EXPECT_EQ(kLineNumber,
            process_data_phase0.tasks[0].birth.location.line_number);

  EXPECT_EQ(kMainThreadName, process_data_phase0.tasks[0].birth.thread_name);

  EXPECT_EQ(1, process_data_phase0.tasks[0].death_data.count);
  EXPECT_EQ(6, process_data_phase0.tasks[0].death_data.run_duration_sum);
  EXPECT_EQ(6, process_data_phase0.tasks[0].death_data.run_duration_max);
  EXPECT_EQ(6, process_data_phase0.tasks[0].death_data.run_duration_sample);
  EXPECT_EQ(7, process_data_phase0.tasks[0].death_data.queue_duration_sum);
  EXPECT_EQ(7, process_data_phase0.tasks[0].death_data.queue_duration_max);
  EXPECT_EQ(7, process_data_phase0.tasks[0].death_data.queue_duration_sample);

  EXPECT_EQ(kMainThreadName, process_data_phase0.tasks[0].death_thread_name);

  auto it1 = process_data.phased_snapshots.find(1);
  ASSERT_TRUE(it1 != process_data.phased_snapshots.end());
  const ProcessDataPhaseSnapshot& process_data_phase1 = it1->second;

  ASSERT_EQ(1u, process_data_phase1.tasks.size());

  EXPECT_EQ(kFile, process_data_phase1.tasks[0].birth.location.file_name);
  EXPECT_EQ(kFunction,
            process_data_phase1.tasks[0].birth.location.function_name);
  EXPECT_EQ(kLineNumber,
            process_data_phase1.tasks[0].birth.location.line_number);

  EXPECT_EQ(kMainThreadName, process_data_phase1.tasks[0].birth.thread_name);

  EXPECT_EQ(1, process_data_phase1.tasks[0].death_data.count);
  EXPECT_EQ(4, process_data_phase1.tasks[0].death_data.run_duration_sum);
  EXPECT_EQ(4, process_data_phase1.tasks[0].death_data.run_duration_max);
  EXPECT_EQ(4, process_data_phase1.tasks[0].death_data.run_duration_sample);
  EXPECT_EQ(5, process_data_phase1.tasks[0].death_data.queue_duration_sum);
  EXPECT_EQ(5, process_data_phase1.tasks[0].death_data.queue_duration_max);
  EXPECT_EQ(5, process_data_phase1.tasks[0].death_data.queue_duration_sample);

  EXPECT_EQ(kMainThreadName, process_data_phase1.tasks[0].death_thread_name);

  auto it2 = process_data.phased_snapshots.find(2);
  ASSERT_TRUE(it2 != process_data.phased_snapshots.end());
  const ProcessDataPhaseSnapshot& process_data_phase2 = it2->second;

  ASSERT_EQ(1u, process_data_phase2.tasks.size());

  EXPECT_EQ(kFile, process_data_phase2.tasks[0].birth.location.file_name);
  EXPECT_EQ(kFunction,
            process_data_phase2.tasks[0].birth.location.function_name);
  EXPECT_EQ(kLineNumber,
            process_data_phase2.tasks[0].birth.location.line_number);

  EXPECT_EQ(kMainThreadName, process_data_phase2.tasks[0].birth.thread_name);

  EXPECT_EQ(1, process_data_phase2.tasks[0].death_data.count);
  EXPECT_EQ(2, process_data_phase2.tasks[0].death_data.run_duration_sum);
  EXPECT_EQ(2, process_data_phase2.tasks[0].death_data.run_duration_max);
  EXPECT_EQ(2, process_data_phase2.tasks[0].death_data.run_duration_sample);
  EXPECT_EQ(3, process_data_phase2.tasks[0].death_data.queue_duration_sum);
  EXPECT_EQ(3, process_data_phase2.tasks[0].death_data.queue_duration_max);
  EXPECT_EQ(3, process_data_phase2.tasks[0].death_data.queue_duration_sample);

  EXPECT_EQ(kMainThreadName, process_data_phase2.tasks[0].death_thread_name);

  EXPECT_EQ(base::GetCurrentProcId(), process_data.process_id);
}

TEST_F(TrackedObjectsTest, TwoPhasesSecondEmpty) {
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::PROFILING_ACTIVE);

  const char kFunction[] = "TwoPhasesSecondEmpty";
  Location location(kFunction, kFile, kLineNumber, NULL);
  ThreadData::InitializeThreadContext(kMainThreadName);

  const TrackedTime kTimePosted = TrackedTime::FromMilliseconds(1);
  const base::TimeTicks kDelayedStartTime = base::TimeTicks();
  // TrackingInfo will call TallyABirth() during construction.
  base::TrackingInfo pending_task(location, kDelayedStartTime);
  pending_task.time_posted = kTimePosted;  // Overwrite implied Now().

  const unsigned int kStartOfRun = 5;
  const unsigned int kEndOfRun = 7;
  SetTestTime(kStartOfRun);
  TaskStopwatch stopwatch;
  stopwatch.Start();
  SetTestTime(kEndOfRun);
  stopwatch.Stop();

  ThreadData::TallyRunOnNamedThreadIfTracking(pending_task, stopwatch);

  ThreadData::OnProfilingPhaseCompleted(0);

  ProcessDataSnapshot process_data;
  ThreadData::Snapshot(1, &process_data);

  ASSERT_EQ(2u, process_data.phased_snapshots.size());

  auto it0 = process_data.phased_snapshots.find(0);
  ASSERT_TRUE(it0 != process_data.phased_snapshots.end());
  const ProcessDataPhaseSnapshot& process_data_phase0 = it0->second;

  ASSERT_EQ(1u, process_data_phase0.tasks.size());

  EXPECT_EQ(kFile, process_data_phase0.tasks[0].birth.location.file_name);
  EXPECT_EQ(kFunction,
            process_data_phase0.tasks[0].birth.location.function_name);
  EXPECT_EQ(kLineNumber,
            process_data_phase0.tasks[0].birth.location.line_number);

  EXPECT_EQ(kMainThreadName, process_data_phase0.tasks[0].birth.thread_name);

  EXPECT_EQ(1, process_data_phase0.tasks[0].death_data.count);
  EXPECT_EQ(2, process_data_phase0.tasks[0].death_data.run_duration_sum);
  EXPECT_EQ(2, process_data_phase0.tasks[0].death_data.run_duration_max);
  EXPECT_EQ(2, process_data_phase0.tasks[0].death_data.run_duration_sample);
  EXPECT_EQ(4, process_data_phase0.tasks[0].death_data.queue_duration_sum);
  EXPECT_EQ(4, process_data_phase0.tasks[0].death_data.queue_duration_max);
  EXPECT_EQ(4, process_data_phase0.tasks[0].death_data.queue_duration_sample);

  EXPECT_EQ(kMainThreadName, process_data_phase0.tasks[0].death_thread_name);

  auto it1 = process_data.phased_snapshots.find(1);
  ASSERT_TRUE(it1 != process_data.phased_snapshots.end());
  const ProcessDataPhaseSnapshot& process_data_phase1 = it1->second;

  ASSERT_EQ(0u, process_data_phase1.tasks.size());

  EXPECT_EQ(base::GetCurrentProcId(), process_data.process_id);
}

TEST_F(TrackedObjectsTest, TwoPhasesFirstEmpty) {
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::PROFILING_ACTIVE);

  ThreadData::OnProfilingPhaseCompleted(0);

  const char kFunction[] = "TwoPhasesSecondEmpty";
  Location location(kFunction, kFile, kLineNumber, NULL);
  ThreadData::InitializeThreadContext(kMainThreadName);

  const TrackedTime kTimePosted = TrackedTime::FromMilliseconds(1);
  const base::TimeTicks kDelayedStartTime = base::TimeTicks();
  // TrackingInfo will call TallyABirth() during construction.
  base::TrackingInfo pending_task(location, kDelayedStartTime);
  pending_task.time_posted = kTimePosted;  // Overwrite implied Now().

  const unsigned int kStartOfRun = 5;
  const unsigned int kEndOfRun = 7;
  SetTestTime(kStartOfRun);
  TaskStopwatch stopwatch;
  stopwatch.Start();
  SetTestTime(kEndOfRun);
  stopwatch.Stop();

  ThreadData::TallyRunOnNamedThreadIfTracking(pending_task, stopwatch);

  ProcessDataSnapshot process_data;
  ThreadData::Snapshot(1, &process_data);

  ASSERT_EQ(1u, process_data.phased_snapshots.size());

  auto it1 = process_data.phased_snapshots.find(1);
  ASSERT_TRUE(it1 != process_data.phased_snapshots.end());
  const ProcessDataPhaseSnapshot& process_data_phase1 = it1->second;

  ASSERT_EQ(1u, process_data_phase1.tasks.size());

  EXPECT_EQ(kFile, process_data_phase1.tasks[0].birth.location.file_name);
  EXPECT_EQ(kFunction,
            process_data_phase1.tasks[0].birth.location.function_name);
  EXPECT_EQ(kLineNumber,
            process_data_phase1.tasks[0].birth.location.line_number);

  EXPECT_EQ(kMainThreadName, process_data_phase1.tasks[0].birth.thread_name);

  EXPECT_EQ(1, process_data_phase1.tasks[0].death_data.count);
  EXPECT_EQ(2, process_data_phase1.tasks[0].death_data.run_duration_sum);
  EXPECT_EQ(2, process_data_phase1.tasks[0].death_data.run_duration_max);
  EXPECT_EQ(2, process_data_phase1.tasks[0].death_data.run_duration_sample);
  EXPECT_EQ(4, process_data_phase1.tasks[0].death_data.queue_duration_sum);
  EXPECT_EQ(4, process_data_phase1.tasks[0].death_data.queue_duration_max);
  EXPECT_EQ(4, process_data_phase1.tasks[0].death_data.queue_duration_sample);

  EXPECT_EQ(kMainThreadName, process_data_phase1.tasks[0].death_thread_name);

  EXPECT_EQ(base::GetCurrentProcId(), process_data.process_id);
}

// We will deactivate tracking after the birth, and before the death, and
// demonstrate that the lifecycle is completely tallied. This ensures that
// our tallied births are matched by tallied deaths (except for when the
// task is still running, or is queued).
TEST_F(TrackedObjectsTest, LifeCycleMidDeactivatedToSnapshotMainThread) {
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::PROFILING_ACTIVE);

  const char kFunction[] = "LifeCycleMidDeactivatedToSnapshotMainThread";
  Location location(kFunction, kFile, kLineNumber, NULL);
  TallyABirth(location, kMainThreadName);

  const TrackedTime kTimePosted = TrackedTime::FromMilliseconds(1);
  const base::TimeTicks kDelayedStartTime = base::TimeTicks();
  // TrackingInfo will call TallyABirth() during construction.
  base::TrackingInfo pending_task(location, kDelayedStartTime);
  pending_task.time_posted = kTimePosted;  // Overwrite implied Now().

  // Turn off tracking now that we have births.
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::DEACTIVATED);

  const unsigned int kStartOfRun = 5;
  const unsigned int kEndOfRun = 7;
  SetTestTime(kStartOfRun);
  TaskStopwatch stopwatch;
  stopwatch.Start();
  SetTestTime(kEndOfRun);
  stopwatch.Stop();

  ThreadData::TallyRunOnNamedThreadIfTracking(pending_task, stopwatch);

  ProcessDataSnapshot process_data;
  ThreadData::Snapshot(0, &process_data);
  ExpectSimpleProcessData(process_data, kFunction, kMainThreadName,
                          kMainThreadName, 1, 2, 4);
}

// We will deactivate tracking before starting a life cycle, and neither
// the birth nor the death will be recorded.
TEST_F(TrackedObjectsTest, LifeCyclePreDeactivatedToSnapshotMainThread) {
  // Start in the deactivated state.
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::DEACTIVATED);

  const char kFunction[] = "LifeCyclePreDeactivatedToSnapshotMainThread";
  Location location(kFunction, kFile, kLineNumber, NULL);
  TallyABirth(location, kMainThreadName);

  const TrackedTime kTimePosted = TrackedTime::FromMilliseconds(1);
  const base::TimeTicks kDelayedStartTime = base::TimeTicks();
  // TrackingInfo will call TallyABirth() during construction.
  base::TrackingInfo pending_task(location, kDelayedStartTime);
  pending_task.time_posted = kTimePosted;  // Overwrite implied Now().

  const unsigned int kStartOfRun = 5;
  const unsigned int kEndOfRun = 7;
  SetTestTime(kStartOfRun);
  TaskStopwatch stopwatch;
  stopwatch.Start();
  SetTestTime(kEndOfRun);
  stopwatch.Stop();

  ThreadData::TallyRunOnNamedThreadIfTracking(pending_task, stopwatch);

  ProcessDataSnapshot process_data;
  ThreadData::Snapshot(0, &process_data);

  ASSERT_EQ(1u, process_data.phased_snapshots.size());

  auto it = process_data.phased_snapshots.find(0);
  ASSERT_TRUE(it != process_data.phased_snapshots.end());
  const ProcessDataPhaseSnapshot& process_data_phase = it->second;

  ASSERT_EQ(0u, process_data_phase.tasks.size());

  EXPECT_EQ(base::GetCurrentProcId(), process_data.process_id);
}

TEST_F(TrackedObjectsTest, TwoLives) {
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::PROFILING_ACTIVE);

  const char kFunction[] = "TwoLives";
  Location location(kFunction, kFile, kLineNumber, NULL);
  TallyABirth(location, kMainThreadName);

  const TrackedTime kTimePosted = TrackedTime::FromMilliseconds(1);
  const base::TimeTicks kDelayedStartTime = base::TimeTicks();
  // TrackingInfo will call TallyABirth() during construction.
  base::TrackingInfo pending_task(location, kDelayedStartTime);
  pending_task.time_posted = kTimePosted;  // Overwrite implied Now().

  const unsigned int kStartOfRun = 5;
  const unsigned int kEndOfRun = 7;
  SetTestTime(kStartOfRun);
  TaskStopwatch stopwatch;
  stopwatch.Start();
  SetTestTime(kEndOfRun);
  stopwatch.Stop();

  ThreadData::TallyRunOnNamedThreadIfTracking(pending_task, stopwatch);

  // TrackingInfo will call TallyABirth() during construction.
  base::TrackingInfo pending_task2(location, kDelayedStartTime);
  pending_task2.time_posted = kTimePosted;  // Overwrite implied Now().
  SetTestTime(kStartOfRun);
  TaskStopwatch stopwatch2;
  stopwatch2.Start();
  SetTestTime(kEndOfRun);
  stopwatch2.Stop();

  ThreadData::TallyRunOnNamedThreadIfTracking(pending_task2, stopwatch2);

  ProcessDataSnapshot process_data;
  ThreadData::Snapshot(0, &process_data);
  ExpectSimpleProcessData(process_data, kFunction, kMainThreadName,
                          kMainThreadName, 2, 2, 4);
}

TEST_F(TrackedObjectsTest, DifferentLives) {
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::PROFILING_ACTIVE);

  // Use a well named thread.
  ThreadData::InitializeThreadContext(kMainThreadName);
  const char kFunction[] = "DifferentLives";
  Location location(kFunction, kFile, kLineNumber, NULL);

  const TrackedTime kTimePosted = TrackedTime::FromMilliseconds(1);
  const base::TimeTicks kDelayedStartTime = base::TimeTicks();
  // TrackingInfo will call TallyABirth() during construction.
  base::TrackingInfo pending_task(location, kDelayedStartTime);
  pending_task.time_posted = kTimePosted;  // Overwrite implied Now().

  const unsigned int kStartOfRun = 5;
  const unsigned int kEndOfRun = 7;
  SetTestTime(kStartOfRun);
  TaskStopwatch stopwatch;
  stopwatch.Start();
  SetTestTime(kEndOfRun);
  stopwatch.Stop();

  ThreadData::TallyRunOnNamedThreadIfTracking(pending_task, stopwatch);

  const int kSecondFakeLineNumber = 999;
  Location second_location(kFunction, kFile, kSecondFakeLineNumber, NULL);

  // TrackingInfo will call TallyABirth() during construction.
  base::TrackingInfo pending_task2(second_location, kDelayedStartTime);
  pending_task2.time_posted = kTimePosted;  // Overwrite implied Now().

  ProcessDataSnapshot process_data;
  ThreadData::Snapshot(0, &process_data);

  ASSERT_EQ(1u, process_data.phased_snapshots.size());
  auto it = process_data.phased_snapshots.find(0);
  ASSERT_TRUE(it != process_data.phased_snapshots.end());
  const ProcessDataPhaseSnapshot& process_data_phase = it->second;

  ASSERT_EQ(2u, process_data_phase.tasks.size());

  EXPECT_EQ(kFile, process_data_phase.tasks[0].birth.location.file_name);
  EXPECT_EQ(kFunction,
            process_data_phase.tasks[0].birth.location.function_name);
  EXPECT_EQ(kLineNumber,
            process_data_phase.tasks[0].birth.location.line_number);
  EXPECT_EQ(kMainThreadName, process_data_phase.tasks[0].birth.thread_name);
  EXPECT_EQ(1, process_data_phase.tasks[0].death_data.count);
  EXPECT_EQ(2, process_data_phase.tasks[0].death_data.run_duration_sum);
  EXPECT_EQ(2, process_data_phase.tasks[0].death_data.run_duration_max);
  EXPECT_EQ(2, process_data_phase.tasks[0].death_data.run_duration_sample);
  EXPECT_EQ(4, process_data_phase.tasks[0].death_data.queue_duration_sum);
  EXPECT_EQ(4, process_data_phase.tasks[0].death_data.queue_duration_max);
  EXPECT_EQ(4, process_data_phase.tasks[0].death_data.queue_duration_sample);
  EXPECT_EQ(kMainThreadName, process_data_phase.tasks[0].death_thread_name);
  EXPECT_EQ(kFile, process_data_phase.tasks[1].birth.location.file_name);
  EXPECT_EQ(kFunction,
            process_data_phase.tasks[1].birth.location.function_name);
  EXPECT_EQ(kSecondFakeLineNumber,
            process_data_phase.tasks[1].birth.location.line_number);
  EXPECT_EQ(kMainThreadName, process_data_phase.tasks[1].birth.thread_name);
  EXPECT_EQ(1, process_data_phase.tasks[1].death_data.count);
  EXPECT_EQ(0, process_data_phase.tasks[1].death_data.run_duration_sum);
  EXPECT_EQ(0, process_data_phase.tasks[1].death_data.run_duration_max);
  EXPECT_EQ(0, process_data_phase.tasks[1].death_data.run_duration_sample);
  EXPECT_EQ(0, process_data_phase.tasks[1].death_data.queue_duration_sum);
  EXPECT_EQ(0, process_data_phase.tasks[1].death_data.queue_duration_max);
  EXPECT_EQ(0, process_data_phase.tasks[1].death_data.queue_duration_sample);
  EXPECT_EQ(kStillAlive, process_data_phase.tasks[1].death_thread_name);
  EXPECT_EQ(base::GetCurrentProcId(), process_data.process_id);
}

TEST_F(TrackedObjectsTest, TaskWithNestedExclusion) {
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::PROFILING_ACTIVE);

  const char kFunction[] = "TaskWithNestedExclusion";
  Location location(kFunction, kFile, kLineNumber, NULL);
  TallyABirth(location, kMainThreadName);

  const TrackedTime kTimePosted = TrackedTime::FromMilliseconds(1);
  const base::TimeTicks kDelayedStartTime = base::TimeTicks();
  // TrackingInfo will call TallyABirth() during construction.
  base::TrackingInfo pending_task(location, kDelayedStartTime);
  pending_task.time_posted = kTimePosted;  // Overwrite implied Now().

  SetTestTime(5);
  TaskStopwatch task_stopwatch;
  task_stopwatch.Start();
  {
    SetTestTime(8);
    TaskStopwatch exclusion_stopwatch;
    exclusion_stopwatch.Start();
    SetTestTime(12);
    exclusion_stopwatch.Stop();
  }
  SetTestTime(15);
  task_stopwatch.Stop();

  ThreadData::TallyRunOnNamedThreadIfTracking(pending_task, task_stopwatch);

  ProcessDataSnapshot process_data;
  ThreadData::Snapshot(0, &process_data);
  ExpectSimpleProcessData(process_data, kFunction, kMainThreadName,
                          kMainThreadName, 1, 6, 4);
}

TEST_F(TrackedObjectsTest, TaskWith2NestedExclusions) {
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::PROFILING_ACTIVE);

  const char kFunction[] = "TaskWith2NestedExclusions";
  Location location(kFunction, kFile, kLineNumber, NULL);
  TallyABirth(location, kMainThreadName);

  const TrackedTime kTimePosted = TrackedTime::FromMilliseconds(1);
  const base::TimeTicks kDelayedStartTime = base::TimeTicks();
  // TrackingInfo will call TallyABirth() during construction.
  base::TrackingInfo pending_task(location, kDelayedStartTime);
  pending_task.time_posted = kTimePosted;  // Overwrite implied Now().

  SetTestTime(5);
  TaskStopwatch task_stopwatch;
  task_stopwatch.Start();
  {
    SetTestTime(8);
    TaskStopwatch exclusion_stopwatch;
    exclusion_stopwatch.Start();
    SetTestTime(12);
    exclusion_stopwatch.Stop();

    SetTestTime(15);
    TaskStopwatch exclusion_stopwatch2;
    exclusion_stopwatch2.Start();
    SetTestTime(18);
    exclusion_stopwatch2.Stop();
  }
  SetTestTime(25);
  task_stopwatch.Stop();

  ThreadData::TallyRunOnNamedThreadIfTracking(pending_task, task_stopwatch);

  ProcessDataSnapshot process_data;
  ThreadData::Snapshot(0, &process_data);
  ExpectSimpleProcessData(process_data, kFunction, kMainThreadName,
                          kMainThreadName, 1, 13, 4);
}

TEST_F(TrackedObjectsTest, TaskWithNestedExclusionWithNestedTask) {
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::PROFILING_ACTIVE);

  const char kFunction[] = "TaskWithNestedExclusionWithNestedTask";
  Location location(kFunction, kFile, kLineNumber, NULL);

  const int kSecondFakeLineNumber = 999;

  TallyABirth(location, kMainThreadName);

  const TrackedTime kTimePosted = TrackedTime::FromMilliseconds(1);
  const base::TimeTicks kDelayedStartTime = base::TimeTicks();
  // TrackingInfo will call TallyABirth() during construction.
  base::TrackingInfo pending_task(location, kDelayedStartTime);
  pending_task.time_posted = kTimePosted;  // Overwrite implied Now().

  SetTestTime(5);
  TaskStopwatch task_stopwatch;
  task_stopwatch.Start();
  {
    SetTestTime(8);
    TaskStopwatch exclusion_stopwatch;
    exclusion_stopwatch.Start();
    {
      Location second_location(kFunction, kFile, kSecondFakeLineNumber, NULL);
      base::TrackingInfo nested_task(second_location, kDelayedStartTime);
       // Overwrite implied Now().
      nested_task.time_posted = TrackedTime::FromMilliseconds(8);
      SetTestTime(9);
      TaskStopwatch nested_task_stopwatch;
      nested_task_stopwatch.Start();
      SetTestTime(11);
      nested_task_stopwatch.Stop();
      ThreadData::TallyRunOnNamedThreadIfTracking(
          nested_task, nested_task_stopwatch);
    }
    SetTestTime(12);
    exclusion_stopwatch.Stop();
  }
  SetTestTime(15);
  task_stopwatch.Stop();

  ThreadData::TallyRunOnNamedThreadIfTracking(pending_task, task_stopwatch);

  ProcessDataSnapshot process_data;
  ThreadData::Snapshot(0, &process_data);

  ASSERT_EQ(1u, process_data.phased_snapshots.size());
  auto it = process_data.phased_snapshots.find(0);
  ASSERT_TRUE(it != process_data.phased_snapshots.end());
  const ProcessDataPhaseSnapshot& process_data_phase = it->second;

  // The order in which the two task follow is platform-dependent.
  int t0 =
      (process_data_phase.tasks[0].birth.location.line_number == kLineNumber)
          ? 0
          : 1;
  int t1 = 1 - t0;

  ASSERT_EQ(2u, process_data_phase.tasks.size());
  EXPECT_EQ(kFile, process_data_phase.tasks[t0].birth.location.file_name);
  EXPECT_EQ(kFunction,
            process_data_phase.tasks[t0].birth.location.function_name);
  EXPECT_EQ(kLineNumber,
            process_data_phase.tasks[t0].birth.location.line_number);
  EXPECT_EQ(kMainThreadName, process_data_phase.tasks[t0].birth.thread_name);
  EXPECT_EQ(1, process_data_phase.tasks[t0].death_data.count);
  EXPECT_EQ(6, process_data_phase.tasks[t0].death_data.run_duration_sum);
  EXPECT_EQ(6, process_data_phase.tasks[t0].death_data.run_duration_max);
  EXPECT_EQ(6, process_data_phase.tasks[t0].death_data.run_duration_sample);
  EXPECT_EQ(4, process_data_phase.tasks[t0].death_data.queue_duration_sum);
  EXPECT_EQ(4, process_data_phase.tasks[t0].death_data.queue_duration_max);
  EXPECT_EQ(4, process_data_phase.tasks[t0].death_data.queue_duration_sample);
  EXPECT_EQ(kMainThreadName, process_data_phase.tasks[t0].death_thread_name);
  EXPECT_EQ(kFile, process_data_phase.tasks[t1].birth.location.file_name);
  EXPECT_EQ(kFunction,
            process_data_phase.tasks[t1].birth.location.function_name);
  EXPECT_EQ(kSecondFakeLineNumber,
            process_data_phase.tasks[t1].birth.location.line_number);
  EXPECT_EQ(kMainThreadName, process_data_phase.tasks[t1].birth.thread_name);
  EXPECT_EQ(1, process_data_phase.tasks[t1].death_data.count);
  EXPECT_EQ(2, process_data_phase.tasks[t1].death_data.run_duration_sum);
  EXPECT_EQ(2, process_data_phase.tasks[t1].death_data.run_duration_max);
  EXPECT_EQ(2, process_data_phase.tasks[t1].death_data.run_duration_sample);
  EXPECT_EQ(1, process_data_phase.tasks[t1].death_data.queue_duration_sum);
  EXPECT_EQ(1, process_data_phase.tasks[t1].death_data.queue_duration_max);
  EXPECT_EQ(1, process_data_phase.tasks[t1].death_data.queue_duration_sample);
  EXPECT_EQ(kMainThreadName, process_data_phase.tasks[t1].death_thread_name);
  EXPECT_EQ(base::GetCurrentProcId(), process_data.process_id);
}

}  // namespace tracked_objects
