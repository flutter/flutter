// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/message_pump/handle_watcher.h"

#include <map>

#include "base/atomic_sequence_num.h"
#include "base/bind.h"
#include "base/logging.h"
#include "base/macros.h"
#include "base/memory/singleton.h"
#include "base/memory/weak_ptr.h"
#include "base/message_loop/message_loop.h"
#include "base/synchronization/lock.h"
#include "base/synchronization/waitable_event.h"
#include "base/thread_task_runner_handle.h"
#include "base/threading/thread.h"
#include "base/threading/thread_restrictions.h"
#include "base/time/time.h"
#include "mojo/message_pump/message_pump_mojo.h"
#include "mojo/message_pump/message_pump_mojo_handler.h"
#include "mojo/message_pump/time_helper.h"

namespace mojo {
namespace common {

typedef int WatcherID;

namespace {

const char kWatcherThreadName[] = "handle-watcher-thread";

base::TimeTicks MojoDeadlineToTimeTicks(MojoDeadline deadline) {
  return deadline == MOJO_DEADLINE_INDEFINITE ? base::TimeTicks() :
      internal::NowTicks() + base::TimeDelta::FromMicroseconds(deadline);
}

// Tracks the data for a single call to Start().
struct WatchData {
  WatchData()
      : id(0),
        handle_signals(MOJO_HANDLE_SIGNAL_NONE),
        task_runner(NULL) {}

  WatcherID id;
  Handle handle;
  MojoHandleSignals handle_signals;
  base::TimeTicks deadline;
  base::Callback<void(MojoResult)> callback;
  scoped_refptr<base::SingleThreadTaskRunner> task_runner;
};

// WatcherBackend --------------------------------------------------------------

// WatcherBackend is responsible for managing the requests and interacting with
// MessagePumpMojo. All access (outside of creation/destruction) is done on the
// thread WatcherThreadManager creates.
class WatcherBackend : public MessagePumpMojoHandler {
 public:
  WatcherBackend();
  ~WatcherBackend() override;

  void StartWatching(const WatchData& data);

  // Cancels a previously scheduled request to start a watch.
  void StopWatching(WatcherID watcher_id);

 private:
  typedef std::map<Handle, WatchData> HandleToWatchDataMap;

  // Invoked when a handle needs to be removed and notified.
  void RemoveAndNotify(const Handle& handle, MojoResult result);

  // Searches through |handle_to_data_| for |watcher_id|. Returns true if found
  // and sets |handle| to the Handle. Returns false if not a known id.
  bool GetMojoHandleByWatcherID(WatcherID watcher_id, Handle* handle) const;

  // MessagePumpMojoHandler overrides:
  void OnHandleReady(const Handle& handle) override;
  void OnHandleError(const Handle& handle, MojoResult result) override;

  // Maps from assigned id to WatchData.
  HandleToWatchDataMap handle_to_data_;

  DISALLOW_COPY_AND_ASSIGN(WatcherBackend);
};

WatcherBackend::WatcherBackend() {
}

WatcherBackend::~WatcherBackend() {
}

void WatcherBackend::StartWatching(const WatchData& data) {
  RemoveAndNotify(data.handle, MOJO_RESULT_CANCELLED);

  DCHECK_EQ(0u, handle_to_data_.count(data.handle));

  handle_to_data_[data.handle] = data;
  MessagePumpMojo::current()->AddHandler(this, data.handle,
                                         data.handle_signals,
                                         data.deadline);
}

void WatcherBackend::StopWatching(WatcherID watcher_id) {
  // Because of the thread hop it is entirely possible to get here and not
  // have a valid handle registered for |watcher_id|.
  Handle handle;
  if (GetMojoHandleByWatcherID(watcher_id, &handle)) {
    handle_to_data_.erase(handle);
    MessagePumpMojo::current()->RemoveHandler(handle);
  }
}

void WatcherBackend::RemoveAndNotify(const Handle& handle,
                                     MojoResult result) {
  if (handle_to_data_.count(handle) == 0)
    return;

  const WatchData data(handle_to_data_[handle]);
  handle_to_data_.erase(handle);
  MessagePumpMojo::current()->RemoveHandler(handle);
  data.task_runner->PostTask(FROM_HERE, base::Bind(data.callback, result));
}

bool WatcherBackend::GetMojoHandleByWatcherID(WatcherID watcher_id,
                                              Handle* handle) const {
  for (HandleToWatchDataMap::const_iterator i = handle_to_data_.begin();
       i != handle_to_data_.end(); ++i) {
    if (i->second.id == watcher_id) {
      *handle = i->second.handle;
      return true;
    }
  }
  return false;
}

void WatcherBackend::OnHandleReady(const Handle& handle) {
  RemoveAndNotify(handle, MOJO_RESULT_OK);
}

void WatcherBackend::OnHandleError(const Handle& handle, MojoResult result) {
  RemoveAndNotify(handle, result);
}

// WatcherThreadManager --------------------------------------------------------

// WatcherThreadManager manages the background thread that listens for handles
// to be ready. All requests are handled by WatcherBackend.
}  // namespace

class WatcherThreadManager {
 public:
  ~WatcherThreadManager();

  // Returns the shared instance.
  static WatcherThreadManager* GetInstance();

  // Starts watching the requested handle. Returns a unique ID that is used to
  // stop watching the handle. When the handle is ready |callback| is notified
  // on the thread StartWatching() was invoked on.
  // This may be invoked on any thread.
  WatcherID StartWatching(const Handle& handle,
                          MojoHandleSignals handle_signals,
                          base::TimeTicks deadline,
                          const base::Callback<void(MojoResult)>& callback);

  // Stops watching a handle.
  // This may be invoked on any thread.
  void StopWatching(WatcherID watcher_id);

 private:
  enum RequestType {
    REQUEST_START,
    REQUEST_STOP,
  };

  // See description of |requests_| for details.
  struct RequestData {
    RequestData() : type(REQUEST_START), stop_id(0), stop_event(NULL) {}

    RequestType type;
    WatchData start_data;
    WatcherID stop_id;
    base::WaitableEvent* stop_event;
  };

  typedef std::vector<RequestData> Requests;

  friend struct DefaultSingletonTraits<WatcherThreadManager>;

  WatcherThreadManager();

  // Schedules a request on the background thread. See |requests_| for details.
  void AddRequest(const RequestData& data);

  // Processes requests added to |requests_|. This is invoked on the backend
  // thread.
  void ProcessRequestsOnBackendThread();

  base::Thread thread_;

  base::AtomicSequenceNumber watcher_id_generator_;

  WatcherBackend backend_;

  // Protects |requests_|.
  base::Lock lock_;

  // Start/Stop result in adding a RequestData to |requests_| (protected by
  // |lock_|). When the background thread wakes up it processes the requests.
  Requests requests_;

  DISALLOW_COPY_AND_ASSIGN(WatcherThreadManager);
};

WatcherThreadManager::~WatcherThreadManager() {
  thread_.Stop();
}

WatcherThreadManager* WatcherThreadManager::GetInstance() {
  return Singleton<WatcherThreadManager>::get();
}

WatcherID WatcherThreadManager::StartWatching(
    const Handle& handle,
    MojoHandleSignals handle_signals,
    base::TimeTicks deadline,
    const base::Callback<void(MojoResult)>& callback) {
  RequestData request_data;
  request_data.type = REQUEST_START;
  request_data.start_data.id = watcher_id_generator_.GetNext();
  request_data.start_data.handle = handle;
  request_data.start_data.callback = callback;
  request_data.start_data.handle_signals = handle_signals;
  request_data.start_data.deadline = deadline;
  request_data.start_data.task_runner = base::ThreadTaskRunnerHandle::Get();
  AddRequest(request_data);
  return request_data.start_data.id;
}

void WatcherThreadManager::StopWatching(WatcherID watcher_id) {
  // Handle the case of StartWatching() followed by StopWatching() before
  // |thread_| woke up.
  {
    base::AutoLock auto_lock(lock_);
    for (Requests::iterator i = requests_.begin(); i != requests_.end(); ++i) {
      if (i->type == REQUEST_START && i->start_data.id == watcher_id) {
        // Watcher ids are not reused, so if we find it we can stop.
        requests_.erase(i);
        return;
      }
    }
  }

  base::ThreadRestrictions::ScopedAllowWait allow_wait;
  base::WaitableEvent event(true, false);
  RequestData request_data;
  request_data.type = REQUEST_STOP;
  request_data.stop_id = watcher_id;
  request_data.stop_event = &event;
  AddRequest(request_data);

  // We need to block until the handle is actually removed.
  event.Wait();
}

void WatcherThreadManager::AddRequest(const RequestData& data) {
  {
    base::AutoLock auto_lock(lock_);
    const bool was_empty = requests_.empty();
    requests_.push_back(data);
    if (!was_empty)
      return;
  }
  // We own |thread_|, so it's safe to use Unretained() here.
  thread_.task_runner()->PostTask(
      FROM_HERE,
      base::Bind(&WatcherThreadManager::ProcessRequestsOnBackendThread,
                 base::Unretained(this)));
}

void WatcherThreadManager::ProcessRequestsOnBackendThread() {
  DCHECK_EQ(thread_.message_loop(), base::MessageLoop::current());

  Requests requests;
  {
    base::AutoLock auto_lock(lock_);
    requests_.swap(requests);
  }
  for (size_t i = 0; i < requests.size(); ++i) {
    if (requests[i].type == REQUEST_START) {
      backend_.StartWatching(requests[i].start_data);
    } else {
      backend_.StopWatching(requests[i].stop_id);
      requests[i].stop_event->Signal();
    }
  }
}

WatcherThreadManager::WatcherThreadManager()
    : thread_(kWatcherThreadName) {
  base::Thread::Options thread_options;
  thread_options.message_pump_factory = base::Bind(&MessagePumpMojo::Create);
  thread_.StartWithOptions(thread_options);
}

// HandleWatcher::StateBase and subclasses -------------------------------------

// The base class of HandleWatcher's state. Owns the user's callback and
// monitors the current thread's MessageLoop to know when to force the callback
// to run (with an error) even though the pipe hasn't been signaled yet.
class HandleWatcher::StateBase : public base::MessageLoop::DestructionObserver {
 public:
  StateBase(HandleWatcher* watcher,
            const base::Callback<void(MojoResult)>& callback)
      : watcher_(watcher),
        callback_(callback),
        got_ready_(false) {
    base::MessageLoop::current()->AddDestructionObserver(this);
  }

  ~StateBase() override {
    base::MessageLoop::current()->RemoveDestructionObserver(this);
  }

 protected:
  void NotifyHandleReady(MojoResult result) {
    got_ready_ = true;
    NotifyAndDestroy(result);
  }

  bool got_ready() const { return got_ready_; }

 private:
  void WillDestroyCurrentMessageLoop() override {
    // The current thread is exiting. Simulate a watch error.
    NotifyAndDestroy(MOJO_RESULT_ABORTED);
  }

  void NotifyAndDestroy(MojoResult result) {
    base::Callback<void(MojoResult)> callback = callback_;
    watcher_->Stop();  // Destroys |this|.

    callback.Run(result);
  }

  HandleWatcher* watcher_;
  base::Callback<void(MojoResult)> callback_;

  // Have we been notified that the handle is ready?
  bool got_ready_;

  DISALLOW_COPY_AND_ASSIGN(StateBase);
};

// If the thread on which HandleWatcher is used runs MessagePumpMojo,
// SameThreadWatchingState is used to directly watch the handle on the same
// thread.
class HandleWatcher::SameThreadWatchingState : public StateBase,
                                               public MessagePumpMojoHandler {
 public:
  SameThreadWatchingState(HandleWatcher* watcher,
                          const Handle& handle,
                          MojoHandleSignals handle_signals,
                          MojoDeadline deadline,
                          const base::Callback<void(MojoResult)>& callback)
      : StateBase(watcher, callback),
        handle_(handle) {
    DCHECK(MessagePumpMojo::IsCurrent());

    MessagePumpMojo::current()->AddHandler(
        this, handle, handle_signals, MojoDeadlineToTimeTicks(deadline));
  }

  ~SameThreadWatchingState() override {
    if (!got_ready())
      MessagePumpMojo::current()->RemoveHandler(handle_);
  }

 private:
  // MessagePumpMojoHandler overrides:
  void OnHandleReady(const Handle& handle) override {
    StopWatchingAndNotifyReady(handle, MOJO_RESULT_OK);
  }

  void OnHandleError(const Handle& handle, MojoResult result) override {
    StopWatchingAndNotifyReady(handle, result);
  }

  void StopWatchingAndNotifyReady(const Handle& handle, MojoResult result) {
    DCHECK_EQ(handle.value(), handle_.value());
    MessagePumpMojo::current()->RemoveHandler(handle_);
    NotifyHandleReady(result);
  }

  Handle handle_;

  DISALLOW_COPY_AND_ASSIGN(SameThreadWatchingState);
};

// If the thread on which HandleWatcher is used runs a message pump different
// from MessagePumpMojo, SecondaryThreadWatchingState is used to watch the
// handle on the handle watcher thread.
class HandleWatcher::SecondaryThreadWatchingState : public StateBase {
 public:
  SecondaryThreadWatchingState(HandleWatcher* watcher,
                               const Handle& handle,
                               MojoHandleSignals handle_signals,
                               MojoDeadline deadline,
                               const base::Callback<void(MojoResult)>& callback)
      : StateBase(watcher, callback),
        weak_factory_(this) {
    watcher_id_ = WatcherThreadManager::GetInstance()->StartWatching(
        handle,
        handle_signals,
        MojoDeadlineToTimeTicks(deadline),
        base::Bind(&SecondaryThreadWatchingState::NotifyHandleReady,
                   weak_factory_.GetWeakPtr()));
  }

  ~SecondaryThreadWatchingState() override {
    // If we've been notified the handle is ready (|got_ready()| is true) then
    // the watch has been implicitly removed by
    // WatcherThreadManager/MessagePumpMojo and we don't have to call
    // StopWatching(). To do so would needlessly entail posting a task and
    // blocking until the background thread services it.
    if (!got_ready())
      WatcherThreadManager::GetInstance()->StopWatching(watcher_id_);
  }

 private:
  WatcherID watcher_id_;

  // Used to weakly bind |this| to the WatcherThreadManager.
  base::WeakPtrFactory<SecondaryThreadWatchingState> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(SecondaryThreadWatchingState);
};

// HandleWatcher ---------------------------------------------------------------

HandleWatcher::HandleWatcher() {
}

HandleWatcher::~HandleWatcher() {
}

void HandleWatcher::Start(const Handle& handle,
                          MojoHandleSignals handle_signals,
                          MojoDeadline deadline,
                          const base::Callback<void(MojoResult)>& callback) {
  DCHECK(handle.is_valid());
  DCHECK_NE(MOJO_HANDLE_SIGNAL_NONE, handle_signals);

  // Need to clear the state before creating a new one.
  state_.reset();
  if (MessagePumpMojo::IsCurrent()) {
    state_.reset(new SameThreadWatchingState(
        this, handle, handle_signals, deadline, callback));
  } else {
    state_.reset(new SecondaryThreadWatchingState(
        this, handle, handle_signals, deadline, callback));
  }
}

void HandleWatcher::Stop() {
  state_.reset();
}

}  // namespace common
}  // namespace mojo
