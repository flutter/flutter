// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Flutter code sample for [AppBar.systemOverlayStyle].

void main() => runApp(const SystemOverlayStyleApp());

class SystemOverlayStyleApp extends StatelessWidget {
  const SystemOverlayStyleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
      home: const SystemOverlayStyleExample(),
    );
  }
}

class SystemOverlayStyleExample extends StatefulWidget {
  const SystemOverlayStyleExample({super.key});

  @override
  State<SystemOverlayStyleExample> createState() => _SystemOverlayStyleExampleState();
}

class _SystemOverlayStyleExampleState extends State<SystemOverlayStyleExample> {
  final math.Random _random = math.Random();
  SystemUiOverlayStyle _currentStyle = SystemUiOverlayStyle.light;

  void _changeColor() {
    final Color color = Color.fromRGBO(
      _random.nextInt(255),
      _random.nextInt(255),
      _random.nextInt(255),
      1.0,
    );
    setState(() {
      _currentStyle = SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: color,
        systemNavigationBarColor: color,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SystemUiOverlayStyle Sample'),
        systemOverlayStyle: _currentStyle,
      ),
      body: Center(
        child: ElevatedButton(onPressed: _changeColor, child: const Text('Change Color')),
      ),
    );
  }
}
