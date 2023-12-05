// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'geometry.dart';
import 'html.dart';

typedef UnderlineStyle = String;
typedef UnderlineThickness = String;

@JS()
@staticInterop
@anonymous
class EditContextInit {
  external factory EditContextInit({
    String text,
    int selectionStart,
    int selectionEnd,
  });
}

extension EditContextInitExtension on EditContextInit {
  external set text(String value);
  external String get text;
  external set selectionStart(int value);
  external int get selectionStart;
  external set selectionEnd(int value);
  external int get selectionEnd;
}

@JS('EditContext')
@staticInterop
class EditContext implements EventTarget {
  external factory EditContext([EditContextInit options]);
}

extension EditContextExtension on EditContext {
  external void updateText(
    int rangeStart,
    int rangeEnd,
    String text,
  );
  external void updateSelection(
    int start,
    int end,
  );
  external void updateControlBounds(DOMRect controlBounds);
  external void updateSelectionBounds(DOMRect selectionBounds);
  external void updateCharacterBounds(
    int rangeStart,
    JSArray characterBounds,
  );
  external JSArray attachedElements();
  external JSArray characterBounds();
  external String get text;
  external int get selectionStart;
  external int get selectionEnd;
  external int get compositionRangeStart;
  external int get compositionRangeEnd;
  external bool get isComposing;
  external DOMRect get controlBounds;
  external DOMRect get selectionBounds;
  external int get characterBoundsRangeStart;
  external set ontextupdate(EventHandler value);
  external EventHandler get ontextupdate;
  external set ontextformatupdate(EventHandler value);
  external EventHandler get ontextformatupdate;
  external set oncharacterboundsupdate(EventHandler value);
  external EventHandler get oncharacterboundsupdate;
  external set oncompositionstart(EventHandler value);
  external EventHandler get oncompositionstart;
  external set oncompositionend(EventHandler value);
  external EventHandler get oncompositionend;
}

@JS()
@staticInterop
@anonymous
class TextUpdateEventInit implements EventInit {
  external factory TextUpdateEventInit({
    int updateRangeStart,
    int updateRangeEnd,
    String text,
    int selectionStart,
    int selectionEnd,
    int compositionStart,
    int compositionEnd,
  });
}

extension TextUpdateEventInitExtension on TextUpdateEventInit {
  external set updateRangeStart(int value);
  external int get updateRangeStart;
  external set updateRangeEnd(int value);
  external int get updateRangeEnd;
  external set text(String value);
  external String get text;
  external set selectionStart(int value);
  external int get selectionStart;
  external set selectionEnd(int value);
  external int get selectionEnd;
  external set compositionStart(int value);
  external int get compositionStart;
  external set compositionEnd(int value);
  external int get compositionEnd;
}

@JS('TextUpdateEvent')
@staticInterop
class TextUpdateEvent implements Event {
  external factory TextUpdateEvent(
    String type, [
    TextUpdateEventInit options,
  ]);
}

extension TextUpdateEventExtension on TextUpdateEvent {
  external int get updateRangeStart;
  external int get updateRangeEnd;
  external String get text;
  external int get selectionStart;
  external int get selectionEnd;
  external int get compositionStart;
  external int get compositionEnd;
}

@JS()
@staticInterop
@anonymous
class TextFormatInit {
  external factory TextFormatInit({
    int rangeStart,
    int rangeEnd,
    UnderlineStyle underlineStyle,
    UnderlineThickness underlineThickness,
  });
}

extension TextFormatInitExtension on TextFormatInit {
  external set rangeStart(int value);
  external int get rangeStart;
  external set rangeEnd(int value);
  external int get rangeEnd;
  external set underlineStyle(UnderlineStyle value);
  external UnderlineStyle get underlineStyle;
  external set underlineThickness(UnderlineThickness value);
  external UnderlineThickness get underlineThickness;
}

@JS('TextFormat')
@staticInterop
class TextFormat {
  external factory TextFormat([TextFormatInit options]);
}

extension TextFormatExtension on TextFormat {
  external int get rangeStart;
  external int get rangeEnd;
  external UnderlineStyle get underlineStyle;
  external UnderlineThickness get underlineThickness;
}

@JS()
@staticInterop
@anonymous
class TextFormatUpdateEventInit implements EventInit {
  external factory TextFormatUpdateEventInit({JSArray textFormats});
}

extension TextFormatUpdateEventInitExtension on TextFormatUpdateEventInit {
  external set textFormats(JSArray value);
  external JSArray get textFormats;
}

@JS('TextFormatUpdateEvent')
@staticInterop
class TextFormatUpdateEvent implements Event {
  external factory TextFormatUpdateEvent(
    String type, [
    TextFormatUpdateEventInit options,
  ]);
}

extension TextFormatUpdateEventExtension on TextFormatUpdateEvent {
  external JSArray getTextFormats();
}

@JS()
@staticInterop
@anonymous
class CharacterBoundsUpdateEventInit implements EventInit {
  external factory CharacterBoundsUpdateEventInit({
    int rangeStart,
    int rangeEnd,
  });
}

extension CharacterBoundsUpdateEventInitExtension
    on CharacterBoundsUpdateEventInit {
  external set rangeStart(int value);
  external int get rangeStart;
  external set rangeEnd(int value);
  external int get rangeEnd;
}

@JS('CharacterBoundsUpdateEvent')
@staticInterop
class CharacterBoundsUpdateEvent implements Event {
  external factory CharacterBoundsUpdateEvent(
    String type, [
    CharacterBoundsUpdateEventInit options,
  ]);
}

extension CharacterBoundsUpdateEventExtension on CharacterBoundsUpdateEvent {
  external int get rangeStart;
  external int get rangeEnd;
}
