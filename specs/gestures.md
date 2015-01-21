Gestures
========

```javascript

callback GestureCallback void (Event event);

abstract class Gesture {
  constructor ();

  // Gestures cycle through states:
  //  - idle: nothing is going on (active, accepted, and discarding
  //    are false).
  //  - buffering: the GestureChooser is passing in some events, but
  //    hasn't yet committed to using this Gesture, and this Gesture
  //    hasn't yet decided that this set of events isn't interesting
  //    (active is true, accepted is false, discarding is false).
  //  - forwarding: this Gesture is still interesting and the
  //    GestureChooser has decided to use this Gesture so events are
  //    being sent along (active is true, accepted is true, discarding
  //    is false).
  //  - discarding: this Gesture got cancelled or didn't match the
  //    pattern (active is true, accepted is false, discarding is
  //    true).

  // TODO(ianh): Need to handle gestures that want to send events
  // beyond the end of the gesture, e.g. inertia in scrolling. In that
  // mode, gestures are sending events but are simultaneously no
  // longer "active"...

  Boolean processEvent(EventTarget target, Event event);
  // as the events are received, they get examined to see if they fit
  // the pattern for the gesture; if they do, then returns true, else,
  // returns false
  //  - returning true after false has been returned is a contract
  //    violation unless active became false in between
  //  - manipulating the event is a contract violation
  //
  // TODO(ianh): replace processEvent()'s return value with an enum:
  //   - acceptable (true and active is true)
  //   - discarding (false but active is still true)
  //   - finished (false and active is now false)
  // in such a world, the contract would be that you can't return
  // 'acceptable' after returning 'discarding' without first returning
  // 'finished'

  void accept(GestureCallback callback);
  // set accepted to true, send the buffered gesture events to
  // callback, and use that callback for all future Gesture events
  // until the gesture is complete
  //  - call this immediately after getting a positive result from
  //    processEvent()

  // internal API:
  // void sendEvent(Event event)
  //  - assert: active is true, discarding is false
  //  - if accepted is true, then send the event straight to the
  //    callback
  //  - otherwise, add it to the buffer
  //
  // void discard()
  //  - throw away the buffer, set discarding to true and accepted to
  //    false

  readonly attribute Boolean active; // not idle (buffering, forwarding, or discarding)
  readonly attribute Boolean accepted; // true if active and accept() has been called (forwarding or discarding)
  readonly attribute Boolean discarding; // true if active and processEvent() has returned false (discarding)
  // 'active' is currently part of the contract between Gesture and GestureChooser (the other two are not)

  // active can be true even if processEvent() returned false; this is
  // the discarding state. It means that the Gesture isn't sending any
  // more events, but that the pointers haven't yet reached a state in
  // which a new touch could begin. For example, a Tap gesture where
  // the finger has gone out of the bounding box can't be retriggered
  // until the finger is lifted.
  
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
  // any time one of the pointer events is received:
  // - if it's pointer-down and it's already captured, ignore the
  //   event; otherwise:
  // - let /candidates/ be a list of gestures, initially empty
  // - if none of the registered gestures are active, then add all of
  //   them to /candidates/ otherwise, add all the active ones to
  //   /candidates/
  // - call processEvent() with the event on all the Gestures in
  //   /candidates/
  // - if it's pointer-down and at least one Gesture returned true,
  //   then capture the event
  // - if accepted is false, and exactly one of the processEvent()
  //   methods returned true, then set accepted to true and call that
  //   Gesture's accept() method, passing it a method that fires the
  //   provided event on the current target (if not null)
  // - if all the processEvent() methods returned false, and all the
  //   Gestures are no longer active, then set active and accepted to
  //   false; otherwise, set active to true
}

class TapGesture : Gesture {
  Boolean processEvent(EventTarget target, Event event);
  // if discarding is true:
  //   - if the event is a primary pointer-up, set active, accepted, and
  //     discarding to false, and return false
  //   - otherwise, just return false
  // if EventTarget isn't an Element:
  //   - set active to true, discard(), and return false
  // if the event is pointer-down:
  //   - if it's primary:
  //      - assert: active is false
  //      - sendEvent() a tap-down event
  //      - set active to true and return true
  //   - otherwise, if we're active:
  //      - return true
  //   - otherwise:
  //      - return false
  // if the event is pointer-move:
  //   - if it's primary:
  //      - if it hit tests within target's bounding box:
  //         - sendEvent() a tap-move event
  //         - return true
  //      - otherwise:
  //         - sendEvent() a tap-cancel event
  //         - discard() and return false
  //   - otherwise, if we're active:
  //      - return true
  //   - otherwise:
  //      - return false
  // if the event is pointer-up:
  //   - if it's primary:
  //      - sendEvent() a tap event
  //      - set accepted and active to false, discard(), and return false
  //   - otherwise, if we're active:
  //      - return true
  //   - otherwise:
  //      - return false
}

class ScrollGesture : Gesture {
  Boolean processEvent(EventTarget target, Event event);  
  // this fires the following events:
  //   TODO(ianh): fill this in
}

```
