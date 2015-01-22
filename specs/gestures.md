Gestures
========

```javascript

callback GestureCallback void (Event event);

dictionary GestureState {
  Boolean valid = false; // if true, the event was part of the current gesture
  Boolean finished = true; // if true, we're ready for the next gesture to start
}

abstract class Gesture {
  constructor ();

  Boolean processEvent(EventTarget target, Event event);
  //  - if this.ready=true, clear the sendEvent() buffer and forget
  //    the last accept() callback, if any.
  //  - let returnValue = this.processEventInternal(...)
  //  - if this.discarding:
  //     - assert: returnValue.valid == false
  //  - if !returnValue.valid, then clear the sendEvent() buffer and
  //    forget the last accept() callback, if any
  //  - set this.ready = returnValue.finished
  //  - set this.canceled = !returnValue.valid
  //  - set this.discarding = !returnValue.valid && !returnValue.finished
  //  - set this.active = returnValue.valid && !returnValue.finished
  //  - return returnValue.valid

  readonly attribute Boolean active; // defaults to false
  // true if the last time processEvent was invoked, valid was true
  // and finished was false, and we haven't been cancel()ed

  readonly attribute Boolean canceled; // defaults to false
  // true if either the last time processEvent was invoked, valid was
  // false, or, we have been cancel()ed

  readonly attribute Boolean discarding; // defaults to false
  // true if the last time processEvent was invoked, valid was false
  // and finished was false, and we haven't been cancel()ed

  readonly attribute Boolean ready; // defaults to true
  // true if the last time processEvent was invoked, the gesture was
  // over, or, we have been cancel()ed

  void accept(GestureCallback callback);
  // assert: this.canceled == false
  // remember the giver accept callback, and send the buffered gesture
  // events to that callback
  //  - call this immediately after getting a positive result from
  //    processEvent()

  virtual void cancel();
  // set active=false, canceled=true, discarding=false, ready=false
  // clear the sendEvent() buffer and forget the last accept()
  // callback, if any
  // descendants may override this if they have more state to drop

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
  //    processEventInternal() call, or between calls to
  //    processEventInternal() assuming that the last such call
  //    returned either valid=true or finished=true.

  void sendEvent(Event event);
  // used internally to queue up or send events
  //  - assert: this.discarding == false
  //  - if accepted is true, then send the event straight to the
  //    callback
  //  - otherwise, add it to the buffer
  
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
  // - let /candidates/ be a list of Gestures, initially empty
  // - if all of the registered Gestures have ready==true, then add
  //   all of them to /candidates/; otherwise, add all the Gestures
  //   with ready==false to /candidates/
  // - call processEvent() with the event on all the Gestures in
  //   /candidates/
  // - if it's pointer-down then:
  //    - if at least one Gesture returned true, then capture the
  //      event
  //    - else send cancel() to all the gestures in /candidates/.
  // - if accepted is false, and exactly one of the processEvent()
  //   methods returned true, then set accepted to true and call that
  //   Gesture's accept() method, passing it a method that fires the
  //   provided event on the current target (if not null)
  // - if all the registered Gestures are now ready==true (regardless
  //   of the return values), then set active and accepted to false;
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
  //       - sendEvent() a tap-down event
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
  //            - sendEvent() a tap-move event
  //            - return { valid: true, finished: false }
  //         - otherwise:
  //            - sendEvent() a tap-cancel event
  //            - return { valid: false, finished: false }
  //      - otherwise:
  //         - // this is the move of some bogus secondary press
  //           // ignore it, but continue listening
  //         - return { valid: true, finished: false }
  //   - if the event is pointer-up:
  //      - if it's primary:
  //         - sendEvent() a tap event
  //         - this.primaryDown = false
  //         - return { valid: true, finished: this.numButtons == 0 }
  //      - otherwise:
  //         - // this is the 'up' of some bogus secondary press
  //           // ignore it, but continue listening for our primary up
  //         - return { valid: this.primaryDown, finished: this.numButtons == 0 }
}

class ScrollGesture : Gesture {
  Boolean processEvent(EventTarget target, Event event);  
  // this fires the following events:
  //   TODO(ianh): fill this in
}

```
