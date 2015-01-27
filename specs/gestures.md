Gestures
========

```javascript
typedef PointerID Integer;

dictionary GestureState {
  Boolean cancel = true; // if true, then cancel the gesture at this point
  Boolean capture = false; // (for pointer-down) if true, then this pointer is relevant
  Boolean choose = false; // if true, the gesture thinks that other gestures should give up
  Boolean finished = true; // if true, we're ready for the next gesture to start

  // choose and cancel are mutually exclusive
}

dictionary SendEventOptions {
  Integer? coallesceGroup = null; // when queuing events, only the last event with each group is kept
  Boolean prechoose = false; // if true, event should just be sent right away, not queued
}

abstract class Gesture : EventTarget {
  constructor (EventTarget target);
  readonly attribute EventTarget target;

  virtual GestureState processEvent(Event event);
  // return {}
  virtual void choose(); // called by GestureManager // make sure to call superclass choose() before
  // - assert: this.active == true
  // - assert: this.chosen == false
  // - set this.chosen = true
  // - if there are any buffered events, dispatch them on this
  virtual void cancel(); // called by GestureManager // make sure to call superclass cancel() after
  // - set active and chosen to false, clear the event buffer

  readonly attribute Boolean ready; // last event, we were finished
  readonly attribute Boolean active; // we have not yet been canceled since we last captured a pointer
  readonly attribute Boolean chosen; // we're the only possible gesture at this point

  // !ready && !active => we're discarding events until the user gets to a state where a new gesture can begin
  // active && !chosen => we're collecting events until no other gesture is valid, or until we take command

  void sendEvent(Event event, SendEventOptions options);
  // used internally to queue up or send events
  //  - assert: this.active == true
  //  - assert: options.prechoose is false or options.coallesceGroup
  //    is null
  //  - set event.gesture = this
  //  - if this.chosen is true or if options.prechoose is true, then
  //    send the event straight to the callback
  //  - otherwise:
  //     - if the event buffer has an entry with the same
  //       coallesceGroup identifier, drop it
  //     - add the event to the event buffer
}
```

``Gesture`` objects have an Event buffer, initially empty. Each Event
in this buffer can be associated with a coallesceGroup, which is
identified by integer.

When created, ``Gesture`` objects register themselves as pointer-down,
pointer-move, and pointer-up event handlers on their target, with the
same event handler. That event handler runs the following steps:
 - let wasActive = this.active
 - if this.ready == true, then:
    - // reset the state to start a new gesture
    - if this.active == true, then:
       - call application.document.cancelGesture(this)
    - set this.active = true
    - set this.ready = false
 - let returnValue be the result of calling ``processEvent()`` with
   the Event object
 - if returnValue.capture == true:
    - assert: the event is a pointer-down event
    - if the event is a pointer-down event:
       - push this onto the event's return value
 - if returnValue.cancel == true:
    - assert: returnValue.choose == false
    - if wasActive == true:
       - call application.document.cancelGesture(this)
       - // if wasActive == false, then no need to cancel, since we never added ourselves
 - if returnValue.cancel == false and this.active == true:
    - if wasActive == false or if event is a pointer-down event:
       - call application.document.addGesture(event, this)
    - if returnValue.choose == true:
       - call application.document.chooseGesture(this)
 - set this.ready = returnValue.finished
 - set this.active = returnValue.valid

Subclasses should override ``processEvent()``:
 - as the events are received, they get examined to see if they
   fit the pattern for the gesture; if they do, then return an
   object with valid=true; if more events for this gesture could
   still come in, return finished=false.
 - if you returned valid=false finished=false, then the next call
   to this must not return valid=true
 - doing anything with the event or target other than reading
   state is a contract violation
 - you are allowed to call sendEvent() at any time during a
   processEventInternal() call, or after a call to
   processEventInternal(), assuming that the last such call returned
   valid=true, until the next call to processEventInternal() or
   cancel().
 - set forceChoose=true on the return value if you are confident
   that this is the gesture the user meant, even if it's possible
   that another gesture is still claiming it's valid (e.g. a long
   press might forceChoose to override a scroll, if the user
   hasn't moved for a while)
 - if you send events, you can set prechoose=true to send the
   event even before the gesture has been chosen
 - if you send prechoose events, make sure to send corresponding
   "cancel" events if cancel() is called

```javascript
dictionary GestureList {
  Array<Gesture> gestures;
  Boolean chosen;
}

class GestureManager {
  constructor (EventTarget target);
  readonly attribute EventTarget target; // the ApplicationDocument, normally

  void addGesture(Event event, Gesture gesture);
  void cancelGesture(Gesture gesture);
  void chooseGesture(Gesture gesture);

  GestureList getActiveGestures(PointerID pointer);
}
```

``GestureManager`` objects have a map of lists of Gesture objects,
keyed on pointer IDs, and with each list associated with a "chosen"
flag indicating if an entry in the list has already been chosen.
Initially the map is empty. It is exposed by the
``getActiveGestures()`` method, which returns the list and flag.

When addGesture() is called with an event and a Gesture, it runs the
following steps:
 - let pointer be the value of the event's pointer field
 - assert: pointer is an integer
 - if we already have an entry for pointer:
    - assert: this Gesture isn't already on the list for pointer
    - if the list's "chosen" flag is set, then call
      ``cancelGesture()`` with this Gesture
    - otherwise, add this Gesture to the list for pointer
 - otherwise, we don't have an entry for this pointer:
    - create a list for pointer
    - add this Gesture to the list for pointer

A ``GestureManager``, when created, starts listening to
``pointer-down`` events on its target. The listener acts as follows:
 - assert: event is a ``pointer-down`` event
 - let pointer be the value of the event's pointer field
 - if we have an entry for this pointer, and the "chosen" flag isn't
   set, and there is just one Gesture in the list, then set the flag
   on the list and call the Gesture's ``choose()`` method.

When ``cancelGesture()`` is called with a Gesture:
 - for each pointer list:
    - if the pointer list has this Gesture, remove it
 - call cancel() on the Gesture
 - for each pointer list:
    - if the pointer list has no entries, forget it
    - if the pointer list has one Gesture and the "chosen" flag isn't
      set, set it and call that Gesture's ``choose()`` method.

When ``chooseGesture()`` is called with a Gesture:
 - if this Gesture is not active, then return silently
   // this could happen e.g. if two gestures simultaneously add themselves
   // and chose themselves for the same pointer-down
 - let losers be an empty list of Gestures
 - for each pointer list:
    - if the pointer list has this Gesture, add all the other Gestures
      in the list to losers, remove them from the list, and set the
      "chosen" flag on that list
 - remove duplicates from losers
 - call ``cancel()`` on each entry in losers
 - call ``choose()`` on the Gesture


```javascript
class TapGesture : Gesture {

  // internal state:
  //   Integer numButtons = 0;
  //   Boolean primaryDown = false;

  virtual GestureState processEvent(Event event);
  // - let returnValue = { finished = false }
  // - if the event is a pointer-down:
  //    - increment this.numButtons
  //    - set returnValue.capture = true
  // - otherwise if it is a pointer-up:
  //    - assert: this.numButtons > 0
  //    - decrement this.numButtons
  //    - if numButtons == 0:
  //       - set returnValue.finished = true
  // - if this.ready == false and this.active == false:
  //    - return returnValue
  // - if EventTarget isn't an Element:
  //    - assert: event is a pointer-down
  //    - return returnValue
  // - if the event is pointer-down:
  //    - assert: this.numButtons > 0
  //    - if it's primary:
  //       - assert: this.ready==true // this is the first press
  //       - this.primaryDown = true
  //       - sendEvent() a tap-down event, with prechoose=true
  //       - set returnValue.cancel = false
  //       - return returnValue
  //    - otherwise:
  //       - if this.primaryDown == true and this.active == true:
  //          - // this is some bogus secondary press that we should have prevent
  //            // taps from starting until it's finished, but it doesn't invalidate
  //            // the existing primary press
  //          - set returnValue.cancel = false
  //          - return returnValue
  //       - otherwise:
  //          - // this is some secondary press but we don't have a first press
  //            // (maybe this is all in the context of a right-click or something)
  //            // we have to wait til it's done before we can start a tap gesture again
  //          - return returnValue
  // - if the event is pointer-move:
  //    - assert: this.numButtons > 0
  //    - if it's primary:
  //       - if it hit tests within target's bounding box:
  //          - sendEvent() a tap-move event, with prechoose=true
  //          - set returnValue.cancel = false
  //          - return returnValue
  //       - otherwise:
  //          - sendEvent() a tap-cancel event, with prechoose=true
  //          - return returnValue
  //    - otherwise:
  //       - // this is the move of some bogus secondary press
  //         // ignore it, but continue listening if we have a primary button down
  //       - if this.primaryDown == true and this.active == true:
  //          - set returnValue.cancel = false
  //       - return returnValue
  // - if the event is pointer-up:
  //    - if it's primary:
  //       - sendEvent() a tap event
  //       - set this.primaryDown = false
  //       - set returnValue.cancel = false
  //       - return returnValue
  //    - otherwise:
  //       - // this is the 'up' of some bogus secondary press
  //         // ignore it, but continue listening for our primary up if necessary
  //       - if this.primaryDown == true and this.active == true:
  //          - set returnValue.cancel = false
  //       - return returnValue
}

class LongPressGesture : Gesture {
  GestureState processEvent(EventTarget target, Event event);  
  // long-tap-start: sent when the primary pointer goes down
  // long-tap-cancel: sent when cancel()ed or finger goes out of bounding box
  // long-tap: sent when the primary pointer is released
}

class DoubleTapGesture : Gesture {
  GestureState processEvent(EventTarget target, Event event);  
  // double-tap-start: sent when the primary pointer goes down the first time
  // double-tap-cancel: sent when cancel()ed or finger goes out of bounding box, or it times out
  // double-tap: sent when the primary pointer is released the second time within the timeout
}


abstract class ScrollGesture : Gesture {
  GestureState processEvent(EventTarget target, Event event);  
  // this fires the following events (inertia is a boolean, delta is a float):
  //   scroll-start, with field inertia=false, delta=0; prechoose=true
  //   scroll, with fields inertia (is this a simulated scroll from inertia or a real scroll?), delta (number of pixels to scroll); prechoose=true
  //   scroll-end, with field inertia (same), delta=0; prechoose=true
  // scroll-start is fired right away
  // scroll is sent whenever the primary pointer moves while down
  // scroll is also sent after the pointer goes back up, based on inertia
  // scroll-end is sent after the pointer goes back up once the scroll reaches delta=0
  // scroll-end is also sent when the gesture is canceled or reset
  // processEvent() returns:
  //  - cancel=false pretty much always so long as there's a primary touch (e.g. not for a right-click)
  //  - chose=true when you travel a certain distance
  //  - finished=true when the primary pointer goes up
}

class HorizontalScrollGesture : ScrollGesture { }
  // a ScrollGesture giving x-axis scrolling

class VerticalScrollGesture : ScrollGesture { }
  // a ScrollGesture giving y-axis scrolling


class PanGesture : Gesture {
  // similar to ScrollGesture, but with two axes
  // pan-start, pan, pan-end
  // events have inertia (boolean), dx (float), dy (float)
}


abstract class ZoomGesture : Gesture {
  GestureState processEvent(EventTarget target, Event event);  
  // zoom-start: sent when we could start zooming (e.g. for pinch-zoom, when two fingers hit the glass) (prechoose)
  // zoom-end: sent when cancel()ed after zoom-start, or when the fingers are lifted (prechoose)
  // zoom, with a 'scale' attribute, whose value is a multiple of the scale factor at zoom-start
  // e.g. if the user zooms to 2x, you'd get a bunch of 'zoom' events like scale=1.0, scale=1.17, ... scale=1.91, scale=2.0
}

class PinchZoomGesture : ZoomGesture {
  // a ZoomGesture for two-finger-pinch gesture
  // zoom is prechoose
}

class DoubleTapZoomGesture : ZoomGesture {
  // a ZoomGesture for the double-tap-slide gesture
  // when the slide starts, forceChoose
}


class PanAndZoomGesture : Gesture {
  GestureState processEvent(EventTarget target, Event event);  
  // manipulate-start (prechoose)
  // manipulate: (prechoose)
  //    panX, panY: pixels
  //    scaleX, scaleY: a multiplier of the scale at manipulate-start
  //    rotation: turns
  // manipulate-end (prechoose)
}


abstract class FlingGesture : Gesture {
  GestureState processEvent(EventTarget target, Event event);  
  // fling-start: when the gesture begins (prechoose)
  // fling-move: while the user is directly dragging the element (has delta attribute with the distance from fling-start) (prechoose)
  // fling: the user has released the pointer and the decision is it was in fact flung
  // fling-cancel: cancel(), or the user has released the pointer and the decision is it was not flung (prechoose)
  // fling-end: cancel(), or after fling or fling-cancel (prechoose)
}

class FlingLeftGesture : FlingGesture { }
class FlingRightGesture : FlingGesture { }
class FlingUpGesture : FlingGesture { }
class FlingDownGesture : FlingGesture { }

```
