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
void canEmplaceHostBuffer() {
  final gpu.HostBuffer hostBuffer = gpu.HostBuffer();

  final gpu.BufferView view0 = hostBuffer
      .emplace(Int8List.fromList(<int>[0, 1, 2, 3]).buffer.asByteData());
  assert(view0.offsetInBytes == 0);
  assert(view0.lengthInBytes == 4);

  final gpu.BufferView view1 = hostBuffer
      .emplace(Int8List.fromList(<int>[0, 1, 2, 3]).buffer.asByteData());
  assert(view1.offsetInBytes >= 4);
  assert(view1.lengthInBytes == 4);
}

@pragma('vm:entry-point')
void canCreateDeviceBuffer() {
  final gpu.DeviceBuffer? deviceBuffer =
      gpu.gpuContext.createDeviceBuffer(gpu.StorageMode.hostVisible, 4);
  assert(deviceBuffer != null);
  assert(deviceBuffer!.sizeInBytes == 4);
}

@pragma('vm:entry-point')
void canOverwriteDeviceBuffer() {
  final gpu.DeviceBuffer? deviceBuffer =
      gpu.gpuContext.createDeviceBuffer(gpu.StorageMode.hostVisible, 4);
  assert(deviceBuffer != null);
  final bool success = deviceBuffer!
      .overwrite(Int8List.fromList(<int>[0, 1, 2, 3]).buffer.asByteData());
  assert(success);
}

@pragma('vm:entry-point')
void deviceBufferOverwriteFailsWhenOutOfBounds() {
  final gpu.DeviceBuffer? deviceBuffer =
      gpu.gpuContext.createDeviceBuffer(gpu.StorageMode.hostVisible, 4);
  assert(deviceBuffer != null);
  final bool success = deviceBuffer!.overwrite(
      Int8List.fromList(<int>[0, 1, 2, 3]).buffer.asByteData(),
      destinationOffsetInBytes: 1);
  assert(!success);
}

@pragma('vm:entry-point')
void deviceBufferOverwriteThrowsForNegativeDestinationOffset() {
  final gpu.DeviceBuffer? deviceBuffer =
      gpu.gpuContext.createDeviceBuffer(gpu.StorageMode.hostVisible, 4);
  assert(deviceBuffer != null);
  String? exception;
  try {
    deviceBuffer!.overwrite(
        Int8List.fromList(<int>[0, 1, 2, 3]).buffer.asByteData(),
        destinationOffsetInBytes: -1);
  } catch (e) {
    exception = e.toString();
  }
  assert(exception!.contains('destinationOffsetInBytes must be positive'));
}

@pragma('vm:entry-point')
void canCreateTexture() {
  final gpu.Texture? texture =
      gpu.gpuContext.createTexture(gpu.StorageMode.hostVisible, 100, 100);
  assert(texture != null);

  // Check the defaults.
  assert(
      texture!.coordinateSystem == gpu.TextureCoordinateSystem.renderToTexture);
  assert(texture!.width == 100);
  assert(texture!.height == 100);
  assert(texture!.storageMode == gpu.StorageMode.hostVisible);
  assert(texture!.sampleCount == 1);
  assert(texture!.format == gpu.PixelFormat.r8g8b8a8UNormInt);
  assert(texture!.enableRenderTargetUsage);
  assert(texture!.enableShaderReadUsage);
  assert(!texture!.enableShaderWriteUsage);
  assert(texture!.bytesPerTexel == 4);
  assert(texture!.GetBaseMipLevelSizeInBytes() == 40000);
}

@pragma('vm:entry-point')
void canOverwriteTexture() {
  final gpu.Texture? texture =
      gpu.gpuContext.createTexture(gpu.StorageMode.hostVisible, 2, 2);
  assert(texture != null);
  final ui.Color red = ui.Color.fromARGB(0xFF, 0xFF, 0, 0);
  final ui.Color green = ui.Color.fromARGB(0xFF, 0, 0xFF, 0);
  final bool success = texture!.overwrite(
      Int32List.fromList(<int>[red.value, green.value, green.value, red.value])
          .buffer
          .asByteData());
  assert(success);
}

@pragma('vm:entry-point')
void textureOverwriteThrowsForWrongBufferSize() {
  final gpu.Texture? texture =
      gpu.gpuContext.createTexture(gpu.StorageMode.hostVisible, 100, 100);
  assert(texture != null);
  final ui.Color red = ui.Color.fromARGB(0xFF, 0xFF, 0, 0);
  String? exception;
  try {
    texture!.overwrite(
        Int32List.fromList(<int>[red.value, red.value, red.value, red.value])
            .buffer
            .asByteData());
  } catch (e) {
    exception = e.toString();
  }
  assert(exception!.contains(
      'The length of sourceBytes (bytes: 16) must exactly match the size of the base mip level (bytes: 40000)'));
}

@pragma('vm:entry-point')
void textureAsImageReturnsAValidUIImageHandle() {
  final gpu.Texture? texture =
      gpu.gpuContext.createTexture(gpu.StorageMode.hostVisible, 100, 100);
  assert(texture != null);

  final ui.Image image = texture!.asImage();
  assert(image.width == 100);
  assert(image.height == 100);
}

@pragma('vm:entry-point')
void textureAsImageThrowsWhenNotShaderReadable() {
  final gpu.Texture? texture = gpu.gpuContext.createTexture(
      gpu.StorageMode.hostVisible, 100, 100,
      enableShaderReadUsage: false);
  assert(texture != null);
  String? exception;
  try {
    texture!.asImage();
  } catch (e) {
    exception = e.toString();
  }
  assert(exception!.contains(
      'Only shader readable Flutter GPU textures can be used as UI Images'));
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

  final gpu.HostBuffer transients = gpu.HostBuffer();
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
