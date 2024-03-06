// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_relative_lib_imports

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:litetest/litetest.dart';

import '../../lib/gpu/lib/gpu.dart' as gpu;
import 'impeller_enabled.dart';

void main() {
  // TODO(131346): Remove this once we migrate the Dart GPU API into this space.
  test('smoketest', () async {
    final int result = gpu.testProc();
    expect(result, 1);

    final String? message = gpu.testProcWithCallback((int result) {
      expect(result, 1234);
    });
    expect(message, null);

    final gpu.FlutterGpuTestClass a = gpu.FlutterGpuTestClass();
    a.coolMethod(9847);
  });

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
    expect(success, true);
  }, skip: !impellerEnabled);

  test('DeviceBuffer.overwrite fails when out of bounds', () async {
    final gpu.DeviceBuffer? deviceBuffer =
        gpu.gpuContext.createDeviceBuffer(gpu.StorageMode.hostVisible, 4);
    assert(deviceBuffer != null);

    final bool success = deviceBuffer!.overwrite(
        Int8List.fromList(<int>[0, 1, 2, 3]).buffer.asByteData(),
        destinationOffsetInBytes: 1);
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
}
