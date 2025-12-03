// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:android_driver_extensions/extension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

import '../src/allow_list_devices.dart';

// Enum to represent the different clipper types that can be toggled in this
// test app. See their definitions below.
enum ClipperType { triangle, cubicWave, overlappingNonZero, overlappingEvenOdd }

void main() async {
  ensureAndroidDevice();
  enableFlutterDriverExtension(
    handler: (String? command) async {
      return json.encode(<String, Object?>{
        'supported': await HybridAndroidViewController.checkIfSupported(),
      });
    },
    commands: <CommandExtension>[nativeDriverCommands],
  );

  // Run on full screen.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(const ClipperToggleApp());
}

class ClipperToggleApp extends StatelessWidget {
  const ClipperToggleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(elevatedButtonTheme: const ElevatedButtonThemeData()),
      home: const ClipperHomePage(),
    );
  }
}

class ClipperHomePage extends StatefulWidget {
  const ClipperHomePage({super.key});

  @override
  State<ClipperHomePage> createState() => _ClipperHomePageState();
}

class _ClipperHomePageState extends State<ClipperHomePage> {
  // State map to track which clippers are active
  // Initialize all clippers to off (false)
  final Map<ClipperType, bool> _clipperStates = <ClipperType, bool>{
    for (ClipperType type in ClipperType.values) type: false,
  };

  // Instantiate clippers (keep these readily available)
  final Map<ClipperType, CustomClipper<Path>> _clippers = <ClipperType, CustomClipper<Path>>{
    ClipperType.triangle: TriangleClipper(),
    ClipperType.cubicWave: CubicWaveClipper(),
    ClipperType.overlappingNonZero: OverlappingRectClipper(fillType: PathFillType.nonZero),
    ClipperType.overlappingEvenOdd: OverlappingRectClipper(fillType: PathFillType.evenOdd),
  };

  // Define the order in which clippers will be nested (outermost to innermost)
  // The build logic will apply them in this sequence.
  final List<ClipperType> _clipperNestingOrder = <ClipperType>[
    ClipperType.triangle,
    ClipperType.cubicWave,
    ClipperType.overlappingNonZero,
    ClipperType.overlappingEvenOdd,
  ];

  // Method to toggle the state of a specific clipper
  void _toggleClipper(ClipperType type) {
    setState(() {
      _clipperStates[type] = !(_clipperStates[type] ?? false);
    });
  }

  // Helper function to build the potentially nested ClipPath structure
  Widget _buildClippedContent(Widget child) {
    var currentChild = child;
    // Iterate through the defined nesting order
    for (final ClipperType clipperType in _clipperNestingOrder) {
      // If the clipper is active in the state map, wrap the current widget
      if (_clipperStates[clipperType] ?? false) {
        currentChild = ClipPath(
          clipper: _clippers[clipperType], // Get the clipper instance
          child: currentChild, // Wrap the previously built widget
        );
      }
    }
    return currentChild; // Return the final potentially nested structure
  }

  @override
  Widget build(BuildContext context) {
    // Content that will be clipped
    const Widget contentToClip = ClipOval(
      // Inner ClipOval remains
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Background
          SizedBox(width: 500, height: 500, child: ColoredBox(color: Colors.green)),
          SizedBox(
            width: 400,
            height: 400,
            child: _HybridCompositionAndroidPlatformView(
              viewType: 'changing_color_button_platform_view',
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: Column(
        children: <Widget>[
          // Row of buttons to toggle each clipper
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              alignment: WrapAlignment.center,
              children: ClipperType.values.map((ClipperType type) {
                return ElevatedButton(
                  key: ValueKey<String>('clipper_button_${type.name}'), // Use enum name in key
                  onPressed: () => _toggleClipper(type),
                  child: Text(type.name), // Display clipper name on button
                );
              }).toList(),
            ),
          ),
          // Expanded takes remaining space for the clipped content
          Expanded(
            // Dynamically build the clipped structure
            child: _buildClippedContent(contentToClip),
          ),
        ],
      ),
    );
  }
}

// Clips to show the top half of the screen, with a cubic wave as the dividing
// line.
class CubicWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Closer to 1 moves the wave lower, closer to 0 moves it higher.
    final double waveHeight = size.height * 0.65;

    path.lineTo(0, waveHeight);

    path.cubicTo(
      size.width * 0.25,
      waveHeight * 0.8,
      size.width * 0.75,
      waveHeight * 1.2,
      size.width,
      waveHeight,
    );

    path.lineTo(size.width, 0);
    path.lineTo(0, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

// Clips a triangle off the top left of the screen.
class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, 0);
    path.lineTo(0, size.height / 2);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

// Clips based on two overlapping rectangles.
class OverlappingRectClipper extends CustomClipper<Path> {
  OverlappingRectClipper({required this.fillType});
  final PathFillType fillType;

  @override
  Path getClip(Size size) {
    // Note: Path coordinates are relative to the widget being clipped.
    final path = Path();

    // Define the two rectangles relative to the widget's size
    final double rectWidth = size.width * 0.4;
    final double rectHeight = size.height * 0.4;
    final double offsetX1 = size.width * 0.1;
    final double offsetY1 = size.height * 0.1;
    final double offsetX2 = size.width * 0.25;
    final double offsetY2 = size.height * 0.25;

    final rect1 = Rect.fromLTWH(offsetX1, offsetY1, rectWidth, rectHeight);
    final rect2 = Rect.fromLTWH(offsetX2, offsetY2, rectWidth, rectHeight); // Overlaps rect1

    // Add the rectangles to the path
    path.addRect(rect1);
    path.addRect(rect2);

    path.fillType = fillType;

    return path;
  }

  @override
  bool shouldReclip(covariant OverlappingRectClipper oldClipper) {
    // Reclip only if the fillType changes.
    return oldClipper.fillType != fillType;
  }
}

// --- Platform View Definition ---
final class _HybridCompositionAndroidPlatformView extends StatelessWidget {
  const _HybridCompositionAndroidPlatformView({required this.viewType});

  final String viewType;

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      viewType: viewType,
      surfaceFactory: (BuildContext context, PlatformViewController controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
        );
      },
      onCreatePlatformView: (PlatformViewCreationParams params) {
        // Use initHybridAndroidView for Hybrid Composition
        return PlatformViewsService.initHybridAndroidView(
            id: params.id,
            viewType: viewType,
            layoutDirection: TextDirection.ltr,
            creationParamsCodec: const StandardMessageCodec(),
          )
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..create();
      },
    );
  }
}
