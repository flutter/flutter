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

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

import 'barcode_scanner_utils.dart';
import 'colors.dart';

class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  CameraController _controller;
  BarcodeDetector _detector;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIOverlays(<SystemUiOverlay>[]);
    _startScanningBarcodes();
  }

  Future<void> _startScanningBarcodes() async {
    final CameraDescription camera = await getCamera(CameraLensDirection.back);
    await _openCamera(camera);
    await _streamImages(camera);
  }

  Future<void> _openCamera(CameraDescription camera) async {
    final ResolutionPreset preset =
        defaultTargetPlatform == TargetPlatform.android
            ? ResolutionPreset.medium
            : ResolutionPreset.low;

    _controller = CameraController(camera, preset);
    await _controller.initialize();

    setState(() {});
  }

  Future<void> _streamImages(CameraDescription camera) async {
    _detector = FirebaseVision.instance.barcodeDetector();

    _controller.startImageStream((CameraImage image) {
      if (_isDetecting) {
        return;
      }
      _isDetecting = true;

      final ImageRotation rotation = rotationIntToImageRotation(
        camera.sensorOrientation,
      );

      detect(image, _detector.detectInImage, rotation).then(
        (dynamic result) {
          final List<Barcode> barcodes = result;
          if (barcodes.isNotEmpty) print(barcodes[0].rawValue);
        },
      ).whenComplete(() => _isDetecting = false);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildCameraPreview() {
    final Size size = MediaQuery.of(context).size;
    final double deviceRatio = size.width / size.height;

    return Transform.scale(
      scale: _controller.value.aspectRatio / deviceRatio,
      child: Center(
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: CameraPreview(_controller),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller.value.isInitialized) {
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
                windowFrameColor: Colors.white54,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: const <Color>[Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0.0,
            bottom: 0.0,
            right: 0.0,
            height: 56,
            child: Container(
              color: kShrinePink50,
              child: Center(
                child: Text('Point your camera at a barcode'),
              ),
            ),
          ),
          AppBar(
            leading: IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            actions: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.flash_off,
                  color: Colors.white,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(
                  Icons.help_outline,
                  color: Colors.white,
                ),
                onPressed: () {},
              ),
            ],
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
