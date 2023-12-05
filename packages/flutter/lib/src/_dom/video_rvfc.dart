// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'hr_time.dart';

typedef VideoFrameRequestCallback = JSFunction;

@JS()
@staticInterop
@anonymous
class VideoFrameCallbackMetadata {
  external factory VideoFrameCallbackMetadata({
    required DOMHighResTimeStamp presentationTime,
    required DOMHighResTimeStamp expectedDisplayTime,
    required int width,
    required int height,
    required num mediaTime,
    required int presentedFrames,
    num processingDuration,
    DOMHighResTimeStamp captureTime,
    DOMHighResTimeStamp receiveTime,
    int rtpTimestamp,
  });
}

extension VideoFrameCallbackMetadataExtension on VideoFrameCallbackMetadata {
  external set presentationTime(DOMHighResTimeStamp value);
  external DOMHighResTimeStamp get presentationTime;
  external set expectedDisplayTime(DOMHighResTimeStamp value);
  external DOMHighResTimeStamp get expectedDisplayTime;
  external set width(int value);
  external int get width;
  external set height(int value);
  external int get height;
  external set mediaTime(num value);
  external num get mediaTime;
  external set presentedFrames(int value);
  external int get presentedFrames;
  external set processingDuration(num value);
  external num get processingDuration;
  external set captureTime(DOMHighResTimeStamp value);
  external DOMHighResTimeStamp get captureTime;
  external set receiveTime(DOMHighResTimeStamp value);
  external DOMHighResTimeStamp get receiveTime;
  external set rtpTimestamp(int value);
  external int get rtpTimestamp;
}
