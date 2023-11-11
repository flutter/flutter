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
