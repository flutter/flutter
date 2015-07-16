// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/platform/platform_event_source.h"

#include "base/bind.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/scoped_vector.h"
#include "base/message_loop/message_loop.h"
#include "base/run_loop.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/events/platform/platform_event_dispatcher.h"
#include "ui/events/platform/platform_event_observer.h"
#include "ui/events/platform/scoped_event_dispatcher.h"

namespace ui {

namespace {

scoped_ptr<PlatformEvent> CreatePlatformEvent() {
  scoped_ptr<PlatformEvent> event(new PlatformEvent());
  memset(event.get(), 0, sizeof(PlatformEvent));
  return event.Pass();
}

template <typename T>
void DestroyScopedPtr(scoped_ptr<T> object) {}

void RemoveDispatcher(PlatformEventDispatcher* dispatcher) {
  PlatformEventSource::GetInstance()->RemovePlatformEventDispatcher(dispatcher);
}

void RemoveDispatchers(PlatformEventDispatcher* first,
                       PlatformEventDispatcher* second) {
  PlatformEventSource::GetInstance()->RemovePlatformEventDispatcher(first);
  PlatformEventSource::GetInstance()->RemovePlatformEventDispatcher(second);
}

void AddDispatcher(PlatformEventDispatcher* dispatcher) {
  PlatformEventSource::GetInstance()->AddPlatformEventDispatcher(dispatcher);
}

}  // namespace

class TestPlatformEventSource : public PlatformEventSource {
 public:
  TestPlatformEventSource()
      : stop_stream_(false) {
  }
  ~TestPlatformEventSource() override {}

  uint32_t Dispatch(const PlatformEvent& event) { return DispatchEvent(event); }

  // Dispatches the stream of events, and returns the number of events that are
  // dispatched before it is requested to stop.
  size_t DispatchEventStream(const ScopedVector<PlatformEvent>& events) {
    stop_stream_ = false;
    for (size_t count = 0; count < events.size(); ++count) {
      DispatchEvent(*events[count]);
      if (stop_stream_)
        return count + 1;
    }
    return events.size();
  }

  // PlatformEventSource:
  void StopCurrentEventStream() override {
    stop_stream_ = true;
  }

 private:
  bool stop_stream_;
  DISALLOW_COPY_AND_ASSIGN(TestPlatformEventSource);
};

class TestPlatformEventDispatcher : public PlatformEventDispatcher {
 public:
  TestPlatformEventDispatcher(int id, std::vector<int>* list)
      : id_(id),
        list_(list),
        post_dispatch_action_(POST_DISPATCH_NONE),
        stop_stream_(false) {
    PlatformEventSource::GetInstance()->AddPlatformEventDispatcher(this);
  }
  ~TestPlatformEventDispatcher() override {
    PlatformEventSource::GetInstance()->RemovePlatformEventDispatcher(this);
  }

  void set_post_dispatch_action(uint32_t action) {
    post_dispatch_action_ = action;
  }

 protected:
  // PlatformEventDispatcher:
  bool CanDispatchEvent(const PlatformEvent& event) override {
    return true;
  }

  uint32_t DispatchEvent(const PlatformEvent& event) override {
    list_->push_back(id_);
    return post_dispatch_action_;
  }

 private:
  int id_;
  std::vector<int>* list_;
  uint32_t post_dispatch_action_;
  bool stop_stream_;

  DISALLOW_COPY_AND_ASSIGN(TestPlatformEventDispatcher);
};

class TestPlatformEventObserver : public PlatformEventObserver {
 public:
  TestPlatformEventObserver(int id, std::vector<int>* list)
      : id_(id), list_(list) {
    PlatformEventSource::GetInstance()->AddPlatformEventObserver(this);
  }
  ~TestPlatformEventObserver() override {
    PlatformEventSource::GetInstance()->RemovePlatformEventObserver(this);
  }

 protected:
  // PlatformEventObserver:
  void WillProcessEvent(const PlatformEvent& event) override {
    list_->push_back(id_);
  }

  void DidProcessEvent(const PlatformEvent& event) override {}

 private:
  int id_;
  std::vector<int>* list_;

  DISALLOW_COPY_AND_ASSIGN(TestPlatformEventObserver);
};

class PlatformEventTest : public testing::Test {
 public:
  PlatformEventTest() {}
  ~PlatformEventTest() override {}

  TestPlatformEventSource* source() { return source_.get(); }

 protected:
  // testing::Test:
  void SetUp() override {
    source_.reset(new TestPlatformEventSource());
  }

 private:
  scoped_ptr<TestPlatformEventSource> source_;

  DISALLOW_COPY_AND_ASSIGN(PlatformEventTest);
};

// Tests that a dispatcher receives an event.
TEST_F(PlatformEventTest, DispatcherBasic) {
  std::vector<int> list_dispatcher;
  scoped_ptr<PlatformEvent> event(CreatePlatformEvent());
  source()->Dispatch(*event);
  EXPECT_EQ(0u, list_dispatcher.size());
  {
    TestPlatformEventDispatcher dispatcher(1, &list_dispatcher);

    scoped_ptr<PlatformEvent> event(CreatePlatformEvent());
    source()->Dispatch(*event);
    ASSERT_EQ(1u, list_dispatcher.size());
    EXPECT_EQ(1, list_dispatcher[0]);
  }

  list_dispatcher.clear();
  event = CreatePlatformEvent();
  source()->Dispatch(*event);
  EXPECT_EQ(0u, list_dispatcher.size());
}

// Tests that dispatchers receive events in the correct order.
TEST_F(PlatformEventTest, DispatcherOrder) {
  std::vector<int> list_dispatcher;
  int sequence[] = {21, 3, 6, 45};
  ScopedVector<TestPlatformEventDispatcher> dispatchers;
  for (size_t i = 0; i < arraysize(sequence); ++i) {
    dispatchers.push_back(
        new TestPlatformEventDispatcher(sequence[i], &list_dispatcher));
  }
  scoped_ptr<PlatformEvent> event(CreatePlatformEvent());
  source()->Dispatch(*event);
  ASSERT_EQ(arraysize(sequence), list_dispatcher.size());
  EXPECT_EQ(std::vector<int>(sequence, sequence + arraysize(sequence)),
            list_dispatcher);
}

// Tests that if a dispatcher consumes the event, the subsequent dispatchers do
// not receive the event.
TEST_F(PlatformEventTest, DispatcherConsumesEventToStopDispatch) {
  std::vector<int> list_dispatcher;
  TestPlatformEventDispatcher first(12, &list_dispatcher);
  TestPlatformEventDispatcher second(23, &list_dispatcher);

  scoped_ptr<PlatformEvent> event(CreatePlatformEvent());
  source()->Dispatch(*event);
  ASSERT_EQ(2u, list_dispatcher.size());
  EXPECT_EQ(12, list_dispatcher[0]);
  EXPECT_EQ(23, list_dispatcher[1]);
  list_dispatcher.clear();

  first.set_post_dispatch_action(POST_DISPATCH_STOP_PROPAGATION);
  event = CreatePlatformEvent();
  source()->Dispatch(*event);
  ASSERT_EQ(1u, list_dispatcher.size());
  EXPECT_EQ(12, list_dispatcher[0]);
}

// Tests that observers receive events.
TEST_F(PlatformEventTest, ObserverBasic) {
  std::vector<int> list_observer;
  scoped_ptr<PlatformEvent> event(CreatePlatformEvent());
  source()->Dispatch(*event);
  EXPECT_EQ(0u, list_observer.size());
  {
    TestPlatformEventObserver observer(31, &list_observer);

    scoped_ptr<PlatformEvent> event(CreatePlatformEvent());
    source()->Dispatch(*event);
    ASSERT_EQ(1u, list_observer.size());
    EXPECT_EQ(31, list_observer[0]);
  }

  list_observer.clear();
  event = CreatePlatformEvent();
  source()->Dispatch(*event);
  EXPECT_EQ(0u, list_observer.size());
}

// Tests that observers receive events in the correct order.
TEST_F(PlatformEventTest, ObserverOrder) {
  std::vector<int> list_observer;
  const int sequence[] = {21, 3, 6, 45};
  ScopedVector<TestPlatformEventObserver> observers;
  for (size_t i = 0; i < arraysize(sequence); ++i) {
    observers.push_back(
        new TestPlatformEventObserver(sequence[i], &list_observer));
  }
  scoped_ptr<PlatformEvent> event(CreatePlatformEvent());
  source()->Dispatch(*event);
  ASSERT_EQ(arraysize(sequence), list_observer.size());
  EXPECT_EQ(std::vector<int>(sequence, sequence + arraysize(sequence)),
            list_observer);
}

// Tests that observers and dispatchers receive events in the correct order.
TEST_F(PlatformEventTest, DispatcherAndObserverOrder) {
  std::vector<int> list;
  TestPlatformEventDispatcher first_d(12, &list);
  TestPlatformEventObserver first_o(10, &list);
  TestPlatformEventDispatcher second_d(23, &list);
  TestPlatformEventObserver second_o(20, &list);
  scoped_ptr<PlatformEvent> event(CreatePlatformEvent());
  source()->Dispatch(*event);
  const int expected[] = {10, 20, 12, 23};
  EXPECT_EQ(std::vector<int>(expected, expected + arraysize(expected)), list);
}

// Tests that an overridden dispatcher receives events before the default
// dispatchers.
TEST_F(PlatformEventTest, OverriddenDispatcherBasic) {
  std::vector<int> list;
  TestPlatformEventDispatcher dispatcher(10, &list);
  TestPlatformEventObserver observer(15, &list);
  scoped_ptr<PlatformEvent> event(CreatePlatformEvent());
  source()->Dispatch(*event);
  ASSERT_EQ(2u, list.size());
  EXPECT_EQ(15, list[0]);
  EXPECT_EQ(10, list[1]);
  list.clear();

  TestPlatformEventDispatcher overriding_dispatcher(20, &list);
  source()->RemovePlatformEventDispatcher(&overriding_dispatcher);
  scoped_ptr<ScopedEventDispatcher> handle =
      source()->OverrideDispatcher(&overriding_dispatcher);
  source()->Dispatch(*event);
  ASSERT_EQ(2u, list.size());
  EXPECT_EQ(15, list[0]);
  EXPECT_EQ(20, list[1]);
}

// Tests that an overridden dispatcher can request that the default dispatchers
// can dispatch the events.
TEST_F(PlatformEventTest, OverriddenDispatcherInvokeDefaultDispatcher) {
  std::vector<int> list;
  TestPlatformEventDispatcher dispatcher(10, &list);
  TestPlatformEventObserver observer(15, &list);
  TestPlatformEventDispatcher overriding_dispatcher(20, &list);
  source()->RemovePlatformEventDispatcher(&overriding_dispatcher);
  scoped_ptr<ScopedEventDispatcher> handle =
      source()->OverrideDispatcher(&overriding_dispatcher);
  overriding_dispatcher.set_post_dispatch_action(POST_DISPATCH_PERFORM_DEFAULT);

  scoped_ptr<PlatformEvent> event(CreatePlatformEvent());
  source()->Dispatch(*event);
  // First the observer, then the overriding dispatcher, then the default
  // dispatcher.
  ASSERT_EQ(3u, list.size());
  EXPECT_EQ(15, list[0]);
  EXPECT_EQ(20, list[1]);
  EXPECT_EQ(10, list[2]);
  list.clear();

  // Install a second overriding dispatcher.
  TestPlatformEventDispatcher second_overriding(50, &list);
  source()->RemovePlatformEventDispatcher(&second_overriding);
  scoped_ptr<ScopedEventDispatcher> second_override_handle =
      source()->OverrideDispatcher(&second_overriding);
  source()->Dispatch(*event);
  ASSERT_EQ(2u, list.size());
  EXPECT_EQ(15, list[0]);
  EXPECT_EQ(50, list[1]);
  list.clear();

  second_overriding.set_post_dispatch_action(POST_DISPATCH_PERFORM_DEFAULT);
  source()->Dispatch(*event);
  // First the observer, then the second overriding dispatcher, then the default
  // dispatcher.
  ASSERT_EQ(3u, list.size());
  EXPECT_EQ(15, list[0]);
  EXPECT_EQ(50, list[1]);
  EXPECT_EQ(10, list[2]);
}

// Runs a callback during an event dispatch.
class RunCallbackDuringDispatch : public TestPlatformEventDispatcher {
 public:
  RunCallbackDuringDispatch(int id, std::vector<int>* list)
      : TestPlatformEventDispatcher(id, list) {}
  ~RunCallbackDuringDispatch() override {}

  void set_callback(const base::Closure& callback) {
    callback_ = callback;
  }

 protected:
  // PlatformEventDispatcher:
  uint32_t DispatchEvent(const PlatformEvent& event) override {
    if (!callback_.is_null())
      callback_.Run();
    return TestPlatformEventDispatcher::DispatchEvent(event);
  }

 private:
  base::Closure callback_;

  DISALLOW_COPY_AND_ASSIGN(RunCallbackDuringDispatch);
};

// Test that if a dispatcher removes another dispatcher that is later in the
// dispatcher list during dispatching an event, then event dispatching still
// continues correctly.
TEST_F(PlatformEventTest, DispatcherRemovesNextDispatcherDuringDispatch) {
  std::vector<int> list;
  TestPlatformEventDispatcher first(10, &list);
  RunCallbackDuringDispatch second(15, &list);
  TestPlatformEventDispatcher third(20, &list);
  TestPlatformEventDispatcher fourth(30, &list);

  second.set_callback(base::Bind(&RemoveDispatcher, base::Unretained(&third)));

  scoped_ptr<PlatformEvent> event(CreatePlatformEvent());
  source()->Dispatch(*event);
  // |second| removes |third| from the dispatcher list during dispatch. So the
  // event should only reach |first|, |second|, and |fourth|.
  ASSERT_EQ(3u, list.size());
  EXPECT_EQ(10, list[0]);
  EXPECT_EQ(15, list[1]);
  EXPECT_EQ(30, list[2]);
}

// Tests that if a dispatcher removes itself from the dispatcher list during
// dispatching an event, then event dispatching continues correctly.
TEST_F(PlatformEventTest, DispatcherRemovesSelfDuringDispatch) {
  std::vector<int> list;
  TestPlatformEventDispatcher first(10, &list);
  RunCallbackDuringDispatch second(15, &list);
  TestPlatformEventDispatcher third(20, &list);

  second.set_callback(base::Bind(&RemoveDispatcher, base::Unretained(&second)));

  scoped_ptr<PlatformEvent> event(CreatePlatformEvent());
  source()->Dispatch(*event);
  // |second| removes itself from the dispatcher list during dispatch. So the
  // event should reach all three dispatchers in the list.
  ASSERT_EQ(3u, list.size());
  EXPECT_EQ(10, list[0]);
  EXPECT_EQ(15, list[1]);
  EXPECT_EQ(20, list[2]);
}

// Tests that if a dispatcher removes itself from the dispatcher list during
// dispatching an event, and this dispatcher is last in the dispatcher-list,
// then event dispatching ends correctly.
TEST_F(PlatformEventTest, DispatcherRemovesSelfDuringDispatchLast) {
  std::vector<int> list;
  TestPlatformEventDispatcher first(10, &list);
  RunCallbackDuringDispatch second(15, &list);

  second.set_callback(base::Bind(&RemoveDispatcher, base::Unretained(&second)));

  scoped_ptr<PlatformEvent> event(CreatePlatformEvent());
  source()->Dispatch(*event);
  // |second| removes itself during dispatch. So both dispatchers will have
  // received the event.
  ASSERT_EQ(2u, list.size());
  EXPECT_EQ(10, list[0]);
  EXPECT_EQ(15, list[1]);
}

// Tests that if a dispatcher removes a single dispatcher that comes before it
// in the dispatcher list, then dispatch continues correctly.
TEST_F(PlatformEventTest, DispatcherRemovesPrevDispatcherDuringDispatch) {
  std::vector<int> list;
  TestPlatformEventDispatcher first(10, &list);
  RunCallbackDuringDispatch second(15, &list);
  TestPlatformEventDispatcher third(20, &list);

  second.set_callback(base::Bind(&RemoveDispatcher, base::Unretained(&first)));

  scoped_ptr<PlatformEvent> event(CreatePlatformEvent());
  source()->Dispatch(*event);
  // |second| removes |first| from the dispatcher list during dispatch. The
  // event should reach all three dispatchers.
  ASSERT_EQ(3u, list.size());
  EXPECT_EQ(10, list[0]);
  EXPECT_EQ(15, list[1]);
  EXPECT_EQ(20, list[2]);
}

// Tests that if a dispatcher removes multiple dispatchers that comes before it
// in the dispatcher list, then dispatch continues correctly.
TEST_F(PlatformEventTest, DispatcherRemovesPrevDispatchersDuringDispatch) {
  std::vector<int> list;
  TestPlatformEventDispatcher first(10, &list);
  TestPlatformEventDispatcher second(12, &list);
  RunCallbackDuringDispatch third(15, &list);
  TestPlatformEventDispatcher fourth(20, &list);

  third.set_callback(base::Bind(&RemoveDispatchers,
                                base::Unretained(&first),
                                base::Unretained(&second)));

  scoped_ptr<PlatformEvent> event(CreatePlatformEvent());
  source()->Dispatch(*event);
  // |third| removes |first| and |second| from the dispatcher list during
  // dispatch. The event should reach all three dispatchers.
  ASSERT_EQ(4u, list.size());
  EXPECT_EQ(10, list[0]);
  EXPECT_EQ(12, list[1]);
  EXPECT_EQ(15, list[2]);
  EXPECT_EQ(20, list[3]);
}

// Tests that adding a dispatcher during dispatching an event receives that
// event.
TEST_F(PlatformEventTest, DispatcherAddedDuringDispatchReceivesEvent) {
  std::vector<int> list;
  TestPlatformEventDispatcher first(10, &list);
  RunCallbackDuringDispatch second(15, &list);
  TestPlatformEventDispatcher third(20, &list);
  TestPlatformEventDispatcher fourth(30, &list);
  RemoveDispatchers(&third, &fourth);

  scoped_ptr<PlatformEvent> event(CreatePlatformEvent());
  source()->Dispatch(*event);
  ASSERT_EQ(2u, list.size());
  EXPECT_EQ(10, list[0]);
  EXPECT_EQ(15, list[1]);

  second.set_callback(base::Bind(&AddDispatcher, base::Unretained(&third)));
  list.clear();
  source()->Dispatch(*event);
  ASSERT_EQ(3u, list.size());
  EXPECT_EQ(10, list[0]);
  EXPECT_EQ(15, list[1]);
  EXPECT_EQ(20, list[2]);

  second.set_callback(base::Bind(&AddDispatcher, base::Unretained(&fourth)));
  list.clear();
  source()->Dispatch(*event);
  ASSERT_EQ(4u, list.size());
  EXPECT_EQ(10, list[0]);
  EXPECT_EQ(15, list[1]);
  EXPECT_EQ(20, list[2]);
  EXPECT_EQ(30, list[3]);
}

// Provides mechanism for running tests from inside an active message-loop.
class PlatformEventTestWithMessageLoop : public PlatformEventTest {
 public:
  PlatformEventTestWithMessageLoop() {}
  ~PlatformEventTestWithMessageLoop() override {}

  void Run() {
    message_loop_.PostTask(
        FROM_HERE,
        base::Bind(&PlatformEventTestWithMessageLoop::RunTest,
                   base::Unretained(this)));
    message_loop_.Run();
  }

 protected:
  void RunTest() {
    RunTestImpl();
    message_loop_.Quit();
  }

  virtual void RunTestImpl() = 0;

 private:
  base::MessageLoopForUI message_loop_;

  DISALLOW_COPY_AND_ASSIGN(PlatformEventTestWithMessageLoop);
};

#define RUN_TEST_IN_MESSAGE_LOOP(name) \
  TEST_F(name, Run) { Run(); }

// Tests that a ScopedEventDispatcher restores the previous dispatcher when
// destroyed.
class ScopedDispatcherRestoresAfterDestroy
    : public PlatformEventTestWithMessageLoop {
 public:
  // PlatformEventTestWithMessageLoop:
  void RunTestImpl() override {
    std::vector<int> list;
    TestPlatformEventDispatcher dispatcher(10, &list);
    TestPlatformEventObserver observer(15, &list);

    TestPlatformEventDispatcher first_overriding(20, &list);
    source()->RemovePlatformEventDispatcher(&first_overriding);
    scoped_ptr<ScopedEventDispatcher> first_override_handle =
        source()->OverrideDispatcher(&first_overriding);

    // Install a second overriding dispatcher.
    TestPlatformEventDispatcher second_overriding(50, &list);
    source()->RemovePlatformEventDispatcher(&second_overriding);
    scoped_ptr<ScopedEventDispatcher> second_override_handle =
        source()->OverrideDispatcher(&second_overriding);

    scoped_ptr<PlatformEvent> event(CreatePlatformEvent());
    source()->Dispatch(*event);
    ASSERT_EQ(2u, list.size());
    EXPECT_EQ(15, list[0]);
    EXPECT_EQ(50, list[1]);
    list.clear();

    second_override_handle.reset();
    source()->Dispatch(*event);
    ASSERT_EQ(2u, list.size());
    EXPECT_EQ(15, list[0]);
    EXPECT_EQ(20, list[1]);
  }
};

RUN_TEST_IN_MESSAGE_LOOP(ScopedDispatcherRestoresAfterDestroy)

// This dispatcher destroys the handle to the ScopedEventDispatcher when
// dispatching an event.
class DestroyScopedHandleDispatcher : public TestPlatformEventDispatcher {
 public:
  DestroyScopedHandleDispatcher(int id, std::vector<int>* list)
      : TestPlatformEventDispatcher(id, list) {}
  ~DestroyScopedHandleDispatcher() override {}

  void SetScopedHandle(scoped_ptr<ScopedEventDispatcher> handler) {
    handler_ = handler.Pass();
  }

  void set_callback(const base::Closure& callback) {
    callback_ = callback;
  }

 private:
  // PlatformEventDispatcher:
  bool CanDispatchEvent(const PlatformEvent& event) override {
    return true;
  }

  uint32_t DispatchEvent(const PlatformEvent& event) override {
    handler_.reset();
    uint32_t action = TestPlatformEventDispatcher::DispatchEvent(event);
    if (!callback_.is_null()) {
      callback_.Run();
      callback_ = base::Closure();
    }
    return action;
  }

  scoped_ptr<ScopedEventDispatcher> handler_;
  base::Closure callback_;

  DISALLOW_COPY_AND_ASSIGN(DestroyScopedHandleDispatcher);
};

// Tests that resetting an overridden dispatcher causes the nested message-loop
// iteration to stop and the rest of the events are dispatched in the next
// iteration.
class DestroyedNestedOverriddenDispatcherQuitsNestedLoopIteration
    : public PlatformEventTestWithMessageLoop {
 public:
  void NestedTask(std::vector<int>* list,
                  TestPlatformEventDispatcher* dispatcher) {
    ScopedVector<PlatformEvent> events;
    scoped_ptr<PlatformEvent> event(CreatePlatformEvent());
    events.push_back(event.release());
    event = CreatePlatformEvent();
    events.push_back(event.release());

    // Attempt to dispatch a couple of events. Dispatching the first event will
    // have terminated the ScopedEventDispatcher object, which will terminate
    // the current iteration of the message-loop.
    size_t count = source()->DispatchEventStream(events);
    EXPECT_EQ(1u, count);
    ASSERT_EQ(2u, list->size());
    EXPECT_EQ(15, (*list)[0]);
    EXPECT_EQ(20, (*list)[1]);
    list->clear();

    ASSERT_LT(count, events.size());
    events.erase(events.begin(), events.begin() + count);

    count = source()->DispatchEventStream(events);
    EXPECT_EQ(1u, count);
    ASSERT_EQ(2u, list->size());
    EXPECT_EQ(15, (*list)[0]);
    EXPECT_EQ(10, (*list)[1]);
    list->clear();

    // Terminate the message-loop.
    base::MessageLoopForUI::current()->QuitNow();
  }

  // PlatformEventTestWithMessageLoop:
  void RunTestImpl() override {
    std::vector<int> list;
    TestPlatformEventDispatcher dispatcher(10, &list);
    TestPlatformEventObserver observer(15, &list);

    DestroyScopedHandleDispatcher overriding(20, &list);
    source()->RemovePlatformEventDispatcher(&overriding);
    scoped_ptr<ScopedEventDispatcher> override_handle =
        source()->OverrideDispatcher(&overriding);

    scoped_ptr<PlatformEvent> event(CreatePlatformEvent());
    source()->Dispatch(*event);
    ASSERT_EQ(2u, list.size());
    EXPECT_EQ(15, list[0]);
    EXPECT_EQ(20, list[1]);
    list.clear();

    overriding.SetScopedHandle(override_handle.Pass());
    base::RunLoop run_loop;
    base::MessageLoopForUI* loop = base::MessageLoopForUI::current();
    base::MessageLoopForUI::ScopedNestableTaskAllower allow_nested(loop);
    loop->PostTask(
        FROM_HERE,
        base::Bind(
            &DestroyedNestedOverriddenDispatcherQuitsNestedLoopIteration::
                NestedTask,
            base::Unretained(this),
            base::Unretained(&list),
            base::Unretained(&overriding)));
    run_loop.Run();

    // Dispatching the event should now reach the default dispatcher.
    source()->Dispatch(*event);
    ASSERT_EQ(2u, list.size());
    EXPECT_EQ(15, list[0]);
    EXPECT_EQ(10, list[1]);
  }
};

RUN_TEST_IN_MESSAGE_LOOP(
    DestroyedNestedOverriddenDispatcherQuitsNestedLoopIteration)

// Tests that resetting an overridden dispatcher, and installing another
// overridden dispatcher before the nested message-loop completely unwinds
// function correctly.
class ConsecutiveOverriddenDispatcherInTheSameMessageLoopIteration
    : public PlatformEventTestWithMessageLoop {
 public:
  void NestedTask(scoped_ptr<ScopedEventDispatcher> dispatch_handle,
                  std::vector<int>* list) {
    scoped_ptr<PlatformEvent> event(CreatePlatformEvent());
    source()->Dispatch(*event);
    ASSERT_EQ(2u, list->size());
    EXPECT_EQ(15, (*list)[0]);
    EXPECT_EQ(20, (*list)[1]);
    list->clear();

    // Reset the override dispatcher. This should restore the default
    // dispatcher.
    dispatch_handle.reset();
    source()->Dispatch(*event);
    ASSERT_EQ(2u, list->size());
    EXPECT_EQ(15, (*list)[0]);
    EXPECT_EQ(10, (*list)[1]);
    list->clear();

    // Install another override-dispatcher.
    DestroyScopedHandleDispatcher second_overriding(70, list);
    source()->RemovePlatformEventDispatcher(&second_overriding);
    scoped_ptr<ScopedEventDispatcher> second_override_handle =
        source()->OverrideDispatcher(&second_overriding);

    source()->Dispatch(*event);
    ASSERT_EQ(2u, list->size());
    EXPECT_EQ(15, (*list)[0]);
    EXPECT_EQ(70, (*list)[1]);
    list->clear();

    second_overriding.SetScopedHandle(second_override_handle.Pass());
    second_overriding.set_post_dispatch_action(POST_DISPATCH_NONE);
    base::RunLoop run_loop;
    second_overriding.set_callback(run_loop.QuitClosure());
    base::MessageLoopForUI* loop = base::MessageLoopForUI::current();
    base::MessageLoopForUI::ScopedNestableTaskAllower allow_nested(loop);
    loop->PostTask(
        FROM_HERE,
        base::Bind(base::IgnoreResult(&TestPlatformEventSource::Dispatch),
                   base::Unretained(source()),
                   *event));
    run_loop.Run();
    ASSERT_EQ(2u, list->size());
    EXPECT_EQ(15, (*list)[0]);
    EXPECT_EQ(70, (*list)[1]);
    list->clear();

    // Terminate the message-loop.
    base::MessageLoopForUI::current()->QuitNow();
  }

  // PlatformEventTestWithMessageLoop:
  void RunTestImpl() override {
    std::vector<int> list;
    TestPlatformEventDispatcher dispatcher(10, &list);
    TestPlatformEventObserver observer(15, &list);

    TestPlatformEventDispatcher overriding(20, &list);
    source()->RemovePlatformEventDispatcher(&overriding);
    scoped_ptr<ScopedEventDispatcher> override_handle =
        source()->OverrideDispatcher(&overriding);

    scoped_ptr<PlatformEvent> event(CreatePlatformEvent());
    source()->Dispatch(*event);
    ASSERT_EQ(2u, list.size());
    EXPECT_EQ(15, list[0]);
    EXPECT_EQ(20, list[1]);
    list.clear();

    // Start a nested message-loop, and destroy |override_handle| in the nested
    // loop. That should terminate the nested loop, restore the previous
    // dispatchers, and return control to this function.
    base::RunLoop run_loop;
    base::MessageLoopForUI* loop = base::MessageLoopForUI::current();
    base::MessageLoopForUI::ScopedNestableTaskAllower allow_nested(loop);
    loop->PostTask(
        FROM_HERE,
        base::Bind(
            &ConsecutiveOverriddenDispatcherInTheSameMessageLoopIteration::
                NestedTask,
            base::Unretained(this),
            base::Passed(&override_handle),
            base::Unretained(&list)));
    run_loop.Run();

    // Dispatching the event should now reach the default dispatcher.
    source()->Dispatch(*event);
    ASSERT_EQ(2u, list.size());
    EXPECT_EQ(15, list[0]);
    EXPECT_EQ(10, list[1]);
  }
};

RUN_TEST_IN_MESSAGE_LOOP(
    ConsecutiveOverriddenDispatcherInTheSameMessageLoopIteration)

}  // namespace ui
