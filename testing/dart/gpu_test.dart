// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter GPU API tests.
// The flutter_gpu package is located at //flutter/impeller/lib/gpu.

// ignore_for_file: avoid_relative_lib_imports

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:test/test.dart';

import '../../lib/gpu/lib/gpu.dart' as gpu;

import 'goldens.dart';
import 'impeller_enabled.dart';

ByteData float32(List<double> values) {
  return Float32List.fromList(values).buffer.asByteData();
}

gpu.RenderPipeline createUnlitRenderPipeline() {
  final gpu.ShaderLibrary? library =
      gpu.ShaderLibrary.fromAsset('test.shaderbundle');
  assert(library != null);
  final gpu.Shader? vertex = library!['UnlitVertex'];
  assert(vertex != null);
  final gpu.Shader? fragment = library['UnlitFragment'];
  assert(fragment != null);
  return gpu.gpuContext.createRenderPipeline(vertex!, fragment!);
}

void main() async {
  final ImageComparer comparer = await ImageComparer.create();

  test('gpu.context throws exception for incompatible embedders', () async {
    try {
      // ignore: unnecessary_statements
      gpu.gpuContext; // Force the context to instantiate.
      if (!impellerEnabled) {
        fail('Exception not thrown, but no Impeller context available.');
      }
    } catch (e) {
      if (impellerEnabled) {
        fail('Exception thrown even though Impeller is enabled.');
      }
      expect(
          e.toString(),
          contains(
              'Flutter GPU requires the Impeller rendering backend to be enabled.'));
    }
  });

  test('GpuContext.minimumUniformByteAlignment', () async {
    final int alignment = gpu.gpuContext.minimumUniformByteAlignment;
    expect(alignment, greaterThanOrEqualTo(16));
  }, skip: !impellerEnabled);

  test('HostBuffer.emplace', () async {
    final gpu.HostBuffer hostBuffer = gpu.gpuContext.createHostBuffer();

    final gpu.BufferView view0 = hostBuffer
        .emplace(Int8List.fromList(<int>[0, 1, 2, 3]).buffer.asByteData());
    expect(view0.offsetInBytes, 0);
    expect(view0.lengthInBytes, 4);

    final gpu.BufferView view1 = hostBuffer
        .emplace(Int8List.fromList(<int>[0, 1, 2, 3]).buffer.asByteData());
    expect(view1.offsetInBytes >= 4, true);
    expect(view1.lengthInBytes, 4);
  }, skip: !impellerEnabled);

  test('GpuContext.createDeviceBuffer', () async {
    final gpu.DeviceBuffer? deviceBuffer =
        gpu.gpuContext.createDeviceBuffer(gpu.StorageMode.hostVisible, 4);
    assert(deviceBuffer != null);

    expect(deviceBuffer!.sizeInBytes, 4);
  }, skip: !impellerEnabled);

  test('DeviceBuffer.overwrite', () async {
    final gpu.DeviceBuffer? deviceBuffer =
        gpu.gpuContext.createDeviceBuffer(gpu.StorageMode.hostVisible, 4);
    assert(deviceBuffer != null);

    final bool success = deviceBuffer!
        .overwrite(Int8List.fromList(<int>[0, 1, 2, 3]).buffer.asByteData());
    deviceBuffer.flush();
    expect(success, true);
  }, skip: !impellerEnabled);

  test('DeviceBuffer.overwrite fails when out of bounds', () async {
    final gpu.DeviceBuffer? deviceBuffer =
        gpu.gpuContext.createDeviceBuffer(gpu.StorageMode.hostVisible, 4);
    assert(deviceBuffer != null);

    final bool success = deviceBuffer!.overwrite(
        Int8List.fromList(<int>[0, 1, 2, 3]).buffer.asByteData(),
        destinationOffsetInBytes: 1);
    deviceBuffer.flush();
    expect(success, false);
  }, skip: !impellerEnabled);

  test('DeviceBuffer.overwrite throws for negative destination offset',
      () async {
    final gpu.DeviceBuffer? deviceBuffer =
        gpu.gpuContext.createDeviceBuffer(gpu.StorageMode.hostVisible, 4);
    assert(deviceBuffer != null);

    try {
      deviceBuffer!.overwrite(
          Int8List.fromList(<int>[0, 1, 2, 3]).buffer.asByteData(),
          destinationOffsetInBytes: -1);
      deviceBuffer.flush();
      fail('Exception not thrown for negative destination offset.');
    } catch (e) {
      expect(
          e.toString(), contains('destinationOffsetInBytes must be positive'));
    }
  }, skip: !impellerEnabled);

  test('GpuContext.createTexture', () async {
    final gpu.Texture? texture =
        gpu.gpuContext.createTexture(gpu.StorageMode.hostVisible, 100, 100);
    assert(texture != null);

    // Check the defaults.
    expect(
        texture!.coordinateSystem, gpu.TextureCoordinateSystem.renderToTexture);
    expect(texture.width, 100);
    expect(texture.height, 100);
    expect(texture.storageMode, gpu.StorageMode.hostVisible);
    expect(texture.sampleCount, 1);
    expect(texture.format, gpu.PixelFormat.r8g8b8a8UNormInt);
    expect(texture.enableRenderTargetUsage, true);
    expect(texture.enableShaderReadUsage, true);
    expect(!texture.enableShaderWriteUsage, true);
    expect(texture.bytesPerTexel, 4);
    expect(texture.GetBaseMipLevelSizeInBytes(), 40000);
  }, skip: !impellerEnabled);

  test('Texture.overwrite', () async {
    final gpu.Texture? texture =
        gpu.gpuContext.createTexture(gpu.StorageMode.hostVisible, 2, 2);
    assert(texture != null);

    const ui.Color red = ui.Color.fromARGB(0xFF, 0xFF, 0, 0);
    const ui.Color green = ui.Color.fromARGB(0xFF, 0, 0xFF, 0);
    final bool success = texture!.overwrite(Int32List.fromList(
            <int>[red.value, green.value, green.value, red.value])
        .buffer
        .asByteData());

    expect(success, true);
  }, skip: !impellerEnabled);

  test('Texture.overwrite throws for wrong buffer size', () async {
    final gpu.Texture? texture =
        gpu.gpuContext.createTexture(gpu.StorageMode.hostVisible, 100, 100);
    assert(texture != null);

    const ui.Color red = ui.Color.fromARGB(0xFF, 0xFF, 0, 0);
    try {
      texture!.overwrite(
          Int32List.fromList(<int>[red.value, red.value, red.value, red.value])
              .buffer
              .asByteData());
      fail('Exception not thrown for wrong buffer size.');
    } catch (e) {
      expect(
          e.toString(),
          contains(
              'The length of sourceBytes (bytes: 16) must exactly match the size of the base mip level (bytes: 40000)'));
    }
  }, skip: !impellerEnabled);

  test('Texture.asImage returns a valid ui.Image handle', () async {
    final gpu.Texture? texture =
        gpu.gpuContext.createTexture(gpu.StorageMode.hostVisible, 100, 100);
    assert(texture != null);

    final ui.Image image = texture!.asImage();
    expect(image.width, 100);
    expect(image.height, 100);
  }, skip: !impellerEnabled);

  test('Texture.asImage throws when not shader readable', () async {
    final gpu.Texture? texture = gpu.gpuContext.createTexture(
        gpu.StorageMode.hostVisible, 100, 100,
        enableShaderReadUsage: false);
    assert(texture != null);

    try {
      texture!.asImage();
      fail('Exception not thrown when not shader readable.');
    } catch (e) {
      expect(
          e.toString(),
          contains(
              'Only shader readable Flutter GPU textures can be used as UI Images'));
    }
  }, skip: !impellerEnabled);

  test('Can render triangle', () async {
    final gpu.Texture? renderTexture =
        gpu.gpuContext.createTexture(gpu.StorageMode.devicePrivate, 100, 100);
    assert(renderTexture != null);

    final gpu.CommandBuffer commandBuffer =
        gpu.gpuContext.createCommandBuffer();

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
      -0.5, 0.5, //
      0.0, -0.5, //
      0.5, 0.5, //
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

    final ui.Image image = renderTexture.asImage();
    await comparer.addGoldenImage(image, 'flutter_gpu_test_triangle.png');
  }, skip: !impellerEnabled);
}
