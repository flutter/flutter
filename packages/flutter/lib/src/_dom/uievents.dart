// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';
import 'input_device_capabilities.dart';

@JS('UIEvent')
@staticInterop
class UIEvent implements Event {
  external factory UIEvent(
    String type, [
    UIEventInit eventInitDict,
  ]);
}

extension UIEventExtension on UIEvent {
  external void initUIEvent(
    String typeArg, [
    bool bubblesArg,
    bool cancelableArg,
    Window? viewArg,
    int detailArg,
  ]);
  external InputDeviceCapabilities? get sourceCapabilities;
  external Window? get view;
  external int get detail;
  external int get which;
}

@JS()
@staticInterop
@anonymous
class UIEventInit implements EventInit {
  external factory UIEventInit({
    InputDeviceCapabilities? sourceCapabilities,
    Window? view,
    int detail,
    int which,
  });
}

extension UIEventInitExtension on UIEventInit {
  external set sourceCapabilities(InputDeviceCapabilities? value);
  external InputDeviceCapabilities? get sourceCapabilities;
  external set view(Window? value);
  external Window? get view;
  external set detail(int value);
  external int get detail;
  external set which(int value);
  external int get which;
}

@JS('FocusEvent')
@staticInterop
class FocusEvent implements UIEvent {
  external factory FocusEvent(
    String type, [
    FocusEventInit eventInitDict,
  ]);
}

extension FocusEventExtension on FocusEvent {
  external EventTarget? get relatedTarget;
}

@JS()
@staticInterop
@anonymous
class FocusEventInit implements UIEventInit {
  external factory FocusEventInit({EventTarget? relatedTarget});
}

extension FocusEventInitExtension on FocusEventInit {
  external set relatedTarget(EventTarget? value);
  external EventTarget? get relatedTarget;
}

@JS('MouseEvent')
@staticInterop
class MouseEvent implements UIEvent {
  external factory MouseEvent(
    String type, [
    MouseEventInit eventInitDict,
  ]);
}

extension MouseEventExtension on MouseEvent {
  external bool getModifierState(String keyArg);
  external void initMouseEvent(
    String typeArg, [
    bool bubblesArg,
    bool cancelableArg,
    Window? viewArg,
    int detailArg,
    int screenXArg,
    int screenYArg,
    int clientXArg,
    int clientYArg,
    bool ctrlKeyArg,
    bool altKeyArg,
    bool shiftKeyArg,
    bool metaKeyArg,
    int buttonArg,
    EventTarget? relatedTargetArg,
  ]);
  external num get pageX;
  external num get pageY;
  external num get x;
  external num get y;
  external num get offsetX;
  external num get offsetY;
  external num get movementX;
  external num get movementY;
  external int get screenX;
  external int get screenY;
  external int get clientX;
  external int get clientY;
  external int get layerX;
  external int get layerY;
  external bool get ctrlKey;
  external bool get shiftKey;
  external bool get altKey;
  external bool get metaKey;
  external int get button;
  external int get buttons;
  external EventTarget? get relatedTarget;
}

@JS()
@staticInterop
@anonymous
class MouseEventInit implements EventModifierInit {
  external factory MouseEventInit({
    num movementX,
    num movementY,
    int screenX,
    int screenY,
    int clientX,
    int clientY,
    int button,
    int buttons,
    EventTarget? relatedTarget,
  });
}

extension MouseEventInitExtension on MouseEventInit {
  external set movementX(num value);
  external num get movementX;
  external set movementY(num value);
  external num get movementY;
  external set screenX(int value);
  external int get screenX;
  external set screenY(int value);
  external int get screenY;
  external set clientX(int value);
  external int get clientX;
  external set clientY(int value);
  external int get clientY;
  external set button(int value);
  external int get button;
  external set buttons(int value);
  external int get buttons;
  external set relatedTarget(EventTarget? value);
  external EventTarget? get relatedTarget;
}

@JS()
@staticInterop
@anonymous
class EventModifierInit implements UIEventInit {
  external factory EventModifierInit({
    bool ctrlKey,
    bool shiftKey,
    bool altKey,
    bool metaKey,
    bool modifierAltGraph,
    bool modifierCapsLock,
    bool modifierFn,
    bool modifierFnLock,
    bool modifierHyper,
    bool modifierNumLock,
    bool modifierScrollLock,
    bool modifierSuper,
    bool modifierSymbol,
    bool modifierSymbolLock,
  });
}

extension EventModifierInitExtension on EventModifierInit {
  external set ctrlKey(bool value);
  external bool get ctrlKey;
  external set shiftKey(bool value);
  external bool get shiftKey;
  external set altKey(bool value);
  external bool get altKey;
  external set metaKey(bool value);
  external bool get metaKey;
  external set modifierAltGraph(bool value);
  external bool get modifierAltGraph;
  external set modifierCapsLock(bool value);
  external bool get modifierCapsLock;
  external set modifierFn(bool value);
  external bool get modifierFn;
  external set modifierFnLock(bool value);
  external bool get modifierFnLock;
  external set modifierHyper(bool value);
  external bool get modifierHyper;
  external set modifierNumLock(bool value);
  external bool get modifierNumLock;
  external set modifierScrollLock(bool value);
  external bool get modifierScrollLock;
  external set modifierSuper(bool value);
  external bool get modifierSuper;
  external set modifierSymbol(bool value);
  external bool get modifierSymbol;
  external set modifierSymbolLock(bool value);
  external bool get modifierSymbolLock;
}

@JS('WheelEvent')
@staticInterop
class WheelEvent implements MouseEvent {
  external factory WheelEvent(
    String type, [
    WheelEventInit eventInitDict,
  ]);

  external static int get DOM_DELTA_PIXEL;
  external static int get DOM_DELTA_LINE;
  external static int get DOM_DELTA_PAGE;
}

extension WheelEventExtension on WheelEvent {
  external num get deltaX;
  external num get deltaY;
  external num get deltaZ;
  external int get deltaMode;
}

@JS()
@staticInterop
@anonymous
class WheelEventInit implements MouseEventInit {
  external factory WheelEventInit({
    num deltaX,
    num deltaY,
    num deltaZ,
    int deltaMode,
  });
}

extension WheelEventInitExtension on WheelEventInit {
  external set deltaX(num value);
  external num get deltaX;
  external set deltaY(num value);
  external num get deltaY;
  external set deltaZ(num value);
  external num get deltaZ;
  external set deltaMode(int value);
  external int get deltaMode;
}

@JS('InputEvent')
@staticInterop
class InputEvent implements UIEvent {
  external factory InputEvent(
    String type, [
    InputEventInit eventInitDict,
  ]);
}

extension InputEventExtension on InputEvent {
  external JSArray getTargetRanges();
  external DataTransfer? get dataTransfer;
  external String? get data;
  external bool get isComposing;
  external String get inputType;
}

@JS()
@staticInterop
@anonymous
class InputEventInit implements UIEventInit {
  external factory InputEventInit({
    DataTransfer? dataTransfer,
    JSArray targetRanges,
    String? data,
    bool isComposing,
    String inputType,
  });
}

extension InputEventInitExtension on InputEventInit {
  external set dataTransfer(DataTransfer? value);
  external DataTransfer? get dataTransfer;
  external set targetRanges(JSArray value);
  external JSArray get targetRanges;
  external set data(String? value);
  external String? get data;
  external set isComposing(bool value);
  external bool get isComposing;
  external set inputType(String value);
  external String get inputType;
}

@JS('KeyboardEvent')
@staticInterop
class KeyboardEvent implements UIEvent {
  external factory KeyboardEvent(
    String type, [
    KeyboardEventInit eventInitDict,
  ]);

  external static int get DOM_KEY_LOCATION_STANDARD;
  external static int get DOM_KEY_LOCATION_LEFT;
  external static int get DOM_KEY_LOCATION_RIGHT;
  external static int get DOM_KEY_LOCATION_NUMPAD;
}

extension KeyboardEventExtension on KeyboardEvent {
  external bool getModifierState(String keyArg);
  external void initKeyboardEvent(
    String typeArg, [
    bool bubblesArg,
    bool cancelableArg,
    Window? viewArg,
    String keyArg,
    int locationArg,
    bool ctrlKey,
    bool altKey,
    bool shiftKey,
    bool metaKey,
  ]);
  external String get key;
  external String get code;
  external int get location;
  external bool get ctrlKey;
  external bool get shiftKey;
  external bool get altKey;
  external bool get metaKey;
  external bool get repeat;
  external bool get isComposing;
  external int get charCode;
  external int get keyCode;
}

@JS()
@staticInterop
@anonymous
class KeyboardEventInit implements EventModifierInit {
  external factory KeyboardEventInit({
    String key,
    String code,
    int location,
    bool repeat,
    bool isComposing,
    int charCode,
    int keyCode,
  });
}

extension KeyboardEventInitExtension on KeyboardEventInit {
  external set key(String value);
  external String get key;
  external set code(String value);
  external String get code;
  external set location(int value);
  external int get location;
  external set repeat(bool value);
  external bool get repeat;
  external set isComposing(bool value);
  external bool get isComposing;
  external set charCode(int value);
  external int get charCode;
  external set keyCode(int value);
  external int get keyCode;
}

@JS('CompositionEvent')
@staticInterop
class CompositionEvent implements UIEvent {
  external factory CompositionEvent(
    String type, [
    CompositionEventInit eventInitDict,
  ]);
}

extension CompositionEventExtension on CompositionEvent {
  external void initCompositionEvent(
    String typeArg, [
    bool bubblesArg,
    bool cancelableArg,
    Window? viewArg,
    String dataArg,
  ]);
  external String get data;
}

@JS()
@staticInterop
@anonymous
class CompositionEventInit implements UIEventInit {
  external factory CompositionEventInit({String data});
}

extension CompositionEventInitExtension on CompositionEventInit {
  external set data(String value);
  external String get data;
}

@JS('MutationEvent')
@staticInterop
class MutationEvent implements Event {
  external static int get MODIFICATION;
  external static int get ADDITION;
  external static int get REMOVAL;
}

extension MutationEventExtension on MutationEvent {
  external void initMutationEvent(
    String typeArg, [
    bool bubblesArg,
    bool cancelableArg,
    Node? relatedNodeArg,
    String prevValueArg,
    String newValueArg,
    String attrNameArg,
    int attrChangeArg,
  ]);
  external Node? get relatedNode;
  external String get prevValue;
  external String get newValue;
  external String get attrName;
  external int get attrChange;
}
