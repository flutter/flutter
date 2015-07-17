// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/trace_event_memory.h"

#include "base/debug/leak_annotations.h"
#include "base/lazy_instance.h"
#include "base/location.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/single_thread_task_runner.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_split.h"
#include "base/strings/string_util.h"
#include "base/threading/thread_local_storage.h"
#include "base/trace_event/trace_event.h"

namespace base {
namespace trace_event {

namespace {

// Maximum number of nested TRACE_EVENT scopes to record. Must be less than
// or equal to HeapProfileTable::kMaxStackDepth / 2 because we record two
// entries on the pseudo-stack per scope.
const size_t kMaxScopeDepth = 16;

/////////////////////////////////////////////////////////////////////////////
// Holds a memory dump until the tracing system needs to serialize it.
class MemoryDumpHolder : public base::trace_event::ConvertableToTraceFormat {
 public:
  // Takes ownership of dump, which must be a JSON string, allocated with
  // malloc() and NULL terminated.
  explicit MemoryDumpHolder(char* dump) : dump_(dump) {}

  // base::trace_event::ConvertableToTraceFormat overrides:
  void AppendAsTraceFormat(std::string* out) const override {
    AppendHeapProfileAsTraceFormat(dump_, out);
  }

 private:
  ~MemoryDumpHolder() override { free(dump_); }

  char* dump_;

  DISALLOW_COPY_AND_ASSIGN(MemoryDumpHolder);
};

/////////////////////////////////////////////////////////////////////////////
// Records a stack of TRACE_MEMORY events. One per thread is required.
struct TraceMemoryStack {
  TraceMemoryStack() : scope_depth(0) {
    memset(scope_data, 0, kMaxScopeDepth * sizeof(scope_data[0]));
  }

  // Depth of the currently nested TRACE_EVENT scopes. Allowed to be greater
  // than kMaxScopeDepth so we can match scope pushes and pops even if we don't
  // have enough space to store the EventData.
  size_t scope_depth;

  // Stack of categories and names.
  ScopedTraceMemory::ScopeData scope_data[kMaxScopeDepth];
};

// Pointer to a TraceMemoryStack per thread.
base::ThreadLocalStorage::StaticSlot tls_trace_memory_stack = TLS_INITIALIZER;

// Clean up memory pointed to by our thread-local storage.
void DeleteStackOnThreadCleanup(void* value) {
  TraceMemoryStack* stack = static_cast<TraceMemoryStack*>(value);
  delete stack;
}

// Initializes the thread-local TraceMemoryStack pointer.
void InitThreadLocalStorage() {
  if (tls_trace_memory_stack.initialized())
    return;
  // Initialize the thread-local storage key.
  tls_trace_memory_stack.Initialize(&DeleteStackOnThreadCleanup);
}

// Clean up thread-local-storage in the main thread.
void CleanupThreadLocalStorage() {
  if (!tls_trace_memory_stack.initialized())
    return;
  TraceMemoryStack* stack =
      static_cast<TraceMemoryStack*>(tls_trace_memory_stack.Get());
  delete stack;
  tls_trace_memory_stack.Set(NULL);
  // Intentionally do not release the thread-local-storage key here, that is,
  // do not call tls_trace_memory_stack.Free(). Other threads have lazily
  // created pointers in thread-local-storage via GetTraceMemoryStack() below.
  // Those threads need to run the DeleteStack() destructor function when they
  // exit. If we release the key the destructor will not be called and those
  // threads will not clean up their memory.
}

// Returns the thread-local trace memory stack for the current thread, creating
// one if needed. Returns NULL if the thread-local storage key isn't
// initialized, which indicates that heap profiling isn't running.
TraceMemoryStack* GetTraceMemoryStack() {
  TraceMemoryStack* stack =
      static_cast<TraceMemoryStack*>(tls_trace_memory_stack.Get());
  // Lazily initialize TraceMemoryStack objects for new threads.
  if (!stack) {
    stack = new TraceMemoryStack;
    tls_trace_memory_stack.Set(stack);
  }
  return stack;
}

// Returns a "pseudo-stack" of pointers to trace event categories and names.
// Because tcmalloc stores one pointer per stack frame this converts N nested
// trace events into N * 2 pseudo-stack entries. Thus this macro invocation:
//    TRACE_EVENT0("category1", "name1");
//    TRACE_EVENT0("category2", "name2");
// becomes this pseudo-stack:
//    stack_out[0] = "category1"
//    stack_out[1] = "name1"
//    stack_out[2] = "category2"
//    stack_out[3] = "name2"
// Returns int instead of size_t to match the signature required by tcmalloc.
int GetPseudoStack(int skip_count_ignored, void** stack_out) {
  // If the tracing system isn't fully initialized, just skip this allocation.
  // Attempting to initialize will allocate memory, causing this function to
  // be called recursively from inside the allocator.
  if (!tls_trace_memory_stack.initialized() || !tls_trace_memory_stack.Get())
    return 0;
  TraceMemoryStack* stack =
      static_cast<TraceMemoryStack*>(tls_trace_memory_stack.Get());
  // Copy at most kMaxScopeDepth scope entries.
  const size_t count = std::min(stack->scope_depth, kMaxScopeDepth);
  // Notes that memcpy() works for zero bytes.
  memcpy(stack_out,
         stack->scope_data,
         count * sizeof(stack->scope_data[0]));
  // Each item in the trace event stack contains both name and category so tell
  // tcmalloc that we have returned |count| * 2 stack frames.
  return static_cast<int>(count * 2);
}

}  // namespace

//////////////////////////////////////////////////////////////////////////////

TraceMemoryController::TraceMemoryController(
    scoped_refptr<SingleThreadTaskRunner> task_runner,
    HeapProfilerStartFunction heap_profiler_start_function,
    HeapProfilerStopFunction heap_profiler_stop_function,
    GetHeapProfileFunction get_heap_profile_function)
    : task_runner_(task_runner.Pass()),
      heap_profiler_start_function_(heap_profiler_start_function),
      heap_profiler_stop_function_(heap_profiler_stop_function),
      get_heap_profile_function_(get_heap_profile_function),
      weak_factory_(this) {
  // Force the "memory" category to show up in the trace viewer.
  TRACE_EVENT0(TRACE_DISABLED_BY_DEFAULT("memory"), "init");
  // Watch for the tracing system being enabled.
  TraceLog::GetInstance()->AddEnabledStateObserver(this);
}

TraceMemoryController::~TraceMemoryController() {
  if (dump_timer_.IsRunning())
    StopProfiling();
  TraceLog::GetInstance()->RemoveEnabledStateObserver(this);
}

// base::trace_event::TraceLog::EnabledStateChangedObserver overrides:
void TraceMemoryController::OnTraceLogEnabled() {
  // Check to see if tracing is enabled for the memory category.
  bool enabled;
  TRACE_EVENT_CATEGORY_GROUP_ENABLED(TRACE_DISABLED_BY_DEFAULT("memory"),
                                     &enabled);
  if (!enabled)
    return;
  DVLOG(1) << "OnTraceLogEnabled";
  task_runner_->PostTask(FROM_HERE,
                         base::Bind(&TraceMemoryController::StartProfiling,
                                    weak_factory_.GetWeakPtr()));
}

void TraceMemoryController::OnTraceLogDisabled() {
  // The memory category is always disabled before OnTraceLogDisabled() is
  // called, so we cannot tell if it was enabled before. Always try to turn
  // off profiling.
  DVLOG(1) << "OnTraceLogDisabled";
  task_runner_->PostTask(FROM_HERE,
                         base::Bind(&TraceMemoryController::StopProfiling,
                                    weak_factory_.GetWeakPtr()));
}

void TraceMemoryController::StartProfiling() {
  // Watch for the tracing framework sending enabling more than once.
  if (dump_timer_.IsRunning())
    return;
  DVLOG(1) << "Starting trace memory";
  InitThreadLocalStorage();
  ScopedTraceMemory::set_enabled(true);
  // Call ::HeapProfilerWithPseudoStackStart().
  heap_profiler_start_function_(&GetPseudoStack);
  const int kDumpIntervalSeconds = 5;
  dump_timer_.Start(FROM_HERE,
                    TimeDelta::FromSeconds(kDumpIntervalSeconds),
                    base::Bind(&TraceMemoryController::DumpMemoryProfile,
                               weak_factory_.GetWeakPtr()));
}

void TraceMemoryController::DumpMemoryProfile() {
  // Don't trace allocations here in the memory tracing system.
  INTERNAL_TRACE_MEMORY(TRACE_DISABLED_BY_DEFAULT("memory"),
                        TRACE_MEMORY_IGNORE);

  DVLOG(1) << "DumpMemoryProfile";
  // MemoryDumpHolder takes ownership of this string. See GetHeapProfile() in
  // tcmalloc for details.
  char* dump = get_heap_profile_function_();
  const int kSnapshotId = 1;
  TRACE_EVENT_OBJECT_SNAPSHOT_WITH_ID(
      TRACE_DISABLED_BY_DEFAULT("memory"),
      "memory::Heap",
      kSnapshotId,
      scoped_refptr<ConvertableToTraceFormat>(new MemoryDumpHolder(dump)));
}

void TraceMemoryController::StopProfiling() {
  // Watch for the tracing framework sending disabled more than once.
  if (!dump_timer_.IsRunning())
    return;
  DVLOG(1) << "Stopping trace memory";
  dump_timer_.Stop();
  ScopedTraceMemory::set_enabled(false);
  CleanupThreadLocalStorage();
  // Call ::HeapProfilerStop().
  heap_profiler_stop_function_();
}

bool TraceMemoryController::IsTimerRunningForTest() const {
  return dump_timer_.IsRunning();
}

/////////////////////////////////////////////////////////////////////////////

// static
bool ScopedTraceMemory::enabled_ = false;

void ScopedTraceMemory::Initialize(const char* category, const char* name) {
  DCHECK(enabled_);
  // Get our thread's copy of the stack.
  TraceMemoryStack* trace_memory_stack = GetTraceMemoryStack();
  const size_t index = trace_memory_stack->scope_depth;
  // Don't record data for deeply nested scopes, but continue to increment
  // |stack_depth| so we can match pushes and pops.
  if (index < kMaxScopeDepth) {
    ScopeData& event = trace_memory_stack->scope_data[index];
    event.category = category;
    event.name = name;
  }
  trace_memory_stack->scope_depth++;
}

void ScopedTraceMemory::Destroy() {
  DCHECK(enabled_);
  // Get our thread's copy of the stack.
  TraceMemoryStack* trace_memory_stack = GetTraceMemoryStack();
  // The tracing system can be turned on with ScopedTraceMemory objects
  // allocated on the stack, so avoid potential underflow as they are destroyed.
  if (trace_memory_stack->scope_depth > 0)
    trace_memory_stack->scope_depth--;
}

// static
void ScopedTraceMemory::InitForTest() {
  InitThreadLocalStorage();
  enabled_ = true;
}

// static
void ScopedTraceMemory::CleanupForTest() {
  enabled_ = false;
  CleanupThreadLocalStorage();
}

// static
int ScopedTraceMemory::GetStackDepthForTest() {
  TraceMemoryStack* stack = GetTraceMemoryStack();
  return static_cast<int>(stack->scope_depth);
}

// static
ScopedTraceMemory::ScopeData ScopedTraceMemory::GetScopeDataForTest(
    int stack_index) {
  TraceMemoryStack* stack = GetTraceMemoryStack();
  return stack->scope_data[stack_index];
}

/////////////////////////////////////////////////////////////////////////////

void AppendHeapProfileAsTraceFormat(const char* input, std::string* output) {
  // Heap profile output has a header total line, then a list of stacks with
  // memory totals, like this:
  //
  // heap profile:    357:    55227 [ 14653:  2624014] @ heapprofile
  //    95:    40940 [   649:   114260] @ 0x7fa7f4b3be13
  //    77:    32546 [   742:   106234] @
  //    68:     4195 [  1087:    98009] @ 0x7fa7fa9b9ba0 0x7fa7f4b3be13
  //
  // MAPPED_LIBRARIES:
  // 1be411fc1000-1be4139e4000 rw-p 00000000 00:00 0
  // 1be4139e4000-1be4139e5000 ---p 00000000 00:00 0
  // ...
  //
  // Skip input after MAPPED_LIBRARIES.
  std::string input_string;
  const char* mapped_libraries = strstr(input, "MAPPED_LIBRARIES");
  if (mapped_libraries) {
    input_string.assign(input, mapped_libraries - input);
  } else {
    input_string.assign(input);
  }

  std::vector<std::string> lines = base::SplitString(
      input_string, "\n", base::KEEP_WHITESPACE, base::SPLIT_WANT_NONEMPTY);
  if (lines.empty()) {
    DLOG(WARNING) << "No lines found";
    return;
  }

  // Handle the initial summary line.
  output->append("[");
  AppendHeapProfileTotalsAsTraceFormat(lines[0], output);

  // Handle the following stack trace lines.
  for (size_t i = 1; i < lines.size(); i++)
    AppendHeapProfileLineAsTraceFormat(lines[i], output);
  output->append("]\n");
}

void AppendHeapProfileTotalsAsTraceFormat(const std::string& line,
                                          std::string* output) {
  // This is what a line looks like:
  // heap profile:    357:    55227 [ 14653:  2624014] @ heapprofile
  //
  // The numbers represent total allocations since profiling was enabled.
  // From the example above:
  //     357 = Outstanding allocations (mallocs - frees)
  //   55227 = Outstanding bytes (malloc bytes - free bytes)
  //   14653 = Total allocations (mallocs)
  // 2624014 = Total bytes (malloc bytes)
  std::vector<std::string> tokens = base::SplitString(
      line, " :[]@", base::KEEP_WHITESPACE, base::SPLIT_WANT_NONEMPTY);
  if (tokens.size() < 4) {
    DLOG(WARNING) << "Invalid totals line " << line;
    return;
  }
  DCHECK_EQ(tokens[0], "heap");
  DCHECK_EQ(tokens[1], "profile");
  output->append("{\"current_allocs\": ");
  output->append(tokens[2]);
  output->append(", \"current_bytes\": ");
  output->append(tokens[3]);
  output->append(", \"trace\": \"\"}");
}

bool AppendHeapProfileLineAsTraceFormat(const std::string& line,
                                        std::string* output) {
  // This is what a line looks like:
  //    68:     4195 [  1087:    98009] @ 0x7fa7fa9b9ba0 0x7fa7f4b3be13
  //
  // The numbers represent allocations for a particular stack trace since
  // profiling was enabled. From the example above:
  //    68 = Outstanding allocations (mallocs - frees)
  //  4195 = Outstanding bytes (malloc bytes - free bytes)
  //  1087 = Total allocations (mallocs)
  // 98009 = Total bytes (malloc bytes)
  //
  // 0x7fa7fa9b9ba0 0x7fa7f4b3be13 = Stack trace represented as pointers to
  //                                 static strings from trace event categories
  //                                 and names.
  std::vector<std::string> tokens = base::SplitString(
      line, " :[]@", base::KEEP_WHITESPACE, base::SPLIT_WANT_NONEMPTY);
  // It's valid to have no stack addresses, so only require 4 tokens.
  if (tokens.size() < 4) {
    DLOG(WARNING) << "Invalid line " << line;
    return false;
  }
  // Don't bother with stacks that have no current allocations.
  if (tokens[0] == "0")
    return false;
  output->append(",\n");
  output->append("{\"current_allocs\": ");
  output->append(tokens[0]);
  output->append(", \"current_bytes\": ");
  output->append(tokens[1]);
  output->append(", \"trace\": \"");

  // Convert pairs of "stack addresses" into category and name strings.
  const std::string kSingleQuote = "'";
  for (size_t t = 4; t < tokens.size(); t += 2) {
    // Casting strings into pointers is ugly but otherwise tcmalloc would need
    // to gain a special output serializer just for pseudo-stacks.
    const char* trace_category = StringFromHexAddress(tokens[t]);
    DCHECK_LT(t + 1, tokens.size());
    const char* trace_name = StringFromHexAddress(tokens[t + 1]);

    // TODO(jamescook): Report the trace category and name separately to the
    // trace viewer and allow it to decide what decorations to apply. For now
    // just hard-code a decoration for posted tasks (toplevel).
    std::string trace_string(trace_name);
    if (!strcmp(trace_category, "toplevel"))
      trace_string.append("->PostTask");

    // Some trace name strings have double quotes, convert them to single.
    ReplaceChars(trace_string, "\"", kSingleQuote, &trace_string);

    output->append(trace_string);

    // Trace viewer expects a trailing space.
    output->append(" ");
  }
  output->append("\"}");
  return true;
}

const char* StringFromHexAddress(const std::string& hex_address) {
  uint64 address = 0;
  if (!base::HexStringToUInt64(hex_address, &address))
    return "error";
  if (!address)
    return "null";
  // Note that this cast handles 64-bit to 32-bit conversion if necessary.
  return reinterpret_cast<const char*>(address);
}

}  // namespace trace_event
}  // namespace base
