// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:android_driver_extensions/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

import '../src/allow_list_devices.dart';

const MethodChannel _channel = MethodChannel('smiley_face_texture');
Future<int> _fetchTexture(int width, int height) async {
  final int? result = await _channel.invokeMethod<int>('initTexture', <String, int>{
    'width': width,
    'height': height,
  });
  return result!;
}

void main() async {
  ensureAndroidDevice();
  enableFlutterDriverExtension(commands: <CommandExtension>[nativeDriverCommands]);

  // Run on full screen.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  runApp(const MainApp());
}

final class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int? _secondTextureId;

  Future<void> _showSecondTexture() async {
    final int id = await _fetchTexture(512, 512);
    if (mounted) {
      setState(() {
        _secondTextureId = id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: <Widget>[
            const Expanded(child: AndroidView(viewType: 'box_platform_view')),
            Expanded(
              child: GestureDetector(
                key: const ValueKey<String>('ShowSecondTexture'),
                behavior: HitTestBehavior.opaque,
                onTap: _showSecondTexture,
                child: _secondTextureId != null
                    ? Texture(
                        key: const ValueKey<String>('SecondTexture'),
                        textureId: _secondTextureId!,
                      )
                    : const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
