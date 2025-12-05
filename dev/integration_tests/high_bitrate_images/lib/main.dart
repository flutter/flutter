// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'cpu_sdf_canvas.dart';
import 'gpu_sdf_canvas.dart';

enum TestType { cpuR32fSdf, cpuRgba32fSdf, gpuR32fSdf, gpuRgba32fSdf }

TestType testToRun = TestType.cpuR32fSdf;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'SDF Demo', theme: ThemeData.dark(), home: const MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    Widget child;
    switch (testToRun) {
      case TestType.cpuR32fSdf:
        child = const CpuSdfCanvas(targetFormat: ui.TargetPixelFormat.rFloat32);
      case TestType.cpuRgba32fSdf:
        child = const CpuSdfCanvas(targetFormat: ui.TargetPixelFormat.rgbaFloat32);
      case TestType.gpuR32fSdf:
        child = const GpuSdfCanvas(targetFormat: ui.TargetPixelFormat.rFloat32);
      case TestType.gpuRgba32fSdf:
        child = const GpuSdfCanvas(targetFormat: ui.TargetPixelFormat.rgbaFloat32);
    }
    return Scaffold(body: child);
  }
}
