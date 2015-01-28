Animation API
=============

(This is very incomplete, because it's all expected to be in the
framework, not the platform.)

```javascript

dictionary EasingFunctionSettings {
  Float duration; // required
  Callback? completionCallback = null;
}

abstract class EasingFunction {
  abstract constructor (EasingFunctionSettings settings);
  abstract Float getFactor(Float time);
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
