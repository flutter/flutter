// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:android_driver_extensions/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:vector_math/vector_math.dart' as vm;

import 'src/allow_list_devices.dart';

void main() {
  ensureAndroidDevice();
  enableFlutterDriverExtension(commands: <CommandExtension>[nativeDriverCommands]);

  // Run on full screen.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  runApp(const MainApp());
}

Float32List float32(List<double> values) {
  return Float32List.fromList(values);
}

Float32List unlitUBO(Matrix4 mvp, vm.Vector4 color) {
  return float32(<double>[
    mvp[0], mvp[1], mvp[2], mvp[3], //
    mvp[4], mvp[5], mvp[6], mvp[7], //
    mvp[8], mvp[9], mvp[10], mvp[11], //
    mvp[12], mvp[13], mvp[14], mvp[15], //
    color.r, color.g, color.b, color.a,
  ]);
}

gpu.RenderPipeline createUnlitRenderPipeline() {
  final gpu.ShaderLibrary? library = gpu.ShaderLibrary.fromAsset('test.shaderbundle');
  assert(library != null);
  final gpu.Shader? vertex = library!['UnlitVertex'];
  assert(vertex != null);
  final gpu.Shader? fragment = library['UnlitFragment'];
  assert(fragment != null);
  return gpu.gpuContext.createRenderPipeline(vertex!, fragment!);
}

class RenderPassState {
  RenderPassState(this.renderTexture, this.commandBuffer, this.renderPass);

  final gpu.Texture renderTexture;
  final gpu.CommandBuffer commandBuffer;
  final gpu.RenderPass renderPass;
}

/// Create a simple RenderPass with simple color and depth-stencil attachments.
RenderPassState createSimpleRenderPass({
  int width = 100,
  int height = 100,
  vm.Vector4? clearColor,
}) {
  final gpu.Texture renderTexture = gpu.gpuContext.createTexture(
    gpu.StorageMode.devicePrivate,
    width,
    height,
  );

  final gpu.Texture depthStencilTexture = gpu.gpuContext.createTexture(
    gpu.StorageMode.deviceTransient,
    width,
    height,
    format: gpu.gpuContext.defaultDepthStencilFormat,
  );

  final gpu.CommandBuffer commandBuffer = gpu.gpuContext.createCommandBuffer();

  final gpu.RenderTarget renderTarget = gpu.RenderTarget.singleColor(
    gpu.ColorAttachment(texture: renderTexture, clearValue: clearColor),
    depthStencilAttachment: gpu.DepthStencilAttachment(texture: depthStencilTexture),
  );

  final gpu.RenderPass renderPass = commandBuffer.createRenderPass(renderTarget);

  return RenderPassState(renderTexture, commandBuffer, renderPass);
}

void drawTriangle(RenderPassState state, vm.Vector4 color) {
  final gpu.RenderPipeline pipeline = createUnlitRenderPipeline();

  state.renderPass.bindPipeline(pipeline);

  final gpu.HostBuffer transients = gpu.gpuContext.createHostBuffer();
  final Float32List vertexData = float32(<double>[
    -0.5, 0.5, //
    0.0, -0.5, //
    0.5, 0.5, //
  ]);
  final gpu.BufferView vertices = transients.emplace(ByteData.sublistView(vertexData));

  final Float32List uniformData = unlitUBO(Matrix4.identity(), color);
  final gpu.BufferView vertInfoData = transients.emplace(ByteData.sublistView(uniformData));
  state.renderPass.bindVertexBuffer(vertices, 3);

  final gpu.UniformSlot vertInfo = pipeline.vertexShader.getUniformSlot('VertInfo');
  state.renderPass.bindUniform(vertInfo, vertInfoData);

  state.renderPass.draw();
}

final class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 100, height: 100, child: CustomPaint(painter: _ScenePainter()));
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final RenderPassState state = createSimpleRenderPass(width: 100, height: 100);
    drawTriangle(state, vm.Colors.lime);
    state.commandBuffer.submit();

    final ui.Image image = state.renderTexture.asImage();
    canvas.drawImage(image, Offset.zero, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
