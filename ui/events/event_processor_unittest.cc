// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <vector>

#include "testing/gtest/include/gtest/gtest.h"
#include "ui/events/event.h"
#include "ui/events/event_targeter.h"
#include "ui/events/test/events_test_utils.h"
#include "ui/events/test/test_event_handler.h"
#include "ui/events/test/test_event_processor.h"
#include "ui/events/test/test_event_target.h"

typedef std::vector<std::string> HandlerSequenceRecorder;

namespace ui {
namespace test {

class EventProcessorTest : public testing::Test {
 public:
  EventProcessorTest() {}
  ~EventProcessorTest() override {}

  // testing::Test:
  void SetUp() override {
    processor_.SetRoot(scoped_ptr<EventTarget>(new TestEventTarget()));
    processor_.Reset();
    root()->SetEventTargeter(make_scoped_ptr(new EventTargeter()));
  }

  TestEventTarget* root() {
    return static_cast<TestEventTarget*>(processor_.GetRootTarget());
  }

  TestEventProcessor* processor() {
    return &processor_;
  }

  void DispatchEvent(Event* event) {
    processor_.OnEventFromSource(event);
  }

 protected:
  TestEventProcessor processor_;

  DISALLOW_COPY_AND_ASSIGN(EventProcessorTest);
};

TEST_F(EventProcessorTest, Basic) {
  scoped_ptr<TestEventTarget> child(new TestEventTarget());
  root()->AddChild(child.Pass());

  MouseEvent mouse(ET_MOUSE_MOVED, gfx::Point(10, 10), gfx::Point(10, 10),
                   EF_NONE, EF_NONE);
  DispatchEvent(&mouse);
  EXPECT_TRUE(root()->child_at(0)->DidReceiveEvent(ET_MOUSE_MOVED));
  EXPECT_FALSE(root()->DidReceiveEvent(ET_MOUSE_MOVED));

  root()->RemoveChild(root()->child_at(0));
  DispatchEvent(&mouse);
  EXPECT_TRUE(root()->DidReceiveEvent(ET_MOUSE_MOVED));
}

template<typename T>
class BoundsEventTargeter : public EventTargeter {
 public:
  virtual ~BoundsEventTargeter() {}

 protected:
  virtual bool SubtreeShouldBeExploredForEvent(
      EventTarget* target, const LocatedEvent& event) override {
    T* t = static_cast<T*>(target);
    return (t->bounds().Contains(event.location()));
  }
};

class BoundsTestTarget : public TestEventTarget {
 public:
  BoundsTestTarget() {}
  ~BoundsTestTarget() override {}

  void set_bounds(gfx::Rect rect) { bounds_ = rect; }
  gfx::Rect bounds() const { return bounds_; }

  static void ConvertPointToTarget(BoundsTestTarget* source,
                                   BoundsTestTarget* target,
                                   gfx::Point* location) {
    gfx::Vector2d vector;
    if (source->Contains(target)) {
      for (; target && target != source;
           target = static_cast<BoundsTestTarget*>(target->parent())) {
        vector += target->bounds().OffsetFromOrigin();
      }
      *location -= vector;
    } else if (target->Contains(source)) {
      for (; source && source != target;
           source = static_cast<BoundsTestTarget*>(source->parent())) {
        vector += source->bounds().OffsetFromOrigin();
      }
      *location += vector;
    } else {
      NOTREACHED();
    }
  }

 private:
  // EventTarget:
  void ConvertEventToTarget(EventTarget* target,
                            LocatedEvent* event) override {
    event->ConvertLocationToTarget(this,
                                   static_cast<BoundsTestTarget*>(target));
  }

  gfx::Rect bounds_;

  DISALLOW_COPY_AND_ASSIGN(BoundsTestTarget);
};

TEST_F(EventProcessorTest, Bounds) {
  scoped_ptr<BoundsTestTarget> parent(new BoundsTestTarget());
  scoped_ptr<BoundsTestTarget> child(new BoundsTestTarget());
  scoped_ptr<BoundsTestTarget> grandchild(new BoundsTestTarget());

  parent->set_bounds(gfx::Rect(0, 0, 30, 30));
  child->set_bounds(gfx::Rect(5, 5, 20, 20));
  grandchild->set_bounds(gfx::Rect(5, 5, 5, 5));

  child->AddChild(scoped_ptr<TestEventTarget>(grandchild.Pass()));
  parent->AddChild(scoped_ptr<TestEventTarget>(child.Pass()));
  root()->AddChild(scoped_ptr<TestEventTarget>(parent.Pass()));

  ASSERT_EQ(1u, root()->child_count());
  ASSERT_EQ(1u, root()->child_at(0)->child_count());
  ASSERT_EQ(1u, root()->child_at(0)->child_at(0)->child_count());

  TestEventTarget* parent_r = root()->child_at(0);
  TestEventTarget* child_r = parent_r->child_at(0);
  TestEventTarget* grandchild_r = child_r->child_at(0);

  // Dispatch a mouse event that falls on the parent, but not on the child. When
  // the default event-targeter used, the event will still reach |grandchild|,
  // because the default targeter does not look at the bounds.
  MouseEvent mouse(ET_MOUSE_MOVED, gfx::Point(1, 1), gfx::Point(1, 1), EF_NONE,
                   EF_NONE);
  DispatchEvent(&mouse);
  EXPECT_FALSE(root()->DidReceiveEvent(ET_MOUSE_MOVED));
  EXPECT_FALSE(parent_r->DidReceiveEvent(ET_MOUSE_MOVED));
  EXPECT_FALSE(child_r->DidReceiveEvent(ET_MOUSE_MOVED));
  EXPECT_TRUE(grandchild_r->DidReceiveEvent(ET_MOUSE_MOVED));
  grandchild_r->ResetReceivedEvents();

  // Now install a targeter on the parent that looks at the bounds and makes
  // sure the event reaches the target only if the location of the event within
  // the bounds of the target.
  MouseEvent mouse2(ET_MOUSE_MOVED, gfx::Point(1, 1), gfx::Point(1, 1), EF_NONE,
                    EF_NONE);
  parent_r->SetEventTargeter(scoped_ptr<EventTargeter>(
      new BoundsEventTargeter<BoundsTestTarget>()));
  DispatchEvent(&mouse2);
  EXPECT_FALSE(root()->DidReceiveEvent(ET_MOUSE_MOVED));
  EXPECT_TRUE(parent_r->DidReceiveEvent(ET_MOUSE_MOVED));
  EXPECT_FALSE(child_r->DidReceiveEvent(ET_MOUSE_MOVED));
  EXPECT_FALSE(grandchild_r->DidReceiveEvent(ET_MOUSE_MOVED));
  parent_r->ResetReceivedEvents();

  MouseEvent second(ET_MOUSE_MOVED, gfx::Point(12, 12), gfx::Point(12, 12),
                    EF_NONE, EF_NONE);
  DispatchEvent(&second);
  EXPECT_FALSE(root()->DidReceiveEvent(ET_MOUSE_MOVED));
  EXPECT_FALSE(parent_r->DidReceiveEvent(ET_MOUSE_MOVED));
  EXPECT_FALSE(child_r->DidReceiveEvent(ET_MOUSE_MOVED));
  EXPECT_TRUE(grandchild_r->DidReceiveEvent(ET_MOUSE_MOVED));
}

// ReDispatchEventHandler is used to receive mouse events and forward them
// to a specified EventProcessor. Verifies that the event has the correct
// target and phase both before and after the nested event processing. Also
// verifies that the location of the event remains the same after it has
// been processed by the second EventProcessor.
class ReDispatchEventHandler : public TestEventHandler {
 public:
  ReDispatchEventHandler(EventProcessor* processor, EventTarget* target)
      : processor_(processor), expected_target_(target) {}
  ~ReDispatchEventHandler() override {}

  // TestEventHandler:
  void OnMouseEvent(MouseEvent* event) override {
    TestEventHandler::OnMouseEvent(event);

    EXPECT_EQ(expected_target_, event->target());
    EXPECT_EQ(EP_TARGET, event->phase());

    gfx::Point location(event->location());
    EventDispatchDetails details = processor_->OnEventFromSource(event);
    EXPECT_FALSE(details.dispatcher_destroyed);
    EXPECT_FALSE(details.target_destroyed);

    // The nested event-processing should not have mutated the target,
    // phase, or location of |event|.
    EXPECT_EQ(expected_target_, event->target());
    EXPECT_EQ(EP_TARGET, event->phase());
    EXPECT_EQ(location, event->location());
  }

 private:
  EventProcessor* processor_;
  EventTarget* expected_target_;

  DISALLOW_COPY_AND_ASSIGN(ReDispatchEventHandler);
};

// Verifies that the phase and target information of an event is not mutated
// as a result of sending the event to an event processor while it is still
// being processed by another event processor.
TEST_F(EventProcessorTest, NestedEventProcessing) {
  // Add one child to the default event processor used in this test suite.
  scoped_ptr<TestEventTarget> child(new TestEventTarget());
  root()->AddChild(child.Pass());

  // Define a second root target and child.
  scoped_ptr<EventTarget> second_root_scoped(new TestEventTarget());
  TestEventTarget* second_root =
      static_cast<TestEventTarget*>(second_root_scoped.get());
  second_root->SetEventTargeter(make_scoped_ptr(new EventTargeter()));
  scoped_ptr<TestEventTarget> second_child(new TestEventTarget());
  second_root->AddChild(second_child.Pass());

  // Define a second event processor which owns the second root.
  scoped_ptr<TestEventProcessor> second_processor(new TestEventProcessor());
  second_processor->SetRoot(second_root_scoped.Pass());

  // Indicate that an event which is dispatched to the child target owned by the
  // first event processor should be handled by |target_handler| instead.
  scoped_ptr<TestEventHandler> target_handler(
      new ReDispatchEventHandler(second_processor.get(), root()->child_at(0)));
  root()->child_at(0)->set_target_handler(target_handler.get());

  // Dispatch a mouse event to the tree of event targets owned by the first
  // event processor, checking in ReDispatchEventHandler that the phase and
  // target information of the event is correct.
  MouseEvent mouse(
      ET_MOUSE_MOVED, gfx::Point(10, 10), gfx::Point(10, 10), EF_NONE, EF_NONE);
  DispatchEvent(&mouse);

  // Verify also that |mouse| was seen by the child nodes contained in both
  // event processors and that the event was not handled.
  EXPECT_TRUE(root()->child_at(0)->DidReceiveEvent(ET_MOUSE_MOVED));
  EXPECT_TRUE(second_root->child_at(0)->DidReceiveEvent(ET_MOUSE_MOVED));
  EXPECT_FALSE(mouse.handled());
  second_root->child_at(0)->ResetReceivedEvents();
  root()->child_at(0)->ResetReceivedEvents();

  // Indicate that the child of the second root should handle events, and
  // dispatch another mouse event to verify that it is marked as handled.
  second_root->child_at(0)->set_mark_events_as_handled(true);
  MouseEvent mouse2(
      ET_MOUSE_MOVED, gfx::Point(10, 10), gfx::Point(10, 10), EF_NONE, EF_NONE);
  DispatchEvent(&mouse2);
  EXPECT_TRUE(root()->child_at(0)->DidReceiveEvent(ET_MOUSE_MOVED));
  EXPECT_TRUE(second_root->child_at(0)->DidReceiveEvent(ET_MOUSE_MOVED));
  EXPECT_TRUE(mouse2.handled());
}

// Verifies that OnEventProcessingFinished() is called when an event
// has been handled.
TEST_F(EventProcessorTest, OnEventProcessingFinished) {
  scoped_ptr<TestEventTarget> child(new TestEventTarget());
  child->set_mark_events_as_handled(true);
  root()->AddChild(child.Pass());

  // Dispatch a mouse event. We expect the event to be seen by the target,
  // handled, and we expect OnEventProcessingFinished() to be invoked once.
  MouseEvent mouse(ET_MOUSE_MOVED, gfx::Point(10, 10), gfx::Point(10, 10),
                   EF_NONE, EF_NONE);
  DispatchEvent(&mouse);
  EXPECT_TRUE(root()->child_at(0)->DidReceiveEvent(ET_MOUSE_MOVED));
  EXPECT_FALSE(root()->DidReceiveEvent(ET_MOUSE_MOVED));
  EXPECT_TRUE(mouse.handled());
  EXPECT_EQ(1, processor()->num_times_processing_finished());
}

// Verifies that OnEventProcessingStarted() has been called when starting to
// process an event, and that processing does not take place if
// OnEventProcessingStarted() marks the event as handled. Also verifies that
// OnEventProcessingFinished() is also called in either case.
TEST_F(EventProcessorTest, OnEventProcessingStarted) {
  scoped_ptr<TestEventTarget> child(new TestEventTarget());
  root()->AddChild(child.Pass());

  // Dispatch a mouse event. We expect the event to be seen by the target,
  // OnEventProcessingStarted() should be called once, and
  // OnEventProcessingFinished() should be called once. The event should
  // remain unhandled.
  MouseEvent mouse(
      ET_MOUSE_MOVED, gfx::Point(10, 10), gfx::Point(10, 10), EF_NONE, EF_NONE);
  DispatchEvent(&mouse);
  EXPECT_TRUE(root()->child_at(0)->DidReceiveEvent(ET_MOUSE_MOVED));
  EXPECT_FALSE(root()->DidReceiveEvent(ET_MOUSE_MOVED));
  EXPECT_FALSE(mouse.handled());
  EXPECT_EQ(1, processor()->num_times_processing_started());
  EXPECT_EQ(1, processor()->num_times_processing_finished());
  processor()->Reset();
  root()->ResetReceivedEvents();
  root()->child_at(0)->ResetReceivedEvents();

  // Dispatch another mouse event, but with OnEventProcessingStarted() marking
  // the event as handled to prevent processing. We expect the event to not be
  // seen by the target this time, but OnEventProcessingStarted() and
  // OnEventProcessingFinished() should both still be called once.
  processor()->set_should_processing_occur(false);
  MouseEvent mouse2(
      ET_MOUSE_MOVED, gfx::Point(10, 10), gfx::Point(10, 10), EF_NONE, EF_NONE);
  DispatchEvent(&mouse2);
  EXPECT_FALSE(root()->child_at(0)->DidReceiveEvent(ET_MOUSE_MOVED));
  EXPECT_FALSE(root()->DidReceiveEvent(ET_MOUSE_MOVED));
  EXPECT_TRUE(mouse2.handled());
  EXPECT_EQ(1, processor()->num_times_processing_started());
  EXPECT_EQ(1, processor()->num_times_processing_finished());
}

class IgnoreEventTargeter : public EventTargeter {
 public:
  IgnoreEventTargeter() {}
  ~IgnoreEventTargeter() override {}

 private:
  // EventTargeter:
  bool SubtreeShouldBeExploredForEvent(
      EventTarget* target, const LocatedEvent& event) override {
    return false;
  }
};

// Verifies that the EventTargeter installed on an EventTarget can dictate
// whether the target itself can process an event.
TEST_F(EventProcessorTest, TargeterChecksOwningEventTarget) {
  scoped_ptr<TestEventTarget> child(new TestEventTarget());
  root()->AddChild(child.Pass());

  MouseEvent mouse(ET_MOUSE_MOVED, gfx::Point(10, 10), gfx::Point(10, 10),
                   EF_NONE, EF_NONE);
  DispatchEvent(&mouse);
  EXPECT_TRUE(root()->child_at(0)->DidReceiveEvent(ET_MOUSE_MOVED));
  EXPECT_FALSE(root()->DidReceiveEvent(ET_MOUSE_MOVED));
  root()->child_at(0)->ResetReceivedEvents();

  // Install an event handler on |child| which always prevents the target from
  // receiving event.
  root()->child_at(0)->SetEventTargeter(
      scoped_ptr<EventTargeter>(new IgnoreEventTargeter()));
  MouseEvent mouse2(ET_MOUSE_MOVED, gfx::Point(10, 10), gfx::Point(10, 10),
                    EF_NONE, EF_NONE);
  DispatchEvent(&mouse2);
  EXPECT_FALSE(root()->child_at(0)->DidReceiveEvent(ET_MOUSE_MOVED));
  EXPECT_TRUE(root()->DidReceiveEvent(ET_MOUSE_MOVED));
}

// An EventTargeter which is used to allow a bubbling behaviour in event
// dispatch: if an event is not handled after being dispatched to its
// initial target, the event is dispatched to the next-best target as
// specified by FindNextBestTarget().
class BubblingEventTargeter : public EventTargeter {
 public:
  explicit BubblingEventTargeter(TestEventTarget* initial_target)
    : initial_target_(initial_target) {}
  ~BubblingEventTargeter() override {}

 private:
  // EventTargeter:
  EventTarget* FindTargetForEvent(EventTarget* root,
                                          Event* event) override {
    return initial_target_;
  }

  EventTarget* FindNextBestTarget(EventTarget* previous_target,
                                          Event* event) override {
    return previous_target->GetParentTarget();
  }

  TestEventTarget* initial_target_;

  DISALLOW_COPY_AND_ASSIGN(BubblingEventTargeter);
};

// Tests that unhandled events are correctly dispatched to the next-best
// target as decided by the BubblingEventTargeter.
TEST_F(EventProcessorTest, DispatchToNextBestTarget) {
  scoped_ptr<TestEventTarget> child(new TestEventTarget());
  scoped_ptr<TestEventTarget> grandchild(new TestEventTarget());

  root()->SetEventTargeter(
      scoped_ptr<EventTargeter>(new BubblingEventTargeter(grandchild.get())));
  child->AddChild(grandchild.Pass());
  root()->AddChild(child.Pass());

  ASSERT_EQ(1u, root()->child_count());
  ASSERT_EQ(1u, root()->child_at(0)->child_count());
  ASSERT_EQ(0u, root()->child_at(0)->child_at(0)->child_count());

  TestEventTarget* child_r = root()->child_at(0);
  TestEventTarget* grandchild_r = child_r->child_at(0);

  // When the root has a BubblingEventTargeter installed, events targeted
  // at the grandchild target should be dispatched to all three targets.
  KeyEvent key_event(ET_KEY_PRESSED, VKEY_ESCAPE, EF_NONE);
  DispatchEvent(&key_event);
  EXPECT_TRUE(root()->DidReceiveEvent(ET_KEY_PRESSED));
  EXPECT_TRUE(child_r->DidReceiveEvent(ET_KEY_PRESSED));
  EXPECT_TRUE(grandchild_r->DidReceiveEvent(ET_KEY_PRESSED));
  root()->ResetReceivedEvents();
  child_r->ResetReceivedEvents();
  grandchild_r->ResetReceivedEvents();

  // Add a pre-target handler on the child of the root that will mark the event
  // as handled. No targets in the hierarchy should receive the event.
  TestEventHandler handler;
  child_r->AddPreTargetHandler(&handler);
  key_event = KeyEvent(ET_KEY_PRESSED, VKEY_ESCAPE, EF_NONE);
  DispatchEvent(&key_event);
  EXPECT_FALSE(root()->DidReceiveEvent(ET_KEY_PRESSED));
  EXPECT_FALSE(child_r->DidReceiveEvent(ET_KEY_PRESSED));
  EXPECT_FALSE(grandchild_r->DidReceiveEvent(ET_KEY_PRESSED));
  EXPECT_EQ(1, handler.num_key_events());
  handler.Reset();

  // Add a post-target handler on the child of the root that will mark the event
  // as handled. Only the grandchild (the initial target) should receive the
  // event.
  child_r->RemovePreTargetHandler(&handler);
  child_r->AddPostTargetHandler(&handler);
  key_event = KeyEvent(ET_KEY_PRESSED, VKEY_ESCAPE, EF_NONE);
  DispatchEvent(&key_event);
  EXPECT_FALSE(root()->DidReceiveEvent(ET_KEY_PRESSED));
  EXPECT_FALSE(child_r->DidReceiveEvent(ET_KEY_PRESSED));
  EXPECT_TRUE(grandchild_r->DidReceiveEvent(ET_KEY_PRESSED));
  EXPECT_EQ(1, handler.num_key_events());
  handler.Reset();
  grandchild_r->ResetReceivedEvents();
  child_r->RemovePostTargetHandler(&handler);

  // Mark the event as handled when it reaches the EP_TARGET phase of
  // dispatch at the child of the root. The child and grandchild
  // targets should both receive the event, but the root should not.
  child_r->set_mark_events_as_handled(true);
  key_event = KeyEvent(ET_KEY_PRESSED, VKEY_ESCAPE, EF_NONE);
  DispatchEvent(&key_event);
  EXPECT_FALSE(root()->DidReceiveEvent(ET_KEY_PRESSED));
  EXPECT_TRUE(child_r->DidReceiveEvent(ET_KEY_PRESSED));
  EXPECT_TRUE(grandchild_r->DidReceiveEvent(ET_KEY_PRESSED));
  root()->ResetReceivedEvents();
  child_r->ResetReceivedEvents();
  grandchild_r->ResetReceivedEvents();
  child_r->set_mark_events_as_handled(false);
}

// Tests that unhandled events are seen by the correct sequence of
// targets, pre-target handlers, and post-target handlers when
// a BubblingEventTargeter is installed on the root target.
TEST_F(EventProcessorTest, HandlerSequence) {
  scoped_ptr<TestEventTarget> child(new TestEventTarget());
  scoped_ptr<TestEventTarget> grandchild(new TestEventTarget());

  root()->SetEventTargeter(
      scoped_ptr<EventTargeter>(new BubblingEventTargeter(grandchild.get())));
  child->AddChild(grandchild.Pass());
  root()->AddChild(child.Pass());

  ASSERT_EQ(1u, root()->child_count());
  ASSERT_EQ(1u, root()->child_at(0)->child_count());
  ASSERT_EQ(0u, root()->child_at(0)->child_at(0)->child_count());

  TestEventTarget* child_r = root()->child_at(0);
  TestEventTarget* grandchild_r = child_r->child_at(0);

  HandlerSequenceRecorder recorder;
  root()->set_target_name("R");
  root()->set_recorder(&recorder);
  child_r->set_target_name("C");
  child_r->set_recorder(&recorder);
  grandchild_r->set_target_name("G");
  grandchild_r->set_recorder(&recorder);

  TestEventHandler pre_root;
  pre_root.set_handler_name("PreR");
  pre_root.set_recorder(&recorder);
  root()->AddPreTargetHandler(&pre_root);

  TestEventHandler pre_child;
  pre_child.set_handler_name("PreC");
  pre_child.set_recorder(&recorder);
  child_r->AddPreTargetHandler(&pre_child);

  TestEventHandler pre_grandchild;
  pre_grandchild.set_handler_name("PreG");
  pre_grandchild.set_recorder(&recorder);
  grandchild_r->AddPreTargetHandler(&pre_grandchild);

  TestEventHandler post_root;
  post_root.set_handler_name("PostR");
  post_root.set_recorder(&recorder);
  root()->AddPostTargetHandler(&post_root);

  TestEventHandler post_child;
  post_child.set_handler_name("PostC");
  post_child.set_recorder(&recorder);
  child_r->AddPostTargetHandler(&post_child);

  TestEventHandler post_grandchild;
  post_grandchild.set_handler_name("PostG");
  post_grandchild.set_recorder(&recorder);
  grandchild_r->AddPostTargetHandler(&post_grandchild);

  MouseEvent mouse(ET_MOUSE_MOVED, gfx::Point(10, 10), gfx::Point(10, 10),
                   EF_NONE, EF_NONE);
  DispatchEvent(&mouse);

  std::string expected[] = { "PreR", "PreC", "PreG", "G", "PostG", "PostC",
      "PostR", "PreR", "PreC", "C", "PostC", "PostR", "PreR", "R", "PostR" };
  EXPECT_EQ(std::vector<std::string>(
      expected, expected + arraysize(expected)), recorder);
}

}  // namespace test
}  // namespace ui
