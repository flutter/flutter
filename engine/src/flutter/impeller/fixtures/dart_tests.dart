// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui;
import '../../lib/gpu/lib/gpu.dart' as gpu;

void main() {}

@pragma('vm:entry-point')
void sayHi() {
  print('Hi');
}

@pragma('vm:entry-point')
void instantiateDefaultContext() {
  // ignore: unused_local_variable
  final gpu.GpuContext context = gpu.gpuContext;
}

@pragma('vm:entry-point')
void canCreateShaderLibrary() {
  final gpu.ShaderLibrary? library = gpu.ShaderLibrary.fromAsset('playground');
  assert(library != null);
  final gpu.Shader? shader = library!['UnlitVertex'];
  assert(shader != null);
}

@pragma('vm:entry-point')
void canReflectUniformStructs() {
  final gpu.RenderPipeline pipeline = createUnlitRenderPipeline();

  final gpu.UniformSlot vertInfo =
      pipeline.vertexShader.getUniformSlot('VertInfo');
  assert(vertInfo.uniformName == 'VertInfo');
  final int? totalSize = vertInfo.sizeInBytes;
  assert(totalSize != null);
  assert(totalSize! == 128);
  final int? mvpOffset = vertInfo.getMemberOffsetInBytes('mvp');
  assert(mvpOffset != null);
  assert(mvpOffset! == 0);
  final int? colorOffset = vertInfo.getMemberOffsetInBytes('color');
  assert(colorOffset != null);
  assert(colorOffset! == 64);
}

gpu.RenderPipeline createUnlitRenderPipeline() {
  final gpu.ShaderLibrary? library = gpu.ShaderLibrary.fromAsset('playground');
  assert(library != null);
  final gpu.Shader? vertex = library!['UnlitVertex'];
  assert(vertex != null);
  final gpu.Shader? fragment = library['UnlitFragment'];
  assert(fragment != null);
  return gpu.gpuContext.createRenderPipeline(vertex!, fragment!);
}

gpu.RenderPass createRenderPass() {
  final gpu.Texture? renderTexture =
      gpu.gpuContext.createTexture(gpu.StorageMode.devicePrivate, 100, 100);
  assert(renderTexture != null);

  final gpu.CommandBuffer commandBuffer = gpu.gpuContext.createCommandBuffer();

  final gpu.RenderTarget renderTarget = gpu.RenderTarget.singleColor(
    gpu.ColorAttachment(texture: renderTexture!),
  );
  return commandBuffer.createRenderPass(renderTarget);
}

@pragma('vm:entry-point')
void uniformBindFailsForInvalidHostBufferOffset() {
  final gpu.RenderPass encoder = createRenderPass();

  final gpu.RenderPipeline pipeline = createUnlitRenderPipeline();
  encoder.bindPipeline(pipeline);

  final gpu.HostBuffer transients = gpu.gpuContext.createHostBuffer();
  final gpu.BufferView vertInfoData = transients.emplace(float32(<double>[
    1, 0, 0, 0, // mvp
    0, 1, 0, 0, // mvp
    0, 0, 1, 0, // mvp
    0, 0, 0, 1, // mvp
    0, 1, 0, 1, // color
  ]));
  final gpu.BufferView viewWithBadOffset = gpu.BufferView(vertInfoData.buffer,
      offsetInBytes: 1, lengthInBytes: vertInfoData.lengthInBytes);

  final gpu.UniformSlot vertInfo =
      pipeline.vertexShader.getUniformSlot('VertInfo');
  String? exception;
  try {
    encoder.bindUniform(vertInfo, viewWithBadOffset);
  } catch (e) {
    exception = e.toString();
  }
  assert(exception!.contains('Failed to bind uniform'));
}

ByteData float32(List<double> values) {
  return Float32List.fromList(values).buffer.asByteData();
}

@pragma('vm:entry-point')
void canCreateRenderPassAndSubmit() {
  final gpu.Texture? renderTexture =
      gpu.gpuContext.createTexture(gpu.StorageMode.devicePrivate, 100, 100);
  assert(renderTexture != null);

  final gpu.CommandBuffer commandBuffer = gpu.gpuContext.createCommandBuffer();

  final gpu.RenderTarget renderTarget = gpu.RenderTarget.singleColor(
    gpu.ColorAttachment(texture: renderTexture!),
  );
  final gpu.RenderPass encoder = commandBuffer.createRenderPass(renderTarget);

  final gpu.RenderPipeline pipeline = createUnlitRenderPipeline();
  encoder.bindPipeline(pipeline);

  // Configure blending with defaults (just to test the bindings).
  encoder.setColorBlendEnable(true);
  encoder.setColorBlendEquation(gpu.ColorBlendEquation());

  final gpu.HostBuffer transients = gpu.gpuContext.createHostBuffer();
  final gpu.BufferView vertices = transients.emplace(float32(<double>[
    -0.5, -0.5, //
    0.5, 0.5, //
    0.5, -0.5, //
  ]));
  final gpu.BufferView vertInfoData = transients.emplace(float32(<double>[
    1, 0, 0, 0, // mvp
    0, 1, 0, 0, // mvp
    0, 0, 1, 0, // mvp
    0, 0, 0, 1, // mvp
    0, 1, 0, 1, // color
  ]));
  encoder.bindVertexBuffer(vertices, 3);

  final gpu.UniformSlot vertInfo =
      pipeline.vertexShader.getUniformSlot('VertInfo');
  encoder.bindUniform(vertInfo, vertInfoData);
  encoder.draw();

  commandBuffer.submit();
}
