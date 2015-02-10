Animation API
=============

```dart
typedef void TimerCallback();

class AnimationTimer extends Timer {
  external factory whenIdle(TimerCallback callback, { double budget: 1.0 });
  // calls callback next time the system is idle
  // - if budget is in the range 0.0 < budget <= 1.0, then callback is
  //   guaranteed to have that many milliseconds before being killed
  // - if budget <= 0.0, then the callback could be killed [at any time](script.md).
  // - if budget > 1.0, then it is treated as 1.0.

  external factory beforePaint(TimerCallback callback, { int priority: 0 });
  // runs this timeout before this frame's layout/paint phases begin
  external factory nextFrame(TimerCallback callback, { int priority: 0 });
  // runs this timeout right away

  // for beforePaint and nextFrame, the callbacks are first sorted by
  // priority, and then run in decreasing order of priority,
  // tie-breaking by registration time, earliest first.

  // once there is no more time for callbacks this frame, the Timers
  // are all canceled, so isActive will become false

}
```


Easing Functions
----------------

```dart
// part of the framework, not sky:core

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
