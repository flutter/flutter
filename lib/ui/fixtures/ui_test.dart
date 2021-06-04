// @dart = 2.6
// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

void main() {}

@pragma('vm:entry-point')
void validateSceneBuilderAndScene() {
  final SceneBuilder builder = SceneBuilder();
  builder.pushOffset(10, 10);
  _validateBuilderHasLayers(builder);
  final Scene scene = builder.build();
  _validateBuilderHasNoLayers();
  _captureScene(scene);
  scene.dispose();
  _validateSceneHasNoLayers();
}
_validateBuilderHasLayers(SceneBuilder builder) native 'ValidateBuilderHasLayers';
_validateBuilderHasNoLayers() native 'ValidateBuilderHasNoLayers';
_captureScene(Scene scene) native 'CaptureScene';
_validateSceneHasNoLayers() native 'ValidateSceneHasNoLayers';

@pragma('vm:entry-point')
void validateEngineLayerDispose() {
  final SceneBuilder builder = SceneBuilder();
  final EngineLayer layer = builder.pushOffset(10, 10);
  _captureRootLayer(builder);
  final Scene scene = builder.build();
  scene.dispose();
  _validateLayerTreeCounts();
  layer.dispose();
  _validateEngineLayerDispose();
}
_captureRootLayer(SceneBuilder sceneBuilder) native 'CaptureRootLayer';
_validateLayerTreeCounts() native 'ValidateLayerTreeCounts';
_validateEngineLayerDispose() native 'ValidateEngineLayerDispose';

@pragma('vm:entry-point')
Future<void> createSingleFrameCodec() async {
  final ImmutableBuffer buffer = await ImmutableBuffer.fromUint8List(Uint8List.fromList(List<int>.filled(4, 100)));
  final ImageDescriptor descriptor = ImageDescriptor.raw(
    buffer,
    width: 1,
    height: 1,
    pixelFormat: PixelFormat.rgba8888,
  );
  final Codec codec = await descriptor.instantiateCodec();
  _validateCodec(codec);
  final FrameInfo info = await codec.getNextFrame();
  info.image.dispose();
  _validateCodec(codec);
  codec.dispose();
  descriptor.dispose();
  buffer.dispose();
  assert(buffer.debugDisposed);
  _finish();
}
void _validateCodec(Codec codec) native 'ValidateCodec';
void _finish() native 'Finish';

@pragma('vm:entry-point')
void createVertices() {
  const int uint16max = 65535;

  final Int32List colors = Int32List(uint16max);
  final Float32List coords = Float32List(uint16max * 2);
  final Uint16List indices = Uint16List(uint16max);
  final Float32List positions = Float32List(uint16max * 2);
  colors[0] = const Color(0xFFFF0000).value;
  colors[1] = const Color(0xFF00FF00).value;
  colors[2] = const Color(0xFF0000FF).value;
  colors[3] = const Color(0xFF00FFFF).value;
  indices[1] = indices[3] = 1;
  indices[2] = indices[5] = 3;
  indices[4] = 2;
  positions[2] = positions[4] = positions[5] = positions[7] = 250.0;

  final Vertices vertices = Vertices.raw(
    VertexMode.triangles,
    positions,
    textureCoordinates: coords,
    colors: colors,
    indices: indices,
  );
  _validateVertices(vertices);
}
void _validateVertices(Vertices vertices) native 'ValidateVertices';

@pragma('vm:entry-point')
void sendSemanticsUpdate() {
  final SemanticsUpdateBuilder builder = SemanticsUpdateBuilder();
  final String label = "label";
  final List<StringAttribute> labelAttributes = <StringAttribute> [
    SpellOutStringAttribute(range: TextRange(start: 1, end: 2)),
  ];

  final String value = "value";
  final List<StringAttribute> valueAttributes = <StringAttribute> [
    SpellOutStringAttribute(range: TextRange(start: 2, end: 3)),
  ];

  final String increasedValue = "increasedValue";
  final List<StringAttribute> increasedValueAttributes = <StringAttribute> [
    SpellOutStringAttribute(range: TextRange(start: 4, end: 5)),
  ];

  final String decreasedValue = "decreasedValue";
  final List<StringAttribute> decreasedValueAttributes = <StringAttribute> [
    SpellOutStringAttribute(range: TextRange(start: 5, end: 6)),
  ];

  final String hint = "hint";
  final List<StringAttribute> hintAttributes = <StringAttribute> [
    LocaleStringAttribute(
      locale: Locale('en', 'MX'), range: TextRange(start: 0, end: 1),
    ),
  ];

  final Float64List transform = Float64List(16);
  final Int32List childrenInTraversalOrder = Int32List(0);
  final Int32List childrenInHitTestOrder = Int32List(0);
  final Int32List additionalActions = Int32List(0);
  transform[0] = 1;
  transform[1] = 0;
  transform[2] = 0;
  transform[3] = 0;

  transform[4] = 0;
  transform[5] = 1;
  transform[6] = 0;
  transform[7] = 0;

  transform[8] = 0;
  transform[9] = 0;
  transform[10] = 1;
  transform[11] = 0;

  transform[12] = 0;
  transform[13] = 0;
  transform[14] = 0;
  transform[15] = 0;
  builder.updateNode(
    id: 0,
    flags: 0,
    actions: 0,
    maxValueLength: 0,
    currentValueLength: 0,
    textSelectionBase: -1,
    textSelectionExtent: -1,
    platformViewId: -1,
    scrollChildren: 0,
    scrollIndex: 0,
    scrollPosition: 0,
    scrollExtentMax: 0,
    scrollExtentMin: 0,
    rect: Rect.fromLTRB(0, 0, 10, 10),
    elevation: 0,
    thickness: 0,
    label: label,
    labelAttributes: labelAttributes,
    value: value,
    valueAttributes: valueAttributes,
    increasedValue: increasedValue,
    increasedValueAttributes: increasedValueAttributes,
    decreasedValue: decreasedValue,
    decreasedValueAttributes: decreasedValueAttributes,
    hint: hint,
    hintAttributes: hintAttributes,
    textDirection: TextDirection.ltr,
    transform: transform,
    childrenInTraversalOrder: childrenInTraversalOrder,
    childrenInHitTestOrder: childrenInHitTestOrder,
    additionalActions: additionalActions
  );
  _semanticsUpdate(builder.build());
}

void _semanticsUpdate(SemanticsUpdate update) native 'SemanticsUpdate';

@pragma('vm:entry-point')
void createPath() {
  final Path path = Path()..lineTo(10, 10);
  _validatePath(path);
  // Arbitrarily hold a reference to the path to make sure it does not get
  // garbage collected.
  Future<void>.delayed(const Duration(days: 100)).then((_) {
    path.lineTo(100, 100);
  });
}
void _validatePath(Path path) native 'ValidatePath';

@pragma('vm:entry-point')
void frameCallback(FrameInfo info) {
  print('called back');
}

@pragma('vm:entry-point')
void messageCallback(dynamic data) {}

@pragma('vm:entry-point')
void validateConfiguration() native 'ValidateConfiguration';


// Draw a circle on a Canvas that has a PictureRecorder. Take the image from
// the PictureRecorder, and encode it as png. Check that the png data is
// backed by an external Uint8List.
@pragma('vm:entry-point')
Future<void> encodeImageProducesExternalUint8List() async {
  final PictureRecorder pictureRecorder = PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);
  final Paint paint = Paint()
    ..color = Color.fromRGBO(255, 255, 255, 1.0)
    ..style = PaintingStyle.fill;
  final Offset c = Offset(50.0, 50.0);
  canvas.drawCircle(c, 25.0, paint);
  final Picture picture = pictureRecorder.endRecording();
  final Image image = await picture.toImage(100, 100);
  _encodeImage(image, ImageByteFormat.png.index, (Uint8List result) {
    // The buffer should be non-null and writable.
    result[0] = 0;
    // The buffer should be external typed data.
    _validateExternal(result);
  });
}
void _encodeImage(Image i, int format, void Function(Uint8List result))
  native 'EncodeImage';
void _validateExternal(Uint8List result) native 'ValidateExternal';

@pragma('vm:entry-point')
Future<void> pumpImage() async {
  const int width = 6000;
  const int height = 6000;
  final Completer<Image> completer = Completer<Image>();
  decodeImageFromPixels(
    Uint8List.fromList(List<int>.filled(width * height * 4, 0xFF)),
    width,
    height,
    PixelFormat.rgba8888,
    (Image image) => completer.complete(image),
  );
  final Image image = await completer.future;

  final FrameCallback renderBlank = (Duration duration) {
    image.dispose();

    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawRect(Rect.largest, Paint());
    final Picture picture = recorder.endRecording();

    final SceneBuilder builder = SceneBuilder();
    builder.addPicture(Offset.zero, picture);

    final Scene scene = builder.build();
    window.render(scene);
    scene.dispose();
    window.onBeginFrame = (Duration duration) {
      window.onDrawFrame = _onBeginFrameDone;
    };
    window.scheduleFrame();
  };

  final FrameCallback renderImage = (Duration duration) {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawImage(image, Offset.zero, Paint());
    final Picture picture = recorder.endRecording();

    final SceneBuilder builder = SceneBuilder();
    builder.addPicture(Offset.zero, picture);

    _captureImageAndPicture(image, picture);

    final Scene scene = builder.build();
    window.render(scene);
    scene.dispose();
    window.onBeginFrame = renderBlank;
    window.scheduleFrame();
  };

  window.onBeginFrame = renderImage;
  window.scheduleFrame();
}
void _captureImageAndPicture(Image image, Picture picture) native 'CaptureImageAndPicture';
Future<void> _onBeginFrameDone() native 'OnBeginFrameDone';
