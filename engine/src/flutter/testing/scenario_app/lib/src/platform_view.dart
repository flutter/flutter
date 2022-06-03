// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';

import 'scenario.dart';
import 'scenarios.dart';

List<int> _to32(int value) {
  final Uint8List temp = Uint8List(4);
  temp.buffer.asByteData().setInt32(0, value, Endian.little);
  return temp;
}

List<int> _to64(num value) {
  final Uint8List temp = Uint8List(15);
  if (value is double) {
    temp.buffer.asByteData().setFloat64(7, value, Endian.little);
  } else if (value is int) {
    temp.buffer.asByteData().setInt64(7, value, Endian.little);
  }
  return temp;
}

/// A simple platform view.
class PlatformViewScenario extends Scenario
    with _BasePlatformViewScenarioMixin {
  /// Creates the PlatformView scenario.
  ///
  /// The [dispatcher] parameter must not be null.
  PlatformViewScenario(PlatformDispatcher dispatcher, String text,
      {required this.id})
      : assert(dispatcher != null),
        super(dispatcher) {
    createPlatformView(dispatcher, text, id);
  }

  /// The platform view identifier.
  final int id;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    finishBuilderByAddingPlatformViewAndPicture(builder, id);
  }
}

/// A simple platform view.
class NonFullScreenFlutterViewPlatformViewScenario extends Scenario
    with _BasePlatformViewScenarioMixin {
  /// Creates the PlatformView scenario.
  ///
  /// The [dispatcher] parameter must not be null.
  NonFullScreenFlutterViewPlatformViewScenario(
      PlatformDispatcher dispatcher, String text,
      {required this.id})
      : assert(dispatcher != null),
        super(dispatcher) {
    createPlatformView(dispatcher, text, id);
  }

  /// The platform view identifier.
  final int id;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    finishBuilderByAddingPlatformViewAndPicture(builder, id);
  }
}

/// A simple platform view with overlay that doesn't intersect with the platform view.
class PlatformViewNoOverlayIntersectionScenario extends Scenario
    with _BasePlatformViewScenarioMixin {
  /// Creates the PlatformView scenario.
  ///
  /// The [dispatcher] parameter must not be null.
  PlatformViewNoOverlayIntersectionScenario(
      PlatformDispatcher dispatcher, String text,
      {required this.id})
      : assert(dispatcher != null),
        super(dispatcher) {
    createPlatformView(dispatcher, text, id);
  }

  /// The platform view identifier.
  final int id;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    finishBuilderByAddingPlatformViewAndPicture(
      builder,
      id,
      overlayOffset: const Offset(150, 350),
    );
  }
}

/// A simple platform view with an overlay that partially intersects with the platform view.
class PlatformViewPartialIntersectionScenario extends Scenario
    with _BasePlatformViewScenarioMixin {
  /// Creates the PlatformView scenario.
  ///
  /// The [dispatcher] parameter must not be null.
  PlatformViewPartialIntersectionScenario(
      PlatformDispatcher dispatcher, String text,
      {required this.id})
      : assert(dispatcher != null),
        super(dispatcher) {
    createPlatformView(dispatcher, text, id);
  }

  /// The platform view identifier .
  final int id;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    finishBuilderByAddingPlatformViewAndPicture(
      builder,
      id,
      overlayOffset: const Offset(150, 250),
    );
  }
}

/// A simple platform view with two overlays that intersect with each other and the platform view.
class PlatformViewTwoIntersectingOverlaysScenario extends Scenario
    with _BasePlatformViewScenarioMixin {
  /// Creates the PlatformView scenario.
  ///
  /// The [dispatcher] parameter must not be null.
  PlatformViewTwoIntersectingOverlaysScenario(
      PlatformDispatcher dispatcher, String text,
      {required this.id})
      : assert(dispatcher != null),
        super(dispatcher) {
    createPlatformView(dispatcher, text, id);
  }

  /// The platform view identifier.
  final int id;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    _addPlatformViewToScene(builder, id, 500, 500);
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawCircle(
      const Offset(50, 50),
      50,
      Paint()..color = const Color(0xFFABCDEF),
    );
    canvas.drawCircle(
      const Offset(100, 100),
      50,
      Paint()..color = const Color(0xFFABCDEF),
    );
    final Picture picture = recorder.endRecording();
    builder.addPicture(const Offset(300, 300), picture);
    final Scene scene = builder.build();
    window.render(scene);
    scene.dispose();
  }
}

/// A simple platform view with one overlay and two overlays that intersect with each other and the platform view.
class PlatformViewOneOverlayTwoIntersectingOverlaysScenario extends Scenario
    with _BasePlatformViewScenarioMixin {
  /// Creates the PlatformView scenario.
  ///
  /// The [dispatcher] parameter must not be null.
  PlatformViewOneOverlayTwoIntersectingOverlaysScenario(
      PlatformDispatcher dispatcher, String text,
      {required this.id})
      : assert(dispatcher != null),
        super(dispatcher) {
    createPlatformView(dispatcher, text, id);
  }

  /// The platform view identifier.
  final int id;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    _addPlatformViewToScene(builder, id, 500, 500);
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawCircle(
      const Offset(50, 50),
      50,
      Paint()..color = const Color(0xFFABCDEF),
    );
    canvas.drawCircle(
      const Offset(100, 100),
      50,
      Paint()..color = const Color(0xFFABCDEF),
    );
    canvas.drawCircle(
      const Offset(-100, 200),
      50,
      Paint()..color = const Color(0xFFABCDEF),
    );
    final Picture picture = recorder.endRecording();
    builder.addPicture(const Offset(300, 300), picture);
    final Scene scene = builder.build();
    window.render(scene);
    scene.dispose();
  }
}

/// Two platform views without an overlay intersecting either platform view.
class MultiPlatformViewWithoutOverlaysScenario extends Scenario
    with _BasePlatformViewScenarioMixin {
  /// Creates the PlatformView scenario.
  ///
  /// The [dispatcher] parameter must not be null.
  MultiPlatformViewWithoutOverlaysScenario(
      PlatformDispatcher dispatcher, String text,
      {required this.firstId, required this.secondId})
      : assert(dispatcher != null),
        super(dispatcher) {
    createPlatformView(dispatcher, text, firstId);
    createPlatformView(dispatcher, text, secondId);
  }

  /// The platform view identifier to use for the first platform view.
  final int firstId;

  /// The platform view identifier to use for the second platform view.
  final int secondId;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    builder.pushOffset(0, 600);
    _addPlatformViewToScene(builder, firstId, 500, 500);
    builder.pop();

    _addPlatformViewToScene(builder, secondId, 500, 500);

    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTRB(0, 0, 100, 1000),
      Paint()..color = const Color(0xFFFF0000),
    );
    final Picture picture = recorder.endRecording();
    builder.addPicture(const Offset(580, 0), picture);

    builder.pop();
    final Scene scene = builder.build();
    window.render(scene);
    scene.dispose();
  }
}

/// A simple platform view with too many overlays result in a single native view.
class PlatformViewMaxOverlaysScenario extends Scenario
    with _BasePlatformViewScenarioMixin {
  /// Creates the PlatformView scenario.
  ///
  /// The [dispatcher] parameter must not be null.
  PlatformViewMaxOverlaysScenario(PlatformDispatcher dispatcher, String text,
      {required this.id})
      : assert(dispatcher != null),
        super(dispatcher) {
    createPlatformView(dispatcher, text, id);
  }

  /// The platform view identifier.
  final int id;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    _addPlatformViewToScene(builder, id, 500, 500);
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawCircle(
      const Offset(50, 50),
      50,
      Paint()..color = const Color(0xFFABCDEF),
    );
    canvas.drawCircle(
      const Offset(100, 100),
      50,
      Paint()..color = const Color(0xFFABCDEF),
    );
    canvas.drawCircle(
      const Offset(-100, 200),
      50,
      Paint()..color = const Color(0xFFABCDEF),
    );
    canvas.drawCircle(
      const Offset(-100, -80),
      50,
      Paint()..color = const Color(0xFFABCDEF),
    );
    final Picture picture = recorder.endRecording();
    builder.addPicture(const Offset(300, 300), picture);
    final Scene scene = builder.build();
    window.render(scene);
    scene.dispose();
  }
}

/// Builds a scene with 2 platform views.
class MultiPlatformViewScenario extends Scenario
    with _BasePlatformViewScenarioMixin {
  /// Creates the PlatformView scenario.
  ///
  /// The [dispatcher] parameter must not be null.
  MultiPlatformViewScenario(PlatformDispatcher dispatcher,
      {required this.firstId, required this.secondId})
      : assert(dispatcher != null),
        super(dispatcher) {
    createPlatformView(dispatcher, 'platform view 1', firstId);
    createPlatformView(dispatcher, 'platform view 2', secondId);
  }

  /// The platform view identifier to use for the first platform view.
  final int firstId;

  /// The platform view identifier to use for the second platform view.
  final int secondId;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    builder.pushOffset(0, 600);
    _addPlatformViewToScene(builder, firstId, 500, 500);
    builder.pop();

    finishBuilderByAddingPlatformViewAndPicture(builder, secondId);
  }
}

/// Scenario for verifying platform views after background and foregrounding the app.
///
/// Renders a frame with 2 platform views covered by a flutter drawn rectangle,
/// when the app goes to the background and comes back to the foreground renders a new frame
/// with the 2 platform views but without the flutter drawn rectangle.
class MultiPlatformViewBackgroundForegroundScenario extends Scenario
    with _BasePlatformViewScenarioMixin {
  /// Creates the PlatformView scenario.
  ///
  /// The [dispatcher] parameter must not be null.
  MultiPlatformViewBackgroundForegroundScenario(PlatformDispatcher dispatcher,
      {required this.firstId, required this.secondId})
      : assert(dispatcher != null),
        super(dispatcher) {
    _nextFrame = _firstFrame;
    createPlatformView(dispatcher, 'platform view 1', firstId);
    createPlatformView(dispatcher, 'platform view 2', secondId);
  }

  /// The platform view identifier to use for the first platform view.
  final int firstId;

  /// The platform view identifier to use for the second platform view.
  final int secondId;

  @override
  void onBeginFrame(Duration duration) {
    _nextFrame();
  }

  late VoidCallback _nextFrame;

  void _firstFrame() {
    final SceneBuilder builder = SceneBuilder();

    builder.pushOffset(50, 600);
    _addPlatformViewToScene(builder, firstId, 500, 500);
    builder.pop();

    builder.pushOffset(50, 0);
    _addPlatformViewToScene(builder, secondId, 500, 500);
    builder.pop();

    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTRB(0, 0, 500, 1000),
      Paint()..color = const Color(0xFFFF0000),
    );
    final Picture picture = recorder.endRecording();
    builder.addPicture(const Offset(0, 0), picture);

    final Scene scene = builder.build();
    window.render(scene);
    scene.dispose();
  }

  void _secondFrame() {
    final SceneBuilder builder = SceneBuilder();

    builder.pushOffset(0, 600);
    _addPlatformViewToScene(builder, firstId, 500, 500);
    builder.pop();

    _addPlatformViewToScene(builder, secondId, 500, 500);

    final Scene scene = builder.build();
    window.render(scene);
    scene.dispose();
  }

  String _lastLifecycleState = '';

  @override
  void onPlatformMessage(
    String name,
    ByteData? data,
    PlatformMessageResponseCallback? callback,
  ) {
    if (name != 'flutter/lifecycle') {
      return;
    }
    final String message = utf8.decode(data!.buffer.asUint8List());
    if (_lastLifecycleState == 'AppLifecycleState.inactive' &&
        message == 'AppLifecycleState.resumed') {
      _nextFrame = _secondFrame;
      window.scheduleFrame();
    }

    _lastLifecycleState = message;
  }
}

/// Platform view with clip rect.
class PlatformViewClipRectScenario extends Scenario
    with _BasePlatformViewScenarioMixin {
  /// Constructs a platform view with clip rect scenario.
  PlatformViewClipRectScenario(PlatformDispatcher dispatcher, String text,
      {required this.id})
      : assert(dispatcher != null),
        super(dispatcher) {
    createPlatformView(dispatcher, text, id);
  }

  /// The platform view identifier.
  final int id;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder()
      ..pushClipRect(const Rect.fromLTRB(100, 100, 400, 400));

    finishBuilderByAddingPlatformViewAndPicture(builder, id);
  }
}

/// Platform view with clip rrect.
class PlatformViewClipRRectScenario extends PlatformViewScenario {
  /// Constructs a platform view with clip rrect scenario.
  PlatformViewClipRRectScenario(PlatformDispatcher dispatcher, String text,
      {int id = 0})
      : super(dispatcher, text, id: id);

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();
    builder.pushClipRRect(
      RRect.fromLTRBAndCorners(
        100,
        100,
        400,
        400,
        topLeft: const Radius.circular(15),
        topRight: const Radius.circular(50),
        bottomLeft: const Radius.circular(50),
      ),
    );
    finishBuilderByAddingPlatformViewAndPicture(builder, id);
  }
}

/// Platform view with clip path.
class PlatformViewClipPathScenario extends PlatformViewScenario {
  /// Constructs a platform view with clip rrect scenario.
  PlatformViewClipPathScenario(PlatformDispatcher dispatcher, String text,
      {int id = 0})
      : super(dispatcher, text, id: id);

  @override
  void onBeginFrame(Duration duration) {
    final Path path = Path()
      ..moveTo(100, 100)
      ..quadraticBezierTo(50, 250, 100, 400)
      ..lineTo(350, 400)
      ..cubicTo(400, 300, 300, 200, 350, 100)
      ..close();

    final SceneBuilder builder = SceneBuilder()..pushClipPath(path);
    finishBuilderByAddingPlatformViewAndPicture(builder, id);
  }
}

/// Platform view with transform.
class PlatformViewTransformScenario extends PlatformViewScenario {
  /// Constructs a platform view with transform scenario.
  PlatformViewTransformScenario(PlatformDispatcher dispatcher, String text,
      {int id = 0})
      : super(dispatcher, text, id: id);

  @override
  void onBeginFrame(Duration duration) {
    final Matrix4 matrix4 = Matrix4.identity()
      ..rotateZ(1)
      ..scale(0.5, 0.5, 1.0)
      ..translate(1000.0, 100.0, 0.0);

    final SceneBuilder builder = SceneBuilder()..pushTransform(matrix4.storage);

    finishBuilderByAddingPlatformViewAndPicture(builder, id);
  }
}

/// Platform view with opacity.
class PlatformViewOpacityScenario extends PlatformViewScenario {
  /// Constructs a platform view with transform scenario.
  PlatformViewOpacityScenario(PlatformDispatcher dispatcher, String text,
      {int id = 0})
      : super(dispatcher, text, id: id);

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder()..pushOpacity(150);
    finishBuilderByAddingPlatformViewAndPicture(builder, id);
  }
}

/// A simple platform view for testing touch events from iOS.
class PlatformViewForTouchIOSScenario extends Scenario
    with _BasePlatformViewScenarioMixin {
  /// Creates the PlatformView scenario.
  ///
  /// The [dispatcher] parameter must not be null.
  PlatformViewForTouchIOSScenario(PlatformDispatcher dispatcher, String text,
      {int id = 0, required bool accept, bool rejectUntilTouchesEnded = false})
      : assert(dispatcher != null),
        _accept = accept,
        _viewId = id,
        super(dispatcher) {
    if (rejectUntilTouchesEnded) {
      createPlatformView(dispatcher, text, id,
          viewType: 'scenarios/textPlatformView_blockPolicyUntilTouchesEnded');
    } else {
      createPlatformView(dispatcher, text, id);
    }
    _nextFrame = _firstFrame;
  }

  int _viewId;
  bool _accept;
  late VoidCallback _nextFrame;

  @override
  void onBeginFrame(Duration duration) {
    _nextFrame();
  }

  @override
  void onDrawFrame() {
    // Some iOS gesture recognizers bugs are introduced in the second frame (with a different platform view rect) after laying out the platform view.
    // So in this test, we load 2 frames to ensure that we cover those cases.
    // See https://github.com/flutter/flutter/issues/66044
    if (_nextFrame == _firstFrame) {
      _nextFrame = _secondFrame;
      window.scheduleFrame();
    }
    super.onDrawFrame();
  }

  @override
  void onPointerDataPacket(PointerDataPacket packet) {
    if (packet.data.first.change == PointerChange.add) {
      String method = 'rejectGesture';
      if (_accept) {
        method = 'acceptGesture';
      }
      const int _valueString = 7;
      const int _valueInt32 = 3;
      const int _valueMap = 13;
      final Uint8List message = Uint8List.fromList(<int>[
        _valueString,
        method.length,
        ...utf8.encode(method),
        _valueMap,
        1,
        _valueString,
        'id'.length,
        ...utf8.encode('id'),
        _valueInt32,
        ..._to32(_viewId),
      ]);
      window.sendPlatformMessage(
        'flutter/platform_views',
        message.buffer.asByteData(),
        (ByteData? response) {},
      );
    }
  }

  void _firstFrame() {
    final SceneBuilder builder = SceneBuilder();
    finishBuilderByAddingPlatformViewAndPicture(builder, _viewId);
  }

  void _secondFrame() {
    final SceneBuilder builder = SceneBuilder()..pushOffset(5, 5);
    finishBuilderByAddingPlatformViewAndPicture(builder, _viewId);
  }
}

/// A simple platform view for testing platform view with a continuous texture layer.
/// For example, it simulates a video being played.
class PlatformViewWithContinuousTexture extends PlatformViewScenario {
  /// Constructs a platform view with continuous texture layer.
  PlatformViewWithContinuousTexture(PlatformDispatcher dispatcher, String text,
      {int id = 0})
      : super(dispatcher, text, id: id);

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    builder.addTexture(0,
        width: 300, height: 300, offset: const Offset(200, 200));

    finishBuilderByAddingPlatformViewAndPicture(builder, id);
  }
}

/// A simple platform view for testing backDropFilter with a platform view in the scene.
///
/// The stack would look like: picture 1-> filter -> picture 2 -> pv -> picture 3. And picture 1 should be filtered.
///
/// Note it is not testing applying backDropFilter on a platform view.
/// See: https://github.com/flutter/flutter/issues/80766
class PlatformViewWithOtherBackDropFilter extends PlatformViewScenario {
  /// Constructs the scenario.
  PlatformViewWithOtherBackDropFilter(
      PlatformDispatcher dispatcher, String text,
      {int id = 0})
      : super(dispatcher, text, id: id);

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    // This is just a background picture to make the result more viewable.
    canvas.drawRect(
      const Rect.fromLTRB(0, 0, 500, 400),
      Paint()..color = const Color(0xFFFF0000),
    );
    // This rect should look blur due to the backdrop filter.
    canvas.drawRect(
      const Rect.fromLTRB(0, 0, 300, 300),
      Paint()..color = const Color(0xFF00FF00),
    );
    final Picture picture = recorder.endRecording();
    builder.addPicture(const Offset(0, 0), picture);

    final ImageFilter filter = ImageFilter.blur(sigmaX: 8, sigmaY: 8);
    builder.pushBackdropFilter(filter);

    final PictureRecorder recorder2 = PictureRecorder();
    final Canvas canvas2 = Canvas(recorder2);
    // This circle should not look blur.
    canvas2.drawCircle(
      const Offset(200, 100),
      50,
      Paint()..color = const Color(0xFF0000EF),
    );
    final Picture picture2 = recorder2.endRecording();
    builder.addPicture(const Offset(100, 100), picture2);

    builder.pop();

    builder.pushOffset(0, 600);
    _addPlatformViewToScene(builder, id, 500, 500);
    builder.pop();

    final PictureRecorder recorder3 = PictureRecorder();
    final Canvas canvas3 = Canvas(recorder3);
    // Add another picture layer so an overlay UIView is created, which was
    // the root cause of the original issue.
    canvas3.drawCircle(
      const Offset(300, 200),
      50,
      Paint()..color = const Color(0xFF0000EF),
    );
    final Picture picture3 = recorder3.endRecording();
    builder.addPicture(const Offset(100, 100), picture3);

    final Scene scene = builder.build();
    window.render(scene);
    scene.dispose();
  }
}

/// A simple platform view for testing backDropFilter with a platform view in the scene.
///
/// The stack would look like: picture 1 -> pv1 -> picture 2 -> filter -> pv2 - > picture 3.
/// Because backdrop filter on platform views has not been implemented(see: https://github.com/flutter/flutter/issues/43902),
/// the result will not including a filtered pv1.
class TwoPlatformViewsWithOtherBackDropFilter extends Scenario
    with _BasePlatformViewScenarioMixin {
  /// Constructs the scenario.
  TwoPlatformViewsWithOtherBackDropFilter(PlatformDispatcher dispatcher,
      {required int firstId, required int secondId})
      : _firstId = firstId,
        _secondId = secondId,
        super(dispatcher) {
    createPlatformView(dispatcher, 'platform view 1', firstId);
    createPlatformView(dispatcher, 'platform view 2', secondId);
  }

  final int _firstId;
  final int _secondId;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    // This is just a background picture to make the result more viewable.
    canvas.drawRect(
      const Rect.fromLTRB(0, 0, 600, 1000),
      Paint()..color = const Color(0xFFFF0000),
    );
    // This rect should look blur due to the backdrop filter.
    canvas.drawRect(
      const Rect.fromLTRB(0, 0, 300, 300),
      Paint()..color = const Color(0xFF00FF00),
    );
    final Picture picture1 = recorder.endRecording();
    builder.addPicture(const Offset(0, 0), picture1);

    builder.pushOffset(0, 200);
    _addPlatformViewToScene(builder, _firstId, 100, 100);

    final PictureRecorder recorder2 = PictureRecorder();
    final Canvas canvas2 = Canvas(recorder2);
    // This circle should look blur due to the backdrop filter.
    canvas2.drawCircle(
      const Offset(200, 100),
      50,
      Paint()..color = const Color(0xFF0000EF),
    );
    final Picture picture2 = recorder2.endRecording();
    builder.addPicture(const Offset(100, 100), picture2);

    final ImageFilter filter = ImageFilter.blur(sigmaX: 8, sigmaY: 8);
    builder.pushBackdropFilter(filter);

    builder.pushOffset(0, 600);
    _addPlatformViewToScene(builder, _secondId, 500, 500);
    builder.pop();

    builder.pop();

    final PictureRecorder recorder3 = PictureRecorder();
    final Canvas canvas3 = Canvas(recorder3);
    // Add another picture layer so an overlay UIView is created, which was
    // the root cause of the original issue.
    canvas3.drawCircle(
      const Offset(300, 200),
      50,
      Paint()..color = const Color(0xFF0000EF),
    );
    final Picture picture3 = recorder3.endRecording();
    builder.addPicture(const Offset(100, 100), picture3);

    final Scene scene = builder.build();
    window.render(scene);
    scene.dispose();
  }
}

/// Builds a scenario where many platform views are scrolling and pass under a picture.
class PlatformViewScrollingUnderWidget extends Scenario
    with _BasePlatformViewScenarioMixin {
  /// Creates the PlatformView scenario.
  ///
  /// The [dispatcher] parameter must not be null.
  PlatformViewScrollingUnderWidget(PlatformDispatcher dispatcher,
      {required int firstPlatformViewId, required int lastPlatformViewId})
      : _firstPlatformViewId = firstPlatformViewId,
        _lastPlatformViewId = lastPlatformViewId,
        assert(dispatcher != null),
        super(dispatcher) {
    for (int i = _firstPlatformViewId; i <= _lastPlatformViewId; i++) {
      createPlatformView(dispatcher, 'platform view', i);
    }
  }

  final int _firstPlatformViewId;

  final int _lastPlatformViewId;

  double _offset = 0;

  bool _movingUp = true;

  @override
  void onBeginFrame(Duration duration) {
    _buildOneFrame(_offset);
  }

  @override
  void onDrawFrame() {
    // Scroll up until -1000, then scroll down until -1.
    if (_offset < -1000) {
      _movingUp = false;
    } else if (_offset > -1) {
      _movingUp = true;
    }

    if (_movingUp) {
      _offset -= 100;
    } else {
      _offset += 100;
    }
    window.scheduleFrame();
    super.onDrawFrame();
  }

  void _buildOneFrame(double offset) {
    const double cellWidth = 1000;
    double localOffset = offset;
    final SceneBuilder builder = SceneBuilder();
    const double cellHeight = 300;
    for (int i = _firstPlatformViewId; i <= _lastPlatformViewId; i++) {
      // Build a list view with platform views.
      builder.pushOffset(0, localOffset);
      _addPlatformViewToScene(builder, i, cellWidth, cellHeight);
      builder.pop();
      localOffset += cellHeight;
    }

    // Add a "banner" that should display on top of the list view.
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTRB(0, cellHeight, cellWidth, 100),
      Paint()..color = const Color(0xFFFF0000),
    );
    final Picture picture = recorder.endRecording();
    builder.addPicture(const Offset(0, 20), picture);

    final Scene scene = builder.build();
    window.render(scene);
    scene.dispose();
  }
}

mixin _BasePlatformViewScenarioMixin on Scenario {
  int? _textureId;

  bool get usesAndroidHybridComposition {
    return (scenarioParams['use_android_view'] as bool?) == true;
  }

  /// Construct the platform view related scenario
  ///
  /// It prepare a TextPlatformView so it can be added to the SceneBuilder in `onBeginFrame`.
  /// Call this method in the constructor of the platform view related scenarios
  /// to perform necessary set up.
  void createPlatformView(PlatformDispatcher dispatcher, String text, int id,
      {String viewType = 'scenarios/textPlatformView'}) {
    const int _valueTrue = 1;
    const int _valueInt32 = 3;
    const int _valueFloat64 = 6;
    const int _valueString = 7;
    const int _valueUint8List = 8;
    const int _valueMap = 13;

    final Uint8List message = Uint8List.fromList(<int>[
      _valueString,
      'create'.length, // this won't work if we use multi-byte characters.
      ...utf8.encode('create'),
      _valueMap,
      if (Platform.isIOS) 3, // 3 entries in map for iOS.
      if (Platform.isAndroid && !usesAndroidHybridComposition)
        6, // 6 entries in map for virtual displays on Android.
      if (Platform.isAndroid && usesAndroidHybridComposition)
        5, // 5 entries in map for Android views.
      _valueString,
      'id'.length,
      ...utf8.encode('id'),
      _valueInt32,
      ..._to32(id),
      _valueString,
      'viewType'.length,
      ...utf8.encode('viewType'),
      _valueString,
      viewType.length,
      ...utf8.encode(viewType),
      if (Platform.isAndroid && !usesAndroidHybridComposition) ...<int>[
        _valueString,
        'width'.length,
        ...utf8.encode('width'),
        _valueFloat64,
        ..._to64(500.0),
        _valueString,
        'height'.length,
        ...utf8.encode('height'),
        _valueFloat64,
        ..._to64(500.0),
        _valueString,
        'direction'.length,
        ...utf8.encode('direction'),
        _valueInt32,
        ..._to32(0), // LTR
      ],
      if (Platform.isAndroid && usesAndroidHybridComposition) ...<int>[
        _valueString,
        'hybrid'.length,
        ...utf8.encode('hybrid'),
        _valueTrue,
        _valueString,
        'direction'.length,
        ...utf8.encode('direction'),
        _valueInt32,
        ..._to32(0), // LTR
      ],
      _valueString,
      'params'.length,
      ...utf8.encode('params'),
      _valueUint8List,
      text.length,
      ...utf8.encode(text),
    ]);

    dispatcher.sendPlatformMessage(
      'flutter/platform_views',
      message.buffer.asByteData(),
      (ByteData? response) {
        if (response != null &&
            Platform.isAndroid &&
            !usesAndroidHybridComposition) {
          // Envelope.
          _textureId = response.getUint8(0);
        }
      },
    );
  }

  void _addPlatformViewToScene(
    SceneBuilder sceneBuilder,
    int viewId,
    double width,
    double height,
  ) {
    if (Platform.isIOS) {
      sceneBuilder.addPlatformView(viewId, width: width, height: height);
    } else if (Platform.isAndroid) {
      if (usesAndroidHybridComposition) {
        sceneBuilder.addPlatformView(viewId, width: width, height: height);
      } else if (_textureId != null) {
        sceneBuilder.addTexture(_textureId!, width: width, height: height);
      }
    } else {
      throw UnsupportedError(
          'Platform ${Platform.operatingSystem} is not supported');
    }
  }

  // Add a platform view and a picture to the scene, then finish the `sceneBuilder`.
  void finishBuilderByAddingPlatformViewAndPicture(
    SceneBuilder sceneBuilder,
    int viewId, {
    Offset? overlayOffset,
  }) {
    overlayOffset ??= const Offset(50, 50);
    _addPlatformViewToScene(
      sceneBuilder,
      viewId,
      500,
      500,
    );
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawCircle(
      overlayOffset,
      50,
      Paint()..color = const Color(0xFFABCDEF),
    );
    final Picture picture = recorder.endRecording();
    sceneBuilder.addPicture(const Offset(300, 300), picture);
    final Scene scene = sceneBuilder.build();
    window.render(scene);
    scene.dispose();
  }
}
