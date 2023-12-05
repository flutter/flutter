// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'css_typed_om.dart';
import 'dom.dart';
import 'web_animations.dart';

typedef EffectCallback = JSFunction;
typedef IterationCompositeOperation = String;

@JS('GroupEffect')
@staticInterop
class GroupEffect {
  external factory GroupEffect(
    JSArray? children, [
    JSAny timing,
  ]);
}

extension GroupEffectExtension on GroupEffect {
  external GroupEffect clone();
  external void prepend(AnimationEffect effects);
  external void append(AnimationEffect effects);
  external AnimationNodeList get children;
  external AnimationEffect? get firstChild;
  external AnimationEffect? get lastChild;
}

@JS('AnimationNodeList')
@staticInterop
class AnimationNodeList {}

extension AnimationNodeListExtension on AnimationNodeList {
  external AnimationEffect? item(int index);
  external int get length;
}

@JS('SequenceEffect')
@staticInterop
class SequenceEffect implements GroupEffect {
  external factory SequenceEffect(
    JSArray? children, [
    JSAny timing,
  ]);
}

extension SequenceEffectExtension on SequenceEffect {
  external SequenceEffect clone();
}

@JS()
@staticInterop
@anonymous
class TimelineRangeOffset {
  external factory TimelineRangeOffset({
    String? rangeName,
    CSSNumericValue offset,
  });
}

extension TimelineRangeOffsetExtension on TimelineRangeOffset {
  external set rangeName(String? value);
  external String? get rangeName;
  external set offset(CSSNumericValue value);
  external CSSNumericValue get offset;
}

@JS('AnimationPlaybackEvent')
@staticInterop
class AnimationPlaybackEvent implements Event {
  external factory AnimationPlaybackEvent(
    String type, [
    AnimationPlaybackEventInit eventInitDict,
  ]);
}

extension AnimationPlaybackEventExtension on AnimationPlaybackEvent {
  external CSSNumberish? get currentTime;
  external CSSNumberish? get timelineTime;
}

@JS()
@staticInterop
@anonymous
class AnimationPlaybackEventInit implements EventInit {
  external factory AnimationPlaybackEventInit({
    CSSNumberish? currentTime,
    CSSNumberish? timelineTime,
  });
}

extension AnimationPlaybackEventInitExtension on AnimationPlaybackEventInit {
  external set currentTime(CSSNumberish? value);
  external CSSNumberish? get currentTime;
  external set timelineTime(CSSNumberish? value);
  external CSSNumberish? get timelineTime;
}
