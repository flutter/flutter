// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/memory_dump_manager.h"

#include <algorithm>

#include "base/atomic_sequence_num.h"
#include "base/compiler_specific.h"
#include "base/trace_event/memory_dump_provider.h"
#include "base/trace_event/memory_dump_session_state.h"
#include "base/trace_event/process_memory_dump.h"
#include "base/trace_event/trace_event_argument.h"
#include "build/build_config.h"

#if !defined(OS_NACL)
#include "base/trace_event/process_memory_totals_dump_provider.h"
#endif

#if defined(OS_LINUX) || defined(OS_ANDROID)
#include "base/trace_event/malloc_dump_provider.h"
#include "base/trace_event/process_memory_maps_dump_provider.h"
#endif

#if defined(OS_ANDROID)
#include "base/trace_event/java_heap_dump_provider_android.h"
#endif

#if defined(OS_WIN)
#include "base/trace_event/winheap_dump_provider_win.h"
#endif

namespace base {
namespace trace_event {

namespace {

// TODO(primiano): this should be smarter and should do something similar to
// trace event synthetic delays.
const char kTraceCategory[] = TRACE_DISABLED_BY_DEFAULT("memory-infra");

MemoryDumpManager* g_instance_for_testing = nullptr;
const int kDumpIntervalSeconds = 2;
const int kTraceEventNumArgs = 1;
const char* kTraceEventArgNames[] = {"dumps"};
const unsigned char kTraceEventArgTypes[] = {TRACE_VALUE_TYPE_CONVERTABLE};
StaticAtomicSequenceNumber g_next_guid;

const char* MemoryDumpTypeToString(const MemoryDumpType& dump_type) {
  switch (dump_type) {
    case MemoryDumpType::TASK_BEGIN:
      return "TASK_BEGIN";
    case MemoryDumpType::TASK_END:
      return "TASK_END";
    case MemoryDumpType::PERIODIC_INTERVAL:
      return "PERIODIC_INTERVAL";
    case MemoryDumpType::EXPLICITLY_TRIGGERED:
      return "EXPLICITLY_TRIGGERED";
  }
  NOTREACHED();
  return "UNKNOWN";
}

// Internal class used to hold details about ProcessMemoryDump requests for the
// current process.
// TODO(primiano): In the upcoming CLs, ProcessMemoryDump will become async.
// and this class will be used to convey more details across PostTask()s.
class ProcessMemoryDumpHolder
    : public RefCountedThreadSafe<ProcessMemoryDumpHolder> {
 public:
  ProcessMemoryDumpHolder(
      MemoryDumpRequestArgs req_args,
      const scoped_refptr<MemoryDumpSessionState>& session_state,
      MemoryDumpCallback callback)
      : process_memory_dump(session_state),
        req_args(req_args),
        callback(callback),
        task_runner(MessageLoop::current()->task_runner()),
        num_pending_async_requests(0) {}

  ProcessMemoryDump process_memory_dump;
  const MemoryDumpRequestArgs req_args;

  // Callback passed to the initial call to CreateProcessDump().
  MemoryDumpCallback callback;

  // Thread on which FinalizeDumpAndAddToTrace() should be called, which is the
  // same that invoked the initial CreateProcessDump().
  const scoped_refptr<SingleThreadTaskRunner> task_runner;

  // Number of pending ContinueAsyncProcessDump() calls.
  int num_pending_async_requests;

 private:
  friend class RefCountedThreadSafe<ProcessMemoryDumpHolder>;
  virtual ~ProcessMemoryDumpHolder() {}
  DISALLOW_COPY_AND_ASSIGN(ProcessMemoryDumpHolder);
};

void FinalizeDumpAndAddToTrace(
    const scoped_refptr<ProcessMemoryDumpHolder>& pmd_holder) {
  DCHECK_EQ(0, pmd_holder->num_pending_async_requests);

  if (!pmd_holder->task_runner->BelongsToCurrentThread()) {
    pmd_holder->task_runner->PostTask(
        FROM_HERE, Bind(&FinalizeDumpAndAddToTrace, pmd_holder));
    return;
  }

  scoped_refptr<ConvertableToTraceFormat> event_value(new TracedValue());
  pmd_holder->process_memory_dump.AsValueInto(
      static_cast<TracedValue*>(event_value.get()));
  const char* const event_name =
      MemoryDumpTypeToString(pmd_holder->req_args.dump_type);

  TRACE_EVENT_API_ADD_TRACE_EVENT(
      TRACE_EVENT_PHASE_MEMORY_DUMP,
      TraceLog::GetCategoryGroupEnabled(kTraceCategory), event_name,
      pmd_holder->req_args.dump_guid, kTraceEventNumArgs, kTraceEventArgNames,
      kTraceEventArgTypes, nullptr /* arg_values */, &event_value,
      TRACE_EVENT_FLAG_HAS_ID);

  if (!pmd_holder->callback.is_null()) {
    pmd_holder->callback.Run(pmd_holder->req_args.dump_guid, true);
    pmd_holder->callback.Reset();
  }
}

void RequestPeriodicGlobalDump() {
  MemoryDumpManager::GetInstance()->RequestGlobalDump(
      MemoryDumpType::PERIODIC_INTERVAL);
}

}  // namespace

// static
const char* const MemoryDumpManager::kTraceCategoryForTesting = kTraceCategory;

// static
MemoryDumpManager* MemoryDumpManager::GetInstance() {
  if (g_instance_for_testing)
    return g_instance_for_testing;

  return Singleton<MemoryDumpManager,
                   LeakySingletonTraits<MemoryDumpManager>>::get();
}

// static
void MemoryDumpManager::SetInstanceForTesting(MemoryDumpManager* instance) {
  if (instance)
    instance->skip_core_dumpers_auto_registration_for_testing_ = true;
  g_instance_for_testing = instance;
}

MemoryDumpManager::MemoryDumpManager()
    : delegate_(nullptr),
      memory_tracing_enabled_(0),
      skip_core_dumpers_auto_registration_for_testing_(false) {
  g_next_guid.GetNext();  // Make sure that first guid is not zero.
}

MemoryDumpManager::~MemoryDumpManager() {
  base::trace_event::TraceLog::GetInstance()->RemoveEnabledStateObserver(this);
}

void MemoryDumpManager::Initialize() {
  TRACE_EVENT0(kTraceCategory, "init");  // Add to trace-viewer category list.
  trace_event::TraceLog::GetInstance()->AddEnabledStateObserver(this);

  if (skip_core_dumpers_auto_registration_for_testing_)
    return;

  // Enable the core dump providers.
#if !defined(OS_NACL)
  RegisterDumpProvider(ProcessMemoryTotalsDumpProvider::GetInstance());
#endif

#if defined(OS_LINUX) || defined(OS_ANDROID)
  RegisterDumpProvider(ProcessMemoryMapsDumpProvider::GetInstance());
  RegisterDumpProvider(MallocDumpProvider::GetInstance());
#endif

#if defined(OS_ANDROID)
  RegisterDumpProvider(JavaHeapDumpProvider::GetInstance());
#endif

#if defined(OS_WIN)
  RegisterDumpProvider(WinHeapDumpProvider::GetInstance());
#endif
}

void MemoryDumpManager::SetDelegate(MemoryDumpManagerDelegate* delegate) {
  AutoLock lock(lock_);
  DCHECK_EQ(static_cast<MemoryDumpManagerDelegate*>(nullptr), delegate_);
  delegate_ = delegate;
}

void MemoryDumpManager::RegisterDumpProvider(
    MemoryDumpProvider* mdp,
    const scoped_refptr<SingleThreadTaskRunner>& task_runner) {
  MemoryDumpProviderInfo mdp_info(task_runner);
  AutoLock lock(lock_);
  dump_providers_.insert(std::make_pair(mdp, mdp_info));
}

void MemoryDumpManager::RegisterDumpProvider(MemoryDumpProvider* mdp) {
  RegisterDumpProvider(mdp, nullptr);
}

void MemoryDumpManager::UnregisterDumpProvider(MemoryDumpProvider* mdp) {
  AutoLock lock(lock_);

  auto it = dump_providers_.find(mdp);
  if (it == dump_providers_.end())
    return;

  const MemoryDumpProviderInfo& mdp_info = it->second;
  // Unregistration of a MemoryDumpProvider while tracing is ongoing is safe
  // only if the MDP has specified a thread affinity (via task_runner()) AND
  // the unregistration happens on the same thread (so the MDP cannot unregister
  // and OnMemoryDump() at the same time).
  // Otherwise, it is not possible to guarantee that its unregistration is
  // race-free. If you hit this DCHECK, your MDP has a bug.
  DCHECK_IMPLIES(
      subtle::NoBarrier_Load(&memory_tracing_enabled_),
      mdp_info.task_runner && mdp_info.task_runner->BelongsToCurrentThread())
      << "The MemoryDumpProvider attempted to unregister itself in a racy way. "
      << " Please file a crbug.";

  // Remove from the enabled providers list. This is to deal with the case that
  // UnregisterDumpProvider is called while the trace is enabled.
  dump_providers_.erase(it);
}

void MemoryDumpManager::RequestGlobalDump(
    MemoryDumpType dump_type,
    const MemoryDumpCallback& callback) {
  // Bail out immediately if tracing is not enabled at all.
  if (!UNLIKELY(subtle::NoBarrier_Load(&memory_tracing_enabled_)))
    return;

  const uint64 guid =
      TraceLog::GetInstance()->MangleEventId(g_next_guid.GetNext());

  // The delegate_ is supposed to be thread safe, immutable and long lived.
  // No need to keep the lock after we ensure that a delegate has been set.
  MemoryDumpManagerDelegate* delegate;
  {
    AutoLock lock(lock_);
    delegate = delegate_;
  }

  if (delegate) {
    // The delegate is in charge to coordinate the request among all the
    // processes and call the CreateLocalDumpPoint on the local process.
    MemoryDumpRequestArgs args = {guid, dump_type};
    delegate->RequestGlobalMemoryDump(args, callback);
  } else if (!callback.is_null()) {
    callback.Run(guid, false /* success */);
  }
}

void MemoryDumpManager::RequestGlobalDump(MemoryDumpType dump_type) {
  RequestGlobalDump(dump_type, MemoryDumpCallback());
}

// Creates a memory dump for the current process and appends it to the trace.
void MemoryDumpManager::CreateProcessDump(const MemoryDumpRequestArgs& args,
                                          const MemoryDumpCallback& callback) {
  scoped_refptr<ProcessMemoryDumpHolder> pmd_holder(
      new ProcessMemoryDumpHolder(args, session_state_, callback));
  ProcessMemoryDump* pmd = &pmd_holder->process_memory_dump;
  bool did_any_provider_dump = false;

  // Iterate over the active dump providers and invoke OnMemoryDump(pmd).
  // The MDM guarantees linearity (at most one MDP is active within one
  // process) and thread-safety (MDM enforces the right locking when entering /
  // leaving the MDP.OnMemoryDump() call). This is to simplify the clients'
  // design
  // and not let the MDPs worry about locking.
  // As regards thread affinity, depending on the MDP configuration (see
  // memory_dump_provider.h), the OnMemoryDump() invocation can happen:
  //  - Synchronousy on the MDM thread, when MDP.task_runner() is not set.
  //  - Posted on MDP.task_runner(), when MDP.task_runner() is set.
  {
    AutoLock lock(lock_);
    for (auto it = dump_providers_.begin(); it != dump_providers_.end(); ++it) {
      MemoryDumpProvider* mdp = it->first;
      MemoryDumpProviderInfo* mdp_info = &it->second;
      if (mdp_info->disabled)
        continue;
      if (mdp_info->task_runner) {
        // The OnMemoryDump() call must be posted.
        bool did_post_async_task = mdp_info->task_runner->PostTask(
            FROM_HERE, Bind(&MemoryDumpManager::ContinueAsyncProcessDump,
                            Unretained(this), Unretained(mdp), pmd_holder));
        // The thread underlying the TaskRunner might have gone away.
        if (did_post_async_task)
          ++pmd_holder->num_pending_async_requests;
      } else {
        // Invoke the dump provider synchronously.
        did_any_provider_dump |= InvokeDumpProviderLocked(mdp, pmd);
      }
    }
  }  // AutoLock

  // If at least one synchronous provider did dump and there are no pending
  // asynchronous requests, add the dump to the trace and invoke the callback
  // straight away (FinalizeDumpAndAddToTrace() takes care of the callback).
  if (did_any_provider_dump && pmd_holder->num_pending_async_requests == 0)
    FinalizeDumpAndAddToTrace(pmd_holder);
}

// Invokes the MemoryDumpProvider.OnMemoryDump(), taking care of the fail-safe
// logic which disables the dumper when failing (crbug.com/461788).
bool MemoryDumpManager::InvokeDumpProviderLocked(MemoryDumpProvider* mdp,
                                                 ProcessMemoryDump* pmd) {
  lock_.AssertAcquired();
  bool dump_successful = mdp->OnMemoryDump(pmd);
  if (!dump_successful) {
    LOG(ERROR) << "The memory dumper failed, possibly due to sandboxing "
                  "(crbug.com/461788), disabling it for current process. Try "
                  "restarting chrome with the --no-sandbox switch.";
    dump_providers_.find(mdp)->second.disabled = true;
  }
  return dump_successful;
}

// This is posted to arbitrary threads as a continuation of CreateProcessDump(),
// when one or more MemoryDumpProvider(s) require the OnMemoryDump() call to
// happen on a different thread.
void MemoryDumpManager::ContinueAsyncProcessDump(
    MemoryDumpProvider* mdp,
    scoped_refptr<ProcessMemoryDumpHolder> pmd_holder) {
  bool should_finalize_dump = false;
  {
    // The lock here is to guarantee that different asynchronous dumps on
    // different threads are still serialized, so that the MemoryDumpProvider
    // has a consistent view of the |pmd| argument passed.
    AutoLock lock(lock_);
    ProcessMemoryDump* pmd = &pmd_holder->process_memory_dump;

    // Check if the MemoryDumpProvider is still there. It might have been
    // destroyed and unregistered while hopping threads.
    if (dump_providers_.count(mdp))
      InvokeDumpProviderLocked(mdp, pmd);

    // Finalize the dump appending it to the trace if this was the last
    // asynchronous request pending.
    --pmd_holder->num_pending_async_requests;
    if (pmd_holder->num_pending_async_requests == 0)
      should_finalize_dump = true;
  }  // AutoLock(lock_)

  if (should_finalize_dump)
    FinalizeDumpAndAddToTrace(pmd_holder);
}

void MemoryDumpManager::OnTraceLogEnabled() {
  // TODO(primiano): at this point we query  TraceLog::GetCurrentCategoryFilter
  // to figure out (and cache) which dumpers should be enabled or not.
  // For the moment piggy back everything on the generic "memory" category.
  bool enabled;
  TRACE_EVENT_CATEGORY_GROUP_ENABLED(kTraceCategory, &enabled);

  AutoLock lock(lock_);

  // There is no point starting the tracing without a delegate.
  if (!enabled || !delegate_) {
    // Disable all the providers.
    for (auto it = dump_providers_.begin(); it != dump_providers_.end(); ++it)
      it->second.disabled = true;
    return;
  }

  session_state_ = new MemoryDumpSessionState();
  for (auto it = dump_providers_.begin(); it != dump_providers_.end(); ++it)
    it->second.disabled = false;

  subtle::NoBarrier_Store(&memory_tracing_enabled_, 1);

  if (delegate_->IsCoordinatorProcess()) {
    periodic_dump_timer_.Start(FROM_HERE,
                               TimeDelta::FromSeconds(kDumpIntervalSeconds),
                               base::Bind(&RequestPeriodicGlobalDump));
  }
}

void MemoryDumpManager::OnTraceLogDisabled() {
  AutoLock lock(lock_);
  periodic_dump_timer_.Stop();
  subtle::NoBarrier_Store(&memory_tracing_enabled_, 0);
  session_state_ = nullptr;
}

MemoryDumpManager::MemoryDumpProviderInfo::MemoryDumpProviderInfo(
    const scoped_refptr<SingleThreadTaskRunner>& task_runner)
    : task_runner(task_runner), disabled(false) {
}
MemoryDumpManager::MemoryDumpProviderInfo::~MemoryDumpProviderInfo() {
}

}  // namespace trace_event
}  // namespace base
