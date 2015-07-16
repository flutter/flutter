// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/trace_event_impl.h"

#include <algorithm>
#include <cmath>

#include "base/base_switches.h"
#include "base/bind.h"
#include "base/command_line.h"
#include "base/debug/leak_annotations.h"
#include "base/format_macros.h"
#include "base/json/string_escape.h"
#include "base/lazy_instance.h"
#include "base/location.h"
#include "base/memory/singleton.h"
#include "base/process/process_metrics.h"
#include "base/stl_util.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_split.h"
#include "base/strings/string_tokenizer.h"
#include "base/strings/string_util.h"
#include "base/strings/stringprintf.h"
#include "base/strings/utf_string_conversions.h"
#include "base/synchronization/cancellation_flag.h"
#include "base/synchronization/waitable_event.h"
#include "base/sys_info.h"
#include "base/third_party/dynamic_annotations/dynamic_annotations.h"
#include "base/thread_task_runner_handle.h"
#include "base/threading/platform_thread.h"
#include "base/threading/thread_id_name_manager.h"
#include "base/threading/worker_pool.h"
#include "base/time/time.h"
#include "base/trace_event/trace_event.h"
#include "base/trace_event/trace_event_synthetic_delay.h"

#if defined(OS_WIN)
#include "base/trace_event/trace_event_etw_export_win.h"
#include "base/trace_event/trace_event_win.h"
#endif

class DeleteTraceLogForTesting {
 public:
  static void Delete() {
    Singleton<base::trace_event::TraceLog,
              LeakySingletonTraits<base::trace_event::TraceLog>>::OnExit(0);
  }
};

// The thread buckets for the sampling profiler.
BASE_EXPORT TRACE_EVENT_API_ATOMIC_WORD g_trace_state[3];

namespace base {
namespace trace_event {

namespace {

// The overhead of TraceEvent above this threshold will be reported in the
// trace.
const int kOverheadReportThresholdInMicroseconds = 50;

// Controls the number of trace events we will buffer in-memory
// before throwing them away.
const size_t kTraceBufferChunkSize = TraceBufferChunk::kTraceBufferChunkSize;
const size_t kTraceEventVectorBigBufferChunks =
    512000000 / kTraceBufferChunkSize;
const size_t kTraceEventVectorBufferChunks = 256000 / kTraceBufferChunkSize;
const size_t kTraceEventRingBufferChunks = kTraceEventVectorBufferChunks / 4;
const size_t kTraceEventBufferSizeInBytes = 100 * 1024;
// Can store results for 30 seconds with 1 ms sampling interval.
const size_t kMonitorTraceEventBufferChunks = 30000 / kTraceBufferChunkSize;
// ECHO_TO_CONSOLE needs a small buffer to hold the unfinished COMPLETE events.
const size_t kEchoToConsoleTraceEventBufferChunks = 256;

const int kThreadFlushTimeoutMs = 3000;

#if !defined(OS_NACL)
// These categories will cause deadlock when ECHO_TO_CONSOLE. crbug.com/325575.
const char kEchoToConsoleCategoryFilter[] = "-ipc,-task";
#endif

#define MAX_CATEGORY_GROUPS 100

// Parallel arrays g_category_groups and g_category_group_enabled are separate
// so that a pointer to a member of g_category_group_enabled can be easily
// converted to an index into g_category_groups. This allows macros to deal
// only with char enabled pointers from g_category_group_enabled, and we can
// convert internally to determine the category name from the char enabled
// pointer.
const char* g_category_groups[MAX_CATEGORY_GROUPS] = {
  "toplevel",
  "tracing already shutdown",
  "tracing categories exhausted; must increase MAX_CATEGORY_GROUPS",
  "__metadata",
  // For reporting trace_event overhead. For thread local event buffers only.
  "trace_event_overhead"};

// The enabled flag is char instead of bool so that the API can be used from C.
unsigned char g_category_group_enabled[MAX_CATEGORY_GROUPS] = { 0 };
// Indexes here have to match the g_category_groups array indexes above.
const int g_category_already_shutdown = 1;
const int g_category_categories_exhausted = 2;
const int g_category_metadata = 3;
const int g_category_trace_event_overhead = 4;
const int g_num_builtin_categories = 5;
// Skip default categories.
base::subtle::AtomicWord g_category_index = g_num_builtin_categories;

// The name of the current thread. This is used to decide if the current
// thread name has changed. We combine all the seen thread names into the
// output name for the thread.
LazyInstance<ThreadLocalPointer<const char> >::Leaky
    g_current_thread_name = LAZY_INSTANCE_INITIALIZER;

ThreadTicks ThreadNow() {
  return ThreadTicks::IsSupported() ? ThreadTicks::Now() : ThreadTicks();
}

class TraceBufferRingBuffer : public TraceBuffer {
 public:
  TraceBufferRingBuffer(size_t max_chunks)
      : max_chunks_(max_chunks),
        recyclable_chunks_queue_(new size_t[queue_capacity()]),
        queue_head_(0),
        queue_tail_(max_chunks),
        current_iteration_index_(0),
        current_chunk_seq_(1) {
    chunks_.reserve(max_chunks);
    for (size_t i = 0; i < max_chunks; ++i)
      recyclable_chunks_queue_[i] = i;
  }

  scoped_ptr<TraceBufferChunk> GetChunk(size_t* index) override {
    // Because the number of threads is much less than the number of chunks,
    // the queue should never be empty.
    DCHECK(!QueueIsEmpty());

    *index = recyclable_chunks_queue_[queue_head_];
    queue_head_ = NextQueueIndex(queue_head_);
    current_iteration_index_ = queue_head_;

    if (*index >= chunks_.size())
      chunks_.resize(*index + 1);

    TraceBufferChunk* chunk = chunks_[*index];
    chunks_[*index] = NULL;  // Put NULL in the slot of a in-flight chunk.
    if (chunk)
      chunk->Reset(current_chunk_seq_++);
    else
      chunk = new TraceBufferChunk(current_chunk_seq_++);

    return scoped_ptr<TraceBufferChunk>(chunk);
  }

  void ReturnChunk(size_t index, scoped_ptr<TraceBufferChunk> chunk) override {
    // When this method is called, the queue should not be full because it
    // can contain all chunks including the one to be returned.
    DCHECK(!QueueIsFull());
    DCHECK(chunk);
    DCHECK_LT(index, chunks_.size());
    DCHECK(!chunks_[index]);
    chunks_[index] = chunk.release();
    recyclable_chunks_queue_[queue_tail_] = index;
    queue_tail_ = NextQueueIndex(queue_tail_);
  }

  bool IsFull() const override { return false; }

  size_t Size() const override {
    // This is approximate because not all of the chunks are full.
    return chunks_.size() * kTraceBufferChunkSize;
  }

  size_t Capacity() const override {
    return max_chunks_ * kTraceBufferChunkSize;
  }

  TraceEvent* GetEventByHandle(TraceEventHandle handle) override {
    if (handle.chunk_index >= chunks_.size())
      return NULL;
    TraceBufferChunk* chunk = chunks_[handle.chunk_index];
    if (!chunk || chunk->seq() != handle.chunk_seq)
      return NULL;
    return chunk->GetEventAt(handle.event_index);
  }

  const TraceBufferChunk* NextChunk() override {
    if (chunks_.empty())
      return NULL;

    while (current_iteration_index_ != queue_tail_) {
      size_t chunk_index = recyclable_chunks_queue_[current_iteration_index_];
      current_iteration_index_ = NextQueueIndex(current_iteration_index_);
      if (chunk_index >= chunks_.size()) // Skip uninitialized chunks.
        continue;
      DCHECK(chunks_[chunk_index]);
      return chunks_[chunk_index];
    }
    return NULL;
  }

  scoped_ptr<TraceBuffer> CloneForIteration() const override {
    scoped_ptr<ClonedTraceBuffer> cloned_buffer(new ClonedTraceBuffer());
    for (size_t queue_index = queue_head_; queue_index != queue_tail_;
        queue_index = NextQueueIndex(queue_index)) {
      size_t chunk_index = recyclable_chunks_queue_[queue_index];
      if (chunk_index >= chunks_.size()) // Skip uninitialized chunks.
        continue;
      TraceBufferChunk* chunk = chunks_[chunk_index];
      cloned_buffer->chunks_.push_back(chunk ? chunk->Clone().release() : NULL);
    }
    return cloned_buffer.Pass();
  }

 private:
  class ClonedTraceBuffer : public TraceBuffer {
   public:
    ClonedTraceBuffer() : current_iteration_index_(0) {}

    // The only implemented method.
    const TraceBufferChunk* NextChunk() override {
      return current_iteration_index_ < chunks_.size() ?
          chunks_[current_iteration_index_++] : NULL;
    }

    scoped_ptr<TraceBufferChunk> GetChunk(size_t* index) override {
      NOTIMPLEMENTED();
      return scoped_ptr<TraceBufferChunk>();
    }
    void ReturnChunk(size_t index, scoped_ptr<TraceBufferChunk>) override {
      NOTIMPLEMENTED();
    }
    bool IsFull() const override { return false; }
    size_t Size() const override { return 0; }
    size_t Capacity() const override { return 0; }
    TraceEvent* GetEventByHandle(TraceEventHandle handle) override {
      return NULL;
    }
    scoped_ptr<TraceBuffer> CloneForIteration() const override {
      NOTIMPLEMENTED();
      return scoped_ptr<TraceBuffer>();
    }

    size_t current_iteration_index_;
    ScopedVector<TraceBufferChunk> chunks_;
  };

  bool QueueIsEmpty() const {
    return queue_head_ == queue_tail_;
  }

  size_t QueueSize() const {
    return queue_tail_ > queue_head_ ? queue_tail_ - queue_head_ :
        queue_tail_ + queue_capacity() - queue_head_;
  }

  bool QueueIsFull() const {
    return QueueSize() == queue_capacity() - 1;
  }

  size_t queue_capacity() const {
    // One extra space to help distinguish full state and empty state.
    return max_chunks_ + 1;
  }

  size_t NextQueueIndex(size_t index) const {
    index++;
    if (index >= queue_capacity())
      index = 0;
    return index;
  }

  size_t max_chunks_;
  ScopedVector<TraceBufferChunk> chunks_;

  scoped_ptr<size_t[]> recyclable_chunks_queue_;
  size_t queue_head_;
  size_t queue_tail_;

  size_t current_iteration_index_;
  uint32 current_chunk_seq_;

  DISALLOW_COPY_AND_ASSIGN(TraceBufferRingBuffer);
};

class TraceBufferVector : public TraceBuffer {
 public:
  TraceBufferVector(size_t max_chunks)
      : in_flight_chunk_count_(0),
        current_iteration_index_(0),
        max_chunks_(max_chunks) {
    chunks_.reserve(max_chunks_);
  }

  scoped_ptr<TraceBufferChunk> GetChunk(size_t* index) override {
    // This function may be called when adding normal events or indirectly from
    // AddMetadataEventsWhileLocked(). We can not DECHECK(!IsFull()) because we
    // have to add the metadata events and flush thread-local buffers even if
    // the buffer is full.
    *index = chunks_.size();
    chunks_.push_back(NULL);  // Put NULL in the slot of a in-flight chunk.
    ++in_flight_chunk_count_;
    // + 1 because zero chunk_seq is not allowed.
    return scoped_ptr<TraceBufferChunk>(
        new TraceBufferChunk(static_cast<uint32>(*index) + 1));
  }

  void ReturnChunk(size_t index, scoped_ptr<TraceBufferChunk> chunk) override {
    DCHECK_GT(in_flight_chunk_count_, 0u);
    DCHECK_LT(index, chunks_.size());
    DCHECK(!chunks_[index]);
    --in_flight_chunk_count_;
    chunks_[index] = chunk.release();
  }

  bool IsFull() const override { return chunks_.size() >= max_chunks_; }

  size_t Size() const override {
    // This is approximate because not all of the chunks are full.
    return chunks_.size() * kTraceBufferChunkSize;
  }

  size_t Capacity() const override {
    return max_chunks_ * kTraceBufferChunkSize;
  }

  TraceEvent* GetEventByHandle(TraceEventHandle handle) override {
    if (handle.chunk_index >= chunks_.size())
      return NULL;
    TraceBufferChunk* chunk = chunks_[handle.chunk_index];
    if (!chunk || chunk->seq() != handle.chunk_seq)
      return NULL;
    return chunk->GetEventAt(handle.event_index);
  }

  const TraceBufferChunk* NextChunk() override {
    while (current_iteration_index_ < chunks_.size()) {
      // Skip in-flight chunks.
      const TraceBufferChunk* chunk = chunks_[current_iteration_index_++];
      if (chunk)
        return chunk;
    }
    return NULL;
  }

  scoped_ptr<TraceBuffer> CloneForIteration() const override {
    NOTIMPLEMENTED();
    return scoped_ptr<TraceBuffer>();
  }

 private:
  size_t in_flight_chunk_count_;
  size_t current_iteration_index_;
  size_t max_chunks_;
  ScopedVector<TraceBufferChunk> chunks_;

  DISALLOW_COPY_AND_ASSIGN(TraceBufferVector);
};

template <typename T>
void InitializeMetadataEvent(TraceEvent* trace_event,
                             int thread_id,
                             const char* metadata_name, const char* arg_name,
                             const T& value) {
  if (!trace_event)
    return;

  int num_args = 1;
  unsigned char arg_type;
  unsigned long long arg_value;
  ::trace_event_internal::SetTraceValue(value, &arg_type, &arg_value);
  trace_event->Initialize(thread_id,
                          TraceTicks(), ThreadTicks(),
                          TRACE_EVENT_PHASE_METADATA,
                          &g_category_group_enabled[g_category_metadata],
                          metadata_name, ::trace_event_internal::kNoEventId,
                          num_args, &arg_name, &arg_type, &arg_value, NULL,
                          TRACE_EVENT_FLAG_NONE);
}

class AutoThreadLocalBoolean {
 public:
  explicit AutoThreadLocalBoolean(ThreadLocalBoolean* thread_local_boolean)
      : thread_local_boolean_(thread_local_boolean) {
    DCHECK(!thread_local_boolean_->Get());
    thread_local_boolean_->Set(true);
  }
  ~AutoThreadLocalBoolean() {
    thread_local_boolean_->Set(false);
  }

 private:
  ThreadLocalBoolean* thread_local_boolean_;
  DISALLOW_COPY_AND_ASSIGN(AutoThreadLocalBoolean);
};

}  // namespace

void TraceBufferChunk::Reset(uint32 new_seq) {
  for (size_t i = 0; i < next_free_; ++i)
    chunk_[i].Reset();
  next_free_ = 0;
  seq_ = new_seq;
}

TraceEvent* TraceBufferChunk::AddTraceEvent(size_t* event_index) {
  DCHECK(!IsFull());
  *event_index = next_free_++;
  return &chunk_[*event_index];
}

scoped_ptr<TraceBufferChunk> TraceBufferChunk::Clone() const {
  scoped_ptr<TraceBufferChunk> cloned_chunk(new TraceBufferChunk(seq_));
  cloned_chunk->next_free_ = next_free_;
  for (size_t i = 0; i < next_free_; ++i)
    cloned_chunk->chunk_[i].CopyFrom(chunk_[i]);
  return cloned_chunk.Pass();
}

// A helper class that allows the lock to be acquired in the middle of the scope
// and unlocks at the end of scope if locked.
class TraceLog::OptionalAutoLock {
 public:
  explicit OptionalAutoLock(Lock* lock) : lock_(lock), locked_(false) {}

  ~OptionalAutoLock() {
    if (locked_)
      lock_->Release();
  }

  void EnsureAcquired() {
    if (!locked_) {
      lock_->Acquire();
      locked_ = true;
    }
  }

 private:
  Lock* lock_;
  bool locked_;
  DISALLOW_COPY_AND_ASSIGN(OptionalAutoLock);
};

// Use this function instead of TraceEventHandle constructor to keep the
// overhead of ScopedTracer (trace_event.h) constructor minimum.
void MakeHandle(uint32 chunk_seq, size_t chunk_index, size_t event_index,
                TraceEventHandle* handle) {
  DCHECK(chunk_seq);
  DCHECK(chunk_index < (1u << 16));
  DCHECK(event_index < (1u << 16));
  handle->chunk_seq = chunk_seq;
  handle->chunk_index = static_cast<uint16>(chunk_index);
  handle->event_index = static_cast<uint16>(event_index);
}

////////////////////////////////////////////////////////////////////////////////
//
// TraceEvent
//
////////////////////////////////////////////////////////////////////////////////

namespace {

size_t GetAllocLength(const char* str) { return str ? strlen(str) + 1 : 0; }

// Copies |*member| into |*buffer|, sets |*member| to point to this new
// location, and then advances |*buffer| by the amount written.
void CopyTraceEventParameter(char** buffer,
                             const char** member,
                             const char* end) {
  if (*member) {
    size_t written = strlcpy(*buffer, *member, end - *buffer) + 1;
    DCHECK_LE(static_cast<int>(written), end - *buffer);
    *member = *buffer;
    *buffer += written;
  }
}

}  // namespace

TraceEvent::TraceEvent()
    : duration_(TimeDelta::FromInternalValue(-1)),
      id_(0u),
      category_group_enabled_(NULL),
      name_(NULL),
      thread_id_(0),
      phase_(TRACE_EVENT_PHASE_BEGIN),
      flags_(0) {
  for (int i = 0; i < kTraceMaxNumArgs; ++i)
    arg_names_[i] = NULL;
  memset(arg_values_, 0, sizeof(arg_values_));
}

TraceEvent::~TraceEvent() {
}

void TraceEvent::CopyFrom(const TraceEvent& other) {
  timestamp_ = other.timestamp_;
  thread_timestamp_ = other.thread_timestamp_;
  duration_ = other.duration_;
  id_ = other.id_;
  category_group_enabled_ = other.category_group_enabled_;
  name_ = other.name_;
  thread_id_ = other.thread_id_;
  phase_ = other.phase_;
  flags_ = other.flags_;
  parameter_copy_storage_ = other.parameter_copy_storage_;

  for (int i = 0; i < kTraceMaxNumArgs; ++i) {
    arg_names_[i] = other.arg_names_[i];
    arg_types_[i] = other.arg_types_[i];
    arg_values_[i] = other.arg_values_[i];
    convertable_values_[i] = other.convertable_values_[i];
  }
}

void TraceEvent::Initialize(
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
    unsigned char flags) {
  timestamp_ = timestamp;
  thread_timestamp_ = thread_timestamp;
  duration_ = TimeDelta::FromInternalValue(-1);
  id_ = id;
  category_group_enabled_ = category_group_enabled;
  name_ = name;
  thread_id_ = thread_id;
  phase_ = phase;
  flags_ = flags;

  // Clamp num_args since it may have been set by a third_party library.
  num_args = (num_args > kTraceMaxNumArgs) ? kTraceMaxNumArgs : num_args;
  int i = 0;
  for (; i < num_args; ++i) {
    arg_names_[i] = arg_names[i];
    arg_types_[i] = arg_types[i];

    if (arg_types[i] == TRACE_VALUE_TYPE_CONVERTABLE)
      convertable_values_[i] = convertable_values[i];
    else
      arg_values_[i].as_uint = arg_values[i];
  }
  for (; i < kTraceMaxNumArgs; ++i) {
    arg_names_[i] = NULL;
    arg_values_[i].as_uint = 0u;
    convertable_values_[i] = NULL;
    arg_types_[i] = TRACE_VALUE_TYPE_UINT;
  }

  bool copy = !!(flags & TRACE_EVENT_FLAG_COPY);
  size_t alloc_size = 0;
  if (copy) {
    alloc_size += GetAllocLength(name);
    for (i = 0; i < num_args; ++i) {
      alloc_size += GetAllocLength(arg_names_[i]);
      if (arg_types_[i] == TRACE_VALUE_TYPE_STRING)
        arg_types_[i] = TRACE_VALUE_TYPE_COPY_STRING;
    }
  }

  bool arg_is_copy[kTraceMaxNumArgs];
  for (i = 0; i < num_args; ++i) {
    // No copying of convertable types, we retain ownership.
    if (arg_types_[i] == TRACE_VALUE_TYPE_CONVERTABLE)
      continue;

    // We only take a copy of arg_vals if they are of type COPY_STRING.
    arg_is_copy[i] = (arg_types_[i] == TRACE_VALUE_TYPE_COPY_STRING);
    if (arg_is_copy[i])
      alloc_size += GetAllocLength(arg_values_[i].as_string);
  }

  if (alloc_size) {
    parameter_copy_storage_ = new RefCountedString;
    parameter_copy_storage_->data().resize(alloc_size);
    char* ptr = string_as_array(&parameter_copy_storage_->data());
    const char* end = ptr + alloc_size;
    if (copy) {
      CopyTraceEventParameter(&ptr, &name_, end);
      for (i = 0; i < num_args; ++i) {
        CopyTraceEventParameter(&ptr, &arg_names_[i], end);
      }
    }
    for (i = 0; i < num_args; ++i) {
      if (arg_types_[i] == TRACE_VALUE_TYPE_CONVERTABLE)
        continue;
      if (arg_is_copy[i])
        CopyTraceEventParameter(&ptr, &arg_values_[i].as_string, end);
    }
    DCHECK_EQ(end, ptr) << "Overrun by " << ptr - end;
  }
}

void TraceEvent::Reset() {
  // Only reset fields that won't be initialized in Initialize(), or that may
  // hold references to other objects.
  duration_ = TimeDelta::FromInternalValue(-1);
  parameter_copy_storage_ = NULL;
  for (int i = 0; i < kTraceMaxNumArgs; ++i)
    convertable_values_[i] = NULL;
}

void TraceEvent::UpdateDuration(const TraceTicks& now,
                                const ThreadTicks& thread_now) {
  DCHECK_EQ(duration_.ToInternalValue(), -1);
  duration_ = now - timestamp_;
  thread_duration_ = thread_now - thread_timestamp_;
}

// static
void TraceEvent::AppendValueAsJSON(unsigned char type,
                                   TraceEvent::TraceValue value,
                                   std::string* out) {
  switch (type) {
    case TRACE_VALUE_TYPE_BOOL:
      *out += value.as_bool ? "true" : "false";
      break;
    case TRACE_VALUE_TYPE_UINT:
      StringAppendF(out, "%" PRIu64, static_cast<uint64>(value.as_uint));
      break;
    case TRACE_VALUE_TYPE_INT:
      StringAppendF(out, "%" PRId64, static_cast<int64>(value.as_int));
      break;
    case TRACE_VALUE_TYPE_DOUBLE: {
      // FIXME: base/json/json_writer.cc is using the same code,
      //        should be made into a common method.
      std::string real;
      double val = value.as_double;
      if (std::isfinite(val)) {
        real = DoubleToString(val);
        // Ensure that the number has a .0 if there's no decimal or 'e'.  This
        // makes sure that when we read the JSON back, it's interpreted as a
        // real rather than an int.
        if (real.find('.') == std::string::npos &&
            real.find('e') == std::string::npos &&
            real.find('E') == std::string::npos) {
          real.append(".0");
        }
        // The JSON spec requires that non-integer values in the range (-1,1)
        // have a zero before the decimal point - ".52" is not valid, "0.52" is.
        if (real[0] == '.') {
          real.insert(0, "0");
        } else if (real.length() > 1 && real[0] == '-' && real[1] == '.') {
          // "-.1" bad "-0.1" good
          real.insert(1, "0");
        }
      } else if (std::isnan(val)){
        // The JSON spec doesn't allow NaN and Infinity (since these are
        // objects in EcmaScript).  Use strings instead.
        real = "\"NaN\"";
      } else if (val < 0) {
        real = "\"-Infinity\"";
      } else {
        real = "\"Infinity\"";
      }
      StringAppendF(out, "%s", real.c_str());
      break;
    }
    case TRACE_VALUE_TYPE_POINTER:
      // JSON only supports double and int numbers.
      // So as not to lose bits from a 64-bit pointer, output as a hex string.
      StringAppendF(out, "\"0x%" PRIx64 "\"", static_cast<uint64>(
                                     reinterpret_cast<intptr_t>(
                                     value.as_pointer)));
      break;
    case TRACE_VALUE_TYPE_STRING:
    case TRACE_VALUE_TYPE_COPY_STRING:
      EscapeJSONString(value.as_string ? value.as_string : "NULL", true, out);
      break;
    default:
      NOTREACHED() << "Don't know how to print this value";
      break;
  }
}

void TraceEvent::AppendAsJSON(
    std::string* out,
    const ArgumentFilterPredicate& argument_filter_predicate) const {
  int64 time_int64 = timestamp_.ToInternalValue();
  int process_id = TraceLog::GetInstance()->process_id();
  const char* category_group_name =
      TraceLog::GetCategoryGroupName(category_group_enabled_);

  // Category group checked at category creation time.
  DCHECK(!strchr(name_, '"'));
  StringAppendF(out, "{\"pid\":%i,\"tid\":%i,\"ts\":%" PRId64
                     ","
                     "\"ph\":\"%c\",\"cat\":\"%s\",\"name\":\"%s\",\"args\":{",
                process_id, thread_id_, time_int64, phase_, category_group_name,
                name_);

  // Output argument names and values, stop at first NULL argument name.
  if (arg_names_[0]) {
    bool allow_args = argument_filter_predicate.is_null() ||
                      argument_filter_predicate.Run(category_group_name, name_);

    if (allow_args) {
      for (int i = 0; i < kTraceMaxNumArgs && arg_names_[i]; ++i) {
        if (i > 0)
          *out += ",";
        *out += "\"";
        *out += arg_names_[i];
        *out += "\":";

        if (arg_types_[i] == TRACE_VALUE_TYPE_CONVERTABLE)
          convertable_values_[i]->AppendAsTraceFormat(out);
        else
          AppendValueAsJSON(arg_types_[i], arg_values_[i], out);
      }
    } else {
      *out += "\"stripped\":1";
    }
  }

  *out += "}";

  if (phase_ == TRACE_EVENT_PHASE_COMPLETE) {
    int64 duration = duration_.ToInternalValue();
    if (duration != -1)
      StringAppendF(out, ",\"dur\":%" PRId64, duration);
    if (!thread_timestamp_.is_null()) {
      int64 thread_duration = thread_duration_.ToInternalValue();
      if (thread_duration != -1)
        StringAppendF(out, ",\"tdur\":%" PRId64, thread_duration);
    }
  }

  // Output tts if thread_timestamp is valid.
  if (!thread_timestamp_.is_null()) {
    int64 thread_time_int64 = thread_timestamp_.ToInternalValue();
    StringAppendF(out, ",\"tts\":%" PRId64, thread_time_int64);
  }

  // Output async tts marker field if flag is set.
  if (flags_ & TRACE_EVENT_FLAG_ASYNC_TTS) {
    StringAppendF(out, ", \"use_async_tts\":1");
  }

  // If id_ is set, print it out as a hex string so we don't loose any
  // bits (it might be a 64-bit pointer).
  if (flags_ & TRACE_EVENT_FLAG_HAS_ID)
    StringAppendF(out, ",\"id\":\"0x%" PRIx64 "\"", static_cast<uint64>(id_));

  // Instant events also output their scope.
  if (phase_ == TRACE_EVENT_PHASE_INSTANT) {
    char scope = '?';
    switch (flags_ & TRACE_EVENT_FLAG_SCOPE_MASK) {
      case TRACE_EVENT_SCOPE_GLOBAL:
        scope = TRACE_EVENT_SCOPE_NAME_GLOBAL;
        break;

      case TRACE_EVENT_SCOPE_PROCESS:
        scope = TRACE_EVENT_SCOPE_NAME_PROCESS;
        break;

      case TRACE_EVENT_SCOPE_THREAD:
        scope = TRACE_EVENT_SCOPE_NAME_THREAD;
        break;
    }
    StringAppendF(out, ",\"s\":\"%c\"", scope);
  }

  *out += "}";
}

void TraceEvent::AppendPrettyPrinted(std::ostringstream* out) const {
  *out << name_ << "[";
  *out << TraceLog::GetCategoryGroupName(category_group_enabled_);
  *out << "]";
  if (arg_names_[0]) {
    *out << ", {";
    for (int i = 0; i < kTraceMaxNumArgs && arg_names_[i]; ++i) {
      if (i > 0)
        *out << ", ";
      *out << arg_names_[i] << ":";
      std::string value_as_text;

      if (arg_types_[i] == TRACE_VALUE_TYPE_CONVERTABLE)
        convertable_values_[i]->AppendAsTraceFormat(&value_as_text);
      else
        AppendValueAsJSON(arg_types_[i], arg_values_[i], &value_as_text);

      *out << value_as_text;
    }
    *out << "}";
  }
}

////////////////////////////////////////////////////////////////////////////////
//
// TraceResultBuffer
//
////////////////////////////////////////////////////////////////////////////////

TraceResultBuffer::OutputCallback
    TraceResultBuffer::SimpleOutput::GetCallback() {
  return Bind(&SimpleOutput::Append, Unretained(this));
}

void TraceResultBuffer::SimpleOutput::Append(
    const std::string& json_trace_output) {
  json_output += json_trace_output;
}

TraceResultBuffer::TraceResultBuffer() : append_comma_(false) {
}

TraceResultBuffer::~TraceResultBuffer() {
}

void TraceResultBuffer::SetOutputCallback(
    const OutputCallback& json_chunk_callback) {
  output_callback_ = json_chunk_callback;
}

void TraceResultBuffer::Start() {
  append_comma_ = false;
  output_callback_.Run("[");
}

void TraceResultBuffer::AddFragment(const std::string& trace_fragment) {
  if (append_comma_)
    output_callback_.Run(",");
  append_comma_ = true;
  output_callback_.Run(trace_fragment);
}

void TraceResultBuffer::Finish() {
  output_callback_.Run("]");
}

////////////////////////////////////////////////////////////////////////////////
//
// TraceSamplingThread
//
////////////////////////////////////////////////////////////////////////////////
class TraceBucketData;
typedef base::Callback<void(TraceBucketData*)> TraceSampleCallback;

class TraceBucketData {
 public:
  TraceBucketData(base::subtle::AtomicWord* bucket,
                  const char* name,
                  TraceSampleCallback callback);
  ~TraceBucketData();

  TRACE_EVENT_API_ATOMIC_WORD* bucket;
  const char* bucket_name;
  TraceSampleCallback callback;
};

// This object must be created on the IO thread.
class TraceSamplingThread : public PlatformThread::Delegate {
 public:
  TraceSamplingThread();
  ~TraceSamplingThread() override;

  // Implementation of PlatformThread::Delegate:
  void ThreadMain() override;

  static void DefaultSamplingCallback(TraceBucketData* bucekt_data);

  void Stop();
  void WaitSamplingEventForTesting();

 private:
  friend class TraceLog;

  void GetSamples();
  // Not thread-safe. Once the ThreadMain has been called, this can no longer
  // be called.
  void RegisterSampleBucket(TRACE_EVENT_API_ATOMIC_WORD* bucket,
                            const char* const name,
                            TraceSampleCallback callback);
  // Splits a combined "category\0name" into the two component parts.
  static void ExtractCategoryAndName(const char* combined,
                                     const char** category,
                                     const char** name);
  std::vector<TraceBucketData> sample_buckets_;
  bool thread_running_;
  CancellationFlag cancellation_flag_;
  WaitableEvent waitable_event_for_testing_;
};


TraceSamplingThread::TraceSamplingThread()
    : thread_running_(false),
      waitable_event_for_testing_(false, false) {
}

TraceSamplingThread::~TraceSamplingThread() {
}

void TraceSamplingThread::ThreadMain() {
  PlatformThread::SetName("Sampling Thread");
  thread_running_ = true;
  const int kSamplingFrequencyMicroseconds = 1000;
  while (!cancellation_flag_.IsSet()) {
    PlatformThread::Sleep(
        TimeDelta::FromMicroseconds(kSamplingFrequencyMicroseconds));
    GetSamples();
    waitable_event_for_testing_.Signal();
  }
}

// static
void TraceSamplingThread::DefaultSamplingCallback(
    TraceBucketData* bucket_data) {
  TRACE_EVENT_API_ATOMIC_WORD category_and_name =
      TRACE_EVENT_API_ATOMIC_LOAD(*bucket_data->bucket);
  if (!category_and_name)
    return;
  const char* const combined =
      reinterpret_cast<const char* const>(category_and_name);
  const char* category_group;
  const char* name;
  ExtractCategoryAndName(combined, &category_group, &name);
  TRACE_EVENT_API_ADD_TRACE_EVENT(TRACE_EVENT_PHASE_SAMPLE,
      TraceLog::GetCategoryGroupEnabled(category_group),
      name, 0, 0, NULL, NULL, NULL, NULL, 0);
}

void TraceSamplingThread::GetSamples() {
  for (size_t i = 0; i < sample_buckets_.size(); ++i) {
    TraceBucketData* bucket_data = &sample_buckets_[i];
    bucket_data->callback.Run(bucket_data);
  }
}

void TraceSamplingThread::RegisterSampleBucket(
    TRACE_EVENT_API_ATOMIC_WORD* bucket,
    const char* const name,
    TraceSampleCallback callback) {
  // Access to sample_buckets_ doesn't cause races with the sampling thread
  // that uses the sample_buckets_, because it is guaranteed that
  // RegisterSampleBucket is called before the sampling thread is created.
  DCHECK(!thread_running_);
  sample_buckets_.push_back(TraceBucketData(bucket, name, callback));
}

// static
void TraceSamplingThread::ExtractCategoryAndName(const char* combined,
                                                 const char** category,
                                                 const char** name) {
  *category = combined;
  *name = &combined[strlen(combined) + 1];
}

void TraceSamplingThread::Stop() {
  cancellation_flag_.Set();
}

void TraceSamplingThread::WaitSamplingEventForTesting() {
  waitable_event_for_testing_.Wait();
}

TraceBucketData::TraceBucketData(base::subtle::AtomicWord* bucket,
                                 const char* name,
                                 TraceSampleCallback callback)
    : bucket(bucket),
      bucket_name(name),
      callback(callback) {
}

TraceBucketData::~TraceBucketData() {
}

////////////////////////////////////////////////////////////////////////////////
//
// TraceLog
//
////////////////////////////////////////////////////////////////////////////////

class TraceLog::ThreadLocalEventBuffer
    : public MessageLoop::DestructionObserver {
 public:
  ThreadLocalEventBuffer(TraceLog* trace_log);
  ~ThreadLocalEventBuffer() override;

  TraceEvent* AddTraceEvent(TraceEventHandle* handle);

  void ReportOverhead(const TraceTicks& event_timestamp,
                      const ThreadTicks& event_thread_timestamp);

  TraceEvent* GetEventByHandle(TraceEventHandle handle) {
    if (!chunk_ || handle.chunk_seq != chunk_->seq() ||
        handle.chunk_index != chunk_index_)
      return NULL;

    return chunk_->GetEventAt(handle.event_index);
  }

  int generation() const { return generation_; }

 private:
  // MessageLoop::DestructionObserver
  void WillDestroyCurrentMessageLoop() override;

  void FlushWhileLocked();

  void CheckThisIsCurrentBuffer() const {
    DCHECK(trace_log_->thread_local_event_buffer_.Get() == this);
  }

  // Since TraceLog is a leaky singleton, trace_log_ will always be valid
  // as long as the thread exists.
  TraceLog* trace_log_;
  scoped_ptr<TraceBufferChunk> chunk_;
  size_t chunk_index_;
  int event_count_;
  TimeDelta overhead_;
  int generation_;

  DISALLOW_COPY_AND_ASSIGN(ThreadLocalEventBuffer);
};

TraceLog::ThreadLocalEventBuffer::ThreadLocalEventBuffer(TraceLog* trace_log)
    : trace_log_(trace_log),
      chunk_index_(0),
      event_count_(0),
      generation_(trace_log->generation()) {
  // ThreadLocalEventBuffer is created only if the thread has a message loop, so
  // the following message_loop won't be NULL.
  MessageLoop* message_loop = MessageLoop::current();
  message_loop->AddDestructionObserver(this);

  AutoLock lock(trace_log->lock_);
  trace_log->thread_message_loops_.insert(message_loop);
}

TraceLog::ThreadLocalEventBuffer::~ThreadLocalEventBuffer() {
  CheckThisIsCurrentBuffer();
  MessageLoop::current()->RemoveDestructionObserver(this);

  // Zero event_count_ happens in either of the following cases:
  // - no event generated for the thread;
  // - the thread has no message loop;
  // - trace_event_overhead is disabled.
  if (event_count_) {
    InitializeMetadataEvent(AddTraceEvent(NULL),
                            static_cast<int>(base::PlatformThread::CurrentId()),
                            "overhead", "average_overhead",
                            overhead_.InMillisecondsF() / event_count_);
  }

  {
    AutoLock lock(trace_log_->lock_);
    FlushWhileLocked();
    trace_log_->thread_message_loops_.erase(MessageLoop::current());
  }
  trace_log_->thread_local_event_buffer_.Set(NULL);
}

TraceEvent* TraceLog::ThreadLocalEventBuffer::AddTraceEvent(
    TraceEventHandle* handle) {
  CheckThisIsCurrentBuffer();

  if (chunk_ && chunk_->IsFull()) {
    AutoLock lock(trace_log_->lock_);
    FlushWhileLocked();
    chunk_.reset();
  }
  if (!chunk_) {
    AutoLock lock(trace_log_->lock_);
    chunk_ = trace_log_->logged_events_->GetChunk(&chunk_index_);
    trace_log_->CheckIfBufferIsFullWhileLocked();
  }
  if (!chunk_)
    return NULL;

  size_t event_index;
  TraceEvent* trace_event = chunk_->AddTraceEvent(&event_index);
  if (trace_event && handle)
    MakeHandle(chunk_->seq(), chunk_index_, event_index, handle);

  return trace_event;
}

void TraceLog::ThreadLocalEventBuffer::ReportOverhead(
    const TraceTicks& event_timestamp,
    const ThreadTicks& event_thread_timestamp) {
  if (!g_category_group_enabled[g_category_trace_event_overhead])
    return;

  CheckThisIsCurrentBuffer();

  event_count_++;
  ThreadTicks thread_now = ThreadNow();
  TraceTicks now = trace_log_->OffsetNow();
  TimeDelta overhead = now - event_timestamp;
  if (overhead.InMicroseconds() >= kOverheadReportThresholdInMicroseconds) {
    TraceEvent* trace_event = AddTraceEvent(NULL);
    if (trace_event) {
      trace_event->Initialize(
          static_cast<int>(PlatformThread::CurrentId()),
          event_timestamp, event_thread_timestamp,
          TRACE_EVENT_PHASE_COMPLETE,
          &g_category_group_enabled[g_category_trace_event_overhead],
          "overhead", 0, 0, NULL, NULL, NULL, NULL, 0);
      trace_event->UpdateDuration(now, thread_now);
    }
  }
  overhead_ += overhead;
}

void TraceLog::ThreadLocalEventBuffer::WillDestroyCurrentMessageLoop() {
  delete this;
}

void TraceLog::ThreadLocalEventBuffer::FlushWhileLocked() {
  if (!chunk_)
    return;

  trace_log_->lock_.AssertAcquired();
  if (trace_log_->CheckGeneration(generation_)) {
    // Return the chunk to the buffer only if the generation matches.
    trace_log_->logged_events_->ReturnChunk(chunk_index_, chunk_.Pass());
  }
  // Otherwise this method may be called from the destructor, or TraceLog will
  // find the generation mismatch and delete this buffer soon.
}

TraceLogStatus::TraceLogStatus() : event_capacity(0), event_count(0) {
}

TraceLogStatus::~TraceLogStatus() {
}

// static
TraceLog* TraceLog::GetInstance() {
  return Singleton<TraceLog, LeakySingletonTraits<TraceLog> >::get();
}

TraceLog::TraceLog()
    : mode_(DISABLED),
      num_traces_recorded_(0),
      event_callback_(0),
      dispatching_to_observer_list_(false),
      process_sort_index_(0),
      process_id_hash_(0),
      process_id_(0),
      watch_category_(0),
      trace_options_(kInternalRecordUntilFull),
      sampling_thread_handle_(0),
      trace_config_(TraceConfig()),
      event_callback_trace_config_(TraceConfig()),
      thread_shared_chunk_index_(0),
      generation_(0),
      use_worker_thread_(false) {
  // Trace is enabled or disabled on one thread while other threads are
  // accessing the enabled flag. We don't care whether edge-case events are
  // traced or not, so we allow races on the enabled flag to keep the trace
  // macros fast.
  // TODO(jbates): ANNOTATE_BENIGN_RACE_SIZED crashes windows TSAN bots:
  // ANNOTATE_BENIGN_RACE_SIZED(g_category_group_enabled,
  //                            sizeof(g_category_group_enabled),
  //                           "trace_event category enabled");
  for (int i = 0; i < MAX_CATEGORY_GROUPS; ++i) {
    ANNOTATE_BENIGN_RACE(&g_category_group_enabled[i],
                         "trace_event category enabled");
  }
#if defined(OS_NACL)  // NaCl shouldn't expose the process id.
  SetProcessID(0);
#else
  SetProcessID(static_cast<int>(GetCurrentProcId()));

  // NaCl also shouldn't access the command line.
  if (CommandLine::InitializedForCurrentProcess() &&
      CommandLine::ForCurrentProcess()->HasSwitch(switches::kTraceToConsole)) {
    std::string filter = CommandLine::ForCurrentProcess()->GetSwitchValueASCII(
        switches::kTraceToConsole);
    if (filter.empty()) {
      filter = kEchoToConsoleCategoryFilter;
    } else {
      filter.append(",");
      filter.append(kEchoToConsoleCategoryFilter);
    }

    LOG(ERROR) << "Start " << switches::kTraceToConsole
               << " with CategoryFilter '" << filter << "'.";
    SetEnabled(TraceConfig(filter, ECHO_TO_CONSOLE), RECORDING_MODE);
  }
#endif

  logged_events_.reset(CreateTraceBuffer());
}

TraceLog::~TraceLog() {
}

const unsigned char* TraceLog::GetCategoryGroupEnabled(
    const char* category_group) {
  TraceLog* tracelog = GetInstance();
  if (!tracelog) {
    DCHECK(!g_category_group_enabled[g_category_already_shutdown]);
    return &g_category_group_enabled[g_category_already_shutdown];
  }
  return tracelog->GetCategoryGroupEnabledInternal(category_group);
}

const char* TraceLog::GetCategoryGroupName(
    const unsigned char* category_group_enabled) {
  // Calculate the index of the category group by finding
  // category_group_enabled in g_category_group_enabled array.
  uintptr_t category_begin =
      reinterpret_cast<uintptr_t>(g_category_group_enabled);
  uintptr_t category_ptr = reinterpret_cast<uintptr_t>(category_group_enabled);
  DCHECK(category_ptr >= category_begin &&
         category_ptr < reinterpret_cast<uintptr_t>(
             g_category_group_enabled + MAX_CATEGORY_GROUPS)) <<
      "out of bounds category pointer";
  uintptr_t category_index =
      (category_ptr - category_begin) / sizeof(g_category_group_enabled[0]);
  return g_category_groups[category_index];
}

void TraceLog::UpdateCategoryGroupEnabledFlag(size_t category_index) {
  unsigned char enabled_flag = 0;
  const char* category_group = g_category_groups[category_index];
  if (mode_ == RECORDING_MODE &&
      trace_config_.IsCategoryGroupEnabled(category_group))
    enabled_flag |= ENABLED_FOR_RECORDING;
  else if (mode_ == MONITORING_MODE &&
      trace_config_.IsCategoryGroupEnabled(category_group))
    enabled_flag |= ENABLED_FOR_MONITORING;
  if (event_callback_ &&
      event_callback_trace_config_.IsCategoryGroupEnabled(category_group))
    enabled_flag |= ENABLED_FOR_EVENT_CALLBACK;
#if defined(OS_WIN)
  if (base::trace_event::TraceEventETWExport::isETWExportEnabled())
    enabled_flag |= ENABLED_FOR_ETW_EXPORT;
#endif

  g_category_group_enabled[category_index] = enabled_flag;
}

void TraceLog::UpdateCategoryGroupEnabledFlags() {
  size_t category_index = base::subtle::NoBarrier_Load(&g_category_index);
  for (size_t i = 0; i < category_index; i++)
    UpdateCategoryGroupEnabledFlag(i);
}

void TraceLog::UpdateSyntheticDelaysFromTraceConfig() {
  ResetTraceEventSyntheticDelays();
  const TraceConfig::StringList& delays =
      trace_config_.GetSyntheticDelayValues();
  TraceConfig::StringList::const_iterator ci;
  for (ci = delays.begin(); ci != delays.end(); ++ci) {
    StringTokenizer tokens(*ci, ";");
    if (!tokens.GetNext())
      continue;
    TraceEventSyntheticDelay* delay =
        TraceEventSyntheticDelay::Lookup(tokens.token());
    while (tokens.GetNext()) {
      std::string token = tokens.token();
      char* duration_end;
      double target_duration = strtod(token.c_str(), &duration_end);
      if (duration_end != token.c_str()) {
        delay->SetTargetDuration(TimeDelta::FromMicroseconds(
            static_cast<int64>(target_duration * 1e6)));
      } else if (token == "static") {
        delay->SetMode(TraceEventSyntheticDelay::STATIC);
      } else if (token == "oneshot") {
        delay->SetMode(TraceEventSyntheticDelay::ONE_SHOT);
      } else if (token == "alternating") {
        delay->SetMode(TraceEventSyntheticDelay::ALTERNATING);
      }
    }
  }
}

const unsigned char* TraceLog::GetCategoryGroupEnabledInternal(
    const char* category_group) {
  DCHECK(!strchr(category_group, '"')) <<
      "Category groups may not contain double quote";
  // The g_category_groups is append only, avoid using a lock for the fast path.
  size_t current_category_index = base::subtle::Acquire_Load(&g_category_index);

  // Search for pre-existing category group.
  for (size_t i = 0; i < current_category_index; ++i) {
    if (strcmp(g_category_groups[i], category_group) == 0) {
      return &g_category_group_enabled[i];
    }
  }

  unsigned char* category_group_enabled = NULL;
  // This is the slow path: the lock is not held in the case above, so more
  // than one thread could have reached here trying to add the same category.
  // Only hold to lock when actually appending a new category, and
  // check the categories groups again.
  AutoLock lock(lock_);
  size_t category_index = base::subtle::Acquire_Load(&g_category_index);
  for (size_t i = 0; i < category_index; ++i) {
    if (strcmp(g_category_groups[i], category_group) == 0) {
      return &g_category_group_enabled[i];
    }
  }

  // Create a new category group.
  DCHECK(category_index < MAX_CATEGORY_GROUPS) <<
      "must increase MAX_CATEGORY_GROUPS";
  if (category_index < MAX_CATEGORY_GROUPS) {
    // Don't hold on to the category_group pointer, so that we can create
    // category groups with strings not known at compile time (this is
    // required by SetWatchEvent).
    const char* new_group = strdup(category_group);
    ANNOTATE_LEAKING_OBJECT_PTR(new_group);
    g_category_groups[category_index] = new_group;
    DCHECK(!g_category_group_enabled[category_index]);
    // Note that if both included and excluded patterns in the
    // TraceConfig are empty, we exclude nothing,
    // thereby enabling this category group.
    UpdateCategoryGroupEnabledFlag(category_index);
    category_group_enabled = &g_category_group_enabled[category_index];
    // Update the max index now.
    base::subtle::Release_Store(&g_category_index, category_index + 1);
  } else {
    category_group_enabled =
        &g_category_group_enabled[g_category_categories_exhausted];
  }
  return category_group_enabled;
}

void TraceLog::GetKnownCategoryGroups(
    std::vector<std::string>* category_groups) {
  AutoLock lock(lock_);
  category_groups->push_back(
      g_category_groups[g_category_trace_event_overhead]);
  size_t category_index = base::subtle::NoBarrier_Load(&g_category_index);
  for (size_t i = g_num_builtin_categories; i < category_index; i++)
    category_groups->push_back(g_category_groups[i]);
}

void TraceLog::SetEnabled(const TraceConfig& trace_config, Mode mode) {
  std::vector<EnabledStateObserver*> observer_list;
  {
    AutoLock lock(lock_);

    // Can't enable tracing when Flush() is in progress.
    DCHECK(!flush_task_runner_);

    InternalTraceOptions new_options =
        GetInternalOptionsFromTraceConfig(trace_config);

   InternalTraceOptions old_options = trace_options();

    if (IsEnabled()) {
      if (new_options != old_options) {
        DLOG(ERROR) << "Attempting to re-enable tracing with a different "
                    << "set of options.";
      }

      if (mode != mode_) {
        DLOG(ERROR) << "Attempting to re-enable tracing with a different mode.";
      }

      trace_config_.Merge(trace_config);
      UpdateCategoryGroupEnabledFlags();
      return;
    }

    if (dispatching_to_observer_list_) {
      DLOG(ERROR) <<
          "Cannot manipulate TraceLog::Enabled state from an observer.";
      return;
    }

    mode_ = mode;

    if (new_options != old_options) {
      subtle::NoBarrier_Store(&trace_options_, new_options);
      UseNextTraceBuffer();
    }

    num_traces_recorded_++;

    trace_config_ = TraceConfig(trace_config);
    UpdateCategoryGroupEnabledFlags();
    UpdateSyntheticDelaysFromTraceConfig();

    if (new_options & kInternalEnableSampling) {
      sampling_thread_.reset(new TraceSamplingThread);
      sampling_thread_->RegisterSampleBucket(
          &g_trace_state[0],
          "bucket0",
          Bind(&TraceSamplingThread::DefaultSamplingCallback));
      sampling_thread_->RegisterSampleBucket(
          &g_trace_state[1],
          "bucket1",
          Bind(&TraceSamplingThread::DefaultSamplingCallback));
      sampling_thread_->RegisterSampleBucket(
          &g_trace_state[2],
          "bucket2",
          Bind(&TraceSamplingThread::DefaultSamplingCallback));
      if (!PlatformThread::Create(
            0, sampling_thread_.get(), &sampling_thread_handle_)) {
        DCHECK(false) << "failed to create thread";
      }
    }

    dispatching_to_observer_list_ = true;
    observer_list = enabled_state_observer_list_;
  }
  // Notify observers outside the lock in case they trigger trace events.
  for (size_t i = 0; i < observer_list.size(); ++i)
    observer_list[i]->OnTraceLogEnabled();

  {
    AutoLock lock(lock_);
    dispatching_to_observer_list_ = false;
  }
}

void TraceLog::SetArgumentFilterPredicate(
    const TraceEvent::ArgumentFilterPredicate& argument_filter_predicate) {
  AutoLock lock(lock_);
  DCHECK(!argument_filter_predicate.is_null());
  DCHECK(argument_filter_predicate_.is_null());
  argument_filter_predicate_ = argument_filter_predicate;
}

TraceLog::InternalTraceOptions TraceLog::GetInternalOptionsFromTraceConfig(
    const TraceConfig& config) {
  InternalTraceOptions ret =
      config.IsSamplingEnabled() ? kInternalEnableSampling : kInternalNone;
  if (config.IsArgumentFilterEnabled())
    ret |= kInternalEnableArgumentFilter;
  switch (config.GetTraceRecordMode()) {
    case RECORD_UNTIL_FULL:
      return ret | kInternalRecordUntilFull;
    case RECORD_CONTINUOUSLY:
      return ret | kInternalRecordContinuously;
    case ECHO_TO_CONSOLE:
      return ret | kInternalEchoToConsole;
    case RECORD_AS_MUCH_AS_POSSIBLE:
      return ret | kInternalRecordAsMuchAsPossible;
  }
  NOTREACHED();
  return kInternalNone;
}

TraceConfig TraceLog::GetCurrentTraceConfig() const {
  AutoLock lock(lock_);
  return trace_config_;
}

void TraceLog::SetDisabled() {
  AutoLock lock(lock_);
  SetDisabledWhileLocked();
}

void TraceLog::SetDisabledWhileLocked() {
  lock_.AssertAcquired();

  if (!IsEnabled())
    return;

  if (dispatching_to_observer_list_) {
    DLOG(ERROR)
        << "Cannot manipulate TraceLog::Enabled state from an observer.";
    return;
  }

  mode_ = DISABLED;

  if (sampling_thread_.get()) {
    // Stop the sampling thread.
    sampling_thread_->Stop();
    lock_.Release();
    PlatformThread::Join(sampling_thread_handle_);
    lock_.Acquire();
    sampling_thread_handle_ = PlatformThreadHandle();
    sampling_thread_.reset();
  }

  trace_config_.Clear();
  subtle::NoBarrier_Store(&watch_category_, 0);
  watch_event_name_ = "";
  UpdateCategoryGroupEnabledFlags();
  AddMetadataEventsWhileLocked();

  dispatching_to_observer_list_ = true;
  std::vector<EnabledStateObserver*> observer_list =
      enabled_state_observer_list_;

  {
    // Dispatch to observers outside the lock in case the observer triggers a
    // trace event.
    AutoUnlock unlock(lock_);
    for (size_t i = 0; i < observer_list.size(); ++i)
      observer_list[i]->OnTraceLogDisabled();
  }
  dispatching_to_observer_list_ = false;
}

int TraceLog::GetNumTracesRecorded() {
  AutoLock lock(lock_);
  if (!IsEnabled())
    return -1;
  return num_traces_recorded_;
}

void TraceLog::AddEnabledStateObserver(EnabledStateObserver* listener) {
  enabled_state_observer_list_.push_back(listener);
}

void TraceLog::RemoveEnabledStateObserver(EnabledStateObserver* listener) {
  std::vector<EnabledStateObserver*>::iterator it =
      std::find(enabled_state_observer_list_.begin(),
                enabled_state_observer_list_.end(),
                listener);
  if (it != enabled_state_observer_list_.end())
    enabled_state_observer_list_.erase(it);
}

bool TraceLog::HasEnabledStateObserver(EnabledStateObserver* listener) const {
  std::vector<EnabledStateObserver*>::const_iterator it =
      std::find(enabled_state_observer_list_.begin(),
                enabled_state_observer_list_.end(),
                listener);
  return it != enabled_state_observer_list_.end();
}

TraceLogStatus TraceLog::GetStatus() const {
  AutoLock lock(lock_);
  TraceLogStatus result;
  result.event_capacity = logged_events_->Capacity();
  result.event_count = logged_events_->Size();
  return result;
}

bool TraceLog::BufferIsFull() const {
  AutoLock lock(lock_);
  return logged_events_->IsFull();
}

TraceBuffer* TraceLog::CreateTraceBuffer() {
  InternalTraceOptions options = trace_options();
  if (options & kInternalRecordContinuously)
    return new TraceBufferRingBuffer(kTraceEventRingBufferChunks);
  else if ((options & kInternalEnableSampling) && mode_ == MONITORING_MODE)
    return new TraceBufferRingBuffer(kMonitorTraceEventBufferChunks);
  else if (options & kInternalEchoToConsole)
    return new TraceBufferRingBuffer(kEchoToConsoleTraceEventBufferChunks);
  else if (options & kInternalRecordAsMuchAsPossible)
    return CreateTraceBufferVectorOfSize(kTraceEventVectorBigBufferChunks);
  return CreateTraceBufferVectorOfSize(kTraceEventVectorBufferChunks);
}

TraceBuffer* TraceLog::CreateTraceBufferVectorOfSize(size_t max_chunks) {
  return new TraceBufferVector(max_chunks);
}

TraceEvent* TraceLog::AddEventToThreadSharedChunkWhileLocked(
    TraceEventHandle* handle, bool check_buffer_is_full) {
  lock_.AssertAcquired();

  if (thread_shared_chunk_ && thread_shared_chunk_->IsFull()) {
    logged_events_->ReturnChunk(thread_shared_chunk_index_,
                                thread_shared_chunk_.Pass());
  }

  if (!thread_shared_chunk_) {
    thread_shared_chunk_ = logged_events_->GetChunk(
        &thread_shared_chunk_index_);
    if (check_buffer_is_full)
      CheckIfBufferIsFullWhileLocked();
  }
  if (!thread_shared_chunk_)
    return NULL;

  size_t event_index;
  TraceEvent* trace_event = thread_shared_chunk_->AddTraceEvent(&event_index);
  if (trace_event && handle) {
    MakeHandle(thread_shared_chunk_->seq(), thread_shared_chunk_index_,
               event_index, handle);
  }
  return trace_event;
}

void TraceLog::CheckIfBufferIsFullWhileLocked() {
  lock_.AssertAcquired();
  if (logged_events_->IsFull()) {
    if (buffer_limit_reached_timestamp_.is_null()) {
      buffer_limit_reached_timestamp_ = OffsetNow();
    }
    SetDisabledWhileLocked();
  }
}

void TraceLog::SetEventCallbackEnabled(const TraceConfig& trace_config,
                                       EventCallback cb) {
  AutoLock lock(lock_);
  subtle::NoBarrier_Store(&event_callback_,
                          reinterpret_cast<subtle::AtomicWord>(cb));
  event_callback_trace_config_ = trace_config;
  UpdateCategoryGroupEnabledFlags();
};

void TraceLog::SetEventCallbackDisabled() {
  AutoLock lock(lock_);
  subtle::NoBarrier_Store(&event_callback_, 0);
  UpdateCategoryGroupEnabledFlags();
}

// Flush() works as the following:
// 1. Flush() is called in thread A whose task runner is saved in
//    flush_task_runner_;
// 2. If thread_message_loops_ is not empty, thread A posts task to each message
//    loop to flush the thread local buffers; otherwise finish the flush;
// 3. FlushCurrentThread() deletes the thread local event buffer:
//    - The last batch of events of the thread are flushed into the main buffer;
//    - The message loop will be removed from thread_message_loops_;
//    If this is the last message loop, finish the flush;
// 4. If any thread hasn't finish its flush in time, finish the flush.
void TraceLog::Flush(const TraceLog::OutputCallback& cb,
                     bool use_worker_thread) {
  use_worker_thread_ = use_worker_thread;
  if (IsEnabled()) {
    // Can't flush when tracing is enabled because otherwise PostTask would
    // - generate more trace events;
    // - deschedule the calling thread on some platforms causing inaccurate
    //   timing of the trace events.
    scoped_refptr<RefCountedString> empty_result = new RefCountedString;
    if (!cb.is_null())
      cb.Run(empty_result, false);
    LOG(WARNING) << "Ignored TraceLog::Flush called when tracing is enabled";
    return;
  }

  int generation = this->generation();
  // Copy of thread_message_loops_ to be used without locking.
  std::vector<scoped_refptr<SingleThreadTaskRunner> >
      thread_message_loop_task_runners;
  {
    AutoLock lock(lock_);
    DCHECK(!flush_task_runner_);
    flush_task_runner_ = ThreadTaskRunnerHandle::IsSet()
                             ? ThreadTaskRunnerHandle::Get()
                             : nullptr;
    DCHECK_IMPLIES(thread_message_loops_.size(), flush_task_runner_);
    flush_output_callback_ = cb;

    if (thread_shared_chunk_) {
      logged_events_->ReturnChunk(thread_shared_chunk_index_,
                                  thread_shared_chunk_.Pass());
    }

    if (thread_message_loops_.size()) {
      for (hash_set<MessageLoop*>::const_iterator it =
           thread_message_loops_.begin();
           it != thread_message_loops_.end(); ++it) {
        thread_message_loop_task_runners.push_back((*it)->task_runner());
      }
    }
  }

  if (thread_message_loop_task_runners.size()) {
    for (size_t i = 0; i < thread_message_loop_task_runners.size(); ++i) {
      thread_message_loop_task_runners[i]->PostTask(
          FROM_HERE,
          Bind(&TraceLog::FlushCurrentThread, Unretained(this), generation));
    }
    flush_task_runner_->PostDelayedTask(
        FROM_HERE,
        Bind(&TraceLog::OnFlushTimeout, Unretained(this), generation),
        TimeDelta::FromMilliseconds(kThreadFlushTimeoutMs));
    return;
  }

  FinishFlush(generation);
}

// Usually it runs on a different thread.
void TraceLog::ConvertTraceEventsToTraceFormat(
    scoped_ptr<TraceBuffer> logged_events,
    const OutputCallback& flush_output_callback,
    const TraceEvent::ArgumentFilterPredicate& argument_filter_predicate) {
  if (flush_output_callback.is_null())
    return;

  // The callback need to be called at least once even if there is no events
  // to let the caller know the completion of flush.
  bool has_more_events = true;
  do {
    scoped_refptr<RefCountedString> json_events_str_ptr =
        new RefCountedString();

    while (json_events_str_ptr->size() < kTraceEventBufferSizeInBytes) {
      const TraceBufferChunk* chunk = logged_events->NextChunk();
      has_more_events = chunk != NULL;
      if (!chunk)
        break;
      for (size_t j = 0; j < chunk->size(); ++j) {
        if (json_events_str_ptr->size())
          json_events_str_ptr->data().append(",\n");
        chunk->GetEventAt(j)->AppendAsJSON(&(json_events_str_ptr->data()),
                                           argument_filter_predicate);
      }
    }
    flush_output_callback.Run(json_events_str_ptr, has_more_events);
  } while (has_more_events);
}

void TraceLog::FinishFlush(int generation) {
  scoped_ptr<TraceBuffer> previous_logged_events;
  OutputCallback flush_output_callback;
  TraceEvent::ArgumentFilterPredicate argument_filter_predicate;

  if (!CheckGeneration(generation))
    return;

  {
    AutoLock lock(lock_);

    previous_logged_events.swap(logged_events_);
    UseNextTraceBuffer();
    thread_message_loops_.clear();

    flush_task_runner_ = NULL;
    flush_output_callback = flush_output_callback_;
    flush_output_callback_.Reset();

    if (trace_options() & kInternalEnableArgumentFilter) {
      CHECK(!argument_filter_predicate_.is_null());
      argument_filter_predicate = argument_filter_predicate_;
    }
  }

  if (use_worker_thread_ &&
      WorkerPool::PostTask(
          FROM_HERE, Bind(&TraceLog::ConvertTraceEventsToTraceFormat,
                          Passed(&previous_logged_events),
                          flush_output_callback, argument_filter_predicate),
          true)) {
    return;
  }

  ConvertTraceEventsToTraceFormat(previous_logged_events.Pass(),
                                  flush_output_callback,
                                  argument_filter_predicate);
}

// Run in each thread holding a local event buffer.
void TraceLog::FlushCurrentThread(int generation) {
  {
    AutoLock lock(lock_);
    if (!CheckGeneration(generation) || !flush_task_runner_) {
      // This is late. The corresponding flush has finished.
      return;
    }
  }

  // This will flush the thread local buffer.
  delete thread_local_event_buffer_.Get();

  AutoLock lock(lock_);
  if (!CheckGeneration(generation) || !flush_task_runner_ ||
      thread_message_loops_.size())
    return;

  flush_task_runner_->PostTask(
      FROM_HERE, Bind(&TraceLog::FinishFlush, Unretained(this), generation));
}

void TraceLog::OnFlushTimeout(int generation) {
  {
    AutoLock lock(lock_);
    if (!CheckGeneration(generation) || !flush_task_runner_) {
      // Flush has finished before timeout.
      return;
    }

    LOG(WARNING) <<
        "The following threads haven't finished flush in time. "
        "If this happens stably for some thread, please call "
        "TraceLog::GetInstance()->SetCurrentThreadBlocksMessageLoop() from "
        "the thread to avoid its trace events from being lost.";
    for (hash_set<MessageLoop*>::const_iterator it =
         thread_message_loops_.begin();
         it != thread_message_loops_.end(); ++it) {
      LOG(WARNING) << "Thread: " << (*it)->thread_name();
    }
  }
  FinishFlush(generation);
}

void TraceLog::FlushButLeaveBufferIntact(
    const TraceLog::OutputCallback& flush_output_callback) {
  scoped_ptr<TraceBuffer> previous_logged_events;
  TraceEvent::ArgumentFilterPredicate argument_filter_predicate;
  {
    AutoLock lock(lock_);
    AddMetadataEventsWhileLocked();
    if (thread_shared_chunk_) {
      // Return the chunk to the main buffer to flush the sampling data.
      logged_events_->ReturnChunk(thread_shared_chunk_index_,
                                  thread_shared_chunk_.Pass());
    }
    previous_logged_events = logged_events_->CloneForIteration().Pass();

    if (trace_options() & kInternalEnableArgumentFilter) {
      CHECK(!argument_filter_predicate_.is_null());
      argument_filter_predicate = argument_filter_predicate_;
    }
  }  // release lock

  ConvertTraceEventsToTraceFormat(previous_logged_events.Pass(),
                                  flush_output_callback,
                                  argument_filter_predicate);
}

void TraceLog::UseNextTraceBuffer() {
  logged_events_.reset(CreateTraceBuffer());
  subtle::NoBarrier_AtomicIncrement(&generation_, 1);
  thread_shared_chunk_.reset();
  thread_shared_chunk_index_ = 0;
}

TraceEventHandle TraceLog::AddTraceEvent(
    char phase,
    const unsigned char* category_group_enabled,
    const char* name,
    unsigned long long id,
    int num_args,
    const char** arg_names,
    const unsigned char* arg_types,
    const unsigned long long* arg_values,
    const scoped_refptr<ConvertableToTraceFormat>* convertable_values,
    unsigned char flags) {
  int thread_id = static_cast<int>(base::PlatformThread::CurrentId());
  base::TraceTicks now = base::TraceTicks::Now();
  return AddTraceEventWithThreadIdAndTimestamp(phase, category_group_enabled,
                                               name, id, thread_id, now,
                                               num_args, arg_names,
                                               arg_types, arg_values,
                                               convertable_values, flags);
}

TraceEventHandle TraceLog::AddTraceEventWithThreadIdAndTimestamp(
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
    unsigned char flags) {
  TraceEventHandle handle = { 0, 0, 0 };
  if (!*category_group_enabled)
    return handle;

  // Avoid re-entrance of AddTraceEvent. This may happen in GPU process when
  // ECHO_TO_CONSOLE is enabled: AddTraceEvent -> LOG(ERROR) ->
  // GpuProcessLogMessageHandler -> PostPendingTask -> TRACE_EVENT ...
  if (thread_is_in_trace_event_.Get())
    return handle;

  AutoThreadLocalBoolean thread_is_in_trace_event(&thread_is_in_trace_event_);

  DCHECK(name);
  DCHECK(!timestamp.is_null());

  if (flags & TRACE_EVENT_FLAG_MANGLE_ID)
    id = MangleEventId(id);

  TraceTicks offset_event_timestamp = OffsetTimestamp(timestamp);
  TraceTicks now = flags & TRACE_EVENT_FLAG_EXPLICIT_TIMESTAMP ?
      OffsetNow() : offset_event_timestamp;
  ThreadTicks thread_now = ThreadNow();

  ThreadLocalEventBuffer* thread_local_event_buffer = NULL;
  // A ThreadLocalEventBuffer needs the message loop
  // - to know when the thread exits;
  // - to handle the final flush.
  // For a thread without a message loop or the message loop may be blocked, the
  // trace events will be added into the main buffer directly.
  if (!thread_blocks_message_loop_.Get() && MessageLoop::current()) {
    thread_local_event_buffer = thread_local_event_buffer_.Get();
    if (thread_local_event_buffer &&
        !CheckGeneration(thread_local_event_buffer->generation())) {
      delete thread_local_event_buffer;
      thread_local_event_buffer = NULL;
    }
    if (!thread_local_event_buffer) {
      thread_local_event_buffer = new ThreadLocalEventBuffer(this);
      thread_local_event_buffer_.Set(thread_local_event_buffer);
    }
  }

  // Check and update the current thread name only if the event is for the
  // current thread to avoid locks in most cases.
  if (thread_id == static_cast<int>(PlatformThread::CurrentId())) {
    const char* new_name = ThreadIdNameManager::GetInstance()->
        GetName(thread_id);
    // Check if the thread name has been set or changed since the previous
    // call (if any), but don't bother if the new name is empty. Note this will
    // not detect a thread name change within the same char* buffer address: we
    // favor common case performance over corner case correctness.
    if (new_name != g_current_thread_name.Get().Get() &&
        new_name && *new_name) {
      g_current_thread_name.Get().Set(new_name);

      AutoLock thread_info_lock(thread_info_lock_);

      hash_map<int, std::string>::iterator existing_name =
          thread_names_.find(thread_id);
      if (existing_name == thread_names_.end()) {
        // This is a new thread id, and a new name.
        thread_names_[thread_id] = new_name;
      } else {
        // This is a thread id that we've seen before, but potentially with a
        // new name.
        std::vector<StringPiece> existing_names;
        Tokenize(existing_name->second, ",", &existing_names);
        bool found = std::find(existing_names.begin(),
                               existing_names.end(),
                               new_name) != existing_names.end();
        if (!found) {
          if (existing_names.size())
            existing_name->second.push_back(',');
          existing_name->second.append(new_name);
        }
      }
    }
  }

#if defined(OS_WIN)
  // This is done sooner rather than later, to avoid creating the event and
  // acquiring the lock, which is not needed for ETW as it's already threadsafe.
  if (*category_group_enabled & ENABLED_FOR_ETW_EXPORT)
    TraceEventETWExport::AddEvent(phase, category_group_enabled, name, id,
                                  num_args, arg_names, arg_types, arg_values,
                                  convertable_values);
#endif  // OS_WIN

  std::string console_message;
  if (*category_group_enabled &
      (ENABLED_FOR_RECORDING | ENABLED_FOR_MONITORING)) {
    OptionalAutoLock lock(&lock_);

    TraceEvent* trace_event = NULL;
    if (thread_local_event_buffer) {
      trace_event = thread_local_event_buffer->AddTraceEvent(&handle);
    } else {
      lock.EnsureAcquired();
      trace_event = AddEventToThreadSharedChunkWhileLocked(&handle, true);
    }

    if (trace_event) {
      trace_event->Initialize(thread_id, offset_event_timestamp, thread_now,
                              phase, category_group_enabled, name, id,
                              num_args, arg_names, arg_types, arg_values,
                              convertable_values, flags);

#if defined(OS_ANDROID)
      trace_event->SendToATrace();
#endif
    }

    if (trace_options() & kInternalEchoToConsole) {
      console_message = EventToConsoleMessage(
          phase == TRACE_EVENT_PHASE_COMPLETE ? TRACE_EVENT_PHASE_BEGIN : phase,
          timestamp, trace_event);
    }
  }

  if (console_message.size())
    LOG(ERROR) << console_message;

  if (reinterpret_cast<const unsigned char*>(subtle::NoBarrier_Load(
      &watch_category_)) == category_group_enabled) {
    bool event_name_matches;
    WatchEventCallback watch_event_callback_copy;
    {
      AutoLock lock(lock_);
      event_name_matches = watch_event_name_ == name;
      watch_event_callback_copy = watch_event_callback_;
    }
    if (event_name_matches) {
      if (!watch_event_callback_copy.is_null())
        watch_event_callback_copy.Run();
    }
  }

  if (*category_group_enabled & ENABLED_FOR_EVENT_CALLBACK) {
    EventCallback event_callback = reinterpret_cast<EventCallback>(
        subtle::NoBarrier_Load(&event_callback_));
    if (event_callback) {
      event_callback(offset_event_timestamp,
                     phase == TRACE_EVENT_PHASE_COMPLETE ?
                         TRACE_EVENT_PHASE_BEGIN : phase,
                     category_group_enabled, name, id,
                     num_args, arg_names, arg_types, arg_values,
                     flags);
    }
  }

  if (thread_local_event_buffer)
    thread_local_event_buffer->ReportOverhead(now, thread_now);

  return handle;
}

// May be called when a COMPELETE event ends and the unfinished event has been
// recycled (phase == TRACE_EVENT_PHASE_END and trace_event == NULL).
std::string TraceLog::EventToConsoleMessage(unsigned char phase,
                                            const TraceTicks& timestamp,
                                            TraceEvent* trace_event) {
  AutoLock thread_info_lock(thread_info_lock_);

  // The caller should translate TRACE_EVENT_PHASE_COMPLETE to
  // TRACE_EVENT_PHASE_BEGIN or TRACE_EVENT_END.
  DCHECK(phase != TRACE_EVENT_PHASE_COMPLETE);

  TimeDelta duration;
  int thread_id = trace_event ?
      trace_event->thread_id() : PlatformThread::CurrentId();
  if (phase == TRACE_EVENT_PHASE_END) {
    duration = timestamp - thread_event_start_times_[thread_id].top();
    thread_event_start_times_[thread_id].pop();
  }

  std::string thread_name = thread_names_[thread_id];
  if (thread_colors_.find(thread_name) == thread_colors_.end())
    thread_colors_[thread_name] = (thread_colors_.size() % 6) + 1;

  std::ostringstream log;
  log << base::StringPrintf("%s: \x1b[0;3%dm",
                            thread_name.c_str(),
                            thread_colors_[thread_name]);

  size_t depth = 0;
  if (thread_event_start_times_.find(thread_id) !=
      thread_event_start_times_.end())
    depth = thread_event_start_times_[thread_id].size();

  for (size_t i = 0; i < depth; ++i)
    log << "| ";

  if (trace_event)
    trace_event->AppendPrettyPrinted(&log);
  if (phase == TRACE_EVENT_PHASE_END)
    log << base::StringPrintf(" (%.3f ms)", duration.InMillisecondsF());

  log << "\x1b[0;m";

  if (phase == TRACE_EVENT_PHASE_BEGIN)
    thread_event_start_times_[thread_id].push(timestamp);

  return log.str();
}

void TraceLog::AddTraceEventEtw(char phase,
                                const char* name,
                                const void* id,
                                const char* extra) {
#if defined(OS_WIN)
  TraceEventETWProvider::Trace(name, phase, id, extra);
#endif
  INTERNAL_TRACE_EVENT_ADD(phase, "ETW Trace Event", name,
                           TRACE_EVENT_FLAG_COPY, "id", id, "extra", extra);
}

void TraceLog::AddTraceEventEtw(char phase,
                                const char* name,
                                const void* id,
                                const std::string& extra) {
#if defined(OS_WIN)
  TraceEventETWProvider::Trace(name, phase, id, extra);
#endif
  INTERNAL_TRACE_EVENT_ADD(phase, "ETW Trace Event", name,
                           TRACE_EVENT_FLAG_COPY, "id", id, "extra", extra);
}

void TraceLog::UpdateTraceEventDuration(
    const unsigned char* category_group_enabled,
    const char* name,
    TraceEventHandle handle) {
  // Avoid re-entrance of AddTraceEvent. This may happen in GPU process when
  // ECHO_TO_CONSOLE is enabled: AddTraceEvent -> LOG(ERROR) ->
  // GpuProcessLogMessageHandler -> PostPendingTask -> TRACE_EVENT ...
  if (thread_is_in_trace_event_.Get())
    return;

  AutoThreadLocalBoolean thread_is_in_trace_event(&thread_is_in_trace_event_);

  ThreadTicks thread_now = ThreadNow();
  TraceTicks now = OffsetNow();

  std::string console_message;
  if (*category_group_enabled & ENABLED_FOR_RECORDING) {
    OptionalAutoLock lock(&lock_);

    TraceEvent* trace_event = GetEventByHandleInternal(handle, &lock);
    if (trace_event) {
      DCHECK(trace_event->phase() == TRACE_EVENT_PHASE_COMPLETE);
      trace_event->UpdateDuration(now, thread_now);
#if defined(OS_ANDROID)
      trace_event->SendToATrace();
#endif
    }

    if (trace_options() & kInternalEchoToConsole) {
      console_message = EventToConsoleMessage(TRACE_EVENT_PHASE_END,
                                              now, trace_event);
    }
  }

  if (console_message.size())
    LOG(ERROR) << console_message;

  if (*category_group_enabled & ENABLED_FOR_EVENT_CALLBACK) {
    EventCallback event_callback = reinterpret_cast<EventCallback>(
        subtle::NoBarrier_Load(&event_callback_));
    if (event_callback) {
      event_callback(now, TRACE_EVENT_PHASE_END, category_group_enabled, name,
                     trace_event_internal::kNoEventId, 0, NULL, NULL, NULL,
                     TRACE_EVENT_FLAG_NONE);
    }
  }
}

void TraceLog::SetWatchEvent(const std::string& category_name,
                             const std::string& event_name,
                             const WatchEventCallback& callback) {
  const unsigned char* category = GetCategoryGroupEnabled(
      category_name.c_str());
  AutoLock lock(lock_);
  subtle::NoBarrier_Store(&watch_category_,
                          reinterpret_cast<subtle::AtomicWord>(category));
  watch_event_name_ = event_name;
  watch_event_callback_ = callback;
}

void TraceLog::CancelWatchEvent() {
  AutoLock lock(lock_);
  subtle::NoBarrier_Store(&watch_category_, 0);
  watch_event_name_ = "";
  watch_event_callback_.Reset();
}

uint64 TraceLog::MangleEventId(uint64 id) {
  return id ^ process_id_hash_;
}

void TraceLog::AddMetadataEventsWhileLocked() {
  lock_.AssertAcquired();

#if !defined(OS_NACL)  // NaCl shouldn't expose the process id.
  InitializeMetadataEvent(AddEventToThreadSharedChunkWhileLocked(NULL, false),
                          0,
                          "num_cpus", "number",
                          base::SysInfo::NumberOfProcessors());
#endif


  int current_thread_id = static_cast<int>(base::PlatformThread::CurrentId());
  if (process_sort_index_ != 0) {
    InitializeMetadataEvent(AddEventToThreadSharedChunkWhileLocked(NULL, false),
                            current_thread_id,
                            "process_sort_index", "sort_index",
                            process_sort_index_);
  }

  if (process_name_.size()) {
    InitializeMetadataEvent(AddEventToThreadSharedChunkWhileLocked(NULL, false),
                            current_thread_id,
                            "process_name", "name",
                            process_name_);
  }

  if (process_labels_.size() > 0) {
    std::vector<std::string> labels;
    for(base::hash_map<int, std::string>::iterator it = process_labels_.begin();
        it != process_labels_.end();
        it++) {
      labels.push_back(it->second);
    }
    InitializeMetadataEvent(AddEventToThreadSharedChunkWhileLocked(NULL, false),
                            current_thread_id,
                            "process_labels", "labels",
                            JoinString(labels, ','));
  }

  // Thread sort indices.
  for(hash_map<int, int>::iterator it = thread_sort_indices_.begin();
      it != thread_sort_indices_.end();
      it++) {
    if (it->second == 0)
      continue;
    InitializeMetadataEvent(AddEventToThreadSharedChunkWhileLocked(NULL, false),
                            it->first,
                            "thread_sort_index", "sort_index",
                            it->second);
  }

  // Thread names.
  AutoLock thread_info_lock(thread_info_lock_);
  for(hash_map<int, std::string>::iterator it = thread_names_.begin();
      it != thread_names_.end();
      it++) {
    if (it->second.empty())
      continue;
    InitializeMetadataEvent(AddEventToThreadSharedChunkWhileLocked(NULL, false),
                            it->first,
                            "thread_name", "name",
                            it->second);
  }

  // If buffer is full, add a metadata record to report this.
  if (!buffer_limit_reached_timestamp_.is_null()) {
    InitializeMetadataEvent(AddEventToThreadSharedChunkWhileLocked(NULL, false),
                            current_thread_id,
                            "trace_buffer_overflowed",
                            "overflowed_at_ts",
                            buffer_limit_reached_timestamp_);
  }
}

void TraceLog::WaitSamplingEventForTesting() {
  if (!sampling_thread_)
    return;
  sampling_thread_->WaitSamplingEventForTesting();
}

void TraceLog::DeleteForTesting() {
  DeleteTraceLogForTesting::Delete();
}

TraceEvent* TraceLog::GetEventByHandle(TraceEventHandle handle) {
  return GetEventByHandleInternal(handle, NULL);
}

TraceEvent* TraceLog::GetEventByHandleInternal(TraceEventHandle handle,
                                               OptionalAutoLock* lock) {
  if (!handle.chunk_seq)
    return NULL;

  if (thread_local_event_buffer_.Get()) {
    TraceEvent* trace_event =
        thread_local_event_buffer_.Get()->GetEventByHandle(handle);
    if (trace_event)
      return trace_event;
  }

  // The event has been out-of-control of the thread local buffer.
  // Try to get the event from the main buffer with a lock.
  if (lock)
    lock->EnsureAcquired();

  if (thread_shared_chunk_ &&
      handle.chunk_index == thread_shared_chunk_index_) {
    return handle.chunk_seq == thread_shared_chunk_->seq() ?
        thread_shared_chunk_->GetEventAt(handle.event_index) : NULL;
  }

  return logged_events_->GetEventByHandle(handle);
}

void TraceLog::SetProcessID(int process_id) {
  process_id_ = process_id;
  // Create a FNV hash from the process ID for XORing.
  // See http://isthe.com/chongo/tech/comp/fnv/ for algorithm details.
  unsigned long long offset_basis = 14695981039346656037ull;
  unsigned long long fnv_prime = 1099511628211ull;
  unsigned long long pid = static_cast<unsigned long long>(process_id_);
  process_id_hash_ = (offset_basis ^ pid) * fnv_prime;
}

void TraceLog::SetProcessSortIndex(int sort_index) {
  AutoLock lock(lock_);
  process_sort_index_ = sort_index;
}

void TraceLog::SetProcessName(const std::string& process_name) {
  AutoLock lock(lock_);
  process_name_ = process_name;
}

void TraceLog::UpdateProcessLabel(
    int label_id, const std::string& current_label) {
  if(!current_label.length())
    return RemoveProcessLabel(label_id);

  AutoLock lock(lock_);
  process_labels_[label_id] = current_label;
}

void TraceLog::RemoveProcessLabel(int label_id) {
  AutoLock lock(lock_);
  base::hash_map<int, std::string>::iterator it = process_labels_.find(
      label_id);
  if (it == process_labels_.end())
    return;

  process_labels_.erase(it);
}

void TraceLog::SetThreadSortIndex(PlatformThreadId thread_id, int sort_index) {
  AutoLock lock(lock_);
  thread_sort_indices_[static_cast<int>(thread_id)] = sort_index;
}

void TraceLog::SetTimeOffset(TimeDelta offset) {
  time_offset_ = offset;
}

size_t TraceLog::GetObserverCountForTest() const {
  return enabled_state_observer_list_.size();
}

void TraceLog::SetCurrentThreadBlocksMessageLoop() {
  thread_blocks_message_loop_.Set(true);
  if (thread_local_event_buffer_.Get()) {
    // This will flush the thread local buffer.
    delete thread_local_event_buffer_.Get();
  }
}

}  // namespace trace_event
}  // namespace base

namespace trace_event_internal {

ScopedTraceBinaryEfficient::ScopedTraceBinaryEfficient(
    const char* category_group, const char* name) {
  // The single atom works because for now the category_group can only be "gpu".
  DCHECK_EQ(strcmp(category_group, "gpu"), 0);
  static TRACE_EVENT_API_ATOMIC_WORD atomic = 0;
  INTERNAL_TRACE_EVENT_GET_CATEGORY_INFO_CUSTOM_VARIABLES(
      category_group, atomic, category_group_enabled_);
  name_ = name;
  if (*category_group_enabled_) {
    event_handle_ =
        TRACE_EVENT_API_ADD_TRACE_EVENT_WITH_THREAD_ID_AND_TIMESTAMP(
            TRACE_EVENT_PHASE_COMPLETE, category_group_enabled_, name,
            trace_event_internal::kNoEventId,
            static_cast<int>(base::PlatformThread::CurrentId()),
            base::TraceTicks::Now(), 0, NULL, NULL, NULL, NULL,
            TRACE_EVENT_FLAG_NONE);
  }
}

ScopedTraceBinaryEfficient::~ScopedTraceBinaryEfficient() {
  if (*category_group_enabled_) {
    TRACE_EVENT_API_UPDATE_TRACE_EVENT_DURATION(category_group_enabled_,
                                                name_, event_handle_);
  }
}

}  // namespace trace_event_internal
