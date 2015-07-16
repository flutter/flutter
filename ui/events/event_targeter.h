// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_EVENT_TARGETER_H_
#define UI_EVENTS_EVENT_TARGETER_H_

#include "base/compiler_specific.h"
#include "ui/events/event.h"
#include "ui/events/events_export.h"

namespace ui {

class Event;
class EventTarget;
class LocatedEvent;

class EVENTS_EXPORT EventTargeter {
 public:
  virtual ~EventTargeter();

  // Returns the target |event| should be dispatched to. If there is no such
  // target, return NULL. If |event| is a located event, the location of |event|
  // is in the coordinate space of |root|. Furthermore, the targeter can mutate
  // the event (e.g., by changing the location of the event to be in the
  // returned target's coordinate space) so that it can be dispatched to the
  // target without any further modification.
  virtual EventTarget* FindTargetForEvent(EventTarget* root,
                                          Event* event);

  // Same as FindTargetForEvent(), but used for positional events. The location
  // etc. of |event| are in |root|'s coordinate system. When finding the target
  // for the event, the targeter can mutate the |event| (e.g. change the
  // coordinate to be in the returned target's coordinate system) so that it can
  // be dispatched to the target without any further modification.
  // TODO(tdanderson|sadrul): This should not be in the public API of
  //                          EventTargeter.
  virtual EventTarget* FindTargetForLocatedEvent(EventTarget* root,
                                                 LocatedEvent* event);

  // Returns true if |target| or one of its descendants can be a target of
  // |event|. This requires that |target| and its descendants are not
  // prohibited from accepting the event, and that the event is within an
  // actionable region of the target's bounds. Note that the location etc. of
  // |event| is in |target|'s parent's coordinate system.
  // TODO(tdanderson|sadrul): This function should be made non-virtual and
  //                          non-public.
  virtual bool SubtreeShouldBeExploredForEvent(EventTarget* target,
                                               const LocatedEvent& event);

  // Returns the next best target for |event| as compared to |previous_target|.
  // |event| is in the local coordinate space of |previous_target|.
  // Also mutates |event| so that it can be dispatched to the returned target
  // (e.g., by changing |event|'s location to be in the returned target's
  // coordinate space).
  virtual EventTarget* FindNextBestTarget(EventTarget* previous_target,
                                          Event* event);

 protected:
  // Returns false if neither |target| nor any of its descendants are allowed
  // to accept |event| for reasons unrelated to the event's location or the
  // target's bounds. For example, overrides of this function may consider
  // attributes such as the visibility or enabledness of |target|. Note that
  // the location etc. of |event| is in |target|'s parent's coordinate system.
  virtual bool SubtreeCanAcceptEvent(EventTarget* target,
                                     const LocatedEvent& event) const;

  // Returns whether the location of the event is in an actionable region of the
  // target. Note that the location etc. of |event| is in the |target|'s
  // parent's coordinate system.
  virtual bool EventLocationInsideBounds(EventTarget* target,
                                         const LocatedEvent& event) const;
};

}  // namespace ui

#endif  // UI_EVENTS_EVENT_TARGETER_H_
