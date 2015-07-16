// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_TEST_TEST_EVENT_TARGET_H_
#define UI_EVENTS_TEST_TEST_EVENT_TARGET_H_

#include <set>
#include <string>
#include <vector>

#include "base/memory/scoped_vector.h"
#include "ui/events/event_target.h"

typedef std::vector<std::string> HandlerSequenceRecorder;

namespace gfx {
class Point;
}

namespace ui {
namespace test {

class TestEventTarget : public EventTarget {
 public:
  TestEventTarget();
  ~TestEventTarget() override;

  void AddChild(scoped_ptr<TestEventTarget> child);
  scoped_ptr<TestEventTarget> RemoveChild(TestEventTarget* child);

  TestEventTarget* parent() { return parent_; }

  void set_mark_events_as_handled(bool handle) {
    mark_events_as_handled_ = handle;
  }

  TestEventTarget* child_at(int index) { return children_[index]; }
  size_t child_count() const { return children_.size(); }

  void SetEventTargeter(scoped_ptr<EventTargeter> targeter);

  bool DidReceiveEvent(ui::EventType type) const;
  void ResetReceivedEvents();

  void set_recorder(HandlerSequenceRecorder* recorder) {
    recorder_ = recorder;
  }
  void set_target_name(const std::string& target_name) {
    target_name_ = target_name;
  }

 protected:
  bool Contains(TestEventTarget* target) const;

  // EventTarget:
  bool CanAcceptEvent(const ui::Event& event) override;
  EventTarget* GetParentTarget() override;
  scoped_ptr<EventTargetIterator> GetChildIterator() override;
  EventTargeter* GetEventTargeter() override;

  // EventHandler:
  void OnEvent(Event* event) override;

 private:
  void set_parent(TestEventTarget* parent) { parent_ = parent; }

  TestEventTarget* parent_;
  ScopedVector<TestEventTarget> children_;
  scoped_ptr<EventTargeter> targeter_;
  bool mark_events_as_handled_;

  std::set<ui::EventType> received_;

  HandlerSequenceRecorder* recorder_;
  std::string target_name_;

  DISALLOW_COPY_AND_ASSIGN(TestEventTarget);
};

}  // namespace test
}  // namespace ui

#endif  // UI_EVENTS_TEST_TEST_EVENT_TARGET_H_
