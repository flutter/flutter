// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';

@JS('DocumentPictureInPicture')
@staticInterop
class DocumentPictureInPicture implements EventTarget {}

extension DocumentPictureInPictureExtension on DocumentPictureInPicture {
  external JSPromise requestWindow([DocumentPictureInPictureOptions options]);
  external Window get window;
  external set onenter(EventHandler value);
  external EventHandler get onenter;
}

@JS()
@staticInterop
@anonymous
class DocumentPictureInPictureOptions {
  external factory DocumentPictureInPictureOptions({
    int width,
    int height,
  });
}

extension DocumentPictureInPictureOptionsExtension
    on DocumentPictureInPictureOptions {
  external set width(int value);
  external int get width;
  external set height(int value);
  external int get height;
}

@JS('DocumentPictureInPictureEvent')
@staticInterop
class DocumentPictureInPictureEvent implements Event {
  external factory DocumentPictureInPictureEvent(
    String type,
    DocumentPictureInPictureEventInit eventInitDict,
  );
}

extension DocumentPictureInPictureEventExtension
    on DocumentPictureInPictureEvent {
  external Window get window;
}

@JS()
@staticInterop
@anonymous
class DocumentPictureInPictureEventInit implements EventInit {
  external factory DocumentPictureInPictureEventInit({required Window window});
}

extension DocumentPictureInPictureEventInitExtension
    on DocumentPictureInPictureEventInit {
  external set window(Window value);
  external Window get window;
}
