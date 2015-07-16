// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


#ifndef BASE_TRACE_EVENT_TRACE_EVENT_IMPL_H_
#define BASE_TRACE_EVENT_TRACE_EVENT_IMPL_H_

#include <stack>
#include <string>
#include <vector>

#include "base/atomicops.h"
#include "base/base_export.h"
#include "base/callback.h"
#include "base/containers/hash_tables.h"
#include "base/gtest_prod_util.h"
#include "base/memory/ref_counted_memory.h"
#include "base/memory/scoped_vector.h"
#include "base/observer_list.h"
#include "base/single_thread_task_runner.h"
#include "base/strings/string_util.h"
#include "base/synchronization/condition_variable.h"
#include "base/synchronization/lock.h"
#include "base/threading/thread.h"
#include "base/threading/thread_local.h"
#include "base/trace_event/trace_config.h"

// Older style trace macros with explicit id and extra data
// Only these macros result in publishing data to ETW as currently implemented.
// TODO(georgesak): Update/replace these with new ETW macros.
#define TRACE_EVENT_BEGIN_ETW(name, id, extra) \
    base::trace_event::TraceLog::AddTraceEventEtw( \
        TRACE_EVENT_PHASE_BEGIN, \
        name, reinterpret_cast<const void*>(id), extra)

#define TRACE_EVENT_END_ETW(name, id, extra) \
    base::trace_event::TraceLog::AddTraceEventEtw( \
        TRACE_EVENT_PHASE_END, \
        name, reinterpret_cast<const void*>(id), extra)

#define TRACE_EVENT_INSTANT_ETW(name, id, extra) \
    base::trace_event::TraceLog::AddTraceEventEtw( \
        TRACE_EVENT_PHASE_INSTANT, \
        name, reinterpret_cast<const void*>(id), extra)

template <typename Type>
struct DefaultSingletonTraits;

namespace base {

class WaitableEvent;
class MessageLoop;

namespace trace_event {

// For any argument of type TRACE_VALUE_TYPE_CONVERTABLE the provided
// class must implement this interface.
class BASE_EXPORT ConvertableToTraceFormat
    : public RefCounted<ConvertableToTraceFormat> {
 public:
  // Append the class info to the provided |out| string. The appended
  // data must be a valid JSON object. Strings must be properly quoted, and
  // escaped. There is no processing applied to the content after it is
  // appended.
  virtual void AppendAsTraceFormat(std::string* out) const = 0;

  std::string ToString() const {
    std::string result;
    AppendAsTraceFormat(&result);
    return result;
  }

 protected:
  virtual ~ConvertableToTraceFormat() {}

 private:
  friend class RefCounted<ConvertableToTraceFormat>;
};

struct TraceEventHandle {
  uint32 chunk_seq;
  uint16 chunk_index;
  uint16 event_index;
};

const int kTraceMaxNumArgs = 2;

class BASE_EXPORT TraceEvent {
 public:
  union TraceValue {
    bool as_bool;
    unsigned long long as_uint;
    long long as_int;
    double as_double;
    const void* as_pointer;
    const char* as_string;
  };

  TraceEvent();
  ~TraceEvent();

  // We don't need to copy TraceEvent except when TraceEventBuffer is cloned.
  // Use explicit copy method to avoid accidentally misuse of copy.
  void CopyFrom(const TraceEvent& other);

  void Initialize(
      int thread_id,
      TraceTicks timestamp,
      ThreadTicks thread_timestamp,
      char phase,
      const unsigned char* category_group_enabled,
      const char* name,
      unsigned long long id,
      int num_args,
      const char** arg_names,
      const unsigned char* arg_types,
      const unsigned long long* arg_values,
      const scoped_refptr<ConvertableToTraceFormat>* convertable_values,
      unsigned char flags);

  void Reset();

  void UpdateDuration(const TraceTicks& now, const ThreadTicks& thread_now);

  // Serialize event data to JSON
  typedef base::Callback<bool(const char* category_group_name,
                              const char* event_name)> ArgumentFilterPredicate;
  void AppendAsJSON(
      std::string* out,
      const ArgumentFilterPredicate& argument_filter_predicate) const;
  void AppendPrettyPrinted(std::ostringstream* out) const;

  static void AppendValueAsJSON(unsigned char type,
                                TraceValue value,
                                std::string* out);

  TraceTicks timestamp() const { return timestamp_; }
  ThreadTicks thread_timestamp() const { return thread_timestamp_; }
  char phase() const { return phase_; }
  int thread_id() const { return thread_id_; }
  TimeDelta duration() const { return duration_; }
  TimeDelta thread_duration() const { return thread_duration_; }
  unsigned long long id() const { return id_; }
  unsigned char flags() const { return flags_; }

  // Exposed for unittesting:

  const base::RefCountedString* parameter_copy_storage() const {
    return parameter_copy_storage_.get();
  }

  const unsigned char* category_group_enabled() const {
    return category_group_enabled_;
  }

  const char* name() const { return name_; }

#if defined(OS_ANDROID)
  void SendToATrace();
#endif

 private:
  // Note: these are ordered by size (largest first) for optimal packing.
  TraceTicks timestamp_;
  ThreadTicks thread_timestamp_;
  TimeDelta duration_;
  TimeDelta thread_duration_;
  // id_ can be used to store phase-specific data.
  unsigned long long id_;
  TraceValue arg_values_[kTraceMaxNumArgs];
  const char* arg_names_[kTraceMaxNumArgs];
  scoped_refptr<ConvertableToTraceFormat> convertable_values_[kTraceMaxNumArgs];
  const unsigned char* category_group_enabled_;
  const char* name_;
  scoped_refptr<base::RefCountedString> parameter_copy_storage_;
  int thread_id_;
  char phase_;
  unsigned char flags_;
  unsigned char arg_types_[kTraceMaxNumArgs];

  DISALLOW_COPY_AND_ASSIGN(TraceEvent);
};

// TraceBufferChunk is the basic unit of TraceBuffer.
class BASE_EXPORT TraceBufferChunk {
 public:
  explicit TraceBufferChunk(uint32 seq)
      : next_free_(0),
        seq_(seq) {
  }

  void Reset(uint32 new_seq);
  TraceEvent* AddTraceEvent(size_t* event_index);
  bool IsFull() const { return next_free_ == kTraceBufferChunkSize; }

  uint32 seq() const { return seq_; }
  size_t capacity() const { return kTraceBufferChunkSize; }
  size_t size() const { return next_free_; }

  TraceEvent* GetEventAt(size_t index) {
    DCHECK(index < size());
    return &chunk_[index];
  }
  const TraceEvent* GetEventAt(size_t index) const {
    DCHECK(index < size());
    return &chunk_[index];
  }

  scoped_ptr<TraceBufferChunk> Clone() const;

  static const size_t kTraceBufferChunkSize = 64;

 private:
  size_t next_free_;
  TraceEvent chunk_[kTraceBufferChunkSize];
  uint32 seq_;
};

// TraceBuffer holds the events as they are collected.
class BASE_EXPORT TraceBuffer {
 public:
  virtual ~TraceBuffer() {}

  virtual scoped_ptr<TraceBufferChunk> GetChunk(size_t *index) = 0;
  virtual void ReturnChunk(size_t index,
                           scoped_ptr<TraceBufferChunk> chunk) = 0;

  virtual bool IsFull() const = 0;
  virtual size_t Size() const = 0;
  virtual size_t Capacity() const = 0;
  virtual TraceEvent* GetEventByHandle(TraceEventHandle handle) = 0;

  // For iteration. Each TraceBuffer can only be iterated once.
  virtual const TraceBufferChunk* NextChunk() = 0;

  virtual scoped_ptr<TraceBuffer> CloneForIteration() const = 0;
};

// TraceResultBuffer collects and converts trace fragments returned by TraceLog
// to JSON output.
class BASE_EXPORT TraceResultBuffer {
 public:
  typedef base::Callback<void(const std::string&)> OutputCallback;

  // If you don't need to stream JSON chunks out efficiently, and just want to
  // get a complete JSON string after calling Finish, use this struct to collect
  // JSON trace output.
  struct BASE_EXPORT SimpleOutput {
    OutputCallback GetCallback();
    void Append(const std::string& json_string);

    // Do what you want with the json_output_ string after calling
    // TraceResultBuffer::Finish.
    std::string json_output;
  };

  TraceResultBuffer();
  ~TraceResultBuffer();

  // Set callback. The callback will be called during Start with the initial
  // JSON output and during AddFragment and Finish with following JSON output
  // chunks. The callback target must live past the last calls to
  // TraceResultBuffer::Start/AddFragment/Finish.
  void SetOutputCallback(const OutputCallback& json_chunk_callback);

  // Start JSON output. This resets all internal state, so you can reuse
  // the TraceResultBuffer by calling Start.
  void Start();

  // Call AddFragment 0 or more times to add trace fragments from TraceLog.
  void AddFragment(const std::string& trace_fragment);

  // When all fragments have been added, call Finish to complete the JSON
  // formatted output.
  void Finish();

 private:
  OutputCallback output_callback_;
  bool append_comma_;
};

class TraceSamplingThread;

struct BASE_EXPORT TraceLogStatus {
  TraceLogStatus();
  ~TraceLogStatus();
  size_t event_capacity;
  size_t event_count;
};

class BASE_EXPORT TraceLog {
 public:
  enum Mode {
    DISABLED = 0,
    RECORDING_MODE,
    MONITORING_MODE,
  };

  // The pointer returned from GetCategoryGroupEnabledInternal() points to a
  // value with zero or more of the following bits. Used in this class only.
  // The TRACE_EVENT macros should only use the value as a bool.
  // These values must be in sync with macro values in TraceEvent.h in Blink.
  enum CategoryGroupEnabledFlags {
    // Category group enabled for the recording mode.
    ENABLED_FOR_RECORDING = 1 << 0,
    // Category group enabled for the monitoring mode.
    ENABLED_FOR_MONITORING = 1 << 1,
    // Category group enabled by SetEventCallbackEnabled().
    ENABLED_FOR_EVENT_CALLBACK = 1 << 2,
    // Category group enabled to export events to ETW.
    ENABLED_FOR_ETW_EXPORT = 1 << 3
  };

  static TraceLog* GetInstance();

  // Get set of known category groups. This can change as new code paths are
  // reached. The known category groups are inserted into |category_groups|.
  void GetKnownCategoryGroups(std::vector<std::string>* category_groups);

  // Retrieves a copy (for thread-safety) of the current TraceConfig.
  TraceConfig GetCurrentTraceConfig() const;

  // Enables normal tracing (recording trace events in the trace buffer).
  // See TraceConfig comments for details on how to control what categories
  // will be traced. If tracing has already been enabled, |category_filter| will
  // be merged into the current category filter.
  void SetEnabled(const TraceConfig& trace_config, Mode mode);

  // Disables normal tracing for all categories.
  void SetDisabled();

  bool IsEnabled() { return mode_ != DISABLED; }

  // The number of times we have begun recording traces. If tracing is off,
  // returns -1. If tracing is on, then it returns the number of times we have
  // recorded a trace. By watching for this number to increment, you can
  // passively discover when a new trace has begun. This is then used to
  // implement the TRACE_EVENT_IS_NEW_TRACE() primitive.
  int GetNumTracesRecorded();

#if defined(OS_ANDROID)
  void StartATrace();
  void StopATrace();
  void AddClockSyncMetadataEvent();
#endif

  // Enabled state listeners give a callback when tracing is enabled or
  // disabled. This can be used to tie into other library's tracing systems
  // on-demand.
  class BASE_EXPORT EnabledStateObserver {
   public:
    // Called just after the tracing system becomes enabled, outside of the
    // |lock_|. TraceLog::IsEnabled() is true at this point.
    virtual void OnTraceLogEnabled() = 0;

    // Called just after the tracing system disables, outside of the |lock_|.
    // TraceLog::IsEnabled() is false at this point.
    virtual void OnTraceLogDisabled() = 0;
  };
  void AddEnabledStateObserver(EnabledStateObserver* listener);
  void RemoveEnabledStateObserver(EnabledStateObserver* listener);
  bool HasEnabledStateObserver(EnabledStateObserver* listener) const;

  TraceLogStatus GetStatus() const;
  bool BufferIsFull() const;

  // Not using base::Callback because of its limited by 7 parameters.
  // Also, using primitive type allows directly passing callback from WebCore.
  // WARNING: It is possible for the previously set callback to be called
  // after a call to SetEventCallbackEnabled() that replaces or a call to
  // SetEventCallbackDisabled() that disables the callback.
  // This callback may be invoked on any thread.
  // For TRACE_EVENT_PHASE_COMPLETE events, the client will still receive pairs
  // of TRACE_EVENT_PHASE_BEGIN and TRACE_EVENT_PHASE_END events to keep the
  // interface simple.
  typedef void (*EventCallback)(TraceTicks timestamp,
                                char phase,
                                const unsigned char* category_group_enabled,
                                const char* name,
                                unsigned long long id,
                                int num_args,
                                const char* const arg_names[],
                                const unsigned char arg_types[],
                                const unsigned long long arg_values[],
                                unsigned char flags);

  // Enable tracing for EventCallback.
  void SetEventCallbackEnabled(const TraceConfig& trace_config,
                               EventCallback cb);
  void SetEventCallbackDisabled();
  void SetArgumentFilterPredicate(
      const TraceEvent::ArgumentFilterPredicate& argument_filter_predicate);

  // Flush all collected events to the given output callback. The callback will
  // be called one or more times either synchronously or asynchronously from
  // the current thread with IPC-bite-size chunks. The string format is
  // undefined. Use TraceResultBuffer to convert one or more trace strings to
  // JSON. The callback can be null if the caller doesn't want any data.
  // Due to the implementation of thread-local buffers, flush can't be
  // done when tracing is enabled. If called when tracing is enabled, the
  // callback will be called directly with (empty_string, false) to indicate
  // the end of this unsuccessful flush. Flush does the serialization
  // on the same thread if the caller doesn't set use_worker_thread explicitly.
  typedef base::Callback<void(const scoped_refptr<base::RefCountedString>&,
                              bool has_more_events)> OutputCallback;
  void Flush(const OutputCallback& cb, bool use_worker_thread = false);
  void FlushButLeaveBufferIntact(const OutputCallback& flush_output_callback);

  // Called by TRACE_EVENT* macros, don't call this directly.
  // The name parameter is a category group for example:
  // TRACE_EVENT0("renderer,webkit", "WebViewImpl::HandleInputEvent")
  static const unsigned char* GetCategoryGroupEnabled(const char* name);
  static const char* GetCategoryGroupName(
      const unsigned char* category_group_enabled);

  // Called by TRACE_EVENT* macros, don't call this directly.
  // If |copy| is set, |name|, |arg_name1| and |arg_name2| will be deep copied
  // into the event; see "Memory scoping note" and TRACE_EVENT_COPY_XXX above.
  TraceEventHandle AddTraceEvent(
      char phase,
      const unsigned char* category_group_enabled,
      const char* name,
      unsigned long long id,
      int num_args,
      const char** arg_names,
      const unsigned char* arg_types,
      const unsigned long long* arg_values,
      const scoped_refptr<ConvertableToTraceFormat>* convertable_values,
      unsigned char flags);
  TraceEventHandle AddTraceEventWithThreadIdAndTimestamp(
      char phase,
      const unsigned char* category_group_enabled,
      const char* name,
      unsigned long long id,
      int thread_id,
      const TraceTicks& timestamp,
      int num_args,
      const char** arg_names,
      const unsigned char* arg_types,
      const unsigned long long* arg_values,
      const scoped_refptr<ConvertableToTraceFormat>* convertable_values,
      unsigned char flags);
  static void AddTraceEventEtw(char phase,
                               const char* category_group,
                               const void* id,
                               const char* extra);
  static void AddTraceEventEtw(char phase,
                               const char* category_group,
                               const void* id,
                               const std::string& extra);

  void UpdateTraceEventDuration(const unsigned char* category_group_enabled,
                                const char* name,
                                TraceEventHandle handle);

  // For every matching event, the callback will be called.
  typedef base::Callback<void()> WatchEventCallback;
  void SetWatchEvent(const std::string& category_name,
                     const std::string& event_name,
                     const WatchEventCallback& callback);
  // Cancel the watch event. If tracing is enabled, this may race with the
  // watch event notification firing.
  void CancelWatchEvent();

  int process_id() const { return process_id_; }

  uint64 MangleEventId(uint64 id);

  // Exposed for unittesting:

  void WaitSamplingEventForTesting();

  // Allows deleting our singleton instance.
  static void DeleteForTesting();

  // Allow tests to inspect TraceEvents.
  TraceEvent* GetEventByHandle(TraceEventHandle handle);

  void SetProcessID(int process_id);

  // Process sort indices, if set, override the order of a process will appear
  // relative to other processes in the trace viewer. Processes are sorted first
  // on their sort index, ascending, then by their name, and then tid.
  void SetProcessSortIndex(int sort_index);

  // Sets the name of the process.
  void SetProcessName(const std::string& process_name);

  // Processes can have labels in addition to their names. Use labels, for
  // instance, to list out the web page titles that a process is handling.
  void UpdateProcessLabel(int label_id, const std::string& current_label);
  void RemoveProcessLabel(int label_id);

  // Thread sort indices, if set, override the order of a thread will appear
  // within its process in the trace viewer. Threads are sorted first on their
  // sort index, ascending, then by their name, and then tid.
  void SetThreadSortIndex(PlatformThreadId , int sort_index);

  // Allow setting an offset between the current TraceTicks time and the time
  // that should be reported.
  void SetTimeOffset(TimeDelta offset);

  size_t GetObserverCountForTest() const;

  // Call this method if the current thread may block the message loop to
  // prevent the thread from using the thread-local buffer because the thread
  // may not handle the flush request in time causing lost of unflushed events.
  void SetCurrentThreadBlocksMessageLoop();

 private:
  typedef unsigned int InternalTraceOptions;

  FRIEND_TEST_ALL_PREFIXES(TraceEventTestFixture,
                           TraceBufferRingBufferGetReturnChunk);
  FRIEND_TEST_ALL_PREFIXES(TraceEventTestFixture,
                           TraceBufferRingBufferHalfIteration);
  FRIEND_TEST_ALL_PREFIXES(TraceEventTestFixture,
                           TraceBufferRingBufferFullIteration);
  FRIEND_TEST_ALL_PREFIXES(TraceEventTestFixture,
                           TraceBufferVectorReportFull);
  FRIEND_TEST_ALL_PREFIXES(TraceEventTestFixture,
                           ConvertTraceConfigToInternalOptions);
  FRIEND_TEST_ALL_PREFIXES(TraceEventTestFixture,
                           TraceRecordAsMuchAsPossibleMode);

  // This allows constructor and destructor to be private and usable only
  // by the Singleton class.
  friend struct DefaultSingletonTraits<TraceLog>;

  // Enable/disable each category group based on the current mode_,
  // category_filter_, event_callback_ and event_callback_category_filter_.
  // Enable the category group in the enabled mode if category_filter_ matches
  // the category group, or event_callback_ is not null and
  // event_callback_category_filter_ matches the category group.
  void UpdateCategoryGroupEnabledFlags();
  void UpdateCategoryGroupEnabledFlag(size_t category_index);

  // Configure synthetic delays based on the values set in the current
  // trace config.
  void UpdateSyntheticDelaysFromTraceConfig();

  InternalTraceOptions GetInternalOptionsFromTraceConfig(
      const TraceConfig& config);

  class ThreadLocalEventBuffer;
  class OptionalAutoLock;

  TraceLog();
  ~TraceLog();
  const unsigned char* GetCategoryGroupEnabledInternal(const char* name);
  void AddMetadataEventsWhileLocked();

  InternalTraceOptions trace_options() const {
    return static_cast<InternalTraceOptions>(
        subtle::NoBarrier_Load(&trace_options_));
  }

  TraceBuffer* trace_buffer() const { return logged_events_.get(); }
  TraceBuffer* CreateTraceBuffer();
  TraceBuffer* CreateTraceBufferVectorOfSize(size_t max_chunks);

  std::string EventToConsoleMessage(unsigned char phase,
                                    const TraceTicks& timestamp,
                                    TraceEvent* trace_event);

  TraceEvent* AddEventToThreadSharedChunkWhileLocked(TraceEventHandle* handle,
                                                     bool check_buffer_is_full);
  void CheckIfBufferIsFullWhileLocked();
  void SetDisabledWhileLocked();

  TraceEvent* GetEventByHandleInternal(TraceEventHandle handle,
                                       OptionalAutoLock* lock);

  // |generation| is used in the following callbacks to check if the callback
  // is called for the flush of the current |logged_events_|.
  void FlushCurrentThread(int generation);
  // Usually it runs on a different thread.
  static void ConvertTraceEventsToTraceFormat(
      scoped_ptr<TraceBuffer> logged_events,
      const TraceLog::OutputCallback& flush_output_callback,
      const TraceEvent::ArgumentFilterPredicate& argument_filter_predicate);
  void FinishFlush(int generation);
  void OnFlushTimeout(int generation);

  int generation() const {
    return static_cast<int>(subtle::NoBarrier_Load(&generation_));
  }
  bool CheckGeneration(int generation) const {
    return generation == this->generation();
  }
  void UseNextTraceBuffer();

  TraceTicks OffsetNow() const {
    return OffsetTimestamp(TraceTicks::Now());
  }
  TraceTicks OffsetTimestamp(const TraceTicks& timestamp) const {
    return timestamp - time_offset_;
  }

  // Internal representation of trace options since we store the currently used
  // trace option as an AtomicWord.
  static const InternalTraceOptions kInternalNone;
  static const InternalTraceOptions kInternalRecordUntilFull;
  static const InternalTraceOptions kInternalRecordContinuously;
  static const InternalTraceOptions kInternalEchoToConsole;
  static const InternalTraceOptions kInternalEnableSampling;
  static const InternalTraceOptions kInternalRecordAsMuchAsPossible;
  static const InternalTraceOptions kInternalEnableArgumentFilter;

  // This lock protects TraceLog member accesses (except for members protected
  // by thread_info_lock_) from arbitrary threads.
  mutable Lock lock_;
  // This lock protects accesses to thread_names_, thread_event_start_times_
  // and thread_colors_.
  Lock thread_info_lock_;
  Mode mode_;
  int num_traces_recorded_;
  scoped_ptr<TraceBuffer> logged_events_;
  subtle::AtomicWord /* EventCallback */ event_callback_;
  bool dispatching_to_observer_list_;
  std::vector<EnabledStateObserver*> enabled_state_observer_list_;

  std::string process_name_;
  base::hash_map<int, std::string> process_labels_;
  int process_sort_index_;
  base::hash_map<int, int> thread_sort_indices_;
  base::hash_map<int, std::string> thread_names_;

  // The following two maps are used only when ECHO_TO_CONSOLE.
  base::hash_map<int, std::stack<TraceTicks> > thread_event_start_times_;
  base::hash_map<std::string, int> thread_colors_;

  TraceTicks buffer_limit_reached_timestamp_;

  // XORed with TraceID to make it unlikely to collide with other processes.
  unsigned long long process_id_hash_;

  int process_id_;

  TimeDelta time_offset_;

  // Allow tests to wake up when certain events occur.
  WatchEventCallback watch_event_callback_;
  subtle::AtomicWord /* const unsigned char* */ watch_category_;
  std::string watch_event_name_;

  subtle::AtomicWord /* Options */ trace_options_;

  // Sampling thread handles.
  scoped_ptr<TraceSamplingThread> sampling_thread_;
  PlatformThreadHandle sampling_thread_handle_;

  TraceConfig trace_config_;
  TraceConfig event_callback_trace_config_;

  ThreadLocalPointer<ThreadLocalEventBuffer> thread_local_event_buffer_;
  ThreadLocalBoolean thread_blocks_message_loop_;
  ThreadLocalBoolean thread_is_in_trace_event_;

  // Contains the message loops of threads that have had at least one event
  // added into the local event buffer. Not using SingleThreadTaskRunner
  // because we need to know the life time of the message loops.
  hash_set<MessageLoop*> thread_message_loops_;

  // For events which can't be added into the thread local buffer, e.g. events
  // from threads without a message loop.
  scoped_ptr<TraceBufferChunk> thread_shared_chunk_;
  size_t thread_shared_chunk_index_;

  // Set when asynchronous Flush is in progress.
  OutputCallback flush_output_callback_;
  scoped_refptr<SingleThreadTaskRunner> flush_task_runner_;
  TraceEvent::ArgumentFilterPredicate argument_filter_predicate_;
  subtle::AtomicWord generation_;
  bool use_worker_thread_;

  DISALLOW_COPY_AND_ASSIGN(TraceLog);
};

}  // namespace trace_event
}  // namespace base

#endif  // BASE_TRACE_EVENT_TRACE_EVENT_IMPL_H_
