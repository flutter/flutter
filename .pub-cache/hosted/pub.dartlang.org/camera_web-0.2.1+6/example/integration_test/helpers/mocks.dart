// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'dart:ui';

import 'package:camera_web/src/camera.dart';
import 'package:camera_web/src/camera_service.dart';
import 'package:camera_web/src/shims/dart_js_util.dart';
import 'package:camera_web/src/types/types.dart';
import 'package:cross_file/cross_file.dart';
import 'package:mocktail/mocktail.dart';

class MockWindow extends Mock implements Window {}

class MockScreen extends Mock implements Screen {}

class MockScreenOrientation extends Mock implements ScreenOrientation {}

class MockDocument extends Mock implements Document {}

class MockElement extends Mock implements Element {}

class MockNavigator extends Mock implements Navigator {}

class MockMediaDevices extends Mock implements MediaDevices {}

class MockCameraService extends Mock implements CameraService {}

class MockMediaStreamTrack extends Mock implements MediaStreamTrack {}

class MockCamera extends Mock implements Camera {}

class MockCameraOptions extends Mock implements CameraOptions {}

class MockVideoElement extends Mock implements VideoElement {}

class MockXFile extends Mock implements XFile {}

class MockJsUtil extends Mock implements JsUtil {}

class MockMediaRecorder extends Mock implements MediaRecorder {}

/// A fake [MediaStream] that returns the provided [_videoTracks].
class FakeMediaStream extends Fake implements MediaStream {
  FakeMediaStream(this._videoTracks);

  final List<MediaStreamTrack> _videoTracks;

  @override
  List<MediaStreamTrack> getVideoTracks() => _videoTracks;
}

/// A fake [MediaDeviceInfo] that returns the provided [_deviceId], [_label] and [_kind].
class FakeMediaDeviceInfo extends Fake implements MediaDeviceInfo {
  FakeMediaDeviceInfo(this._deviceId, this._label, this._kind);

  final String _deviceId;
  final String _label;
  final String _kind;

  @override
  String? get deviceId => _deviceId;

  @override
  String? get label => _label;

  @override
  String? get kind => _kind;
}

/// A fake [MediaError] that returns the provided error [_code] and [_message].
class FakeMediaError extends Fake implements MediaError {
  FakeMediaError(
    this._code, [
    String message = '',
  ]) : _message = message;

  final int _code;
  final String _message;

  @override
  int get code => _code;

  @override
  String? get message => _message;
}

/// A fake [DomException] that returns the provided error [_name] and [_message].
class FakeDomException extends Fake implements DomException {
  FakeDomException(
    this._name, [
    String? message,
  ]) : _message = message;

  final String _name;
  final String? _message;

  @override
  String get name => _name;

  @override
  String? get message => _message;
}

/// A fake [ElementStream] that listens to the provided [_stream] on [listen].
class FakeElementStream<T extends Event> extends Fake
    implements ElementStream<T> {
  FakeElementStream(this._stream);

  final Stream<T> _stream;

  @override
  StreamSubscription<T> listen(void Function(T event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

/// A fake [BlobEvent] that returns the provided blob [data].
class FakeBlobEvent extends Fake implements BlobEvent {
  FakeBlobEvent(this._blob);

  final Blob? _blob;

  @override
  Blob? get data => _blob;
}

/// A fake [DomException] that returns the provided error [_name] and [_message].
class FakeErrorEvent extends Fake implements ErrorEvent {
  FakeErrorEvent(
    String type, [
    String? message,
  ])  : _type = type,
        _message = message;

  final String _type;
  final String? _message;

  @override
  String get type => _type;

  @override
  String? get message => _message;
}

/// Returns a video element with a blank stream of size [videoSize].
///
/// Can be used to mock a video stream:
/// ```dart
/// final videoElement = getVideoElementWithBlankStream(Size(100, 100));
/// final videoStream = videoElement.captureStream();
/// ```
VideoElement getVideoElementWithBlankStream(Size videoSize) {
  final CanvasElement canvasElement = CanvasElement(
    width: videoSize.width.toInt(),
    height: videoSize.height.toInt(),
  )..context2D.fillRect(0, 0, videoSize.width, videoSize.height);

  final VideoElement videoElement = VideoElement()
    ..srcObject = canvasElement.captureStream();

  return videoElement;
}
