// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/gestures/gesture_recognizer_impl.h"

#include <limits>

#include "base/command_line.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_loop.h"
#include "base/time/time.h"
#include "ui/events/event.h"
#include "ui/events/event_constants.h"
#include "ui/events/event_switches.h"
#include "ui/events/event_utils.h"
#include "ui/events/gestures/gesture_configuration.h"
#include "ui/events/gestures/gesture_types.h"

namespace ui {

namespace {

template <typename T>
void TransferConsumer(GestureConsumer* current_consumer,
                      GestureConsumer* new_consumer,
                      std::map<GestureConsumer*, T>* map) {
  if (map->count(current_consumer)) {
    (*map)[new_consumer] = (*map)[current_consumer];
    map->erase(current_consumer);
  }
}

bool RemoveConsumerFromMap(GestureConsumer* consumer,
                           GestureRecognizerImpl::TouchIdToConsumerMap* map) {
  bool consumer_removed = false;
  for (GestureRecognizerImpl::TouchIdToConsumerMap::iterator i = map->begin();
       i != map->end();) {
    if (i->second == consumer) {
      map->erase(i++);
      consumer_removed = true;
    } else {
      ++i;
    }
  }
  return consumer_removed;
}

void TransferTouchIdToConsumerMap(
    GestureConsumer* old_consumer,
    GestureConsumer* new_consumer,
    GestureRecognizerImpl::TouchIdToConsumerMap* map) {
  for (GestureRecognizerImpl::TouchIdToConsumerMap::iterator i = map->begin();
       i != map->end(); ++i) {
    if (i->second == old_consumer)
      i->second = new_consumer;
  }
}

GestureProviderImpl* CreateGestureProvider(GestureProviderImplClient* client) {
  return new GestureProviderImpl(client);
}

}  // namespace

////////////////////////////////////////////////////////////////////////////////
// GestureRecognizerImpl, public:

GestureRecognizerImpl::GestureRecognizerImpl() {
}

GestureRecognizerImpl::~GestureRecognizerImpl() {
  STLDeleteValues(&consumer_gesture_provider_);
}

// Checks if this finger is already down, if so, returns the current target.
// Otherwise, returns NULL.
GestureConsumer* GestureRecognizerImpl::GetTouchLockedTarget(
    const TouchEvent& event) {
  return touch_id_target_[event.touch_id()];
}

GestureConsumer* GestureRecognizerImpl::GetTargetForGestureEvent(
    const GestureEvent& event) {
  GestureConsumer* target = NULL;
  int touch_id = event.details().oldest_touch_id();
  target = touch_id_target_for_gestures_[touch_id];
  return target;
}

GestureConsumer* GestureRecognizerImpl::GetTargetForLocation(
    const gfx::PointF& location, int source_device_id) {
  const float max_distance =
      GestureConfiguration::max_separation_for_gesture_touches_in_pixels();

  gfx::PointF closest_point;
  int closest_touch_id = 0;
  double closest_distance_squared = std::numeric_limits<double>::infinity();

  std::map<GestureConsumer*, GestureProviderImpl*>::iterator i;
  for (i = consumer_gesture_provider_.begin();
       i != consumer_gesture_provider_.end();
       ++i) {
    const MotionEventImpl& pointer_state = i->second->pointer_state();
    for (size_t j = 0; j < pointer_state.GetPointerCount(); ++j) {
      if (source_device_id != pointer_state.GetSourceDeviceId(j))
        continue;
      gfx::PointF point(pointer_state.GetX(j), pointer_state.GetY(j));
      // Relative distance is all we need here, so LengthSquared() is
      // appropriate, and cheaper than Length().
      double distance_squared = (point - location).LengthSquared();
      if (distance_squared < closest_distance_squared) {
        closest_point = point;
        closest_touch_id = pointer_state.GetPointerId(j);
        closest_distance_squared = distance_squared;
      }
    }
  }

  if (closest_distance_squared < max_distance * max_distance)
    return touch_id_target_[closest_touch_id];
  return NULL;
}

void GestureRecognizerImpl::TransferEventsTo(GestureConsumer* current_consumer,
                                             GestureConsumer* new_consumer) {
  // Send cancel to all those save |new_consumer| and |current_consumer|.
  // Don't send a cancel to |current_consumer|, unless |new_consumer| is NULL.
  // Dispatching a touch-cancel event can end up altering |touch_id_target_|
  // (e.g. when the target of the event is destroyed, causing it to be removed
  // from |touch_id_target_| in |CleanupStateForConsumer()|). So create a list
  // of the touch-ids that need to be cancelled, and dispatch the cancel events
  // for them at the end.

  std::vector<GestureConsumer*> consumers;
  std::map<GestureConsumer*, GestureProviderImpl*>::iterator i;
  for (i = consumer_gesture_provider_.begin();
       i != consumer_gesture_provider_.end();
       ++i) {
    if (i->first && i->first != new_consumer &&
        (i->first != current_consumer || new_consumer == NULL)) {
      consumers.push_back(i->first);
    }
  }
  for (std::vector<GestureConsumer*>::iterator iter = consumers.begin();
       iter != consumers.end();
       ++iter) {
    CancelActiveTouches(*iter);
  }
  // Transfer events from |current_consumer| to |new_consumer|.
  if (current_consumer && new_consumer) {
    TransferTouchIdToConsumerMap(current_consumer, new_consumer,
                                 &touch_id_target_);
    TransferTouchIdToConsumerMap(current_consumer, new_consumer,
                                 &touch_id_target_for_gestures_);
    TransferConsumer(
        current_consumer, new_consumer, &consumer_gesture_provider_);
  }
}

bool GestureRecognizerImpl::GetLastTouchPointForTarget(
    GestureConsumer* consumer,
    gfx::PointF* point) {
    if (consumer_gesture_provider_.count(consumer) == 0)
      return false;
    const MotionEvent& pointer_state =
        consumer_gesture_provider_[consumer]->pointer_state();
    *point = gfx::PointF(pointer_state.GetX(), pointer_state.GetY());
    return true;
}

bool GestureRecognizerImpl::CancelActiveTouches(GestureConsumer* consumer) {
  bool cancelled_touch = false;
  if (consumer_gesture_provider_.count(consumer) == 0)
    return false;
  const MotionEventImpl& pointer_state =
      consumer_gesture_provider_[consumer]->pointer_state();
  if (pointer_state.GetPointerCount() == 0)
    return false;
  // Pointer_state is modified every time after DispatchCancelTouchEvent.
  scoped_ptr<MotionEvent> pointer_state_clone = pointer_state.Clone();
  for (size_t i = 0; i < pointer_state_clone->GetPointerCount(); ++i) {
    gfx::PointF point(pointer_state_clone->GetX(i),
                      pointer_state_clone->GetY(i));
    TouchEvent touch_event(ui::ET_TOUCH_CANCELLED,
                           point,
                           ui::EF_IS_SYNTHESIZED,
                           pointer_state_clone->GetPointerId(i),
                           ui::EventTimeForNow(),
                           0.0f,
                           0.0f,
                           0.0f,
                           0.0f);
    GestureEventHelper* helper = FindDispatchHelperForConsumer(consumer);
    if (helper)
      helper->DispatchCancelTouchEvent(&touch_event);
    cancelled_touch = true;
  }
  return cancelled_touch;
}

////////////////////////////////////////////////////////////////////////////////
// GestureRecognizerImpl, private:

GestureProviderImpl* GestureRecognizerImpl::GetGestureProviderForConsumer(
    GestureConsumer* consumer) {
  GestureProviderImpl* gesture_provider = consumer_gesture_provider_[consumer];
  if (!gesture_provider) {
    gesture_provider = CreateGestureProvider(this);
    consumer_gesture_provider_[consumer] = gesture_provider;
  }
  return gesture_provider;
}

void GestureRecognizerImpl::SetupTargets(const TouchEvent& event,
                                         GestureConsumer* target) {
  if (event.type() == ui::ET_TOUCH_RELEASED ||
      event.type() == ui::ET_TOUCH_CANCELLED) {
    touch_id_target_.erase(event.touch_id());
  } else if (event.type() == ui::ET_TOUCH_PRESSED) {
    touch_id_target_[event.touch_id()] = target;
    if (target)
      touch_id_target_for_gestures_[event.touch_id()] = target;
  }
}

void GestureRecognizerImpl::DispatchGestureEvent(GestureEvent* event) {
  GestureConsumer* consumer = GetTargetForGestureEvent(*event);
  if (consumer) {
    GestureEventHelper* helper = FindDispatchHelperForConsumer(consumer);
    if (helper)
      helper->DispatchGestureEvent(event);
  }
}

bool GestureRecognizerImpl::ProcessTouchEventPreDispatch(
    const TouchEvent& event,
    GestureConsumer* consumer) {
  SetupTargets(event, consumer);

  if (event.result() & ER_CONSUMED)
    return false;

  GestureProviderImpl* gesture_provider =
      GetGestureProviderForConsumer(consumer);
  return gesture_provider->OnTouchEvent(event);
}

GestureRecognizer::Gestures*
GestureRecognizerImpl::ProcessTouchEventPostDispatch(
    const TouchEvent& event,
    ui::EventResult result,
    GestureConsumer* consumer) {
  GestureProviderImpl* gesture_provider =
      GetGestureProviderForConsumer(consumer);
  gesture_provider->OnTouchEventAck(result != ER_UNHANDLED);
  return gesture_provider->GetAndResetPendingGestures();
}

GestureRecognizer::Gestures* GestureRecognizerImpl::ProcessTouchEventOnAsyncAck(
    const TouchEvent& event,
    ui::EventResult result,
    GestureConsumer* consumer) {
  if (result & ui::ER_CONSUMED)
    return NULL;
  GestureProviderImpl* gesture_provider =
      GetGestureProviderForConsumer(consumer);
  gesture_provider->OnTouchEventAck(result != ER_UNHANDLED);
  return gesture_provider->GetAndResetPendingGestures();
}

bool GestureRecognizerImpl::CleanupStateForConsumer(
    GestureConsumer* consumer) {
  bool state_cleaned_up = false;

  if (consumer_gesture_provider_.count(consumer)) {
    state_cleaned_up = true;
    delete consumer_gesture_provider_[consumer];
    consumer_gesture_provider_.erase(consumer);
  }

  state_cleaned_up |= RemoveConsumerFromMap(consumer, &touch_id_target_);
  state_cleaned_up |=
      RemoveConsumerFromMap(consumer, &touch_id_target_for_gestures_);
  return state_cleaned_up;
}

void GestureRecognizerImpl::AddGestureEventHelper(GestureEventHelper* helper) {
  helpers_.push_back(helper);
}

void GestureRecognizerImpl::RemoveGestureEventHelper(
    GestureEventHelper* helper) {
  std::vector<GestureEventHelper*>::iterator it = std::find(helpers_.begin(),
      helpers_.end(), helper);
  if (it != helpers_.end())
    helpers_.erase(it);
}

void GestureRecognizerImpl::OnGestureEvent(GestureEvent* event) {
  DispatchGestureEvent(event);
}

GestureEventHelper* GestureRecognizerImpl::FindDispatchHelperForConsumer(
    GestureConsumer* consumer) {
  std::vector<GestureEventHelper*>::iterator it;
  for (it = helpers_.begin(); it != helpers_.end(); ++it) {
    if ((*it)->CanDispatchToConsumer(consumer))
      return (*it);
  }
  return NULL;
}

// GestureRecognizer, static
GestureRecognizer* GestureRecognizer::Create() {
  return new GestureRecognizerImpl();
}

static GestureRecognizerImpl* g_gesture_recognizer_instance = NULL;

// GestureRecognizer, static
GestureRecognizer* GestureRecognizer::Get() {
  if (!g_gesture_recognizer_instance)
    g_gesture_recognizer_instance = new GestureRecognizerImpl();
  return g_gesture_recognizer_instance;
}

// GestureRecognizer, static
void GestureRecognizer::Reset() {
  delete g_gesture_recognizer_instance;
  g_gesture_recognizer_instance = NULL;
}

void SetGestureRecognizerForTesting(GestureRecognizer* gesture_recognizer) {
  // Transfer helpers to the new GR.
  std::vector<GestureEventHelper*>& helpers =
      g_gesture_recognizer_instance->helpers();
  std::vector<GestureEventHelper*>::iterator it;
  for (it = helpers.begin(); it != helpers.end(); ++it)
    gesture_recognizer->AddGestureEventHelper(*it);

  helpers.clear();
  g_gesture_recognizer_instance =
      static_cast<GestureRecognizerImpl*>(gesture_recognizer);
}

}  // namespace ui
