// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'hr_time.dart';

typedef ProfilerResource = String;

@JS('Profiler')
@staticInterop
class Profiler implements EventTarget {
  external factory Profiler(ProfilerInitOptions options);
}

extension ProfilerExtension on Profiler {
  external JSPromise stop();
  external DOMHighResTimeStamp get sampleInterval;
  external bool get stopped;
}

@JS()
@staticInterop
@anonymous
class ProfilerTrace {
  external factory ProfilerTrace({
    required JSArray resources,
    required JSArray frames,
    required JSArray stacks,
    required JSArray samples,
  });
}

extension ProfilerTraceExtension on ProfilerTrace {
  external set resources(JSArray value);
  external JSArray get resources;
  external set frames(JSArray value);
  external JSArray get frames;
  external set stacks(JSArray value);
  external JSArray get stacks;
  external set samples(JSArray value);
  external JSArray get samples;
}

@JS()
@staticInterop
@anonymous
class ProfilerSample {
  external factory ProfilerSample({
    required DOMHighResTimeStamp timestamp,
    int stackId,
  });
}

extension ProfilerSampleExtension on ProfilerSample {
  external set timestamp(DOMHighResTimeStamp value);
  external DOMHighResTimeStamp get timestamp;
  external set stackId(int value);
  external int get stackId;
}

@JS()
@staticInterop
@anonymous
class ProfilerStack {
  external factory ProfilerStack({
    int parentId,
    required int frameId,
  });
}

extension ProfilerStackExtension on ProfilerStack {
  external set parentId(int value);
  external int get parentId;
  external set frameId(int value);
  external int get frameId;
}

@JS()
@staticInterop
@anonymous
class ProfilerFrame {
  external factory ProfilerFrame({
    required String name,
    int resourceId,
    int line,
    int column,
  });
}

extension ProfilerFrameExtension on ProfilerFrame {
  external set name(String value);
  external String get name;
  external set resourceId(int value);
  external int get resourceId;
  external set line(int value);
  external int get line;
  external set column(int value);
  external int get column;
}

@JS()
@staticInterop
@anonymous
class ProfilerInitOptions {
  external factory ProfilerInitOptions({
    required DOMHighResTimeStamp sampleInterval,
    required int maxBufferSize,
  });
}

extension ProfilerInitOptionsExtension on ProfilerInitOptions {
  external set sampleInterval(DOMHighResTimeStamp value);
  external DOMHighResTimeStamp get sampleInterval;
  external set maxBufferSize(int value);
  external int get maxBufferSize;
}
