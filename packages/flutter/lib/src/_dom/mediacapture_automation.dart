// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

typedef MockCapturePromptResult = String;

@JS()
@staticInterop
@anonymous
class MockCapturePromptResultConfiguration {
  external factory MockCapturePromptResultConfiguration({
    MockCapturePromptResult getUserMedia,
    MockCapturePromptResult getDisplayMedia,
  });
}

extension MockCapturePromptResultConfigurationExtension
    on MockCapturePromptResultConfiguration {
  external set getUserMedia(MockCapturePromptResult value);
  external MockCapturePromptResult get getUserMedia;
  external set getDisplayMedia(MockCapturePromptResult value);
  external MockCapturePromptResult get getDisplayMedia;
}

@JS()
@staticInterop
@anonymous
class MockCaptureDeviceConfiguration {
  external factory MockCaptureDeviceConfiguration({
    String label,
    String deviceId,
    String groupId,
  });
}

extension MockCaptureDeviceConfigurationExtension
    on MockCaptureDeviceConfiguration {
  external set label(String value);
  external String get label;
  external set deviceId(String value);
  external String get deviceId;
  external set groupId(String value);
  external String get groupId;
}

@JS()
@staticInterop
@anonymous
class MockCameraConfiguration implements MockCaptureDeviceConfiguration {
  external factory MockCameraConfiguration({
    num defaultFrameRate,
    String facingMode,
  });
}

extension MockCameraConfigurationExtension on MockCameraConfiguration {
  external set defaultFrameRate(num value);
  external num get defaultFrameRate;
  external set facingMode(String value);
  external String get facingMode;
}

@JS()
@staticInterop
@anonymous
class MockMicrophoneConfiguration implements MockCaptureDeviceConfiguration {
  external factory MockMicrophoneConfiguration({int defaultSampleRate});
}

extension MockMicrophoneConfigurationExtension on MockMicrophoneConfiguration {
  external set defaultSampleRate(int value);
  external int get defaultSampleRate;
}
