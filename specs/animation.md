Animation API
=============

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
