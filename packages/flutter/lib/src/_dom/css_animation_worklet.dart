// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'html.dart';
import 'web_animations.dart';

typedef AnimatorInstanceConstructor = JSFunction;

@JS('AnimationWorkletGlobalScope')
@staticInterop
class AnimationWorkletGlobalScope implements WorkletGlobalScope {}

extension AnimationWorkletGlobalScopeExtension on AnimationWorkletGlobalScope {
  external void registerAnimator(
    String name,
    AnimatorInstanceConstructor animatorCtor,
  );
}

@JS('WorkletAnimationEffect')
@staticInterop
class WorkletAnimationEffect {}

extension WorkletAnimationEffectExtension on WorkletAnimationEffect {
  external EffectTiming getTiming();
  external ComputedEffectTiming getComputedTiming();
  external set localTime(num? value);
  external num? get localTime;
}

@JS('WorkletAnimation')
@staticInterop
class WorkletAnimation implements Animation {
  external factory WorkletAnimation(
    String animatorName, [
    JSObject? effects,
    AnimationTimeline? timeline,
    JSAny? options,
  ]);
}

extension WorkletAnimationExtension on WorkletAnimation {
  external String get animatorName;
}

@JS('WorkletGroupEffect')
@staticInterop
class WorkletGroupEffect {}

extension WorkletGroupEffectExtension on WorkletGroupEffect {
  external JSArray getChildren();
}
