Animation API
=============

```dart
typedef void TimerCallback();

external void _addTask({ TimerCallback callback, Duration budget, int bits, int priority, Queue queue });
// see (runloop.md)[runloop.md] for the semantics of tasks and queues
// _addTask() does the zone magic on callback

external final Queue get _idleQueue;
external final Queue get _paintQueue;
external final Queue get _nextPaintQueue;

class AnimationTimer extends Timer {
  factory whenIdle(TimerCallback callback, { Duration budget: 1.0 }) {
    if (budget.inMilliseconds > 1.0)
      budget = new Duration(milliseconds: 1.0);
    _addTask(callback: callback, budget: budget, bits: IdleTask, priority: IdlePriority, queue: _idleQueue);
  }

  factory beforePaint(TimerCallback callback, { int priority: 0 }) {
    _addTask(callback: callback, budget: new Duration(milliseconds: 1.0), bits: PaintTask, priority: priority, queue: _paintQueue);
  }

  factory nextFrame(TimerCallback callback, { int priority: 0 }) {
    _addTask(callback: callback, budget: new Duration(milliseconds: 1.0), bits: PaintTask, priority: priority, queue: _nextPaintQueue);
  }
}
```


Easing Functions
----------------

```dart
// part of the framework, not dart:sky

typedef void AnimationCallback();

abstract class EasingFunction {
  EasingFunction({double duration: 0.0, AnimationCallback completionCallback: null });
  double getFactor(Float time);
  // calls completionCallback if time >= duration
  // then returns a number ostensibly in the range 0.0 to 1.0
  // (but it could in practice go outside this range, e.g. for
  // animation styles that overreach then come back)
}
```

If you want to have two animations simultaneously, e.g. two
transforms, then you can add to the RenderNode's overrideStyles a
StyleValue that combines other StyleValues, e.g. a
"TransformStyleValueCombinerStyleValue", and then add to it the
regular animated StyleValues, e.g. multiple
"AnimatedTransformStyleValue" objects. A framework API could make
setting all that up easy, given the right underlying StyleValue
classes.
