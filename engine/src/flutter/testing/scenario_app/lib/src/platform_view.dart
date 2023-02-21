// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
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
  } else if (value is int) {  // ignore: avoid_double_and_int_checks
    temp.buffer.asByteData().setInt64(7, value, Endian.little);
  }
  return temp;
}

List<int> _encodeString(String value) {
  return <int>[
    value.length, // This won't work if we use multi-byte characters.
    ...utf8.encode(value),
  ];
}

/// A simple platform view.
class PlatformViewScenario extends Scenario
    with _BasePlatformViewScenarioMixin {
  /// Creates the PlatformView scenario.
  ///
  /// The [dispatcher] parameter must not be null.
  PlatformViewScenario(
    PlatformDispatcher dispatcher, {
    required this.id,
  })  : super(dispatcher);

  /// The platform view identifier.
  final int id;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();
    addPlatformView(
      id,
      dispatcher: dispatcher,
      sceneBuilder: builder,
    );
    finishBuilder(builder);
  }
}

/// A simple platform view.
class NonFullScreenFlutterViewPlatformViewScenario extends Scenario
    with _BasePlatformViewScenarioMixin {
  /// Creates the PlatformView scenario.
  ///
  /// The [dispatcher] parameter must not be null.
  NonFullScreenFlutterViewPlatformViewScenario(
    PlatformDispatcher dispatcher, {
    required this.id,
  })  : super(dispatcher);

  /// The platform view identifier.
  final int id;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();
    addPlatformView(
      id,
      dispatcher: dispatcher,
      sceneBuilder: builder,
    );
    finishBuilder(builder);
  }
}

/// A simple platform view with overlay that doesn't intersect with the platform view.
class PlatformViewNoOverlayIntersectionScenario extends Scenario
    with _BasePlatformViewScenarioMixin {
  /// Creates the PlatformView scenario.
  ///
  /// The [dispatcher] parameter must not be null.
  PlatformViewNoOverlayIntersectionScenario(
    PlatformDispatcher dispatcher, {
    required this.id,
  })  : super(dispatcher);

  /// The platform view identifier.
  final int id;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    addPlatformView(
      id,
      dispatcher: dispatcher,
      sceneBuilder: builder,
    );

    finishBuilder(
      builder,
      overlayOffset: const Offset(150, 350),
    );
  }
}


/// A platform view that is larger than the display size.
/// This is only applicable on Android while using virtual displays.
/// Related issue: https://github.com/flutter/flutter/issues/28978.
class PlatformViewLargerThanDisplaySize extends Scenario
    with _BasePlatformViewScenarioMixin {
  /// Creates the PlatformView scenario.
  ///
  /// The [dispatcher] parameter must not be null.
  PlatformViewLargerThanDisplaySize(
    PlatformDispatcher dispatcher, {
    required this.id,
  })  : super(dispatcher);

  /// The platform view identifier.
  final int id;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    addPlatformView(
      id,
      dispatcher: dispatcher,
      sceneBuilder: builder,
      width: 15000,
      height: 60000,
    );

    finishBuilder(
      builder,
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
    PlatformDispatcher dispatcher, {
    required this.id,
  })  : super(dispatcher);

  /// The platform view identifier .
  final int id;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    addPlatformView(
      id,
      dispatcher: dispatcher,
      sceneBuilder: builder,
    );

    finishBuilder(
      builder,
      overlayOffset: const Offset(150, 240),
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
    PlatformDispatcher dispatcher, {
    required this.id,
  })  : super(dispatcher);

  /// The platform view identifier.
  final int id;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    addPlatformView(
      id,
      dispatcher: dispatcher,
      sceneBuilder: builder,
    );
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
    PlatformDispatcher dispatcher, {
    required this.id,
  })  : super(dispatcher);

  /// The platform view identifier.
  final int id;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    addPlatformView(
      id,
      dispatcher: dispatcher,
      sceneBuilder: builder,
    );

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
    PlatformDispatcher dispatcher, {
    required this.firstId,
    required this.secondId,
  })  : super(dispatcher);

  /// The platform view identifier to use for the first platform view.
  final int firstId;

  /// The platform view identifier to use for the second platform view.
  final int secondId;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    builder.pushOffset(0, 600);

    addPlatformView(
      firstId,
      dispatcher: dispatcher,
      sceneBuilder: builder,
      text: 'platform view 1',
    );

    builder.pop();

    addPlatformView(
      secondId,
      dispatcher: dispatcher,
      sceneBuilder: builder,
      text: 'platform view 2',
    );

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
  PlatformViewMaxOverlaysScenario(
    PlatformDispatcher dispatcher, {
    required this.id,
  })  : super(dispatcher);

  /// The platform view identifier.
  final int id;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    addPlatformView(
      id,
      dispatcher: dispatcher,
      sceneBuilder: builder,
    );
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
  MultiPlatformViewScenario(
    PlatformDispatcher dispatcher, {
    required this.firstId,
    required this.secondId,
  })  : super(dispatcher);

  /// The platform view identifier to use for the first platform view.
  final int firstId;

  /// The platform view identifier to use for the second platform view.
  final int secondId;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    builder.pushOffset(0, 600);

    addPlatformView(
      firstId,
      dispatcher: dispatcher,
      sceneBuilder: builder,
      text: 'platform view 1',
    );

    builder.pop();

    addPlatformView(
      secondId,
      dispatcher: dispatcher,
      sceneBuilder: builder,
      text: 'platform view 2',
    );

    finishBuilder(builder);
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
  MultiPlatformViewBackgroundForegroundScenario(
    PlatformDispatcher dispatcher, {
    required this.firstId,
    required this.secondId,
  })  : super(dispatcher) {
    _nextFrame = _firstFrame;
  }

  /// The platform view identifier to use for the first platform view.
  final int firstId;

  /// The platform view identifier to use for the second platform view.
  final int secondId;

  late void Function() _nextFrame;

  @override
  void onBeginFrame(Duration duration) {
    _nextFrame();
  }

  void _firstFrame() {
    final SceneBuilder builder = SceneBuilder();

    builder.pushOffset(50, 600);

    addPlatformView(
      firstId,
      dispatcher: dispatcher,
      sceneBuilder: builder,
      text: 'platform view 1',
    );

    builder.pop();

    builder.pushOffset(50, 0);

    addPlatformView(
      secondId,
      dispatcher: dispatcher,
      sceneBuilder: builder,
      text: 'platform view 2',
    );

    builder.pop();

    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTRB(0, 0, 500, 1000),
      Paint()..color = const Color(0xFFFF0000),
    );
    final Picture picture = recorder.endRecording();
    builder.addPicture(Offset.zero, picture);

    final Scene scene = builder.build();
    window.render(scene);
    scene.dispose();
  }

  void _secondFrame() {
    final SceneBuilder builder = SceneBuilder();

    builder.pushOffset(0, 600);

    addPlatformView(
      firstId,
      dispatcher: dispatcher,
      sceneBuilder: builder,
      text: 'platform view 1',
    );

    builder.pop();

    addPlatformView(
      secondId,
      dispatcher: dispatcher,
      sceneBuilder: builder,
      text: 'platform view 2',
    );

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
class PlatformViewClipRectScenario extends Scenario with _BasePlatformViewScenarioMixin {
  /// Constructs a platform view with clip rect scenario.
  PlatformViewClipRectScenario(
    PlatformDispatcher dispatcher, {
    required this.id,
  }) : super(dispatcher);

  /// The platform view identifier.
  final int id;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder()
      ..pushClipRect(const Rect.fromLTRB(100, 100, 400, 400));

    addPlatformView(
      id,
      dispatcher: dispatcher,
      sceneBuilder: builder,
    );

    finishBuilder(builder);
  }
}

/// Platform view with clip rect then the PlatformView is moved for 10 frames.
///
/// The clip rect moves with the same transform matrix with the PlatformView.
class PlatformViewClipRectAfterMovedScenario extends Scenario with _BasePlatformViewScenarioMixin {
  /// Constructs a platform view with clip rect scenario.
  PlatformViewClipRectAfterMovedScenario(
    PlatformDispatcher dispatcher, {
    required this.id,
  }) : super(dispatcher);

  /// The platform view identifier.
  final int id;

  int _numberOfFrames = 0;

  double _y = 100.0;

  @override
  void onBeginFrame(Duration duration) {
    final Matrix4 translateMatrix = Matrix4.identity()..translate(0.0, _y);
    final SceneBuilder builder = SceneBuilder()
      ..pushTransform(translateMatrix.storage)
      ..pushClipRect(const Rect.fromLTRB(100, 100, 400, 400));

    addPlatformView(
      _numberOfFrames == 10? 10000:id,
      dispatcher: dispatcher,
      sceneBuilder: builder,
    );

    // Add a translucent rect that has the same size of PlatformView.
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 500, 500),
      Paint()..color = const Color(0x22FF0000),
    );
    final Picture picture = recorder.endRecording();
    builder.addPicture(Offset.zero, picture);

    finishBuilder(builder);
    super.onBeginFrame(duration);
  }

  @override
  void onDrawFrame() {
    if (_numberOfFrames < 10) {
      _numberOfFrames ++;
      _y -= 10;
      window.scheduleFrame();
    }
    super.onDrawFrame();
  }
}

/// Platform view with clip rrect.
class PlatformViewClipRRectScenario extends PlatformViewScenario {
  /// Constructs a platform view with clip rrect scenario.
  PlatformViewClipRRectScenario(
    PlatformDispatcher dispatcher, {
    int id = 0,
  }) : super(dispatcher, id: id);

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

    addPlatformView(
      id,
      dispatcher: dispatcher,
      sceneBuilder: builder,
    );

    finishBuilder(builder);
  }
}


/// Platform view with clip rrect.
/// The bounding rect of the rrect is the same as PlatformView and only the corner radii clips the PlatformView.
class PlatformViewLargeClipRRectScenario extends PlatformViewScenario {
  /// Constructs a platform view with large clip rrect scenario.
  PlatformViewLargeClipRRectScenario(
    PlatformDispatcher dispatcher, {
    int id = 0,
  }) : super(dispatcher, id: id);

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();
    builder.pushClipRRect(
      RRect.fromLTRBAndCorners(
        0,
        0,
        500,
        500,
        topLeft: const Radius.circular(15),
        topRight: const Radius.circular(50),
        bottomLeft: const Radius.circular(50),
      ),
    );

    addPlatformView(
      id,
      dispatcher: dispatcher,
      sceneBuilder: builder,
    );

    finishBuilder(builder);
  }
}

/// Platform view with clip path.
class PlatformViewClipPathScenario extends PlatformViewScenario {
  /// Constructs a platform view with clip path scenario.
  PlatformViewClipPathScenario(
    PlatformDispatcher dispatcher, {
    int id = 0,
  }) : super(dispatcher, id: id);

  @override
  void onBeginFrame(Duration duration) {
    final Path path = Path()
      ..moveTo(100, 100)
      ..quadraticBezierTo(50, 250, 100, 400)
      ..lineTo(350, 400)
      ..cubicTo(400, 300, 300, 200, 350, 100)
      ..close();

    final SceneBuilder builder = SceneBuilder()..pushClipPath(path);
    addPlatformView(
      id,
      dispatcher: dispatcher,
      sceneBuilder: builder,
    );
    finishBuilder(builder);
  }
}

/// Platform view with clip rect after transformed.
class PlatformViewClipRectWithTransformScenario extends PlatformViewScenario {
  /// Constructs a platform view with clip rect with transform scenario.
  PlatformViewClipRectWithTransformScenario(
    PlatformDispatcher dispatcher, {
    int id = 0,
  }) : super(dispatcher, id: id);

  @override
  void onBeginFrame(Duration duration) {
    final Matrix4 matrix4 = Matrix4.identity()
      ..rotateZ(1)
      ..scale(0.5, 0.5, 1.0)
      ..translate(1000.0, 100.0);

    final SceneBuilder builder = SceneBuilder()..pushTransform(matrix4.storage);
    builder.pushClipRect(const Rect.fromLTRB(100, 100, 400, 400));

    addPlatformView(
      id,
      dispatcher: dispatcher,
      sceneBuilder: builder,
    );

    // Add a translucent rect that has the same size of PlatformView.
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 500, 500),
      Paint()..color = const Color(0x22FF0000),
    );
    final Picture picture = recorder.endRecording();
    builder.addPicture(Offset.zero, picture);

    finishBuilder(builder);
  }
}

/// Platform view with clip rrect after transformed.
class PlatformViewClipRRectWithTransformScenario extends PlatformViewScenario {
  /// Constructs a platform view with clip rrect with transform scenario.
  PlatformViewClipRRectWithTransformScenario(
    PlatformDispatcher dispatcher, {
    int id = 0,
  }) : super(dispatcher, id: id);

  @override
  void onBeginFrame(Duration duration) {
    final Matrix4 matrix4 = Matrix4.identity()
      ..rotateZ(1)
      ..scale(0.5, 0.5, 1.0)
      ..translate(1000.0, 100.0);

    final SceneBuilder builder = SceneBuilder()..pushTransform(matrix4.storage);
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
    addPlatformView(
      id,
      dispatcher: dispatcher,
      sceneBuilder: builder,
    );

    // Add a translucent rect that has the same size of PlatformView.
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 500, 500),
      Paint()..color = const Color(0x22FF0000),
    );
    final Picture picture = recorder.endRecording();
    builder.addPicture(Offset.zero, picture);

    finishBuilder(builder);
  }
}

/// Platform view with clip rrect after transformed.
/// The bounding rect of the rrect is the same as PlatformView and only the corner radii clips the PlatformView.
class PlatformViewLargeClipRRectWithTransformScenario extends PlatformViewScenario {
  /// Constructs a platform view with large clip rrect with transform scenario.
  PlatformViewLargeClipRRectWithTransformScenario(
    PlatformDispatcher dispatcher, {
    int id = 0,
  }) : super(dispatcher, id: id);

  @override
  void onBeginFrame(Duration duration) {
    final Matrix4 matrix4 = Matrix4.identity()
      ..rotateZ(1)
      ..scale(0.5, 0.5, 1.0)
      ..translate(1000.0, 100.0);

    final SceneBuilder builder = SceneBuilder()..pushTransform(matrix4.storage);
    builder.pushClipRRect(
      RRect.fromLTRBAndCorners(
        0,
        0,
        500,
        500,
        topLeft: const Radius.circular(15),
        topRight: const Radius.circular(50),
        bottomLeft: const Radius.circular(50),
      ),
    );
    addPlatformView(
      id,
      dispatcher: dispatcher,
      sceneBuilder: builder,
    );

    // Add a translucent rect that has the same size of PlatformView.
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 500, 500),
      Paint()..color = const Color(0x22FF0000),
    );
    final Picture picture = recorder.endRecording();
    builder.addPicture(Offset.zero, picture);

    finishBuilder(builder);
  }
}

/// Platform view with clip path after transformed.
class PlatformViewClipPathWithTransformScenario extends PlatformViewScenario {
  /// Constructs a platform view with clip path with transform scenario.
  PlatformViewClipPathWithTransformScenario(
    PlatformDispatcher dispatcher, {
    int id = 0,
  }) : super(dispatcher, id: id);

  @override
  void onBeginFrame(Duration duration) {
    final Matrix4 matrix4 = Matrix4.identity()
      ..rotateZ(1)
      ..scale(0.5, 0.5, 1.0)
      ..translate(1000.0, 100.0);

    final SceneBuilder builder = SceneBuilder()..pushTransform(matrix4.storage);
    final Path path = Path()
      ..moveTo(100, 100)
      ..quadraticBezierTo(50, 250, 100, 400)
      ..lineTo(350, 400)
      ..cubicTo(400, 300, 300, 200, 350, 100)
      ..close();

    builder.pushClipPath(path);
    addPlatformView(
      id,
      dispatcher: dispatcher,
      sceneBuilder: builder,
    );

    // Add a translucent rect that has the same size of PlatformView.
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 500, 500),
      Paint()..color = const Color(0x22FF0000),
    );
    final Picture picture = recorder.endRecording();
    builder.addPicture(Offset.zero, picture);

    finishBuilder(builder);
  }
}

/// Platform view with transform.
class PlatformViewTransformScenario extends PlatformViewScenario {
  /// Constructs a platform view with transform scenario.
  PlatformViewTransformScenario(
    PlatformDispatcher dispatcher, {
    int id = 0,
  }) : super(dispatcher, id: id);

  @override
  void onBeginFrame(Duration duration) {
    final Matrix4 matrix4 = Matrix4.identity()
      ..rotateZ(1)
      ..scale(0.5, 0.5, 1.0)
      ..translate(1000.0, 100.0);

    final SceneBuilder builder = SceneBuilder()..pushTransform(matrix4.storage);
    addPlatformView(
      id,
      dispatcher: dispatcher,
      sceneBuilder: builder,
    );
    finishBuilder(builder);
  }
}

/// Platform view with opacity.
class PlatformViewOpacityScenario extends PlatformViewScenario {
  /// Constructs a platform view with transform scenario.
  PlatformViewOpacityScenario(
    PlatformDispatcher dispatcher, {
    int id = 0,
  }) : super(dispatcher, id: id);

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder()..pushOpacity(150);
    addPlatformView(
      id,
      dispatcher: dispatcher,
      sceneBuilder: builder,
    );
    finishBuilder(builder);
  }
}

/// A simple platform view for testing touch events from iOS.
class PlatformViewForTouchIOSScenario extends Scenario
    with _BasePlatformViewScenarioMixin {
  /// Creates the PlatformView scenario.
  ///
  /// The [dispatcher] parameter must not be null.
  PlatformViewForTouchIOSScenario(
    PlatformDispatcher dispatcher, {
    this.id = 0,
    this.rejectUntilTouchesEnded = false,
    required this.accept,
  }) : super(dispatcher) {
    _nextFrame = _firstFrame;
  }

  late void Function() _nextFrame;

  /// Whether gestures should be accepted or rejected.
  final bool accept;

  /// The platform view identifier.
  final int id;

  /// Whether touches should be rejected until the gesture ends.
  final bool rejectUntilTouchesEnded;

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
      if (accept) {
        method = 'acceptGesture';
      }
      const int valueString = 7;
      const int valueInt32 = 3;
      const int valueMap = 13;
      final Uint8List message = Uint8List.fromList(<int>[
        valueString,
        ..._encodeString(method),
        valueMap,
        1,
        valueString,
        ..._encodeString('id'),
        valueInt32,
        ..._to32(id),
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

    if (rejectUntilTouchesEnded) {
      addPlatformView(
        id,
        dispatcher: dispatcher,
        sceneBuilder: builder,
        viewType: 'scenarios/textPlatformView_blockPolicyUntilTouchesEnded',
      );
    } else {
      addPlatformView(
        id,
        dispatcher: dispatcher,
        sceneBuilder: builder,
      );
    }
    finishBuilder(builder);
  }

  void _secondFrame() {
    final SceneBuilder builder = SceneBuilder()..pushOffset(5, 5);
    if (rejectUntilTouchesEnded) {
      addPlatformView(
        id,
        dispatcher: dispatcher,
        sceneBuilder: builder,
        viewType: 'scenarios/textPlatformView_blockPolicyUntilTouchesEnded',
      );
    } else {
      addPlatformView(
        id,
        dispatcher: dispatcher,
        sceneBuilder: builder,
      );
    }
    finishBuilder(builder);
  }
}

/// Scenario for verifying overlapping platform views can accept touch gesture.
/// See: https://github.com/flutter/flutter/issues/118366.
///
/// Renders the first frame with a foreground platform view.
/// Then renders the second frame with the foreground platform view covering
/// a new background platform view.
///
class PlatformViewForOverlappingPlatformViewsScenario extends Scenario
    with _BasePlatformViewScenarioMixin {

  /// Creates the PlatformViewForOverlappingPlatformViewsScenario.
  ///
  /// The [dispatcher] parameter must not be null.
  PlatformViewForOverlappingPlatformViewsScenario(
      PlatformDispatcher dispatcher, {
        required this.foregroundId,
        required this.backgroundId,
      })  : super(dispatcher) {
    _nextFrame = _firstFrame;
  }

  /// The id for a foreground platform view that covers another background platform view.
  /// A good example is a dialog prompt in a real app.
  final int foregroundId;

  /// The id for a background platform view that is covered by a foreground platform view.
  final int backgroundId;

  late void Function() _nextFrame;

  @override
  void onBeginFrame(Duration duration) {
    _nextFrame();
  }

  void _firstFrame() {
    final SceneBuilder builder = SceneBuilder();

    builder.pushOffset(100, 100);
    addPlatformView(
      foregroundId,
      width: 100,
      height: 100,
      dispatcher: dispatcher,
      sceneBuilder: builder,
      text: 'Foreground',
    );
    builder.pop();

    final Scene scene = builder.build();
    window.render(scene);
    scene.dispose();
  }

  void _secondFrame() {
    final SceneBuilder builder = SceneBuilder();

    builder.pushOffset(0, 0);
    addPlatformView(
      backgroundId,
      width: 300,
      height: 300,
      dispatcher: dispatcher,
      sceneBuilder: builder,
      text: 'Background',
    );
    builder.pop();

    builder.pushOffset(100, 100);
    addPlatformView(
      foregroundId,
      width: 100,
      height: 100,
      dispatcher: dispatcher,
      sceneBuilder: builder,
      text: 'Foreground',
    );
    builder.pop();

    final Scene scene = builder.build();
    window.render(scene);
    scene.dispose();
  }

  int _frameCount = 0;

  @override
  void onDrawFrame() {
    _frameCount += 1;
    // TODO(hellohuanlin): Need further investigation - the first 2 frames are dropped for some reason.
    // Wait for 60 frames to ensure the first frame has actually been rendered
    // (Minimum required is 3 frames, but just to be safe)
    if (_nextFrame == _firstFrame && _frameCount == 60) {
      _nextFrame = _secondFrame;
    }
    window.scheduleFrame();
    super.onDrawFrame();
  }

  @override
  void onPointerDataPacket(PointerDataPacket packet) {
    final PointerData data = packet.data.first;
    final double x = data.physicalX;
    final double y = data.physicalY;
    if (data.change == PointerChange.up && 100 <= x && x < 200 && 100 <= y && y < 200) {
      const int valueString = 7;
      const int valueInt32 = 3;
      const int valueMap = 13;
      final Uint8List message = Uint8List.fromList(<int>[
        valueString,
        ..._encodeString('acceptGesture'),
        valueMap,
        1,
        valueString,
        ..._encodeString('id'),
        valueInt32,
        ..._to32(foregroundId),
      ]);
      window.sendPlatformMessage(
        'flutter/platform_views',
        message.buffer.asByteData(),
            (ByteData? response) {},
      );
    }
  }
}

/// A simple platform view for testing platform view with a continuous texture layer.
/// For example, it simulates a video being played.
class PlatformViewWithContinuousTexture extends PlatformViewScenario {
  /// Constructs a platform view with continuous texture layer.
  PlatformViewWithContinuousTexture(
    PlatformDispatcher dispatcher, {
    int id = 0,
  }) : super(dispatcher, id: id);

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    builder.addTexture(0,
        width: 300, height: 300, offset: const Offset(200, 200));

    addPlatformView(
      id,
      dispatcher: dispatcher,
      sceneBuilder: builder,
    );

    finishBuilder(builder);
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
    PlatformDispatcher dispatcher, {
    int id = 0,
  }) : super(dispatcher, id: id);

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
    builder.addPicture(Offset.zero, picture);

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

    addPlatformView(
      id,
      dispatcher: dispatcher,
      sceneBuilder: builder,
    );

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
  TwoPlatformViewsWithOtherBackDropFilter(
    PlatformDispatcher dispatcher, {
    required int firstId,
    required int secondId,
  }) : _firstId = firstId,
       _secondId = secondId,
       super(dispatcher);

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
    builder.addPicture(Offset.zero, picture1);

    builder.pushOffset(0, 200);

    addPlatformView(
      _firstId,
      dispatcher: dispatcher,
      sceneBuilder: builder,
      width: 100,
      height: 100,
      text: 'platform view 1'
    );

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

    addPlatformView(
      _secondId,
      dispatcher: dispatcher,
      sceneBuilder: builder,
      text: 'platform view 2',
    );

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
  PlatformViewScrollingUnderWidget(
    PlatformDispatcher dispatcher, {
    required int firstPlatformViewId,
    required int lastPlatformViewId,
  }) : _firstPlatformViewId = firstPlatformViewId,
       _lastPlatformViewId = lastPlatformViewId,
       super(dispatcher);

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

  Future<void> _buildOneFrame(double offset) async {
    const double cellWidth = 1000;
    double localOffset = offset;
    final SceneBuilder builder = SceneBuilder();
    const double cellHeight = 300;
    for (int i = _firstPlatformViewId; i <= _lastPlatformViewId; i++) {
      // Build a list view with platform views.
      builder.pushOffset(0, localOffset);
      addPlatformView(
        i,
        dispatcher: dispatcher,
        sceneBuilder: builder,
        text: 'platform view $i',
        width: cellWidth,
        height: cellHeight,
      );
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

final Map<String, int> _createdPlatformViews = <String, int> {};

/// Adds the platform view to the scene.
///
/// First, the platform view is created by calling the corresponding platform channel,
/// then a new frame is scheduled, finally the platform view is added to the scene builder.
void addPlatformView(
  int id, {
  required PlatformDispatcher dispatcher,
  required SceneBuilder sceneBuilder,
  String text = 'platform view',
  double width = 500,
  double height = 500,
  String viewType = 'scenarios/textPlatformView',
}) {
  if (scenarioParams['view_type'] is String) {
    viewType = scenarioParams['view_type'] as String;
  }

  final String platformViewKey = '$viewType-$id';

  if (_createdPlatformViews.containsKey(platformViewKey)) {
    addPlatformViewToSceneBuilder(
      id,
      sceneBuilder: sceneBuilder,
      textureId: _createdPlatformViews[platformViewKey]!,
      width: width,
      height: height,
    );
    return;
  }

  final bool usesAndroidHybridComposition = scenarioParams['use_android_view'] as bool? ?? false;
  final bool expectAndroidHybridCompositionFallback =
      scenarioParams['expect_android_view_fallback'] as bool? ?? false;

  const int valueTrue = 1;
  const int valueFalse = 2;
  const int valueInt32 = 3;
  const int valueFloat64 = 6;
  const int valueString = 7;
  const int valueUint8List = 8;
  const int valueMap = 13;

  final Uint8List message = Uint8List.fromList(<int>[
    valueString,
    ..._encodeString('create'),
    valueMap,
    if (Platform.isIOS) 3, // 3 entries in map for iOS.
    if (Platform.isAndroid && !usesAndroidHybridComposition)
      7, // 7 entries in map for texture on Android.
    if (Platform.isAndroid && usesAndroidHybridComposition)
      5, // 5 entries in map for hybrid composition on Android.
    valueString,
    ..._encodeString('id'),
    valueInt32,
    ..._to32(id),
    valueString,
    ..._encodeString('viewType'),
    valueString,
    ..._encodeString(viewType),
    if (Platform.isAndroid && !usesAndroidHybridComposition) ...<int>[
      valueString,
      ..._encodeString('width'),
      // This is missing the 64-bit boundary alignment, making the entire
      // message encoding fragile to changes before this point. Do not add new
      // variable-length values such as strings before this point.
      // TODO(stuartmorgan): Fix this to use the actual encoding logic,
      // including alignment: https://github.com/flutter/flutter/issues/111188
      valueFloat64,
      ..._to64(width),
      valueString,
      ..._encodeString('height'),
      valueFloat64,
      ..._to64(height),
      valueString,
      ..._encodeString('direction'),
      valueInt32,
      ..._to32(0), // LTR
      valueString,
      ..._encodeString('hybridFallback'),
      if (expectAndroidHybridCompositionFallback) valueTrue
      else valueFalse,
    ],
    if (Platform.isAndroid && usesAndroidHybridComposition) ...<int>[
      valueString,
      ..._encodeString('hybrid'),
      valueTrue,
      valueString,
      ..._encodeString('direction'),
      valueInt32,
      ..._to32(0), // LTR
    ],
    valueString,
    ..._encodeString('params'),
    valueUint8List,
    ..._encodeString(text),
  ]);

  dispatcher.sendPlatformMessage(
    'flutter/platform_views',
    message.buffer.asByteData(),
    (ByteData? response) {
      late int textureId;
      if (response != null &&
          Platform.isAndroid &&
          !usesAndroidHybridComposition) {
        assert(response.getUint8(0) == 0, 'expected envelope');
        final int type = response.getUint8(1);
        if (expectAndroidHybridCompositionFallback) {
          // Fallback is indicated with a null return.
          assert(type == 0, 'expected null');
          textureId = -1;
        } else {
          // This is the texture ID.
          assert(type == 4, 'expected int64');
          textureId = response.getInt64(2, Endian.host);
        }
      } else {
        // There no texture ID.
        textureId = -1;
      }
      _createdPlatformViews[platformViewKey] = textureId;
      dispatcher.scheduleFrame();
    },
  );
}

/// Adds the platform view to the scene builder.
Future<void> addPlatformViewToSceneBuilder(
  int id, {
  required SceneBuilder sceneBuilder,
  required int textureId,
  double width = 500,
  double height = 500,
}) async {
  if (Platform.isIOS) {
    sceneBuilder.addPlatformView(id, width: width, height: height);
  } else if (Platform.isAndroid) {
    final bool expectAndroidHybridCompositionFallback =
      scenarioParams['expect_android_view_fallback'] as bool? ?? false;
    final bool usesAndroidHybridComposition =
      (scenarioParams['use_android_view'] as bool? ?? false) ||
      expectAndroidHybridCompositionFallback;
    if (usesAndroidHybridComposition) {
      sceneBuilder.addPlatformView(id, width: width, height: height);
    } else if (textureId != -1) {
      sceneBuilder.addTexture(textureId, width: width, height: height);
    } else {
      throw UnsupportedError('Invalid texture id $textureId');
    }
  } else {
    throw UnsupportedError(
        'Platform ${Platform.operatingSystem} is not supported');
  }
}

mixin _BasePlatformViewScenarioMixin on Scenario {
  // Add a picture and finishes the `sceneBuilder`.
  void finishBuilder(
    SceneBuilder sceneBuilder, {
    Offset? overlayOffset,
  }) {
    overlayOffset ??= const Offset(50, 50);
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
