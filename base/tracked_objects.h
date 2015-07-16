// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TRACKED_OBJECTS_H_
#define BASE_TRACKED_OBJECTS_H_

#include <map>
#include <set>
#include <stack>
#include <string>
#include <utility>
#include <vector>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/containers/hash_tables.h"
#include "base/gtest_prod_util.h"
#include "base/lazy_instance.h"
#include "base/location.h"
#include "base/process/process_handle.h"
#include "base/profiler/alternate_timer.h"
#include "base/profiler/tracked_time.h"
#include "base/synchronization/lock.h"
#include "base/threading/thread_checker.h"
#include "base/threading/thread_local_storage.h"

namespace base {
struct TrackingInfo;
}

// TrackedObjects provides a database of stats about objects (generally Tasks)
// that are tracked.  Tracking means their birth, death, duration, birth thread,
// death thread, and birth place are recorded.  This data is carefully spread
// across a series of objects so that the counts and times can be rapidly
// updated without (usually) having to lock the data, and hence there is usually
// very little contention caused by the tracking.  The data can be viewed via
// the about:profiler URL, with a variety of sorting and filtering choices.
//
// These classes serve as the basis of a profiler of sorts for the Tasks system.
// As a result, design decisions were made to maximize speed, by minimizing
// recurring allocation/deallocation, lock contention and data copying.  In the
// "stable" state, which is reached relatively quickly, there is no separate
// marginal allocation cost associated with construction or destruction of
// tracked objects, no locks are generally employed, and probably the largest
// computational cost is associated with obtaining start and stop times for
// instances as they are created and destroyed.
//
// The following describes the life cycle of tracking an instance.
//
// First off, when the instance is created, the FROM_HERE macro is expanded
// to specify the birth place (file, line, function) where the instance was
// created.  That data is used to create a transient Location instance
// encapsulating the above triple of information.  The strings (like __FILE__)
// are passed around by reference, with the assumption that they are static, and
// will never go away.  This ensures that the strings can be dealt with as atoms
// with great efficiency (i.e., copying of strings is never needed, and
// comparisons for equality can be based on pointer comparisons).
//
// Next, a Births instance is created for use ONLY on the thread where this
// instance was created.  That Births instance records (in a base class
// BirthOnThread) references to the static data provided in a Location instance,
// as well as a pointer specifying the thread on which the birth takes place.
// Hence there is at most one Births instance for each Location on each thread.
// The derived Births class contains slots for recording statistics about all
// instances born at the same location.  Statistics currently include only the
// count of instances constructed.
//
// Since the base class BirthOnThread contains only constant data, it can be
// freely accessed by any thread at any time (i.e., only the statistic needs to
// be handled carefully, and stats are updated exclusively on the birth thread).
//
// For Tasks, having now either constructed or found the Births instance
// described above, a pointer to the Births instance is then recorded into the
// PendingTask structure in MessageLoop.  This fact alone is very useful in
// debugging, when there is a question of where an instance came from.  In
// addition, the birth time is also recorded and used to later evaluate the
// lifetime duration of the whole Task.  As a result of the above embedding, we
// can find out a Task's location of birth, and thread of birth, without using
// any locks, as all that data is constant across the life of the process.
//
// The above work *could* also be done for any other object as well by calling
// TallyABirthIfActive() and TallyRunOnNamedThreadIfTracking() as appropriate.
//
// The amount of memory used in the above data structures depends on how many
// threads there are, and how many Locations of construction there are.
// Fortunately, we don't use memory that is the product of those two counts, but
// rather we only need one Births instance for each thread that constructs an
// instance at a Location.  In many cases, instances are only created on one
// thread, so the memory utilization is actually fairly restrained.
//
// Lastly, when an instance is deleted, the final tallies of statistics are
// carefully accumulated.  That tallying writes into slots (members) in a
// collection of DeathData instances.  For each birth place Location that is
// destroyed on a thread, there is a DeathData instance to record the additional
// death count, as well as accumulate the run-time and queue-time durations for
// the instance as it is destroyed (dies).  By maintaining a single place to
// aggregate this running sum *only* for the given thread, we avoid the need to
// lock such DeathData instances. (i.e., these accumulated stats in a DeathData
// instance are exclusively updated by the singular owning thread).
//
// With the above life cycle description complete, the major remaining detail
// is explaining how each thread maintains a list of DeathData instances, and
// of Births instances, and is able to avoid additional (redundant/unnecessary)
// allocations.
//
// Each thread maintains a list of data items specific to that thread in a
// ThreadData instance (for that specific thread only).  The two critical items
// are lists of DeathData and Births instances.  These lists are maintained in
// STL maps, which are indexed by Location.  As noted earlier, we can compare
// locations very efficiently as we consider the underlying data (file,
// function, line) to be atoms, and hence pointer comparison is used rather than
// (slow) string comparisons.
//
// To provide a mechanism for iterating over all "known threads," which means
// threads that have recorded a birth or a death, we create a singly linked list
// of ThreadData instances.  Each such instance maintains a pointer to the next
// one.  A static member of ThreadData provides a pointer to the first item on
// this global list, and access via that all_thread_data_list_head_ item
// requires the use of the list_lock_.
// When new ThreadData instances is added to the global list, it is pre-pended,
// which ensures that any prior acquisition of the list is valid (i.e., the
// holder can iterate over it without fear of it changing, or the necessity of
// using an additional lock.  Iterations are actually pretty rare (used
// primarily for cleanup, or snapshotting data for display), so this lock has
// very little global performance impact.
//
// The above description tries to define the high performance (run time)
// portions of these classes.  After gathering statistics, calls instigated
// by visiting about:profiler will assemble and aggregate data for display.  The
// following data structures are used for producing such displays.  They are
// not performance critical, and their only major constraint is that they should
// be able to run concurrently with ongoing augmentation of the birth and death
// data.
//
// This header also exports collection of classes that provide "snapshotted"
// representations of the core tracked_objects:: classes.  These snapshotted
// representations are designed for safe transmission of the tracked_objects::
// data across process boundaries.  Each consists of:
// (1) a default constructor, to support the IPC serialization macros,
// (2) a constructor that extracts data from the type being snapshotted, and
// (3) the snapshotted data.
//
// For a given birth location, information about births is spread across data
// structures that are asynchronously changing on various threads.  For
// serialization and display purposes, we need to construct TaskSnapshot
// instances for each combination of birth thread, death thread, and location,
// along with the count of such lifetimes.  We gather such data into a
// TaskSnapshot instances, so that such instances can be sorted and
// aggregated (and remain frozen during our processing).
//
// Profiling consists of phases.  The concrete phase in the sequence of phases
// is identified by its 0-based index.
//
// The ProcessDataPhaseSnapshot struct is a serialized representation of the
// list of ThreadData objects for a process for a concrete profiling phase.  It
// holds a set of TaskSnapshots.  The statistics in a snapshot are gathered
// asynhcronously relative to their ongoing updates.
// It is possible, though highly unlikely, that stats could be incorrectly
// recorded by this process (all data is held in 32 bit ints, but we are not
// atomically collecting all data, so we could have count that does not, for
// example, match with the number of durations we accumulated).  The advantage
// to having fast (non-atomic) updates of the data outweighs the minimal risk of
// a singular corrupt statistic snapshot (only the snapshot could be corrupt,
// not the underlying and ongoing statistic).  In contrast, pointer data that
// is accessed during snapshotting is completely invariant, and hence is
// perfectly acquired (i.e., no potential corruption, and no risk of a bad
// memory reference).
//
// TODO(jar): We can implement a Snapshot system that *tries* to grab the
// snapshots on the source threads *when* they have MessageLoops available
// (worker threads don't have message loops generally, and hence gathering from
// them will continue to be asynchronous).  We had an implementation of this in
// the past, but the difficulty is dealing with message loops being terminated.
// We can *try* to spam the available threads via some message loop proxy to
// achieve this feat, and it *might* be valuable when we are collecting data
// for upload via UMA (where correctness of data may be more significant than
// for a single screen of about:profiler).
//
// TODO(jar): We need to store DataCollections, and provide facilities for
// taking the difference between two gathered DataCollections.  For now, we're
// just adding a hack that Reset()s to zero all counts and stats.  This is also
// done in a slightly thread-unsafe fashion, as the resetting is done
// asynchronously relative to ongoing updates (but all data is 32 bit in size).
// For basic profiling, this will work "most of the time," and should be
// sufficient... but storing away DataCollections is the "right way" to do this.
// We'll accomplish this via JavaScript storage of snapshots, and then we'll
// remove the Reset() methods.  We may also need a short-term-max value in
// DeathData that is reset (as synchronously as possible) during each snapshot.
// This will facilitate displaying a max value for each snapshot period.

namespace tracked_objects {

//------------------------------------------------------------------------------
// For a specific thread, and a specific birth place, the collection of all
// death info (with tallies for each death thread, to prevent access conflicts).
class ThreadData;
class BASE_EXPORT BirthOnThread {
 public:
  BirthOnThread(const Location& location, const ThreadData& current);

  const Location location() const { return location_; }
  const ThreadData* birth_thread() const { return birth_thread_; }

 private:
  // File/lineno of birth.  This defines the essence of the task, as the context
  // of the birth (construction) often tell what the item is for.  This field
  // is const, and hence safe to access from any thread.
  const Location location_;

  // The thread that records births into this object.  Only this thread is
  // allowed to update birth_count_ (which changes over time).
  const ThreadData* const birth_thread_;

  DISALLOW_COPY_AND_ASSIGN(BirthOnThread);
};

//------------------------------------------------------------------------------
// A "snapshotted" representation of the BirthOnThread class.

struct BASE_EXPORT BirthOnThreadSnapshot {
  BirthOnThreadSnapshot();
  explicit BirthOnThreadSnapshot(const BirthOnThread& birth);
  ~BirthOnThreadSnapshot();

  LocationSnapshot location;
  std::string thread_name;
};

//------------------------------------------------------------------------------
// A class for accumulating counts of births (without bothering with a map<>).

class BASE_EXPORT Births: public BirthOnThread {
 public:
  Births(const Location& location, const ThreadData& current);

  int birth_count() const;

  // When we have a birth we update the count for this birthplace.
  void RecordBirth();

 private:
  // The number of births on this thread for our location_.
  int birth_count_;

  DISALLOW_COPY_AND_ASSIGN(Births);
};

//------------------------------------------------------------------------------
// A "snapshotted" representation of the DeathData class.

struct BASE_EXPORT DeathDataSnapshot {
  DeathDataSnapshot();

  // Constructs the snapshot from individual values.
  // The alternative would be taking a DeathData parameter, but this would
  // create a loop since DeathData indirectly refers DeathDataSnapshot.  Passing
  // a wrapper structure as a param or using an empty constructor for
  // snapshotting DeathData would be less efficient.
  DeathDataSnapshot(int count,
                    int32 run_duration_sum,
                    int32 run_duration_max,
                    int32 run_duration_sample,
                    int32 queue_duration_sum,
                    int32 queue_duration_max,
                    int32 queue_duration_sample);
  ~DeathDataSnapshot();

  // Calculates and returns the delta between this snapshot and an earlier
  // snapshot of the same task |older|.
  DeathDataSnapshot Delta(const DeathDataSnapshot& older) const;

  int count;
  int32 run_duration_sum;
  int32 run_duration_max;
  int32 run_duration_sample;
  int32 queue_duration_sum;
  int32 queue_duration_max;
  int32 queue_duration_sample;
};

//------------------------------------------------------------------------------
// A "snapshotted" representation of the DeathData for a particular profiling
// phase.  Used as an element of the list of phase snapshots owned by DeathData.

struct DeathDataPhaseSnapshot {
  DeathDataPhaseSnapshot(int profiling_phase,
                         int count,
                         int32 run_duration_sum,
                         int32 run_duration_max,
                         int32 run_duration_sample,
                         int32 queue_duration_sum,
                         int32 queue_duration_max,
                         int32 queue_duration_sample,
                         const DeathDataPhaseSnapshot* prev);

  // Profiling phase at which completion this snapshot was taken.
  int profiling_phase;

  // Death data snapshot.
  DeathDataSnapshot death_data;

  // Pointer to a snapshot from the previous phase.
  const DeathDataPhaseSnapshot* prev;
};

//------------------------------------------------------------------------------
// Information about deaths of a task on a given thread, called "death thread".
// Access to members of this class is never protected by a lock.  The fields
// are accessed in such a way that corruptions resulting from race conditions
// are not significant, and don't accumulate as a result of multiple accesses.
// All invocations of DeathData::OnProfilingPhaseCompleted and
// ThreadData::SnapshotMaps (which takes DeathData snapshot) in a given process
// must be called from the same thread. It doesn't matter what thread it is, but
// it's important the same thread is used as a snapshot thread during the whole
// process lifetime.  All fields except sample_probability_count_ can be
// snapshotted.

class BASE_EXPORT DeathData {
 public:
  DeathData();
  DeathData(const DeathData& other);
  ~DeathData();

  // Update stats for a task destruction (death) that had a Run() time of
  // |duration|, and has had a queueing delay of |queue_duration|.
  void RecordDeath(const int32 queue_duration,
                   const int32 run_duration,
                   const uint32 random_number);

  // Metrics and past snapshots accessors, used only for serialization and in
  // tests.
  int count() const { return count_; }
  int32 run_duration_sum() const { return run_duration_sum_; }
  int32 run_duration_max() const { return run_duration_max_; }
  int32 run_duration_sample() const { return run_duration_sample_; }
  int32 queue_duration_sum() const { return queue_duration_sum_; }
  int32 queue_duration_max() const { return queue_duration_max_; }
  int32 queue_duration_sample() const { return queue_duration_sample_; }
  const DeathDataPhaseSnapshot* last_phase_snapshot() const {
    return last_phase_snapshot_;
  }

  // Called when the current profiling phase, identified by |profiling_phase|,
  // ends.
  // Must be called only on the snapshot thread.
  void OnProfilingPhaseCompleted(int profiling_phase);

 private:
  // Members are ordered from most regularly read and updated, to least
  // frequently used.  This might help a bit with cache lines.
  // Number of runs seen (divisor for calculating averages).
  // Can be incremented only on the death thread.
  int count_;

  // Count used in determining probability of selecting exec/queue times from a
  // recorded death as samples.
  // Gets incremented only on the death thread, but can be set to 0 by
  // OnProfilingPhaseCompleted() on the snapshot thread.
  int sample_probability_count_;

  // Basic tallies, used to compute averages.  Can be incremented only on the
  // death thread.
  int32 run_duration_sum_;
  int32 queue_duration_sum_;
  // Max values, used by local visualization routines.  These are often read,
  // but rarely updated.  The max values get assigned only on the death thread,
  // but these fields can be set to 0 by OnProfilingPhaseCompleted() on the
  // snapshot thread.
  int32 run_duration_max_;
  int32 queue_duration_max_;
  // Samples, used by crowd sourcing gatherers.  These are almost never read,
  // and rarely updated.  They can be modified only on the death thread.
  int32 run_duration_sample_;
  int32 queue_duration_sample_;

  // Snapshot of this death data made at the last profiling phase completion, if
  // any.  DeathData owns the whole list starting with this pointer.
  // Can be accessed only on the snapshot thread.
  const DeathDataPhaseSnapshot* last_phase_snapshot_;

  DISALLOW_ASSIGN(DeathData);
};

//------------------------------------------------------------------------------
// A temporary collection of data that can be sorted and summarized.  It is
// gathered (carefully) from many threads.  Instances are held in arrays and
// processed, filtered, and rendered.
// The source of this data was collected on many threads, and is asynchronously
// changing.  The data in this instance is not asynchronously changing.

struct BASE_EXPORT TaskSnapshot {
  TaskSnapshot();
  TaskSnapshot(const BirthOnThreadSnapshot& birth,
               const DeathDataSnapshot& death_data,
               const std::string& death_thread_name);
  ~TaskSnapshot();

  BirthOnThreadSnapshot birth;
  // Delta between death data for a thread for a certain profiling phase and the
  // snapshot for the pervious phase, if any.  Otherwise, just a snapshot.
  DeathDataSnapshot death_data;
  std::string death_thread_name;
};

//------------------------------------------------------------------------------
// For each thread, we have a ThreadData that stores all tracking info generated
// on this thread.  This prevents the need for locking as data accumulates.
// We use ThreadLocalStorage to quickly identfy the current ThreadData context.
// We also have a linked list of ThreadData instances, and that list is used to
// harvest data from all existing instances.

struct ProcessDataPhaseSnapshot;
struct ProcessDataSnapshot;
class BASE_EXPORT TaskStopwatch;

// Map from profiling phase number to the process-wide snapshotted
// representation of the list of ThreadData objects that died during the given
// phase.
typedef std::map<int, ProcessDataPhaseSnapshot> PhasedProcessDataSnapshotMap;

class BASE_EXPORT ThreadData {
 public:
  // Current allowable states of the tracking system.  The states can vary
  // between ACTIVE and DEACTIVATED, but can never go back to UNINITIALIZED.
  enum Status {
    UNINITIALIZED,         // Pristine, link-time state before running.
    DORMANT_DURING_TESTS,  // Only used during testing.
    DEACTIVATED,           // No longer recording profiling.
    PROFILING_ACTIVE,      // Recording profiles.
    STATUS_LAST = PROFILING_ACTIVE
  };

  typedef base::hash_map<Location, Births*, Location::Hash> BirthMap;
  typedef std::map<const Births*, DeathData> DeathMap;

  // Initialize the current thread context with a new instance of ThreadData.
  // This is used by all threads that have names, and should be explicitly
  // set *before* any births on the threads have taken place.  It is generally
  // only used by the message loop, which has a well defined thread name.
  static void InitializeThreadContext(const std::string& suggested_name);

  // Using Thread Local Store, find the current instance for collecting data.
  // If an instance does not exist, construct one (and remember it for use on
  // this thread.
  // This may return NULL if the system is disabled for any reason.
  static ThreadData* Get();

  // Fills |process_data_snapshot| with phased snapshots of all profiling
  // phases, including the current one, identified by |current_profiling_phase|.
  // |current_profiling_phase| is necessary because a child process can start
  // after several phase-changing events, so it needs to receive the current
  // phase number from the browser process to fill the correct entry for the
  // current phase in the |process_data_snapshot| map.
  static void Snapshot(int current_profiling_phase,
                       ProcessDataSnapshot* process_data_snapshot);

  // Called when the current profiling phase, identified by |profiling_phase|,
  // ends.
  // |profiling_phase| is necessary because a child process can start after
  // several phase-changing events, so it needs to receive the phase number from
  // the browser process to fill the correct entry in the
  // completed_phases_snapshots_ map.
  static void OnProfilingPhaseCompleted(int profiling_phase);

  // Finds (or creates) a place to count births from the given location in this
  // thread, and increment that tally.
  // TallyABirthIfActive will returns NULL if the birth cannot be tallied.
  static Births* TallyABirthIfActive(const Location& location);

  // Records the end of a timed run of an object.  The |completed_task| contains
  // a pointer to a Births, the time_posted, and a delayed_start_time if any.
  // The |start_of_run| indicates when we started to perform the run of the
  // task.  The delayed_start_time is non-null for tasks that were posted as
  // delayed tasks, and it indicates when the task should have run (i.e., when
  // it should have posted out of the timer queue, and into the work queue.
  // The |end_of_run| was just obtained by a call to Now() (just after the task
  // finished).  It is provided as an argument to help with testing.
  static void TallyRunOnNamedThreadIfTracking(
      const base::TrackingInfo& completed_task,
      const TaskStopwatch& stopwatch);

  // Record the end of a timed run of an object.  The |birth| is the record for
  // the instance, the |time_posted| records that instant, which is presumed to
  // be when the task was posted into a queue to run on a worker thread.
  // The |start_of_run| is when the worker thread started to perform the run of
  // the task.
  // The |end_of_run| was just obtained by a call to Now() (just after the task
  // finished).
  static void TallyRunOnWorkerThreadIfTracking(const Births* births,
                                               const TrackedTime& time_posted,
                                               const TaskStopwatch& stopwatch);

  // Record the end of execution in region, generally corresponding to a scope
  // being exited.
  static void TallyRunInAScopedRegionIfTracking(const Births* births,
                                                const TaskStopwatch& stopwatch);

  const std::string& thread_name() const { return thread_name_; }

  // Initializes all statics if needed (this initialization call should be made
  // while we are single threaded).
  static void Initialize();

  // Sets internal status_.
  // If |status| is false, then status_ is set to DEACTIVATED.
  // If |status| is true, then status_ is set to PROFILING_ACTIVE.
  static void InitializeAndSetTrackingStatus(Status status);

  static Status status();

  // Indicate if any sort of profiling is being done (i.e., we are more than
  // DEACTIVATED).
  static bool TrackingStatus();

  // Enables profiler timing.
  static void EnableProfilerTiming();

  // Provide a time function that does nothing (runs fast) when we don't have
  // the profiler enabled.  It will generally be optimized away when it is
  // ifdef'ed to be small enough (allowing the profiler to be "compiled out" of
  // the code).
  static TrackedTime Now();

  // Use the function |now| to provide current times, instead of calling the
  // TrackedTime::Now() function.  Since this alternate function is being used,
  // the other time arguments (used for calculating queueing delay) will be
  // ignored.
  static void SetAlternateTimeSource(NowFunction* now);

  // This function can be called at process termination to validate that thread
  // cleanup routines have been called for at least some number of named
  // threads.
  static void EnsureCleanupWasCalled(int major_threads_shutdown_count);

 private:
  friend class TaskStopwatch;
  // Allow only tests to call ShutdownSingleThreadedCleanup.  We NEVER call it
  // in production code.
  // TODO(jar): Make this a friend in DEBUG only, so that the optimizer has a
  // better change of optimizing (inlining? etc.) private methods (knowing that
  // there will be no need for an external entry point).
  friend class TrackedObjectsTest;
  FRIEND_TEST_ALL_PREFIXES(TrackedObjectsTest, MinimalStartupShutdown);
  FRIEND_TEST_ALL_PREFIXES(TrackedObjectsTest, TinyStartupShutdown);

  typedef std::map<const BirthOnThread*, int> BirthCountMap;

  typedef std::vector<std::pair<const Births*, DeathDataPhaseSnapshot>>
      DeathsSnapshot;

  // Worker thread construction creates a name since there is none.
  explicit ThreadData(int thread_number);

  // Message loop based construction should provide a name.
  explicit ThreadData(const std::string& suggested_name);

  ~ThreadData();

  // Push this instance to the head of all_thread_data_list_head_, linking it to
  // the previous head.  This is performed after each construction, and leaves
  // the instance permanently on that list.
  void PushToHeadOfList();

  // (Thread safe) Get start of list of all ThreadData instances using the lock.
  static ThreadData* first();

  // Iterate through the null terminated list of ThreadData instances.
  ThreadData* next() const;


  // In this thread's data, record a new birth.
  Births* TallyABirth(const Location& location);

  // Find a place to record a death on this thread.
  void TallyADeath(const Births& births,
                   int32 queue_duration,
                   const TaskStopwatch& stopwatch);

  // Snapshots (under a lock) the profiled data for the tasks for this thread
  // and writes all of the executed tasks' data -- i.e. the data for all
  // profiling phases (including the current one: |current_profiling_phase|) for
  // the tasks with with entries in the death_map_ -- into |phased_snapshots|.
  // Also updates the |birth_counts| tally for each task to keep track of the
  // number of living instances of the task -- that is, each task maps to the
  // number of births for the task that have not yet been balanced by a death.
  void SnapshotExecutedTasks(int current_profiling_phase,
                             PhasedProcessDataSnapshotMap* phased_snapshots,
                             BirthCountMap* birth_counts);

  // Using our lock, make a copy of the specified maps.  This call may be made
  // on  non-local threads, which necessitate the use of the lock to prevent
  // the map(s) from being reallocated while they are copied.
  void SnapshotMaps(int profiling_phase,
                    BirthMap* birth_map,
                    DeathsSnapshot* deaths);

  // Called for this thread when the current profiling phase, identified by
  // |profiling_phase|, ends.
  void OnProfilingPhaseCompletedOnThread(int profiling_phase);

  // This method is called by the TLS system when a thread terminates.
  // The argument may be NULL if this thread has never tracked a birth or death.
  static void OnThreadTermination(void* thread_data);

  // This method should be called when a worker thread terminates, so that we
  // can save all the thread data into a cache of reusable ThreadData instances.
  void OnThreadTerminationCleanup();

  // Cleans up data structures, and returns statics to near pristine (mostly
  // uninitialized) state.  If there is any chance that other threads are still
  // using the data structures, then the |leak| argument should be passed in as
  // true, and the data structures (birth maps, death maps, ThreadData
  // insntances, etc.) will be leaked and not deleted.  If you have joined all
  // threads since the time that InitializeAndSetTrackingStatus() was called,
  // then you can pass in a |leak| value of false, and this function will
  // delete recursively all data structures, starting with the list of
  // ThreadData instances.
  static void ShutdownSingleThreadedCleanup(bool leak);

  // When non-null, this specifies an external function that supplies monotone
  // increasing time functcion.
  static NowFunction* now_function_;

  // If true, now_function_ returns values that can be used to calculate queue
  // time.
  static bool now_function_is_time_;

  // We use thread local store to identify which ThreadData to interact with.
  static base::ThreadLocalStorage::StaticSlot tls_index_;

  // List of ThreadData instances for use with worker threads.  When a worker
  // thread is done (terminated), we push it onto this list.  When a new worker
  // thread is created, we first try to re-use a ThreadData instance from the
  // list, and if none are available, construct a new one.
  // This is only accessed while list_lock_ is held.
  static ThreadData* first_retired_worker_;

  // Link to the most recently created instance (starts a null terminated list).
  // The list is traversed by about:profiler when it needs to snapshot data.
  // This is only accessed while list_lock_ is held.
  static ThreadData* all_thread_data_list_head_;

  // The next available worker thread number.  This should only be accessed when
  // the list_lock_ is held.
  static int worker_thread_data_creation_count_;

  // The number of times TLS has called us back to cleanup a ThreadData
  // instance.  This is only accessed while list_lock_ is held.
  static int cleanup_count_;

  // Incarnation sequence number, indicating how many times (during unittests)
  // we've either transitioned out of UNINITIALIZED, or into that state.  This
  // value is only accessed while the list_lock_ is held.
  static int incarnation_counter_;

  // Protection for access to all_thread_data_list_head_, and to
  // unregistered_thread_data_pool_.  This lock is leaked at shutdown.
  // The lock is very infrequently used, so we can afford to just make a lazy
  // instance and be safe.
  static base::LazyInstance<base::Lock>::Leaky list_lock_;

  // We set status_ to SHUTDOWN when we shut down the tracking service.
  static Status status_;

  // Link to next instance (null terminated list).  Used to globally track all
  // registered instances (corresponds to all registered threads where we keep
  // data).
  ThreadData* next_;

  // Pointer to another ThreadData instance for a Worker-Thread that has been
  // retired (its thread was terminated).  This value is non-NULL only for a
  // retired ThreadData associated with a Worker-Thread.
  ThreadData* next_retired_worker_;

  // The name of the thread that is being recorded.  If this thread has no
  // message_loop, then this is a worker thread, with a sequence number postfix.
  std::string thread_name_;

  // Indicate if this is a worker thread, and the ThreadData contexts should be
  // stored in the unregistered_thread_data_pool_ when not in use.
  // Value is zero when it is not a worker thread.  Value is a positive integer
  // corresponding to the created thread name if it is a worker thread.
  int worker_thread_number_;

  // A map used on each thread to keep track of Births on this thread.
  // This map should only be accessed on the thread it was constructed on.
  // When a snapshot is needed, this structure can be locked in place for the
  // duration of the snapshotting activity.
  BirthMap birth_map_;

  // Similar to birth_map_, this records informations about death of tracked
  // instances (i.e., when a tracked instance was destroyed on this thread).
  // It is locked before changing, and hence other threads may access it by
  // locking before reading it.
  DeathMap death_map_;

  // Lock to protect *some* access to BirthMap and DeathMap.  The maps are
  // regularly read and written on this thread, but may only be read from other
  // threads.  To support this, we acquire this lock if we are writing from this
  // thread, or reading from another thread.  For reading from this thread we
  // don't need a lock, as there is no potential for a conflict since the
  // writing is only done from this thread.
  mutable base::Lock map_lock_;

  // A random number that we used to select decide which sample to keep as a
  // representative sample in each DeathData instance.  We can't start off with
  // much randomness (because we can't call RandInt() on all our threads), so
  // we stir in more and more as we go.
  uint32 random_number_;

  // Record of what the incarnation_counter_ was when this instance was created.
  // If the incarnation_counter_ has changed, then we avoid pushing into the
  // pool (this is only critical in tests which go through multiple
  // incarnations).
  int incarnation_count_for_pool_;

  // Most recently started (i.e. most nested) stopwatch on the current thread,
  // if it exists; NULL otherwise.
  TaskStopwatch* current_stopwatch_;

  DISALLOW_COPY_AND_ASSIGN(ThreadData);
};

//------------------------------------------------------------------------------
// Stopwatch to measure task run time or simply create a time interval that will
// be subtracted from the current most nested task's run time.  Stopwatches
// coordinate with the stopwatches in which they are nested to avoid
// double-counting nested tasks run times.

class BASE_EXPORT TaskStopwatch {
 public:
  // Starts the stopwatch.
  TaskStopwatch();
  ~TaskStopwatch();

  // Starts stopwatch.
  void Start();

  // Stops stopwatch.
  void Stop();

  // Returns the start time.
  TrackedTime StartTime() const;

  // Task's duration is calculated as the wallclock duration between starting
  // and stopping this stopwatch, minus the wallclock durations of any other
  // instances that are immediately nested in this one, started and stopped on
  // this thread during that period.
  int32 RunDurationMs() const;

  // Returns tracking info for the current thread.
  ThreadData* GetThreadData() const;

 private:
  // Time when the stopwatch was started.
  TrackedTime start_time_;

  // Wallclock duration of the task.
  int32 wallclock_duration_ms_;

  // Tracking info for the current thread.
  ThreadData* current_thread_data_;

  // Sum of wallclock durations of all stopwatches that were directly nested in
  // this one.
  int32 excluded_duration_ms_;

  // Stopwatch which was running on our thread when this stopwatch was started.
  // That preexisting stopwatch must be adjusted to the exclude the wallclock
  // duration of this stopwatch.
  TaskStopwatch* parent_;

#if DCHECK_IS_ON()
  // State of the stopwatch.  Stopwatch is first constructed in a created state
  // state, then is optionally started/stopped, then destructed.
  enum { CREATED, RUNNING, STOPPED } state_;

  // Currently running stopwatch that is directly nested in this one, if such
  // stopwatch exists.  NULL otherwise.
  TaskStopwatch* child_;
#endif
};

//------------------------------------------------------------------------------
// A snapshotted representation of the list of ThreadData objects for a process,
// for a single profiling phase.

struct BASE_EXPORT ProcessDataPhaseSnapshot {
 public:
  ProcessDataPhaseSnapshot();
  ~ProcessDataPhaseSnapshot();

  std::vector<TaskSnapshot> tasks;
};

//------------------------------------------------------------------------------
// A snapshotted representation of the list of ThreadData objects for a process,
// for all profiling phases, including the current one.

struct BASE_EXPORT ProcessDataSnapshot {
 public:
  ProcessDataSnapshot();
  ~ProcessDataSnapshot();

  PhasedProcessDataSnapshotMap phased_snapshots;
  base::ProcessId process_id;
};

}  // namespace tracked_objects

#endif  // BASE_TRACKED_OBJECTS_H_
