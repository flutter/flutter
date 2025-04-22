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

import '../src/allow_list_devices.dart'; // Assuming this path is correct

// Enum to represent the different clipper types
enum ClipperType {
  none,
  triangle,
  cubicWave,
  overlappingNonZero,
  overlappingEvenOdd,
}

void main() async {
  // Ensure WidgetsFlutterBinding is initialized if ensureAndroidDevice requires it
  // WidgetsFlutterBinding.ensureInitialized();
  ensureAndroidDevice(); // Make sure this doesn't require Widgets binding first

  enableFlutterDriverExtension(
    handler: (String? command) async {
      // Example handler: Check if HybridComposition is supported
      // Adapt this handler based on actual test needs
      bool supported = false;
      try {
        supported = await HybridAndroidViewController.checkIfSupported();
      } catch (e) {
        // Handle potential errors if checkIfSupported isn't available or fails
        debugPrint('Error checking HybridAndroidViewController support: $e');
      }
      return json.encode(<String, Object?>{
        'supported': supported,
        // Add other relevant info for your tests if needed
      });
    },
    // Keep nativeDriverCommands if they are still needed
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
    return const MaterialApp(
      home: ClipperHomePage(),
    );
  }
}

class ClipperHomePage extends StatefulWidget {
  const ClipperHomePage({super.key});

  @override
  State<ClipperHomePage> createState() => _ClipperHomePageState();
}

class _ClipperHomePageState extends State<ClipperHomePage> {
  // Currently selected clipper type
  ClipperType _activeClipperType = ClipperType.none; // Start with no clipper

  // Instantiate clippers (consider making them const if possible)
  final CustomClipper<Path> _triangleClipper = TriangleClipper();
  final CustomClipper<Path> _cubicWaveClipper = CubicWaveClipper();
  final CustomClipper<Path> _overlappingNonZeroClipper =
  OverlappingRectClipper(fillType: PathFillType.nonZero);
  final CustomClipper<Path> _overlappingEvenOddClipper =
  OverlappingRectClipper(fillType: PathFillType.evenOdd);

  // Method to change the active clipper
  void _setActiveClipper(ClipperType type) {
    setState(() {
      _activeClipperType = type;
    });
  }

  // Helper to get the clipper instance based on the active type
  CustomClipper<Path>? _getClipper() {
    switch (_activeClipperType) {
      case ClipperType.none:
        return null;
      case ClipperType.triangle:
        return _triangleClipper;
      case ClipperType.cubicWave:
        return _cubicWaveClipper;
      case ClipperType.overlappingNonZero:
        return _overlappingNonZeroClipper;
      case ClipperType.overlappingEvenOdd:
        return _overlappingEvenOddClipper;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Using a Scaffold for better structure, AppBar is optional
      // appBar: AppBar(title: const Text('Clipper Demo')),
      body: Column(
        children: <Widget>[
          // Row of buttons to select the clipper
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap( // Use Wrap for better responsiveness if buttons overflow
              spacing: 8.0, // Horizontal space between buttons
              runSpacing: 4.0, // Vertical space between lines of buttons
              alignment: WrapAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  // Key for test driver to find and tap this button
                  key: const ValueKey<String>('clipper_button_none'),
                  onPressed: () => _setActiveClipper(ClipperType.none),
                  child: const Text('None'),
                ),
                ElevatedButton(
                  key: const ValueKey<String>('clipper_button_triangle'),
                  onPressed: () => _setActiveClipper(ClipperType.triangle),
                  child: const Text('Triangle'),
                ),
                ElevatedButton(
                  key: const ValueKey<String>('clipper_button_cubic'),
                  onPressed: () => _setActiveClipper(ClipperType.cubicWave),
                  child: const Text('Cubic Wave'),
                ),
                ElevatedButton(
                  key: const ValueKey<String>('clipper_button_overlap_nonzero'),
                  onPressed: () => _setActiveClipper(ClipperType.overlappingNonZero),
                  child: const Text('Overlap NonZero'),
                ),
                ElevatedButton(
                  key: const ValueKey<String>('clipper_button_overlap_evenodd'),
                  onPressed: () => _setActiveClipper(ClipperType.overlappingEvenOdd),
                  child: const Text('Overlap EvenOdd'),
                ),
              ],
            ),
          ),
          // Expanded takes remaining space for the clipped content
          Expanded(
            child: ClipPath(
              clipper: _getClipper(), // Dynamically set the clipper
              child: const ClipOval( // Inner ClipOval remains as per original structure
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 500,
                      height: 500,
                      child: ColoredBox(color: Colors.green),
                    ),
                    SizedBox(
                      width: 400,
                      height: 400,
                      child: _HybridCompositionAndroidPlatformView(
                        // Make sure this viewType matches your native setup
                        viewType: 'changing_color_button_platform_view',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Clipper Definitions (TriangleClipper, CubicWaveClipper, OverlappingRectClipper) ---
// (Keep these classes exactly as provided in the original question)

// Clips to show the top half of the screen, with a cubic wave as the dividing
// line.
class CubicWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
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
    final Path path = Path();
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
  final PathFillType fillType;

  OverlappingRectClipper({required this.fillType});

  @override
  Path getClip(Size size) {
    // Note: Path coordinates are relative to the widget being clipped.
    final Path path = Path();

    // Define the two rectangles relative to the widget's size
    // Make them somewhat proportional to the size for better visibility
    final double rectWidth = size.width * 0.4;
    final double rectHeight = size.height * 0.4;
    final double offsetX1 = size.width * 0.1;
    final double offsetY1 = size.height * 0.1;
    final double offsetX2 = size.width * 0.25;
    final double offsetY2 = size.height * 0.25;


    Rect rect1 = Rect.fromLTWH(offsetX1, offsetY1, rectWidth, rectHeight);
    Rect rect2 = Rect.fromLTWH(offsetX2, offsetY2, rectWidth, rectHeight); // Overlaps rect1

    // Add the rectangles to the path
    path.addRect(rect1);
    path.addRect(rect2);

    path.fillType = fillType; // nonZero or evenOdd determines how overlap is handled

    // No need to close rect paths explicitly with addRect

    return path;
  }

  @override
  bool shouldReclip(covariant OverlappingRectClipper oldClipper) {
    // Reclip only if the fillType changes.
    return oldClipper.fillType != fillType;
  }
}


// --- Platform View Definition ---
// (Keep this class exactly as provided in the original question)

final class _HybridCompositionAndroidPlatformView extends StatelessWidget {
  const _HybridCompositionAndroidPlatformView({required this.viewType});

  final String viewType;

  @override
  Widget build(BuildContext context) {
    // Choose the appropriate Android view implementation based on availability
    // For testing purposes, often initHybridComposition is used.
    // Consider adding error handling or alternative implementations if needed.
    // if (AndroidViewController.supportsHybridComposition) {
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
    // } else {
    //   // Fallback or alternative implementation if Hybrid Composition is not supported
    //   // For example, using Virtual Display (though often less performant/compatible)
    //   // return AndroidView(
    //   //   viewType: viewType,
    //   //   layoutDirection: TextDirection.ltr,
    //   //   creationParamsCodec: const StandardMessageCodec(),
    //   // );
    //   // Or display an error/placeholder widget
    //    return const Center(child: Text('Hybrid Composition Not Supported'));
    // }
  }
}
