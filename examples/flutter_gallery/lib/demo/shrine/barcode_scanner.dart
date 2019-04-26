// Copyright 2019-present the Flutter authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  CameraController controller;

  @override
  void initState() {
    super.initState();
    _openCamera();
  }

  Future<void> _openCamera() async {
    SystemChrome.setEnabledSystemUIOverlays(<SystemUiOverlay>[]);

    final List<CameraDescription> cameras = await availableCameras();

    final CameraDescription camera =
        cameras.firstWhere((CameraDescription description) {
      return description.lensDirection == CameraLensDirection.front;
    });

    final ResolutionPreset preset =
        defaultTargetPlatform == TargetPlatform.android
            ? ResolutionPreset.medium
            : ResolutionPreset.low;

    controller = CameraController(camera, preset);
    await controller.initialize();

    setState(() {});
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Widget _buildCameraPreview() {
    final Size size = MediaQuery.of(context).size;
    final double deviceRatio = size.width / size.height;

    return Transform.scale(
      scale: controller.value.aspectRatio / deviceRatio,
      child: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return Container();
    }

    return Scaffold(
      body: Stack(
        children: <Widget>[
          _buildCameraPreview(),
          Container(
            constraints: BoxConstraints.expand(),
            child: CustomPaint(
              painter: WindowPainter(
                windowSize: Size(256, 256),
                windowFrameColor: Colors.white30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WindowPainter extends CustomPainter {
  WindowPainter({@required this.windowSize, @required this.windowFrameColor});

  final Size windowSize;
  final Color windowFrameColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double windowHalfWidth = windowSize.width / 2;
    final double windowHalfHeight = windowSize.height / 2;

    final Rect windowRect = Rect.fromLTRB(
      center.dx - windowHalfWidth,
      center.dy - windowHalfHeight,
      center.dx + windowHalfWidth,
      center.dy + windowHalfHeight,
    );

    final Rect left =
        Rect.fromLTRB(0, windowRect.top, windowRect.left, windowRect.bottom);
    final Rect top = Rect.fromLTRB(0, 0, size.width, windowRect.top);
    final Rect right = Rect.fromLTRB(
      windowRect.right,
      windowRect.top,
      size.width,
      windowRect.bottom,
    );
    final Rect bottom = Rect.fromLTRB(
      0,
      windowRect.bottom,
      size.width,
      size.height,
    );

    final Paint paint = Paint()..color = windowFrameColor;
    canvas.drawRect(left, paint);
    canvas.drawRect(top, paint);
    canvas.drawRect(right, paint);
    canvas.drawRect(bottom, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
