// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/memory_dump_manager.h"

#include <algorithm>

#include "base/atomic_sequence_num.h"
#include "base/compiler_specific.h"
#include "base/hash.h"
#include "base/thread_task_runner_handle.h"
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

// Throttle mmaps at a rate of once every kHeavyMmapsDumpsRate standard dumps.
const int kHeavyMmapsDumpsRate = 8;  // 250 ms * 8 = 2000 ms.
const int kDumpIntervalMs = 250;
const int kTraceEventNumArgs = 1;
const char* kTraceEventArgNames[] = {"dumps"};
const unsigned char kTraceEventArgTypes[] = {TRACE_VALUE_TYPE_CONVERTABLE};

StaticAtomicSequenceNumber g_next_guid;
uint32 g_periodic_dumps_count = 0;
MemoryDumpManager* g_instance_for_testing = nullptr;
MemoryDumpProvider* g_mmaps_dump_provider = nullptr;

void RequestPeriodicGlobalDump() {
  MemoryDumpType dump_type = g_periodic_dumps_count == 0
                                 ? MemoryDumpType::PERIODIC_INTERVAL_WITH_MMAPS
                                 : MemoryDumpType::PERIODIC_INTERVAL;
  if (++g_periodic_dumps_count == kHeavyMmapsDumpsRate)
    g_periodic_dumps_count = 0;

  MemoryDumpManager::GetInstance()->RequestGlobalDump(dump_type);
}

}  // namespace

// static
const char* const MemoryDumpManager::kTraceCategoryForTesting = kTraceCategory;

// static
const uint64 MemoryDumpManager::kInvalidTracingProcessId = 0;

// static
const int MemoryDumpManager::kMaxConsecutiveFailuresCount = 3;

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
    : did_unregister_dump_provider_(false),
      delegate_(nullptr),
      memory_tracing_enabled_(0),
      tracing_process_id_(kInvalidTracingProcessId),
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
  g_mmaps_dump_provider = ProcessMemoryMapsDumpProvider::GetInstance();
  RegisterDumpProvider(g_mmaps_dump_provider);
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
  MemoryDumpProviderInfo mdp_info(mdp, task_runner);
  AutoLock lock(lock_);
  dump_providers_.insert(mdp_info);
}

void MemoryDumpManager::RegisterDumpProvider(MemoryDumpProvider* mdp) {
  RegisterDumpProvider(mdp, nullptr);
}

void MemoryDumpManager::UnregisterDumpProvider(MemoryDumpProvider* mdp) {
  AutoLock lock(lock_);

  auto mdp_iter = dump_providers_.begin();
  for (; mdp_iter != dump_providers_.end(); ++mdp_iter) {
    if (mdp_iter->dump_provider == mdp)
      break;
  }

  if (mdp_iter == dump_providers_.end())
    return;

  // Unregistration of a MemoryDumpProvider while tracing is ongoing is safe
  // only if the MDP has specified a thread affinity (via task_runner()) AND
  // the unregistration happens on the same thread (so the MDP cannot unregister
  // and OnMemoryDump() at the same time).
  // Otherwise, it is not possible to guarantee that its unregistration is
  // race-free. If you hit this DCHECK, your MDP has a bug.
  DCHECK_IMPLIES(
      subtle::NoBarrier_Load(&memory_tracing_enabled_),
      mdp_iter->task_runner && mdp_iter->task_runner->BelongsToCurrentThread())
      << "The MemoryDumpProvider attempted to unregister itself in a racy way. "
      << "Please file a crbug.";

  dump_providers_.erase(mdp_iter);
  did_unregister_dump_provider_ = true;
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

void MemoryDumpManager::CreateProcessDump(const MemoryDumpRequestArgs& args,
                                          const MemoryDumpCallback& callback) {
  scoped_ptr<ProcessMemoryDumpAsyncState> pmd_async_state;
  {
    AutoLock lock(lock_);
    did_unregister_dump_provider_ = false;
    pmd_async_state.reset(new ProcessMemoryDumpAsyncState(
        args, dump_providers_.begin(), session_state_, callback));
  }

  // Start the thread hop. |dump_providers_| are kept sorted by thread, so
  // ContinueAsyncProcessDump will hop at most once per thread (w.r.t. thread
  // affinity specified by the MemoryDumpProvider(s) in RegisterDumpProvider()).
  ContinueAsyncProcessDump(pmd_async_state.Pass());
}

// At most one ContinueAsyncProcessDump() can be active at any time for a given
// PMD, regardless of status of the |lock_|. |lock_| is used here purely to
// ensure consistency w.r.t. (un)registrations of |dump_providers_|.
// The linearization of dump providers' OnMemoryDump invocations is achieved by
// means of subsequent PostTask(s).
//
// 1) Prologue:
//   - Check if the dump provider is disabled, if so skip the dump.
//   - Check if we are on the right thread. If not hop and continue there.
// 2) Invoke the dump provider's OnMemoryDump() (unless skipped).
// 3) Epilogue:
//  - Unregister the dump provider if it failed too many times consecutively.
//  - Advance the |next_dump_provider| iterator to the next dump provider.
//  - If this was the last hop, create a trace event, add it to the trace
//    and finalize (invoke callback).

void MemoryDumpManager::ContinueAsyncProcessDump(
    scoped_ptr<ProcessMemoryDumpAsyncState> pmd_async_state) {
  // Initalizes the ThreadLocalEventBuffer to guarantee that the TRACE_EVENTs
  // in the PostTask below don't end up registering their own dump providers
  // (for discounting trace memory overhead) while holding the |lock_|.
  TraceLog::GetInstance()->InitializeThreadLocalEventBufferIfSupported();

  // DO NOT put any LOG() statement in the locked sections, as in some contexts
  // (GPU process) LOG() ends up performing PostTask/IPCs.
  MemoryDumpProvider* mdp;
  bool skip_dump = false;
  {
    AutoLock lock(lock_);
    // In the unlikely event that a dump provider was unregistered while
    // dumping, abort the dump, as that would make |next_dump_provider| invalid.
    // Registration, on the other hand, is safe as per std::set<> contract.
    if (did_unregister_dump_provider_) {
      return AbortDumpLocked(pmd_async_state->callback,
                             pmd_async_state->task_runner,
                             pmd_async_state->req_args.dump_guid);
    }

    auto* mdp_info = &*pmd_async_state->next_dump_provider;
    mdp = mdp_info->dump_provider;
    if (mdp_info->disabled) {
      skip_dump = true;
    } else if (mdp == g_mmaps_dump_provider &&
               pmd_async_state->req_args.dump_type !=
                   MemoryDumpType::PERIODIC_INTERVAL_WITH_MMAPS) {
      // Mmaps dumping is very heavyweight and cannot be performed at the same
      // rate of other dumps. TODO(primiano): this is a hack and should be
      // cleaned up as part of crbug.com/499731.
      skip_dump = true;
    } else if (mdp_info->task_runner &&
               !mdp_info->task_runner->BelongsToCurrentThread()) {
      // It's time to hop onto another thread.

      // Copy the callback + arguments just for the unlikley case in which
      // PostTask fails. In such case the Bind helper will destroy the
      // pmd_async_state and we must keep a copy of the fields to notify the
      // abort.
      MemoryDumpCallback callback = pmd_async_state->callback;
      scoped_refptr<SingleThreadTaskRunner> callback_task_runner =
          pmd_async_state->task_runner;
      const uint64 dump_guid = pmd_async_state->req_args.dump_guid;

      const bool did_post_task = mdp_info->task_runner->PostTask(
          FROM_HERE, Bind(&MemoryDumpManager::ContinueAsyncProcessDump,
                          Unretained(this), Passed(pmd_async_state.Pass())));
      if (did_post_task)
        return;

      // The thread is gone. At this point the best thing we can do is to
      // disable the dump provider and abort this dump.
      mdp_info->disabled = true;
      return AbortDumpLocked(callback, callback_task_runner, dump_guid);
    }
  }  // AutoLock(lock_)

  // Invoke the dump provider without holding the |lock_|.
  bool finalize = false;
  bool dump_successful = false;
  if (!skip_dump)
    dump_successful = mdp->OnMemoryDump(&pmd_async_state->process_memory_dump);

  {
    AutoLock lock(lock_);
    if (did_unregister_dump_provider_) {
      return AbortDumpLocked(pmd_async_state->callback,
                             pmd_async_state->task_runner,
                             pmd_async_state->req_args.dump_guid);
    }
    auto* mdp_info = &*pmd_async_state->next_dump_provider;
    if (dump_successful) {
      mdp_info->consecutive_failures = 0;
    } else if (!skip_dump) {
      ++mdp_info->consecutive_failures;
      if (mdp_info->consecutive_failures >= kMaxConsecutiveFailuresCount) {
        mdp_info->disabled = true;
      }
    }
    ++pmd_async_state->next_dump_provider;
    finalize = pmd_async_state->next_dump_provider == dump_providers_.end();
  }

  if (!skip_dump && !dump_successful) {
    LOG(ERROR) << "A memory dumper failed, possibly due to sandboxing "
                  "(crbug.com/461788). Disabling dumper for current process. "
                  "Try restarting chrome with the --no-sandbox switch.";
  }

  if (finalize)
    return FinalizeDumpAndAddToTrace(pmd_async_state.Pass());

  ContinueAsyncProcessDump(pmd_async_state.Pass());
}

// static
void MemoryDumpManager::FinalizeDumpAndAddToTrace(
    scoped_ptr<ProcessMemoryDumpAsyncState> pmd_async_state) {
  if (!pmd_async_state->task_runner->BelongsToCurrentThread()) {
    scoped_refptr<SingleThreadTaskRunner> task_runner =
        pmd_async_state->task_runner;
    task_runner->PostTask(FROM_HERE,
                          Bind(&MemoryDumpManager::FinalizeDumpAndAddToTrace,
                               Passed(pmd_async_state.Pass())));
    return;
  }

  scoped_refptr<ConvertableToTraceFormat> event_value(new TracedValue());
  pmd_async_state->process_memory_dump.AsValueInto(
      static_cast<TracedValue*>(event_value.get()));
  const char* const event_name =
      MemoryDumpTypeToString(pmd_async_state->req_args.dump_type);

  TRACE_EVENT_API_ADD_TRACE_EVENT(
      TRACE_EVENT_PHASE_MEMORY_DUMP,
      TraceLog::GetCategoryGroupEnabled(kTraceCategory), event_name,
      pmd_async_state->req_args.dump_guid, kTraceEventNumArgs,
      kTraceEventArgNames, kTraceEventArgTypes, nullptr /* arg_values */,
      &event_value, TRACE_EVENT_FLAG_HAS_ID);

  if (!pmd_async_state->callback.is_null()) {
    pmd_async_state->callback.Run(pmd_async_state->req_args.dump_guid,
                                  true /* success */);
    pmd_async_state->callback.Reset();
  }
}

// static
void MemoryDumpManager::AbortDumpLocked(
    MemoryDumpCallback callback,
    scoped_refptr<SingleThreadTaskRunner> task_runner,
    uint64 dump_guid) {
  if (callback.is_null())
    return;  // There is nothing to NACK.

  // Post the callback even if we are already on the right thread to avoid
  // invoking the callback while holding the lock_.
  task_runner->PostTask(FROM_HERE,
                        Bind(callback, dump_guid, false /* success */));
}

void MemoryDumpManager::OnTraceLogEnabled() {
  // TODO(primiano): at this point we query  TraceLog::GetCurrentCategoryFilter
  // to figure out (and cache) which dumpers should be enabled or not.
  // For the moment piggy back everything on the generic "memory" category.
  bool enabled;
  TRACE_EVENT_CATEGORY_GROUP_ENABLED(kTraceCategory, &enabled);

  // Initialize the TraceLog for the current thread. This is to avoid that the
  // TraceLog memory dump provider is registered lazily in the PostTask() below
  // while the |lock_| is taken;
  TraceLog::GetInstance()->InitializeThreadLocalEventBufferIfSupported();

  AutoLock lock(lock_);

  // There is no point starting the tracing without a delegate.
  if (!enabled || !delegate_) {
    // Disable all the providers.
    for (auto it = dump_providers_.begin(); it != dump_providers_.end(); ++it)
      it->disabled = true;
    return;
  }

  session_state_ = new MemoryDumpSessionState();
  for (auto it = dump_providers_.begin(); it != dump_providers_.end(); ++it) {
    it->disabled = false;
    it->consecutive_failures = 0;
  }

  subtle::NoBarrier_Store(&memory_tracing_enabled_, 1);

  if (delegate_->IsCoordinatorProcess()) {
    g_periodic_dumps_count = 0;
    periodic_dump_timer_.Start(FROM_HERE,
                               TimeDelta::FromMilliseconds(kDumpIntervalMs),
                               base::Bind(&RequestPeriodicGlobalDump));
  }
}

void MemoryDumpManager::OnTraceLogDisabled() {
  AutoLock lock(lock_);
  periodic_dump_timer_.Stop();
  subtle::NoBarrier_Store(&memory_tracing_enabled_, 0);
  session_state_ = nullptr;
}

// static
uint64 MemoryDumpManager::ChildProcessIdToTracingProcessId(
    int child_process_id) {
  return static_cast<uint64>(
             Hash(reinterpret_cast<const char*>(&child_process_id),
                  sizeof(child_process_id))) +
         1;
}

MemoryDumpManager::MemoryDumpProviderInfo::MemoryDumpProviderInfo(
    MemoryDumpProvider* dump_provider,
    const scoped_refptr<SingleThreadTaskRunner>& task_runner)
    : dump_provider(dump_provider),
      task_runner(task_runner),
      consecutive_failures(0),
      disabled(false) {
}

MemoryDumpManager::MemoryDumpProviderInfo::~MemoryDumpProviderInfo() {
}

bool MemoryDumpManager::MemoryDumpProviderInfo::operator<(
    const MemoryDumpProviderInfo& other) const {
  if (task_runner == other.task_runner)
    return dump_provider < other.dump_provider;
  return task_runner < other.task_runner;
}

MemoryDumpManager::ProcessMemoryDumpAsyncState::ProcessMemoryDumpAsyncState(
    MemoryDumpRequestArgs req_args,
    MemoryDumpProviderInfoSet::iterator next_dump_provider,
    const scoped_refptr<MemoryDumpSessionState>& session_state,
    MemoryDumpCallback callback)
    : process_memory_dump(session_state),
      req_args(req_args),
      next_dump_provider(next_dump_provider),
      callback(callback),
      task_runner(MessageLoop::current()->task_runner()) {
}

MemoryDumpManager::ProcessMemoryDumpAsyncState::~ProcessMemoryDumpAsyncState() {
}

}  // namespace trace_event
}  // namespace base
