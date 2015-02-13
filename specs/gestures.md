Gestures
========

```dart
SKY MODULE
<!-- part of dart:sky -->

<script>
abstract class GestureEvent extends Event {
  Gesture _gesture;
  Gesture get gesture => _gesture;
}

class GestureState {
  @nonnull bool cancel = true; // if true, then cancel the gesture at this point
  @nonnull bool capture = false; // (for PointerDownEvent) if true, then this pointer is relevant
  @nonnull bool choose = false; // if true, the gesture thinks that other gestures should give up
  @nonnull bool finished = true; // if true, we're ready for the next gesture to start
  // choose and cancel are mutually exclusive
}

class BufferedEvent {
  const BufferedEvent(this.event, this.coallesceGroup);
  final @nonnull GestureEvent event;
  final int coallesceGroup;
}

abstract class Gesture extends EventTarget {
  Gesture(this.target) : super() {
    target.events.where((event) => event is PointerDownEvent ||
                                   event is PointerMovedEvent ||
                                   event is PointerUpEvent).listen(_handler);
  }
  final @nonnull EventTarget target;

  bool _ready = true; // last event, we were finished
  bool get ready => _ready;
  bool _active = false; // we have not yet been canceled since we last started listening to a pointer
  bool get active => _active;
  bool _chosen = false; // we're the only possible gesture at this point
  bool get chosen => _chosen;

  // (!ready && !active) means we're discarding events until the user
  // gets to a state where a new gesture can begin

  // (active && !chosen) means we're collecting events until no other
  // gesture is valid, or until we take command

  @nonnull GestureState processEvent(@nonnull PointerEvent event);

  List<@nonnull BufferedEvent> _eventBuffer;

  void choose() {
    // called by GestureManager
    // if you override this, make sure to call superclass choose() first
    assert(_active == true);
    assert(_chosen == false);
    _chosen = true;
    // if there are any buffered events, dispatch them on this
    if ((_eventBuffer != null) && (_eventBuffer.length > 0)) {
      // we make a copy of the event buffer first so that the array isn't mutated out from under us
      // while we are doing this
      var events = _eventBuffer;
      _eventBuffer = null;
      for (var item in events)
        dispatchEvent(item.event);
    }
  }

  void cancel() {
    // called by GestureManager
    // if you override this, make sure to call superclass cancel() last
    _active = false;
    _chosen = false;
    _eventBuffer = null;
  }

  // for use by subclasses only
  void sendEvent(@nonnull GestureEvent event,
                 { int coallesceGroup, // when queuing events, only the last event with each group is kept 
                   @nonnull bool prechoose: false // if true, event should just be sent right away, not queued
                 }) {
    assert(_active == true);
    assert(coallesceGroup == null || prechoose == false);
    event._gesture = this;
    if (_chosen || prechoose) {
      dispatchEvent(event);
    } else {
      if (_eventBuffer == null)
        _eventBuffer = new List<BufferedEvent>();
      if (coallesceGroup != null)
        _eventBuffer.removeWhere((candidate) => candidate.coallesceGroup == coallesceGroup);
      _eventBuffer.add(new BufferedEvent(event, coallesceGroup));
    }
  }

  void _handler(@nonnull Event event) {
    bool wasActive = _active;
    if (_ready) {
      // reset the state to start a new gesture
      if (_active)
        module.application.gestureManager.cancelGesture(this);
      _active = true;
      _ready = false;
    }
    GestureState returnValue = processEvent(event);
    if (returnValue.capture) {
      assert(event is PointerDownEvent);
      if (event is PointerDownEvent)
        event.result.add(this);
    }
    if (returnValue.cancel) {
      assert(returnValue.choose == false);
      if (wasActive)
        module.application.cancelGesture(this);
      // if we never became active, then we never called addGesture() below
      _active = false;
    } else if (active == true) {
      if (wasActive == false || event is PointerDownEvent)
        module.application.addGesture(event, this);
      if (returnValue.choose == true)
        module.application.chooseGesture(this);
    }
    _ready = returnValue.finished;
  }
}

/*
```
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

```dart
*/

class PointerState {
  PointerState({this.gestures, this.chosen}) {
    if (gestures == null)
      gestures = new List<Gesture>();
  }
  factory PointerState.clone(PointerState source) {
    return new PointerState(gestures: source.gestures, chosen: source.chosen);
  }
  @nonnull List<@nonnull Gesture> gestures;
  @nonnull bool chosen = false;
}

class GestureManager {
  GestureManager(this.target) {
    target.events.where((event) => event is PointerDownEvent).listen(_handler);
  }
  final @nonnull EventTarget target; // usually the ApplicationDocument object

  Map<@nonnull int, @nonnull PointerState> _pointers = new SplayTreeMap<int, PointerState>();

  void addGesture(@nonnull PointerEvent event, @nonnull Gesture gesture) {
    assert(gesture.active);
    var pointer = event.pointer;
    if (_pointers.containsKey(pointer)) {
      assert(!_pointers[pointer].gestures.contains(gesture));
      if (_pointers[pointer].chosen)
        cancelGesture(gesture);
      else
        _pointers[pointer].gestures.add(gesture);
    } else {
      PointerState pointerState = new PointerState();
      pointerState.gestures.add(gesture);
      _pointers[pointer] = pointerState;
    }
  }

  void cancelGesture(@nonnull Gesture gesture) {
    _pointers.forEach((index, pointerState) => pointerState.gestures.remove(gesture));
    gesture.cancel();
    // get a static copy of the _pointers keys, so we can remove them safely
    var activePointers = new List<int>.from(_pointers.keys);
    // now walk our lists, removing pointers that are obsolete, and choosing
    // gestures from pointers that have only one outstanding gesture
    for (var pointer in activePointers) {
      var pointerState = _pointers[pointer];
      if (pointerState.gestures.length == 0) {
        _pointers.remove(pointer);
      } else {
        if (pointerState.gestures.length == 1 && pointerState.chosen) {
          pointerState.chosen = true;
          pointerState.gestures[0].choose();
        }
      }
    }
  }

  void chooseGesture(@nonnull Gesture gesture) {
    if (!gesture.active)
      // this could happen e.g. if two gestures simultaneously add
      // themselves and chose themselves for the same PointerDownEvent
      return;
    @nonnull List<@nonnull Gesture> losers = new List<@nonnull Gesture>();
    _pointers.values
             .where((pointerState) => pointerState.gestures.contains(gesture))
             .forEach((pointerState) {
               losers.addAll(pointerState.gestures.where((candidateLoser) => candidateLoser != gesture));
               pointerState.gestures.clear();
               pointerState.gestures.add(gesture);
               pointerState.chosen = true;
             });
    assert(losers.every((loser) => loser.active));
    losers.forEach((loser) {
      // we check loser.active because losers could contain duplicates
      // and we should only cancel each gesture once
      if (loser.active)
        loser.cancel();
      assert(!loser.active);
    });
    gesture.choose();
  }

  @nonnull PointerState getActiveGestures(@nonnull int pointer) {
    if (_pointers.containsKey(pointer) && _pointers[pointer].gestures.length > 0)
      return new PointerState.clone(_pointers[pointer]);
    return new PointerState();
  }

  void _handler(@nonnull PointerDownEvent event) {
    var pointer = event.pointer;
    if (_pointers.containsKey(pointer)) {
      var pointerState = _pointers[pointer];
      if ((!pointerState.chosen) && (pointerState.gestures.length == 1)) {
        pointerState.chosen = true;
        pointerState.gestures[0].choose();
      }
    }
  }

}
</script>
```

Gestures defined in the framework
---------------------------------

```dart
SKY MODULE
<!-- not in dart:sky -->
<!-- note: this hasn't been dartified yet -->

<script>
class TapGesture extends Gesture {

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

</script>
```
