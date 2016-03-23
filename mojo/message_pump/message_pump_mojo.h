// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_MESSAGE_PUMP_MESSAGE_PUMP_MOJO_H_
#define MOJO_MESSAGE_PUMP_MESSAGE_PUMP_MOJO_H_

#include <map>
#include <utility>
#include <vector>

#include "base/macros.h"
#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_pump.h"
#include "base/observer_list.h"
#include "base/synchronization/lock.h"
#include "base/time/time.h"
#include "mojo/public/c/system/result.h"
#include "mojo/public/c/system/time.h"
#include "mojo/public/cpp/system/handle.h"

namespace mojo {
namespace common {

class MessagePumpMojoHandler;

// Mojo implementation of MessagePump.
class MessagePumpMojo : public base::MessagePump {
 public:
  class Observer {
   public:
    Observer() {}

    virtual void WillSignalHandler() = 0;
    virtual void DidSignalHandler() = 0;

   protected:
    virtual ~Observer() {}
  };

  MessagePumpMojo();
  ~MessagePumpMojo() override;

  // Static factory function (for using with |base::Thread::Options|, wrapped
  // using |base::Bind()|).
  static scoped_ptr<base::MessagePump> Create();

  // Returns the MessagePumpMojo instance of the current thread, if it exists.
  static MessagePumpMojo* current();

  static bool IsCurrent() { return !!current(); }

  // Registers a MessagePumpMojoHandler for the specified handle. Only one
  // handler can be registered for a specified handle.
  // NOTE: a value of 0 for |deadline| indicates an indefinite timeout.
  void AddHandler(MessagePumpMojoHandler* handler,
                  const Handle& handle,
                  MojoHandleSignals wait_signals,
                  base::TimeTicks deadline);

  void RemoveHandler(const Handle& handle);

  void AddObserver(Observer* observer);
  void RemoveObserver(Observer* observer);

  // MessagePump:
  void Run(Delegate* delegate) override;
  void Quit() override;
  void ScheduleWork() override;
  void ScheduleDelayedWork(const base::TimeTicks& delayed_work_time) override;

 private:
  struct RunState;
  struct WaitState;

  // Contains the data needed to track a request to AddHandler().
  struct Handler {
    Handler() : handler(NULL), wait_signals(MOJO_HANDLE_SIGNAL_NONE), id(0) {}

    MessagePumpMojoHandler* handler;
    MojoHandleSignals wait_signals;
    base::TimeTicks deadline;
    // See description of |MessagePumpMojo::next_handler_id_| for details.
    int id;
  };

  typedef std::map<Handle, Handler> HandleToHandler;
  typedef std::vector<std::pair<Handle, Handler>> HandleToHandlerList;

  // Implementation of Run().
  void DoRunLoop(RunState* run_state, Delegate* delegate);

  // Services the set of handles ready. If |block| is true this waits for a
  // handle to become ready, otherwise this does not block. Returns |true| if a
  // handle has become ready, |false| otherwise.
  bool DoInternalWork(const RunState& run_state, bool block);

  // Removes the given invalid handle. This is called if MojoWaitMany finds an
  // invalid handle.
  void RemoveInvalidHandle(const WaitState& wait_state,
                           MojoResult result,
                           uint32_t result_index);

  void SignalControlPipe(const RunState& run_state);

  void GetWaitState(const RunState& run_state, WaitState* wait_state) const;

  // Returns the deadline for the call to MojoWaitMany().
  MojoDeadline GetDeadlineForWait(const RunState& run_state) const;

  void WillSignalHandler();
  void DidSignalHandler();

  // If non-NULL we're running (inside Run()). Member is reference to value on
  // stack.
  RunState* run_state_;

  // Lock for accessing |run_state_|. In general the only method that we have to
  // worry about is ScheduleWork(). All other methods are invoked on the same
  // thread.
  base::Lock run_state_lock_;

  HandleToHandler handlers_;

  // An ever increasing value assigned to each Handler::id. Used to detect
  // uniqueness while notifying. That is, while notifying expired timers we copy
  // |handlers_| and only notify handlers whose id match. If the id does not
  // match it means the handler was removed then added so that we shouldn't
  // notify it.
  int next_handler_id_;

  base::ObserverList<Observer> observers_;

  DISALLOW_COPY_AND_ASSIGN(MessagePumpMojo);
};

}  // namespace common
}  // namespace mojo

#endif  // MOJO_MESSAGE_PUMP_MESSAGE_PUMP_MOJO_H_
