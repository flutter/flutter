// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_TEST_TEST_EVENT_PROCESSOR_H_
#define UI_EVENTS_TEST_TEST_EVENT_PROCESSOR_H_

#include "base/memory/scoped_ptr.h"
#include "ui/events/event_processor.h"

namespace ui {
namespace test {

class TestEventProcessor : public EventProcessor {
 public:
  TestEventProcessor();
  ~TestEventProcessor() override;

  int num_times_processing_started() const {
    return num_times_processing_started_;
  }

  int num_times_processing_finished() const {
    return num_times_processing_finished_;
  }

  void set_should_processing_occur(bool occur) {
    should_processing_occur_ = occur;
  }

  void SetRoot(scoped_ptr<EventTarget> root);
  void Reset();

  // EventProcessor:
  bool CanDispatchToTarget(EventTarget* target) override;
  EventTarget* GetRootTarget() override;
  EventDispatchDetails OnEventFromSource(Event* event) override;
  void OnEventProcessingStarted(Event* event) override;
  void OnEventProcessingFinished(Event* event) override;

 private:
  scoped_ptr<EventTarget> root_;

  // Used in our override of OnEventProcessingStarted(). If this value is
  // false, mark incoming events as handled.
  bool should_processing_occur_;

  // Counts the number of times OnEventProcessingStarted() has been called.
  int num_times_processing_started_;

  // Counts the number of times OnEventProcessingFinished() has been called.
  int num_times_processing_finished_;

  DISALLOW_COPY_AND_ASSIGN(TestEventProcessor);
};

}  // namespace test
}  // namespace ui

#endif  // UI_EVENTS_TEST_TEST_EVENT_PROCESSOR_H_
