// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:ui';

import 'package:android_driver_extensions/extension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

import '../src/allow_list_devices.dart';

String errorText = '';

void main() async {
  enableFlutterDriverExtension(
    handler: (String? command) async {
      return json.encode(<String, Object?>{
        'supported': await HybridAndroidViewController.checkIfSupported(),
        'checkErrorText': errorText,
      });
    },
    commands: <CommandExtension>[nativeDriverCommands],
  );

  final ErrorCallback? originalPlatformOnError = PlatformDispatcher.instance.onError;

  // Set up a global error handler for unhandled platform messages
  // & other async errors.
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    final currentErrorString = error.toString();
    var handledByThisCallback = false;

    if (error is PlatformException) {
      if (currentErrorString.contains('HC++')) {
        errorText = currentErrorString;
        handledByThisCallback = true; // We've "handled" it by capturing for the test
      }
    }

    if (handledByThisCallback) {
      return true;
    }

    // Otherwise invoke the original handler, if it existed.
    if (originalPlatformOnError != null) {
      return originalPlatformOnError(error, stack);
    }
    return false;
  };

  ensureAndroidDevice();

  // Run on full screen.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(const MyApp());
}

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
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (PlatformViewCreationParams params) {
        return PlatformViewsService.initExpensiveAndroidView(
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

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Center(
        child: ElevatedButton(
          key: const ValueKey<String>('LoadHCPlatformView'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 18),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const PlatformViewDisplayPage(),
              ),
            );
          },
          child: const Text('Load Platform View'),
        ),
      ),
    );
  }
}

class PlatformViewDisplayPage extends StatelessWidget {
  const PlatformViewDisplayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Platform View')),
      body: const _HybridCompositionAndroidPlatformView(
        viewType: 'blue_orange_gradient_platform_view',
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Platform View Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white, // Clean background
        appBarTheme: const AppBarTheme(backgroundColor: Colors.blue, foregroundColor: Colors.white),
      ),
      home: const LandingPage(), // Start with the new landing page
    );
  }
}
