# Camera Web Plugin

The web implementation of [`camera`][camera].

*Note*: This plugin is under development. See [missing implementation](#missing-implementation).

## Usage

### Depend on the package

This package is [endorsed](https://flutter.dev/docs/development/packages-and-plugins/developing-packages#endorsed-federated-plugin),
which means you can simply use `camera`
normally. This package will be automatically included in your app when you do.

## Example

Find the example in the [`camera` package](https://pub.dev/packages/camera#example).

## Limitations on the web platform

### Camera devices

The camera devices are accessed with [Stream Web API](https://developer.mozilla.org/en-US/docs/Web/API/Media_Streams_API)
with the following [browser support](https://caniuse.com/stream):

![Data on support for the Stream feature across the major browsers from caniuse.com](https://caniuse.bitsofco.de/image/stream.png)

Accessing camera devices requires a [secure browsing context](https://developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts).
Broadly speaking, this means that you need to serve your web application over HTTPS
(or `localhost` for local development). For insecure contexts
`CameraPlatform.availableCameras` might throw a `CameraException` with the
`permissionDenied` error code.

### Device orientation

The device orientation implementation is backed by [`Screen Orientation Web API`](https://www.w3.org/TR/screen-orientation/)
with the following [browser support](https://caniuse.com/screen-orientation):

![Data on support for the Screen Orientation feature across the major browsers from caniuse.com](https://caniuse.bitsofco.de/image/screen-orientation.png)

For the browsers that do not support the device orientation:

- `CameraPlatform.onDeviceOrientationChanged` returns an empty stream.
- `CameraPlatform.lockCaptureOrientation` and `CameraPlatform.unlockCaptureOrientation`
throw a `PlatformException` with the `orientationNotSupported` error code.

### Flash mode and zoom level

The flash mode and zoom level implementation is backed by [Image Capture Web API](https://w3c.github.io/mediacapture-image/)
with the following [browser support](https://caniuse.com/mdn-api_imagecapture):

![Data on support for the Image Capture feature across the major browsers from caniuse.com](https://caniuse.bitsofco.de/static/v1/mdn-api__ImageCapture-1628778966589.png)

For the browsers that do not support the flash mode:

- `CameraPlatform.setFlashMode` throws a `PlatformException` with the
`torchModeNotSupported` error code.

For the browsers that do not support the zoom level:

- `CameraPlatform.getMaxZoomLevel`, `CameraPlatform.getMinZoomLevel` and
`CameraPlatform.setZoomLevel` throw a `PlatformException` with the
`zoomLevelNotSupported` error code.

### Taking a picture

The image capturing implementation is backed by [`URL.createObjectUrl` Web API](https://developer.mozilla.org/en-US/docs/Web/API/URL/createObjectURL)
with the following [browser support](https://caniuse.com/bloburls):

![Data on support for the Blob URLs feature across the major browsers from caniuse.com](https://caniuse.bitsofco.de/image/bloburls.png)

The web platform does not support `dart:io`. Attempts to display a captured image
using `Image.file` will throw an error. The capture image contains a network-accessible
URL pointing to a location within the browser (blob) and can be displayed using
`Image.network` or `Image.memory` after loading the image bytes to memory.

See the example below:

```dart
if (kIsWeb) {
  Image.network(capturedImage.path);
} else {
  Image.file(File(capturedImage.path));
}
```

### Video recording 

The video recording implementation is backed by [MediaRecorder Web API](https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder) with the following [browser support](https://caniuse.com/mdn-api_mediarecorder):

![Data on support for the MediaRecorder feature across the major browsers from caniuse.com](https://caniuse.bitsofco.de/image/mediarecorder.png).

A video is recorded in one of the following video MIME types: 
- video/webm (e.g. on Chrome or Firefox)
- video/mp4 (e.g. on Safari)

Pausing, resuming or stopping the video recording throws a `PlatformException` with the `videoRecordingNotStarted` error code if the video recording was not started.

For the browsers that do not support the video recording:
- `CameraPlatform.startVideoRecording` throws a `PlatformException` with the `notSupported` error code.

## Missing implementation

The web implementation of [`camera`][camera] is missing the following features:
- Exposure mode, point and offset
- Focus mode and point
- Sensor orientation
- Image format group
- Streaming of frames

<!-- Links -->
[camera]: https://pub.dev/packages/camera
