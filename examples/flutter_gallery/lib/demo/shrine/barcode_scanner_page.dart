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
import 'dart:io';
import 'dart:ui' show lerpDouble;

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter_gallery/demo/shrine/supplemental/barcode_scanner_utils.dart';
import 'colors.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage(
      {this.validSquareWidth = 256, this.frameColor = Colors.black38});

  final double validSquareWidth;
  final Color frameColor;

  @override
  _BarcodeScannerPageState createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage>
    with TickerProviderStateMixin {
  CameraController _cameraController;
  AnimationController _animationController;
  String _scannerHint;
  bool _closeWindow = false;
  String _barcodePictureFilePath;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _barcodeFound = false;
  Size _previewSize;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIOverlays(<SystemUiOverlay>[]);
    _initCameraAndScanner();
    _initAnimation();
  }

  void _initCameraAndScanner() {
    BarcodeScannerUtils.getCamera(CameraLensDirection.back).then(
      (CameraDescription camera) async {
        await _openCamera(camera);
        await _startStreamingImagesToScanner(camera.sensorOrientation);
      },
    );
  }

  void _initAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1300),
      vsync: this,
    );

    _animationController.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        if (_barcodeFound) {
          _showBottomSheet();
        } else {
          Future<void>.delayed(const Duration(milliseconds: 1600), () {
            _animationController.forward(from: 0);
          });
        }
      }
    });

    _animationController.forward();
  }

  void _handleBarcodeFound() {
    setState(() {
      _barcodeFound = true;
      _scannerHint = 'Loading information...';
      _closeWindow = true;
    });
  }

  Future<void> _openCamera(CameraDescription camera) async {
    final ResolutionPreset preset =
        defaultTargetPlatform == TargetPlatform.android
            ? ResolutionPreset.medium
            : ResolutionPreset.low;

    _cameraController = CameraController(camera, preset);
    await _cameraController.initialize();
    _previewSize = _cameraController.value.previewSize;
    setState(() {});
  }

  Future<void> _startStreamingImagesToScanner(int sensorOrientation) async {
    final BarcodeDetector detector = FirebaseVision.instance.barcodeDetector();
    bool isDetecting = false;
    final MediaQueryData data = MediaQuery.of(context);

    _cameraController.startImageStream((CameraImage image) {
      if (isDetecting) {
        return;
      }

      isDetecting = true;

      BarcodeScannerUtils.detect(
        image: image,
        detectInImage: detector.detectInImage,
        imageRotation: sensorOrientation,
      ).then(
        (dynamic result) {
          _handleResult(
            barcodes: result,
            data: data,
            imageSize: Size(
              image.width.toDouble(),
              image.height.toDouble(),
            ),
          );
        },
      ).whenComplete(() => isDetecting = false);
    });
  }

  void _handleResult({
    @required List<Barcode> barcodes,
    @required MediaQueryData data,
    @required Size imageSize,
  }) {
    if (!_cameraController.value.isStreamingImages || barcodes.isEmpty) {
      return;
    }

    final EdgeInsets padding = data.padding;
    final double maxLogicalHeight =
        data.size.height - padding.top - padding.bottom;

    final double heightScale = imageSize.height / maxLogicalHeight;
    final double halfSquareWidth = heightScale * widget.validSquareWidth / 2;

    final Offset center = imageSize.center(Offset.zero);
    final Rect validRect = Rect.fromLTRB(
      center.dx - halfSquareWidth,
      center.dy - halfSquareWidth,
      center.dx + halfSquareWidth,
      center.dy + halfSquareWidth,
    );

    for (Barcode barcode in barcodes) {
      final Rect intersection = validRect.intersect(barcode.boundingBox);

      final bool doesContain = intersection == barcode.boundingBox;

      if (doesContain) {
        _cameraController.stopImageStream().then((_) {
          _takePicture();
        });

        _animationController.duration = const Duration(milliseconds: 2000);
        _handleBarcodeFound();
        return;
      } else if (validRect.overlaps(barcode.boundingBox)) {
        setState(() {
          _scannerHint = 'Move closer to the barcode';
        });
        return;
      }
    }

    setState(() {
      _scannerHint = null;
    });
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _animationController?.dispose();

    SystemChrome.setEnabledSystemUIOverlays(<SystemUiOverlay>[
      SystemUiOverlay.top,
      SystemUiOverlay.bottom,
    ]);

    super.dispose();
  }

  Future<void> _takePicture() async {
    final Directory extDir = await getApplicationDocumentsDirectory();

    final String dirPath = '${extDir.path}/Pictures/barcodePics';
    await Directory(dirPath).create(recursive: true);

    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    final String filePath = '$dirPath/$timestamp.jpg';

    try {
      await _cameraController.takePicture(filePath);
    } on CameraException catch (e) {
      print(e);
    }

    _cameraController.dispose();
    _cameraController = null;

    setState(() {
      _barcodePictureFilePath = filePath;
    });
  }

  Widget _buildCameraPreview() {
    return Container(
      color: Colors.black,
      child: Transform.scale(
        scale: _getImageZoom(MediaQuery.of(context)),
        child: Center(
          child: AspectRatio(
            aspectRatio: _cameraController.value.aspectRatio,
            child: CameraPreview(_cameraController),
          ),
        ),
      ),
    );
  }

  double _getImageZoom(MediaQueryData data) {
    final double logicalWidth = data.size.width;
    final double logicalHeight = _previewSize.aspectRatio * logicalWidth;

    final EdgeInsets padding = data.padding;
    final double maxLogicalHeight =
        data.size.height - padding.top - padding.bottom;

    return maxLogicalHeight / logicalHeight;
  }

  void _showBottomSheet() {
    final PersistentBottomSheetController<void> controller =
        _scaffoldKey.currentState.showBottomSheet<void>(
      (BuildContext context) {
        return Container(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                alignment: Alignment.topLeft,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey)),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('1 result found'),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(20),
                child: Column(
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Image.asset(
                          '18-0.jpg',
                          package: 'shrine_images',
                          fit: BoxFit.cover,
                          width: 96,
                          height: 96,
                        ),
                        Container(
                          height: 96,
                          margin: const EdgeInsets.only(left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                child: Text(
                                  'SPAN Reader',
                                  style: Theme.of(context)
                                      .textTheme
                                      .body1
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                'Vol. 2',
                                style: Theme.of(context)
                                    .textTheme
                                    .body1
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: const <Widget>[
                                    Text('Material Design'),
                                    Text('120 pages'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 22, bottom: 25),
                      child: const Text('A Japanese & English accompaniment to'
                          'the 2016 SPAN conference.'),
                    ),
                    RaisedButton(
                      onPressed: () {},
                      color: kShrinePink100,
                      child: Container(
                        width: 312,
                        height: 48,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              margin: const EdgeInsets.only(right: 16),
                              child: const Icon(Icons.add_shopping_cart),
                            ),
                            Text('ADD TO CART - \$12.99',
                                style:
                                    Theme.of(context).primaryTextTheme.button),
                          ],
                        ),
                      ),
                      elevation: 8.0,
                      shape: const BeveledRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(7.0)),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );

    controller.closed.then((_) => Navigator.of(context).pop());
  }

  @override
  Widget build(BuildContext context) {
    Widget background;
    if (_barcodePictureFilePath != null) {
      background = Container(
        color: Colors.black,
        child: Transform.scale(
          scale: _getImageZoom(MediaQuery.of(context)),
          child: Center(
            child: Image.file(
              File(_barcodePictureFilePath),
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
      );
    } else if (_cameraController != null &&
        _cameraController.value.isInitialized) {
      background = _buildCameraPreview();
    } else {
      background = Container(
        color: Colors.black,
      );
    }

    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        body: Stack(
          children: <Widget>[
            background,
            Container(
              constraints: const BoxConstraints.expand(),
              child: CustomPaint(
                painter: WindowPainter(
                  windowSize:
                      Size(widget.validSquareWidth, widget.validSquareWidth),
                  outerFrameColor: widget.frameColor,
                  closeWindow: _closeWindow,
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
                  child: Text(
                    _scannerHint ?? 'Point your camera at a barcode',
                    style: Theme.of(context)
                        .textTheme
                        .body1
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints.expand(),
              child: CustomPaint(
                painter: _barcodeFound
                    ? SquareTracePainter(
                        animation: Tween<double>(
                          begin: 0,
                          end: widget.validSquareWidth,
                        ).animate(
                          _animationController,
                        ),
                        square: Square(widget.validSquareWidth, Colors.white),
                      )
                    : SquareOutlinePainter(
                        animation: SquareTween(
                          Square(widget.validSquareWidth, Colors.white),
                          Square(
                            widget.validSquareWidth + 100,
                            Colors.transparent,
                          ),
                        ).animate(_animationController),
                      ),
              ),
            ),
            AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0.0,
              actions: <Widget>[
                IconButton(
                  icon: const Icon(
                    Icons.flash_off,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(
                    Icons.help_outline,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WindowPainter extends CustomPainter {
  WindowPainter({
    @required this.windowSize,
    this.outerFrameColor = Colors.white54,
    this.innerFrameColor = const Color(0xFF442C2E),
    this.innerFrameStrokeWidth = 3,
    this.closeWindow = false,
  });

  final Size windowSize;
  final Color outerFrameColor;
  final Color innerFrameColor;
  final double innerFrameStrokeWidth;
  final bool closeWindow;

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

    final Paint paint = Paint()..color = outerFrameColor;
    canvas.drawRect(left, paint);
    canvas.drawRect(top, paint);
    canvas.drawRect(right, paint);
    canvas.drawRect(bottom, paint);

    if (closeWindow) {
      canvas.drawRect(windowRect, paint);
    }

    canvas.drawRect(
        windowRect,
        Paint()
          ..color = innerFrameColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = innerFrameStrokeWidth);
  }

  @override
  bool shouldRepaint(WindowPainter oldDelegate) =>
      oldDelegate.closeWindow != closeWindow;
}

class Square {
  Square(this.width, this.color);

  final double width;
  final Color color;

  static Square lerp(Square begin, Square end, double t) {
    Color color;
    if (t > 0.75) {
      color = Color.lerp(begin.color, end.color, (t - .75) / .25);
    } else {
      color = begin.color;
    }

    return Square(lerpDouble(begin.width, end.width, t), color);
  }
}

class SquareTween extends Tween<Square> {
  SquareTween(Square begin, Square end) : super(begin: begin, end: end);

  @override
  Square lerp(double t) => Square.lerp(begin, end, t);
}

class SquareOutlinePainter extends CustomPainter {
  SquareOutlinePainter({
    @required this.animation,
    this.strokeWidth = 2,
  }) : super(repaint: animation);

  final Animation<Square> animation;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Square square = animation.value;

    final Paint paint = Paint()
      ..strokeWidth = strokeWidth
      ..color = square.color
      ..style = PaintingStyle.stroke;

    final Offset center = size.center(Offset.zero);
    final double halfWidth = square.width / 2;

    final Rect rect = Rect.fromLTRB(
      center.dx - halfWidth,
      center.dy - halfWidth,
      center.dx + halfWidth,
      center.dy + halfWidth,
    );

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(SquareOutlinePainter oldDelegate) => false;
}

class SquareTracePainter extends CustomPainter {
  SquareTracePainter({
    @required this.animation,
    @required this.square,
    this.strokeWidth = 3,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final Square square;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final double value = animation.value;

    final Offset center = size.center(Offset.zero);
    final double halfWidth = square.width / 2;

    final Rect rect = Rect.fromLTRB(
      center.dx - halfWidth,
      center.dy - halfWidth,
      center.dx + halfWidth,
      center.dy + halfWidth,
    );

    final Paint paint = Paint()
      ..strokeWidth = strokeWidth
      ..color = square.color;

    canvas.drawLine(
      rect.bottomRight,
      Offset(rect.right, rect.top + (square.width - value)),
      paint,
    );

    canvas.drawLine(
      rect.bottomRight,
      Offset(rect.left + (square.width - value), rect.bottom),
      paint,
    );

    canvas.drawLine(
      rect.topLeft,
      Offset(rect.left, rect.top + value),
      paint,
    );

    canvas.drawLine(
      rect.topLeft,
      Offset(rect.left + value, rect.top),
      paint,
    );
  }

  @override
  bool shouldRepaint(SquareTracePainter oldDelegate) => false;
}
