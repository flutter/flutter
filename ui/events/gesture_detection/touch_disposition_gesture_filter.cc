// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/gesture_detection/touch_disposition_gesture_filter.h"

#include "base/auto_reset.h"
#include "base/logging.h"
#include "ui/events/gesture_event_details.h"

namespace ui {
namespace {

// A BitSet32 is used for tracking dropped gesture types.
COMPILE_ASSERT(ET_GESTURE_TYPE_END - ET_GESTURE_TYPE_START < 32,
               gesture_type_count_too_large);

GestureEventData CreateGesture(EventType type,
                               int motion_event_id,
                               MotionEvent::ToolType primary_tool_type,
                               const GestureEventDataPacket& packet) {
  // As the event is purely synthetic, we needn't be strict with event flags.
  int flags = EF_NONE;
  return GestureEventData(GestureEventDetails(type),
                          motion_event_id,
                          primary_tool_type,
                          packet.timestamp(),
                          packet.touch_location().x(),
                          packet.touch_location().y(),
                          packet.raw_touch_location().x(),
                          packet.raw_touch_location().y(),
                          1,
                          gfx::RectF(packet.touch_location(), gfx::SizeF()),
                          flags);
}

enum RequiredTouches {
  RT_NONE = 0,
  RT_START = 1 << 0,
  RT_CURRENT = 1 << 1,
};

struct DispositionHandlingInfo {
  // A bitwise-OR of |RequiredTouches|.
  int required_touches;
  EventType antecedent_event_type;

  explicit DispositionHandlingInfo(int required_touches)
      : required_touches(required_touches), antecedent_event_type(ET_UNKNOWN) {}

  DispositionHandlingInfo(int required_touches,
                          EventType antecedent_event_type)
      : required_touches(required_touches),
        antecedent_event_type(antecedent_event_type) {}
};

DispositionHandlingInfo Info(int required_touches) {
  return DispositionHandlingInfo(required_touches);
}

DispositionHandlingInfo Info(int required_touches,
                             EventType antecedent_event_type) {
  return DispositionHandlingInfo(required_touches, antecedent_event_type);
}

// This approach to disposition handling is described at http://goo.gl/5G8PWJ.
DispositionHandlingInfo GetDispositionHandlingInfo(EventType type) {
  switch (type) {
    case ET_GESTURE_TAP_DOWN:
      return Info(RT_START);
    case ET_GESTURE_TAP_CANCEL:
      return Info(RT_START);
    case ET_GESTURE_SHOW_PRESS:
      return Info(RT_START);
    case ET_GESTURE_LONG_PRESS:
      return Info(RT_START);
    case ET_GESTURE_LONG_TAP:
      return Info(RT_START | RT_CURRENT);
    case ET_GESTURE_TAP:
      return Info(RT_START | RT_CURRENT, ET_GESTURE_TAP_UNCONFIRMED);
    case ET_GESTURE_TAP_UNCONFIRMED:
      return Info(RT_START | RT_CURRENT);
    case ET_GESTURE_DOUBLE_TAP:
      return Info(RT_START | RT_CURRENT, ET_GESTURE_TAP_UNCONFIRMED);
    case ET_GESTURE_SCROLL_BEGIN:
      return Info(RT_START);
    case ET_GESTURE_SCROLL_UPDATE:
      return Info(RT_CURRENT, ET_GESTURE_SCROLL_BEGIN);
    case ET_GESTURE_SCROLL_END:
      return Info(RT_NONE, ET_GESTURE_SCROLL_BEGIN);
    case ET_SCROLL_FLING_START:
      // We rely on |EndScrollGestureIfNecessary| to end the scroll if the fling
      // start is prevented.
      return Info(RT_NONE, ET_GESTURE_SCROLL_UPDATE);
    case ET_SCROLL_FLING_CANCEL:
      return Info(RT_NONE, ET_SCROLL_FLING_START);
    case ET_GESTURE_PINCH_BEGIN:
      return Info(RT_START, ET_GESTURE_SCROLL_BEGIN);
    case ET_GESTURE_PINCH_UPDATE:
      return Info(RT_CURRENT, ET_GESTURE_PINCH_BEGIN);
    case ET_GESTURE_PINCH_END:
      return Info(RT_NONE, ET_GESTURE_PINCH_BEGIN);
    case ET_GESTURE_BEGIN:
      return Info(RT_START);
    case ET_GESTURE_END:
      return Info(RT_NONE, ET_GESTURE_BEGIN);
    case ET_GESTURE_SWIPE:
      return Info(RT_START, ET_GESTURE_SCROLL_BEGIN);
    case ET_GESTURE_TWO_FINGER_TAP:
      return Info(RT_START);
    default:
      break;
  }
  NOTREACHED();
  return Info(RT_NONE);
}

int GetGestureTypeIndex(EventType type) {
  DCHECK_GE(type, ET_GESTURE_TYPE_START);
  DCHECK_LE(type, ET_GESTURE_TYPE_END);
  return type - ET_GESTURE_TYPE_START;
}

bool IsTouchStartEvent(GestureEventDataPacket::GestureSource gesture_source) {
  return gesture_source == GestureEventDataPacket::TOUCH_SEQUENCE_START ||
         gesture_source == GestureEventDataPacket::TOUCH_START;
}

}  // namespace

// TouchDispositionGestureFilter

TouchDispositionGestureFilter::TouchDispositionGestureFilter(
    TouchDispositionGestureFilterClient* client)
    : client_(client),
      ending_event_motion_event_id_(0),
      ending_event_primary_tool_type_(MotionEvent::TOOL_TYPE_UNKNOWN),
      needs_tap_ending_event_(false),
      needs_show_press_event_(false),
      needs_fling_ending_event_(false),
      needs_scroll_ending_event_(false) {
  DCHECK(client_);
}

TouchDispositionGestureFilter::~TouchDispositionGestureFilter() {
}

TouchDispositionGestureFilter::PacketResult
TouchDispositionGestureFilter::OnGesturePacket(
    const GestureEventDataPacket& packet) {
  if (packet.gesture_source() == GestureEventDataPacket::UNDEFINED ||
      packet.gesture_source() == GestureEventDataPacket::INVALID)
    return INVALID_PACKET_TYPE;

  if (packet.gesture_source() == GestureEventDataPacket::TOUCH_SEQUENCE_START)
    sequences_.push(GestureSequence());

  if (IsEmpty())
    return INVALID_PACKET_ORDER;

  if (packet.gesture_source() == GestureEventDataPacket::TOUCH_TIMEOUT &&
      Tail().empty()) {
    // Handle the timeout packet immediately if the packet preceding the timeout
    // has already been dispatched.
    FilterAndSendPacket(packet);
    return SUCCESS;
  }

  Tail().push(packet);
  return SUCCESS;
}

void TouchDispositionGestureFilter::OnTouchEventAck(bool event_consumed) {
  // Spurious touch acks from the renderer should not trigger a crash.
  if (IsEmpty() || (Head().empty() && sequences_.size() == 1))
    return;

  if (Head().empty())
    PopGestureSequence();

  GestureSequence& sequence = Head();

  // Dispatch the packet corresponding to the ack'ed touch, as well as any
  // additional timeout-based packets queued before the ack was received.
  bool touch_packet_for_current_ack_handled = false;
  while (!sequence.empty()) {
    DCHECK_NE(sequence.front().gesture_source(),
              GestureEventDataPacket::UNDEFINED);
    DCHECK_NE(sequence.front().gesture_source(),
              GestureEventDataPacket::INVALID);

    GestureEventDataPacket::GestureSource source =
        sequence.front().gesture_source();
    if (source != GestureEventDataPacket::TOUCH_TIMEOUT) {
      // We should handle at most one non-timeout based packet.
      if (touch_packet_for_current_ack_handled)
        break;
      state_.OnTouchEventAck(event_consumed, IsTouchStartEvent(source));
      touch_packet_for_current_ack_handled = true;
    }
    // We need to pop the current sequence before sending the packet, because
    // sending the packet could result in this method being re-entered (e.g. on
    // Aura, we could trigger a touch-cancel). As popping the sequence destroys
    // the packet, we copy the packet before popping it.
    const GestureEventDataPacket packet = sequence.front();
    sequence.pop();
    FilterAndSendPacket(packet);
  }
  DCHECK(touch_packet_for_current_ack_handled);
}

bool TouchDispositionGestureFilter::IsEmpty() const {
  return sequences_.empty();
}

void TouchDispositionGestureFilter::FilterAndSendPacket(
    const GestureEventDataPacket& packet) {
  if (packet.gesture_source() == GestureEventDataPacket::TOUCH_SEQUENCE_START) {
    CancelTapIfNecessary(packet);
    EndScrollIfNecessary(packet);
    CancelFlingIfNecessary(packet);
  } else if (packet.gesture_source() == GestureEventDataPacket::TOUCH_START) {
    CancelTapIfNecessary(packet);
  }
  int gesture_end_index = -1;
  for (size_t i = 0; i < packet.gesture_count(); ++i) {
    const GestureEventData& gesture = packet.gesture(i);
    DCHECK_GE(gesture.details.type(), ET_GESTURE_TYPE_START);
    DCHECK_LE(gesture.details.type(), ET_GESTURE_TYPE_END);
    if (state_.Filter(gesture.details.type())) {
      CancelTapIfNecessary(packet);
      continue;
    }
    if (packet.gesture_source() == GestureEventDataPacket::TOUCH_TIMEOUT) {
      // Sending a timed gesture could delete |this|, so we need to return
      // directly after the |SendGesture| call.
      SendGesture(gesture, packet);
      // We should not have a timeout gesture and other gestures in the same
      // packet.
      DCHECK_EQ(1U, packet.gesture_count());
      return;
    }
    // Occasionally scroll or tap cancel events are synthesized when a touch
    // sequence has been canceled or terminated, we want to make sure that
    // ET_GESTURE_END always happens after them.
    if (gesture.type() == ET_GESTURE_END) {
      // Make sure there is at most one ET_GESTURE_END event in each packet.
      DCHECK_EQ(-1, gesture_end_index);
      gesture_end_index = static_cast<int>(i);
      continue;
    }
    SendGesture(gesture, packet);
  }

  if (packet.gesture_source() ==
      GestureEventDataPacket::TOUCH_SEQUENCE_CANCEL) {
    EndScrollIfNecessary(packet);
    CancelTapIfNecessary(packet);
  } else if (packet.gesture_source() ==
             GestureEventDataPacket::TOUCH_SEQUENCE_END) {
    EndScrollIfNecessary(packet);
  }
  // Always send the ET_GESTURE_END event as the last one for every touch event.
  if (gesture_end_index >= 0)
    SendGesture(packet.gesture(gesture_end_index), packet);
}

void TouchDispositionGestureFilter::SendGesture(
    const GestureEventData& event,
    const GestureEventDataPacket& packet_being_sent) {
  // TODO(jdduke): Factor out gesture stream reparation code into a standalone
  // utility class.
  switch (event.type()) {
    case ET_GESTURE_LONG_TAP:
      if (!needs_tap_ending_event_)
        return;
      CancelTapIfNecessary(packet_being_sent);
      CancelFlingIfNecessary(packet_being_sent);
      break;
    case ET_GESTURE_TAP_DOWN:
      DCHECK(!needs_tap_ending_event_);
      ending_event_motion_event_id_ = event.motion_event_id;
      ending_event_primary_tool_type_ = event.primary_tool_type;
      needs_show_press_event_ = true;
      needs_tap_ending_event_ = true;
      break;
    case ET_GESTURE_SHOW_PRESS:
      if (!needs_show_press_event_)
        return;
      needs_show_press_event_ = false;
      break;
    case ET_GESTURE_DOUBLE_TAP:
      CancelTapIfNecessary(packet_being_sent);
      needs_show_press_event_ = false;
      break;
    case ET_GESTURE_TAP:
      DCHECK(needs_tap_ending_event_);
      if (needs_show_press_event_) {
        SendGesture(GestureEventData(ET_GESTURE_SHOW_PRESS, event),
                    packet_being_sent);
        DCHECK(!needs_show_press_event_);
      }
      needs_tap_ending_event_ = false;
      break;
    case ET_GESTURE_TAP_CANCEL:
      needs_show_press_event_ = false;
      needs_tap_ending_event_ = false;
      break;
    case ET_GESTURE_SCROLL_BEGIN:
      CancelTapIfNecessary(packet_being_sent);
      CancelFlingIfNecessary(packet_being_sent);
      EndScrollIfNecessary(packet_being_sent);
      ending_event_motion_event_id_ = event.motion_event_id;
      ending_event_primary_tool_type_ = event.primary_tool_type;
      needs_scroll_ending_event_ = true;
      break;
    case ET_GESTURE_SCROLL_END:
      needs_scroll_ending_event_ = false;
      break;
    case ET_SCROLL_FLING_START:
      CancelFlingIfNecessary(packet_being_sent);
      ending_event_motion_event_id_ = event.motion_event_id;
      ending_event_primary_tool_type_ = event.primary_tool_type;
      needs_fling_ending_event_ = true;
      needs_scroll_ending_event_ = false;
      break;
    case ET_SCROLL_FLING_CANCEL:
      needs_fling_ending_event_ = false;
      break;
    default:
      break;
  }
  client_->ForwardGestureEvent(event);
}

void TouchDispositionGestureFilter::CancelTapIfNecessary(
    const GestureEventDataPacket& packet_being_sent) {
  if (!needs_tap_ending_event_)
    return;

  SendGesture(CreateGesture(ET_GESTURE_TAP_CANCEL,
                            ending_event_motion_event_id_,
                            ending_event_primary_tool_type_,
                            packet_being_sent),
              packet_being_sent);
  DCHECK(!needs_tap_ending_event_);
}

void TouchDispositionGestureFilter::CancelFlingIfNecessary(
    const GestureEventDataPacket& packet_being_sent) {
  if (!needs_fling_ending_event_)
    return;

  SendGesture(CreateGesture(ET_SCROLL_FLING_CANCEL,
                            ending_event_motion_event_id_,
                            ending_event_primary_tool_type_,
                            packet_being_sent),
              packet_being_sent);
  DCHECK(!needs_fling_ending_event_);
}

void TouchDispositionGestureFilter::EndScrollIfNecessary(
    const GestureEventDataPacket& packet_being_sent) {
  if (!needs_scroll_ending_event_)
    return;

  SendGesture(CreateGesture(ET_GESTURE_SCROLL_END,
                            ending_event_motion_event_id_,
                            ending_event_primary_tool_type_,
                            packet_being_sent),
              packet_being_sent);
  DCHECK(!needs_scroll_ending_event_);
}

void TouchDispositionGestureFilter::PopGestureSequence() {
  DCHECK(Head().empty());
  state_ = GestureHandlingState();
  sequences_.pop();
}

TouchDispositionGestureFilter::GestureSequence&
TouchDispositionGestureFilter::Head() {
  DCHECK(!sequences_.empty());
  return sequences_.front();
}

TouchDispositionGestureFilter::GestureSequence&
TouchDispositionGestureFilter::Tail() {
  DCHECK(!sequences_.empty());
  return sequences_.back();
}

// TouchDispositionGestureFilter::GestureHandlingState

TouchDispositionGestureFilter::GestureHandlingState::GestureHandlingState()
    : start_touch_consumed_(false),
      current_touch_consumed_(false) {}

void TouchDispositionGestureFilter::GestureHandlingState::OnTouchEventAck(
    bool event_consumed,
    bool is_touch_start_event) {
  current_touch_consumed_ = event_consumed;
  if (event_consumed && is_touch_start_event)
    start_touch_consumed_ = true;
}

bool TouchDispositionGestureFilter::GestureHandlingState::Filter(
    EventType gesture_type) {
  DispositionHandlingInfo disposition_handling_info =
      GetDispositionHandlingInfo(gesture_type);

  int required_touches = disposition_handling_info.required_touches;
  EventType antecedent_event_type =
      disposition_handling_info.antecedent_event_type;
  if ((required_touches & RT_START && start_touch_consumed_) ||
      (required_touches & RT_CURRENT && current_touch_consumed_) ||
      (antecedent_event_type != ET_UNKNOWN &&
       last_gesture_of_type_dropped_.has_bit(
           GetGestureTypeIndex(antecedent_event_type)))) {
    last_gesture_of_type_dropped_.mark_bit(GetGestureTypeIndex(gesture_type));
    return true;
  }
  last_gesture_of_type_dropped_.clear_bit(GetGestureTypeIndex(gesture_type));
  return false;
}

}  // namespace content
