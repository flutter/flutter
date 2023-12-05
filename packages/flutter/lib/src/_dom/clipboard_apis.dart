// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

// ignore_for_file: public_member_api_docs

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';
import 'permissions.dart';

typedef ClipboardItemData = JSPromise;
typedef ClipboardItems = JSArray;
typedef PresentationStyle = String;

@JS()
@staticInterop
@anonymous
class ClipboardEventInit implements EventInit {
  external factory ClipboardEventInit({DataTransfer? clipboardData});
}

extension ClipboardEventInitExtension on ClipboardEventInit {
  external set clipboardData(DataTransfer? value);
  external DataTransfer? get clipboardData;
}

@JS('ClipboardEvent')
@staticInterop
class ClipboardEvent implements Event {
  external factory ClipboardEvent(
    String type, [
    ClipboardEventInit eventInitDict,
  ]);
}

extension ClipboardEventExtension on ClipboardEvent {
  external DataTransfer? get clipboardData;
}

@JS('ClipboardItem')
@staticInterop
class ClipboardItem {
  external factory ClipboardItem(
    JSAny items, [
    ClipboardItemOptions options,
  ]);

  external static bool supports(String type);
}

extension ClipboardItemExtension on ClipboardItem {
  external JSPromise getType(String type);
  external PresentationStyle get presentationStyle;
  external JSArray get types;
}

@JS()
@staticInterop
@anonymous
class ClipboardItemOptions {
  external factory ClipboardItemOptions({PresentationStyle presentationStyle});
}

extension ClipboardItemOptionsExtension on ClipboardItemOptions {
  external set presentationStyle(PresentationStyle value);
  external PresentationStyle get presentationStyle;
}

@JS('Clipboard')
@staticInterop
class Clipboard implements EventTarget {}

extension ClipboardExtension on Clipboard {
  external JSPromise read();
  external JSPromise readText();
  external JSPromise write(ClipboardItems data);
  external JSPromise writeText(String data);
}

@JS()
@staticInterop
@anonymous
class ClipboardPermissionDescriptor implements PermissionDescriptor {
  external factory ClipboardPermissionDescriptor({bool allowWithoutGesture});
}

extension ClipboardPermissionDescriptorExtension
    on ClipboardPermissionDescriptor {
  external set allowWithoutGesture(bool value);
  external bool get allowWithoutGesture;
}
