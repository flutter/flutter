Gestures
========

TODO(ianh): make it possible for a Gesture to time out and cancel even
without having seen a pointer event, to handle double-tap events

TODO(ianh): even with that, we should keep track of finished-but-valid
candidates so that when double-tap cancels itself, the tap, which was
still valid even though it's done, can be accepted

```javascript

callback GestureCallback void (Event event);

dictionary GestureState {
  Boolean valid = false; // if true, the event was part of the current gesture
    Boolean forceCommit = false; // if true, the gesture thinks that other gestures should give up
  Boolean finished = true; // if true, we're ready for the next gesture to start
}

dictionary SendEventOptions {
  Integer? coallesceGroup = null; // when queuing events, only the last event with each group is kept
  Boolean precommit = false; // if true, event should just be sent right away, not queued
}

abstract class Gesture {
  constructor ();

  attribute GestureCallback callback;
  // set by GestureChooser to point to itself

  GestureState processEvent(EventTarget target, Event event);
  //  - if this.ready=true:
  //     - clear the sendEvent() buffer
  //     - set this.accepted = false
  //  - let returnValue = this.processEventInternal(...)
  //  - if this.discarding:
  //     - assert: returnValue.valid == false
  //  - if returnValue.valid == false
  //     - assert: returnValue.forceCommit == false
  //  - if !returnValue.valid, then:
  //     - clear the sendEvent() buffer
  //     - set this.accepted = false
  //  - set this.canceled = !returnValue.valid
  //  - set this.ready = returnValue.finished
  //  - set this.discarding = !returnValue.valid && !returnValue.finished
  //  - set this.active = returnValue.valid && !returnValue.finished
  //  - return returnValue

  readonly attribute Boolean canceled; // defaults to false
  // true if either the last time processEvent was invoked, valid was
  // false, or, we have been cancel()ed

  readonly attribute Boolean ready; // defaults to true
  // true if the last time processEvent was invoked, the gesture was
  // over

  readonly attribute Boolean discarding; // defaults to false
  // true if the last time processEvent was invoked, valid was false
  // and finished was false, or, we have been cancel()ed
  // (aka canceled && !ready)

  readonly attribute Boolean active; // defaults to false
  // true if the last time processEvent was invoked, valid was true
  // and finished was false, and we haven't been cancel()ed
  // (aka !canceled && !ready)

  readonly attribute Boolean accepted; // defaults to false
  // true accept() was called and we haven't been cancel()ed since

  void accept();
  // assert: this.canceled == false
  // set accepted = true
  // send the buffered gesture events to the callback
  //  - call this immediately after getting a positive result from
  //    processEvent()

  virtual void cancel();
  // called to indicate that this gesture isn't going to be chosen,
  // or if it was chosen, that it is finished
  //  - assert: this.canceled == false
  //  - set this.canceled = true
  //  - set this.discarding = !this.ready
  //  - set this.active = false
  //  - clear the sendEvent() buffer
  //  - set this.accepted = false
  //  - descendants may override this if they have more state to drop,
  //    or if they want to send an event to report that it's canceled,
  //    especially if this.accepted is true

  virtual void reset();
  // called immediately after the first pointer-down of a possible
  // gesture is sent to processEvents() to indicate that the pointer
  // wasn't captured so we are to forget anything ever happened (later
  // pointer-downs are always captured)
  //  - set this.canceled = true
  //  - set this.ready = true
  //  - set this.discarding = false
  //  - set this.active = false
  //  - clear the sendEvent() buffer
  //  - set this.accepted = false
  //  - descendants may override this if they have more state to drop

  // internal API:

  virtual GestureState processEventInternal(EventTarget target, Event event);
  // descendants override this
  // default implementation returns { } (defaults)
  //  - if this.discarding == false, then:
  //      - optionally, call sendEvent() to fire gesture-specific
  //        events
  //  - as the events are received, they get examined to see if they
  //    fit the pattern for the gesture; if they do, then return an
  //    object with valid=true; if more events for this gesture could
  //    still come in, return finished=false.
  //  - if you returned valid=false finished=false, then the next call
  //    to this must not return valid=true
  //  - doing anything with the event or target other than reading
  //    state is a contract violation
  //  - you are allowed to call sendEvent() at any time during a
  //    processEventInternal() call, or after a call to
  //    processEventInternal(), assuming that the last such call
  //    returned either valid=true or finished=true, until the next
  //    call to processEventInternal() or cancel().
  //  - set forceCommit=true on the return value if you are confident
  //    that this is the gesture the user meant, even if it's possible
  //    that another gesture is still claiming it's valid (e.g. a long
  //    press might forceCommit to override a scroll, if the user
  //    hasn't moved for a while)
  //  - if you send events, you can set precommit=true to send the
  //    event even before the gesture has been accepted
  //  - if you send precommit events, make sure to send corresponding
  //    "cancel" events if reset() or cancel() are called

  void sendEvent(Event event, SendEventOptions options);
  // used internally to queue up or send events
  //  - assert: this.discarding == false
  //  - assert: options.precommit is false or options.coallesceGroup
  //    is null
  //  - set event.gesture = this
  //  - if this.accepted is true or if options.precommit is true, then
  //    send the event straight to the callback
  //  - otherwise:
  //     - if the buffer has an entry with the same coallesceGroup
  //       identifier, drop it
  //     - add the event to the buffer
}

class GestureChooser : EventTarget {
  constructor (EventTarget? target = null, Array<Gesture> candidates = []);
  // throws if any of the candidates are active

  readonly attribute EventTarget? target;
  void setTarget(EventTarget? target);

  Array<Gesture> getGestures();
  void addGesture(Gesture candidate);
  // throw if candidates.active is true
  void removeGesture(Gesture candidate);
  // if active is true and candidate was the last Gesture in our list
  // to be active, set active and accepted to false

  // while target is not null and the list of candidates is not empty,
  // ensures that it is registered as an event listener for
  // pointer-down, pointer-move, and pointer-up events on the target;
  // when the target changes, or when the list of candidates is
  // emptied, unregisters itself

  readonly attribute Boolean active; // at least one of the gestures is active (initially false)
  readonly attribute Boolean accepted; // we accepted a gesture since the last time active was false (initially false)

  // internal state:
  // /candidates/ is a list of Gesture objects, initially empty
  //
  // any time one of the pointer events is received:
  // - if it's pointer-down and it's already captured, ignore the
  //   event and skip the remaining steps
  // - let captured be a boolean
  // - if /candidates/ is empty, then:
  //    - set captured to false
  //    - if accepted is true, call cancel() on whatever the last
  //      accepted candidate was, if any
  //    - add all the registered Gestures to /candidates/
  // - otherwise:
  //    - set captured to true
  //    - if it's pointer-down, capture the event
  // - call processEvent() with the event on all the Gestures in
  //   /candidates/, collecting their return values (GestureState
  //   objects)
  // - set forcingAccept to false
  // - set willAccept to null
  // - for each Gesture in /candidates/, in registration order:
  //    - if it returned valid==false, then 
  //       - if it is our last accepted candidate, then:
  //          - set this.accepted = false
  //    - if it returned valid==true:
  //       - if it's pointer-down, then:
  //          - set captured to true
  //          - capture the event
  //       - if this.accepted == true:
  //          - assert: this Gesture is the last accepted candidate
  //       - if it returned forceCommit==true then:
  //          - assert that its accepted attribute is false
  //          - if forcingAccept is false, then: 
  //             - set willAccept to this Gesture
  //             - set forcingAccept to true
  //       - otherwise:
  //          - if forcingAccept is false:
  //             - if willAccept is null:
  //                - set willAccept to this Gesture
  //             - otherwise:
  //                - set willAccept to 'undecided'
  //    - if it returned finished==true
  //       - remove the Gesture from /candidates/
  // - if willAccept is set to a Gesture:
  //    - set this.accepted = true
  //    - call the Gesture's accept() method; this is now the last
  //      accepted candidate
  //    - call cancel() on all the other Gesture objects that returned
  //      valid==true
  // - if captured is false:
  //    - call reset() on all the gestures in /candidates/, and then
  //      let /candidates/ be empty
  // - if /candidates/ is now empty, then set active to false;
  //   otherwise, set active to true

}

class TapGesture : Gesture {

  // internal state:
  //   Integer numButtons = 0;
  //   Boolean primaryDown = false;

  virtual Boolean internalProcessEvent(EventTarget target, Event event);
  // - if the event is a pointer-down:
  //    - increment this.numButtons
  // - otherwise if it is a pointer-up:
  //    - assert: this.numButtons > 0
  //    - decrement this.numButtons
  // - if this.discarding == true:
  //      return { valid: false, finished: this.numButtons == 0 }
  // - if EventTarget isn't an Element:
  //    - assert: event is a pointer-down
  //    - assert: this.numButtons > 0
  //    - return { valid: false, finished: false }
  // - if the event is pointer-down:
  //    - assert: this.numButtons > 0
  //    - if it's primary:
  //       - assert: this.ready==true // this is the first press
  //       - this.primaryDown = true
  //       - sendEvent() a tap-down event, with precommit=true
  //       - return { valid: true, finished: false }
  //    - otherwise:
  //       - if this.ready == false:
  //          - // this is a right-click or similar
  //          - return { valid: false, finished: false }
  //       - otherwise, if this.canceled==false:
  //          - assert: this.active==true
  //          - // this is some bogus secondary press that we should ignore
  //            // but it doesn't invalidate the existing primary press
  //          - return { valid true, finished: false }
  //       - otherwise:
  //          - // this is some secondary press but we don't have a first press
  //            // we have to wait til it's done before we can start a
  //            // tap gesture again
  //          - return { valid: false, finished: false }
  // - otherwise:
  //   - assert: this.active
  //     // if we're ready, forcibly the first event we'll see is a pointer-down,
  //     // so this.ready will never be true here
  //     // if we're cancelled, then we won't get to here
  //   - if the event is pointer-move:
  //      - assert: this.numButtons > 0
  //        // because otherwise we would have lost capture and thus not be getting the events
  //      - if it's primary:
  //         - if it hit tests within target's bounding box:
  //            - sendEvent() a tap-move event, with precommit=true
  //            - return { valid: true, finished: false }
  //         - otherwise:
  //            - sendEvent() a tap-cancel event, with precommit=true
  //            - return { valid: false, finished: false }
  //      - otherwise:
  //         - // this is the move of some bogus secondary press
  //           // ignore it, but continue listening
  //         - return { valid: true, finished: false }
  //   - if the event is pointer-up:
  //      - if it's primary:
  //         - sendEvent() a tap event
  //         - this.primaryDown = false
  //         - return { valid: true, forceCommit: this.numButtons == 0, finished: this.numButtons == 0 }
  //      - otherwise:
  //         - // this is the 'up' of some bogus secondary press
  //           // ignore it, but continue listening for our primary up
  //         - return { valid: this.primaryDown, finished: this.numButtons == 0 }
}

class LongPressGesture : Gesture {
  GestureState processEvent(EventTarget target, Event event);  
  // long-tap-start: sent when the primary pointer goes down
  // long-tap-cancel: sent when cancel(), reset(), or finger goes out of bounding box
  // long-tap: sent when the primary pointer is released
}

class DoubleTapGesture : Gesture {
  GestureState processEvent(EventTarget target, Event event);  
  // double-tap-start: sent when the primary pointer goes down the first time
  // double-tap-cancel: sent when cancel(), reset(), or finger goes out of bounding box, or it times out
  // double-tap: sent when the primary pointer is released the second time
}


abstract class ScrollGesture : Gesture {
  GestureState processEvent(EventTarget target, Event event);  
  // this fires the following events (inertia is a boolean, delta is a float):
  //   scroll-start, with field inertia=false, delta=0; precommit=true
  //   scroll, with fields inertia (is this a simulated scroll from inertia or a real scroll?), delta (number of pixels to scroll); precommit=true
  //   scroll-end, with field inertia (same), delta=0; precommit=true
  // scroll-start is fired right away
  // scroll is sent whenever the primary pointer moves while down
  // scroll is also sent after the pointer goes back up, based on inertia
  // scroll-end is sent after the pointer goes back up once the scroll reaches delta=0
  // scroll-end is also sent when the gesture is canceled or reset
  // processEvent() returns:
  //  - valid=true pretty much always so long as there's a primary touch (e.g. not for a right-click)
  //  - forceCommit=true when you travel a certain distance
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
  // zoom-start: sent when we could start zooming (e.g. for pinch-zoom, when two fingers hit the glass) (precommit)
  // zoom-end: sent when cancel()ed after zoom-start, or when the fingers are lifted (precommit)
  // zoom, with a 'scale' attribute, whose value is a multiple of the scale factor at zoom-start
  // e.g. if the user zooms to 2x, you'd get a bunch of 'zoom' events like scale=1.0, scale=1.17, ... scale=1.91, scale=2.0
}

class PinchZoomGesture : ZoomGesture {
  // a ZoomGesture for two-finger-pinch gesture
  // zoom is precommit
}

class DoubleTapZoomGesture : ZoomGesture {
  // a ZoomGesture for the double-tap-slide gesture
  // when the slide starts, forceCommit
}


class PanAndZoomGesture : Gesture {
  GestureState processEvent(EventTarget target, Event event);  
  // manipulate-start (precommit)
  // manipulate: (precommit)
  //    panX, panY: pixels
  //    scaleX, scaleY: a multiplier of the scale at manipulate-start
  //    rotation: turns
  // manipulate-end (precommit)
}


abstract class FlingGesture : Gesture {
  GestureState processEvent(EventTarget target, Event event);  
  // fling-start: when the gesture begins (precommit)
  // fling-move: while the user is directly dragging the element (has delta attribute with the distance from fling-start) (precommit)
  // fling: the user has released the pointer and the decision is it was in fact flung
  // fling-cancel: cancel(), or the user has released the pointer and the decision is it was not flung (precommit)
  // fling-end: cancel(), reset(), or after fling or fling-cancel (precommit)
}

class FlingLeftGesture : FlingGesture { }
class FlingRightGesture : FlingGesture { }
class FlingUpGesture : FlingGesture { }
class FlingDownGesture : FlingGesture { }

```
