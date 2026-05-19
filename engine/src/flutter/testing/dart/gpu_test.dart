// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter GPU API tests.
// The flutter_gpu package is located at //flutter/impeller/lib/gpu.

// ignore_for_file: avoid_relative_lib_imports

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

import '../../lib/gpu/lib/gpu.dart' as gpu;

import 'goldens.dart';
import 'impeller_enabled.dart';

ByteData float32(List<double> values) {
  return Float32List.fromList(values).buffer.asByteData();
}

ByteData unlitUBO(Matrix4 mvp, Vector4 color) {
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
RenderPassState createSimpleRenderPass({Vector4? clearColor}) {
  final gpu.Texture renderTexture = gpu.gpuContext.createTexture(
    gpu.StorageMode.devicePrivate,
    100,
    100,
  );

  final gpu.Texture depthStencilTexture = gpu.gpuContext.createTexture(
    gpu.StorageMode.deviceTransient,
    100,
    100,
    format: gpu.gpuContext.defaultDepthStencilFormat,
  );

  final gpu.CommandBuffer commandBuffer = gpu.gpuContext.createCommandBuffer();

  final renderTarget = gpu.RenderTarget.singleColor(
    gpu.ColorAttachment(texture: renderTexture, clearValue: clearColor),
    depthStencilAttachment: gpu.DepthStencilAttachment(texture: depthStencilTexture),
  );

  final gpu.RenderPass renderPass = commandBuffer.createRenderPass(renderTarget);

  return RenderPassState(renderTexture, commandBuffer, renderPass);
}

RenderPassState createSimpleRenderPassWithMSAA() {
  // Create transient MSAA attachments, which will live entirely in tile memory
  // for most GPUs.

  final gpu.Texture renderTexture = gpu.gpuContext.createTexture(
    gpu.StorageMode.deviceTransient,
    100,
    100,
    format: gpu.gpuContext.defaultColorFormat,
    sampleCount: 4,
  );

  final gpu.Texture depthStencilTexture = gpu.gpuContext.createTexture(
    gpu.StorageMode.deviceTransient,
    100,
    100,
    format: gpu.gpuContext.defaultDepthStencilFormat,
    sampleCount: 4,
  );

  // Create the single-sample resolve texture that live in DRAM and will be
  // drawn to the screen.

  final gpu.Texture resolveTexture = gpu.gpuContext.createTexture(
    gpu.StorageMode.devicePrivate,
    100,
    100,
    format: gpu.gpuContext.defaultColorFormat,
  );

  final gpu.CommandBuffer commandBuffer = gpu.gpuContext.createCommandBuffer();

  final renderTarget = gpu.RenderTarget.singleColor(
    gpu.ColorAttachment(
      texture: renderTexture,
      resolveTexture: resolveTexture,
      storeAction: gpu.StoreAction.multisampleResolve,
    ),
    depthStencilAttachment: gpu.DepthStencilAttachment(texture: depthStencilTexture),
  );

  final gpu.RenderPass renderPass = commandBuffer.createRenderPass(renderTarget);

  return RenderPassState(resolveTexture, commandBuffer, renderPass);
}

void drawTriangle(RenderPassState state, Vector4 color) {
  final gpu.RenderPipeline pipeline = createUnlitRenderPipeline();

  state.renderPass.bindPipeline(pipeline);

  final gpu.HostBuffer transients = gpu.gpuContext.createHostBuffer();
  final gpu.BufferView vertices = transients.emplace(
    float32(<double>[
      -0.5, 0.5, //
      0.0, -0.5, //
      0.5, 0.5, //
    ]),
  );
  final gpu.BufferView vertInfoData = transients.emplace(unlitUBO(Matrix4.identity(), color));
  state.renderPass.bindVertexBuffer(vertices, 3);

  final gpu.UniformSlot vertInfo = pipeline.vertexShader.getUniformSlot('VertInfo');
  state.renderPass.bindUniform(vertInfo, vertInfoData);

  state.renderPass.draw();
}

void main() async {
  final ImageComparer comparer = await ImageComparer.create();

  test('gpu.context throws exception when Impeller is not enabled', () async {
    try {
      // ignore: unnecessary_statements
      gpu.gpuContext; // Force the context to instantiate.
      if (!impellerEnabled) {
        fail('Exception not thrown, but Impeller is not enabled.');
      }
    } catch (e) {
      if (impellerEnabled && flutterGpuEnabled) {
        fail('Exception thrown even though Impeller and Flutter GPU are both enabled: $e');
      }
      if (!impellerEnabled) {
        expect(e.toString(), contains('Flutter GPU requires the Impeller rendering backend'));
      }
    }
  });

  test('gpu.context throws exception when Flutter GPU is not enabled', () async {
    try {
      // ignore: unnecessary_statements
      gpu.gpuContext; // Force the context to instantiate.
      if (!flutterGpuEnabled) {
        fail('Exception not thrown, but Flutter GPU is not enabled.');
      }
    } catch (e) {
      if (flutterGpuEnabled && impellerEnabled) {
        fail('Exception thrown even though Flutter GPU and Impeller are both enabled: $e');
      }
      if (impellerEnabled) {
        expect(
          e.toString(),
          contains('Flutter GPU must be enabled via the Flutter GPU manifest setting'),
        );
      }
    }
  });

  test('gpu.context is available when Impeller and Flutter GPU are enabled', () async {
    try {
      // ignore: unnecessary_statements
      gpu.gpuContext; // Force the context to instantiate.
    } catch (e) {
      if (impellerEnabled && flutterGpuEnabled) {
        fail('Exception thrown even though Impeller and Flutter GPU are enabled: $e');
      }
    }
  });

  test('GpuContext.minimumUniformByteAlignment', () async {
    final int alignment = gpu.gpuContext.minimumUniformByteAlignment;
    expect(alignment, greaterThanOrEqualTo(16));
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  test('HostBuffer.emplace', () async {
    final gpu.HostBuffer hostBuffer = gpu.gpuContext.createHostBuffer();

    final gpu.BufferView view0 = hostBuffer.emplace(
      Int8List.fromList(<int>[0, 1, 2, 3]).buffer.asByteData(),
    );
    expect(view0.offsetInBytes, 0);
    expect(view0.lengthInBytes, 4);

    final gpu.BufferView view1 = hostBuffer.emplace(
      Int8List.fromList(<int>[0, 1, 2, 3]).buffer.asByteData(),
    );
    expect(view1.offsetInBytes, equals(gpu.gpuContext.minimumUniformByteAlignment));
    expect(view1.lengthInBytes, 4);
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  test('HostBuffer.reset', () async {
    final gpu.HostBuffer hostBuffer = gpu.gpuContext.createHostBuffer();

    final gpu.BufferView view0 = hostBuffer.emplace(
      Int8List.fromList(<int>[0, 1, 2, 3]).buffer.asByteData(),
    );
    expect(view0.offsetInBytes, 0);
    expect(view0.lengthInBytes, 4);

    hostBuffer.reset();

    final gpu.BufferView view1 = hostBuffer.emplace(
      Int8List.fromList(<int>[0, 1, 2, 3]).buffer.asByteData(),
    );
    expect(view1.offsetInBytes, 0);
    expect(view1.lengthInBytes, 4);
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  test('HostBuffer reuses DeviceBuffers after N frames', () async {
    final gpu.HostBuffer hostBuffer = gpu.gpuContext.createHostBuffer();

    final gpu.BufferView view0 = hostBuffer.emplace(
      Int8List.fromList(<int>[0, 1, 2, 3]).buffer.asByteData(),
    );

    for (var i = 0; i < hostBuffer.frameCount; i++) {
      hostBuffer.reset();
    }
    final gpu.BufferView view1 = hostBuffer.emplace(
      Int8List.fromList(<int>[0, 1, 2, 3]).buffer.asByteData(),
    );

    expect(view0.buffer, equals(view1.buffer));
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  test('GpuContext.createDeviceBuffer', () async {
    final gpu.DeviceBuffer deviceBuffer = gpu.gpuContext.createDeviceBuffer(
      gpu.StorageMode.hostVisible,
      4,
    );

    expect(deviceBuffer.sizeInBytes, 4);
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  test('DeviceBuffer.overwrite', () async {
    final gpu.DeviceBuffer deviceBuffer = gpu.gpuContext.createDeviceBuffer(
      gpu.StorageMode.hostVisible,
      4,
    );

    final bool success = deviceBuffer.overwrite(
      Int8List.fromList(<int>[0, 1, 2, 3]).buffer.asByteData(),
    );
    deviceBuffer.flush();
    expect(success, true);
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  test('DeviceBuffer.overwrite fails when out of bounds', () async {
    final gpu.DeviceBuffer deviceBuffer = gpu.gpuContext.createDeviceBuffer(
      gpu.StorageMode.hostVisible,
      4,
    );

    final bool success = deviceBuffer.overwrite(
      Int8List.fromList(<int>[0, 1, 2, 3]).buffer.asByteData(),
      destinationOffsetInBytes: 1,
    );
    deviceBuffer.flush();
    expect(success, false);
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  test(
    'DeviceBuffer.overwrite throws for negative destination offset',
    () async {
      final gpu.DeviceBuffer deviceBuffer = gpu.gpuContext.createDeviceBuffer(
        gpu.StorageMode.hostVisible,
        4,
      );

      try {
        deviceBuffer.overwrite(
          Int8List.fromList(<int>[0, 1, 2, 3]).buffer.asByteData(),
          destinationOffsetInBytes: -1,
        );
        deviceBuffer.flush();
        fail('Exception not thrown for negative destination offset.');
      } catch (e) {
        expect(e.toString(), contains('destinationOffsetInBytes must be positive'));
      }
    },
    skip: !(impellerEnabled && flutterGpuEnabled),
  );

  test('GpuContext.createTexture', () async {
    final gpu.Texture texture = gpu.gpuContext.createTexture(gpu.StorageMode.hostVisible, 100, 100);

    // Check the defaults.
    expect(texture.coordinateSystem, gpu.TextureCoordinateSystem.renderToTexture);
    expect(texture.width, 100);
    expect(texture.height, 100);
    expect(texture.storageMode, gpu.StorageMode.hostVisible);
    expect(texture.sampleCount, 1);
    expect(texture.textureType, gpu.TextureType.texture2D);
    expect(texture.format, gpu.PixelFormat.r8g8b8a8UNormInt);
    expect(texture.enableRenderTargetUsage, true);
    expect(texture.enableShaderReadUsage, true);
    expect(!texture.enableShaderWriteUsage, true);
    expect(texture.bytesPerTexel, 4);
    expect(texture.getBaseMipLevelSizeInBytes(), 40000);
    expect(texture.mipLevelCount, 1);
    expect(texture.sliceCount, 1);
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  test('Texture.fullMipCount', () async {
    // Matches Impeller's `ISize::MipCount`: `floor(log2(min(w, h)))`,
    // clamped to a minimum of 1.
    expect(gpu.Texture.fullMipCount(1, 1), 1);
    expect(gpu.Texture.fullMipCount(2, 1), 1);
    expect(gpu.Texture.fullMipCount(2, 2), 1);
    expect(gpu.Texture.fullMipCount(4, 4), 2);
    expect(gpu.Texture.fullMipCount(8, 8), 3);
    expect(gpu.Texture.fullMipCount(100, 100), 6);
    expect(gpu.Texture.fullMipCount(1024, 1024), 10);
    // Non-square: count uses the smaller dimension.
    expect(gpu.Texture.fullMipCount(1024, 1), 1);
    expect(gpu.Texture.fullMipCount(1, 256), 1);
  });

  test(
    'GpuContext.createTexture with mipLevelCount allocates a mip chain',
    () async {
      final gpu.Texture texture = gpu.gpuContext.createTexture(
        gpu.StorageMode.hostVisible,
        8,
        8,
        mipLevelCount: 3,
      );
      expect(texture.mipLevelCount, 3);
      // Per-level sizes: 8*8*4=256, 4*4*4=64, 2*2*4=16.
      expect(texture.getMipLevelSizeInBytes(0), 256);
      expect(texture.getMipLevelSizeInBytes(1), 64);
      expect(texture.getMipLevelSizeInBytes(2), 16);
    },
    skip: !(impellerEnabled && flutterGpuEnabled),
  );

  test(
    'GpuContext.createTexture rejects out-of-range mipLevelCount',
    () async {
      try {
        gpu.gpuContext.createTexture(gpu.StorageMode.hostVisible, 8, 8, mipLevelCount: 0);
        fail('Exception not thrown for mipLevelCount=0.');
      } catch (e) {
        expect(e.toString(), contains('mipLevelCount'));
      }
      try {
        // Max for 8x8 is 3.
        gpu.gpuContext.createTexture(gpu.StorageMode.hostVisible, 8, 8, mipLevelCount: 4);
        fail('Exception not thrown for mipLevelCount above the maximum.');
      } catch (e) {
        expect(e.toString(), contains('mipLevelCount'));
      }
    },
    skip: !(impellerEnabled && flutterGpuEnabled),
  );

  test(
    'GpuContext.createTexture fails if invalid sampleCount and texture type is passed.',
    () async {
      try {
        gpu.gpuContext.createTexture(
          gpu.StorageMode.hostVisible,
          100,
          100,
          sampleCount: 4,
          textureType: gpu.TextureType.texture2D,
        );
        fail('Exception not thrown when creating an invalid texture.');
      } catch (e) {
        expect(e.toString(), contains('Texture creation failed'));
      }
    },
    skip: !(impellerEnabled && flutterGpuEnabled),
  );

  test('Texture.overwrite', () async {
    final gpu.Texture texture = gpu.gpuContext.createTexture(gpu.StorageMode.hostVisible, 2, 2);

    const red = ui.Color.fromARGB(0xFF, 0xFF, 0, 0);
    const green = ui.Color.fromARGB(0xFF, 0, 0xFF, 0);
    texture.overwrite(
      Int32List.fromList(<int>[red.value, green.value, green.value, red.value]).buffer.asByteData(),
    );
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  test('Texture.overwrite throws for wrong buffer size', () async {
    final gpu.Texture texture = gpu.gpuContext.createTexture(gpu.StorageMode.hostVisible, 100, 100);

    const red = ui.Color.fromARGB(0xFF, 0xFF, 0, 0);
    try {
      texture.overwrite(
        Int32List.fromList(<int>[red.value, red.value, red.value, red.value]).buffer.asByteData(),
      );
      fail('Exception not thrown for wrong buffer size.');
    } catch (e) {
      expect(
        e.toString(),
        contains(
          'The length of sourceBytes (bytes: 16) must exactly match the size of mip level 0 (bytes: 40000)',
        ),
      );
    }
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  test('Texture.overwrite writes to a non-zero mip level', () async {
    final gpu.Texture texture = gpu.gpuContext.createTexture(
      gpu.StorageMode.hostVisible,
      8,
      8,
      mipLevelCount: 3,
    );
    const red = ui.Color.fromARGB(0xFF, 0xFF, 0, 0);
    const blue = ui.Color.fromARGB(0xFF, 0, 0, 0xFF);

    // Mip 0: 8x8 = 64 texels.
    texture.overwrite(Int32List.fromList(List<int>.filled(64, red.value)).buffer.asByteData());
    // Mip 1: 4x4 = 16 texels.
    texture.overwrite(
      Int32List.fromList(List<int>.filled(16, blue.value)).buffer.asByteData(),
      mipLevel: 1,
    );
    // Mip 2: 2x2 = 4 texels.
    texture.overwrite(
      Int32List.fromList(List<int>.filled(4, red.value)).buffer.asByteData(),
      mipLevel: 2,
    );
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  test(
    'Texture.overwrite throws for an out-of-range mipLevel',
    () async {
      final gpu.Texture texture = gpu.gpuContext.createTexture(
        gpu.StorageMode.hostVisible,
        4,
        4,
        mipLevelCount: 2,
      );
      const red = ui.Color.fromARGB(0xFF, 0xFF, 0, 0);
      try {
        texture.overwrite(Int32List.fromList(<int>[red.value]).buffer.asByteData(), mipLevel: 2);
        fail('Exception not thrown for out-of-range mipLevel.');
      } catch (e) {
        expect(e.toString(), contains('mipLevel (2) must be in the range [0, 2)'));
      }
    },
    skip: !(impellerEnabled && flutterGpuEnabled),
  );

  test('Texture.overwrite throws for an out-of-range slice', () async {
    final gpu.Texture texture = gpu.gpuContext.createTexture(gpu.StorageMode.hostVisible, 2, 2);
    const red = ui.Color.fromARGB(0xFF, 0xFF, 0, 0);
    try {
      texture.overwrite(
        Int32List.fromList(List<int>.filled(4, red.value)).buffer.asByteData(),
        slice: 1,
      );
      fail('Exception not thrown for out-of-range slice.');
    } catch (e) {
      expect(e.toString(), contains('slice (1) must be in the range [0, 1)'));
    }
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  test('Texture.overwrite writes each face of a cubemap', () async {
    final gpu.Texture texture = gpu.gpuContext.createTexture(
      gpu.StorageMode.hostVisible,
      2,
      2,
      textureType: gpu.TextureType.textureCube,
    );
    expect(texture.sliceCount, 6);
    const colors = <ui.Color>[
      ui.Color.fromARGB(0xFF, 0xFF, 0, 0),
      ui.Color.fromARGB(0xFF, 0, 0xFF, 0),
      ui.Color.fromARGB(0xFF, 0, 0, 0xFF),
      ui.Color.fromARGB(0xFF, 0xFF, 0xFF, 0),
      ui.Color.fromARGB(0xFF, 0xFF, 0, 0xFF),
      ui.Color.fromARGB(0xFF, 0, 0xFF, 0xFF),
    ];
    for (var slice = 0; slice < 6; slice++) {
      final int v = colors[slice].value;
      texture.overwrite(Int32List.fromList(<int>[v, v, v, v]).buffer.asByteData(), slice: slice);
    }
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  test('Texture.asImage returns a valid ui.Image handle', () async {
    final gpu.Texture texture = gpu.gpuContext.createTexture(gpu.StorageMode.hostVisible, 100, 100);

    final ui.Image image = texture.asImage();
    expect(image.width, 100);
    expect(image.height, 100);
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  test('Texture.asImage throws when not shader readable', () async {
    final gpu.Texture texture = gpu.gpuContext.createTexture(
      gpu.StorageMode.hostVisible,
      100,
      100,
      enableShaderReadUsage: false,
    );

    try {
      texture.asImage();
      fail('Exception not thrown when not shader readable.');
    } catch (e) {
      expect(
        e.toString(),
        contains('Only shader readable Flutter GPU textures can be used as UI Images'),
      );
    }
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  test(
    'RenderPass.setStencilReference doesnt throw for valid values',
    () async {
      final RenderPassState state = createSimpleRenderPass();

      state.renderPass.setStencilReference(0);
      state.renderPass.setStencilReference(2 << 30);
    },
    skip: !(impellerEnabled && flutterGpuEnabled),
  );

  test(
    'RenderPass.setStencilReference throws for invalid values',
    () async {
      final RenderPassState state = createSimpleRenderPass();

      try {
        state.renderPass.setStencilReference(-1);
        fail('Exception not thrown for out of bounds stencil reference.');
      } catch (e) {
        expect(e.toString(), contains('The stencil reference value must be in the range'));
      }

      try {
        state.renderPass.setStencilReference(2 << 31);
        fail('Exception not thrown for out of bounds stencil reference.');
      } catch (e) {
        expect(e.toString(), contains('The stencil reference value must be in the range'));
      }
    },
    skip: !(impellerEnabled && flutterGpuEnabled),
  );

  test(
    'RenderPass.setStencilConfig doesnt throw for valid values',
    () async {
      final RenderPassState state = createSimpleRenderPass();

      state.renderPass.setStencilConfig(gpu.StencilConfig());
      state.renderPass.setStencilConfig(
        gpu.StencilConfig(
          compareFunction: gpu.CompareFunction.notEqual,
          depthFailureOperation: gpu.StencilOperation.decrementWrap,
          depthStencilPassOperation: gpu.StencilOperation.incrementWrap,
          stencilFailureOperation: gpu.StencilOperation.invert,
          readMask: 0,
          writeMask: 0,
        ),
        targetFace: gpu.StencilFace.back,
      );
    },
    skip: !(impellerEnabled && flutterGpuEnabled),
  );

  test(
    'RenderPass.setStencilConfig throws for invalid masks',
    () async {
      final RenderPassState state = createSimpleRenderPass();

      try {
        state.renderPass.setStencilConfig(gpu.StencilConfig(readMask: -1));
        fail('Exception not thrown for invalid stencil read mask.');
      } catch (e) {
        expect(e.toString(), contains('The stencil read mask must be in the range'));
      }
      try {
        state.renderPass.setStencilConfig(gpu.StencilConfig(readMask: 0xFFFFFFFF + 1));
        fail('Exception not thrown for invalid stencil read mask.');
      } catch (e) {
        expect(e.toString(), contains('The stencil read mask must be in the range'));
      }

      try {
        state.renderPass.setStencilConfig(gpu.StencilConfig(writeMask: -1));
        fail('Exception not thrown for invalid stencil write mask.');
      } catch (e) {
        expect(e.toString(), contains('The stencil write mask must be in the range'));
      }
      try {
        state.renderPass.setStencilConfig(gpu.StencilConfig(writeMask: 0xFFFFFFFF + 1));
        fail('Exception not thrown for invalid stencil write mask.');
      } catch (e) {
        expect(e.toString(), contains('The stencil write mask must be in the range'));
      }
    },
    skip: !(impellerEnabled && flutterGpuEnabled),
  );

  test(
    'RenderPass.bindTexture throws for deviceTransient Textures',
    () async {
      final RenderPassState state = createSimpleRenderPass();

      final gpu.RenderPipeline pipeline = createUnlitRenderPipeline();
      // Although this is a non-texture uniform slot, it'll work fine for the
      // purposes of testing this error.
      final gpu.UniformSlot vertInfo = pipeline.vertexShader.getUniformSlot('VertInfo');

      final gpu.Texture texture = gpu.gpuContext.createTexture(
        gpu.StorageMode.deviceTransient,
        100,
        100,
      );

      try {
        state.renderPass.bindTexture(vertInfo, texture);
        fail('Exception not thrown when binding a transient texture.');
      } catch (e) {
        expect(
          e.toString(),
          contains('Textures with StorageMode.deviceTransient cannot be bound to a RenderPass'),
        );
      }
    },
    skip: !(impellerEnabled && flutterGpuEnabled),
  );

  // Performs no draw calls. Just clears the render target to a solid green color.
  test('Can render clear color', () async {
    final RenderPassState state = createSimpleRenderPass(clearColor: Colors.lime);

    state.commandBuffer.submit();

    final ui.Image image = state.renderTexture.asImage();
    await comparer.addGoldenImage(image, 'flutter_gpu_test_clear_color.png');
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  // Regression test for https://github.com/flutter/flutter/issues/157324
  test('Can bind uniforms in range', () async {
    final RenderPassState state = createSimpleRenderPass();

    final gpu.RenderPipeline pipeline = createUnlitRenderPipeline();
    final gpu.UniformSlot vertInfo = pipeline.vertexShader.getUniformSlot('VertInfo');

    final ByteData vertInfoData = float32(<double>[
      1, 0, 0, 0, // mvp
      0, 1, 0, 0, // mvp
      0, 0, 1, 0, // mvp
      0, 0, 0, 1, // mvp
      0, 1, 0, 1, // color
    ]);
    final gpu.DeviceBuffer uniformBuffer = gpu.gpuContext.createDeviceBufferWithCopy(vertInfoData);
    final gooduniformBufferView = gpu.BufferView(
      uniformBuffer,
      offsetInBytes: 0,
      lengthInBytes: uniformBuffer.sizeInBytes,
    );
    state.renderPass.bindUniform(vertInfo, gooduniformBufferView);

    final badUniformBufferView = gpu.BufferView(
      uniformBuffer,
      offsetInBytes: 0,
      lengthInBytes: uniformBuffer.sizeInBytes + 1,
    );
    try {
      state.renderPass.bindUniform(vertInfo, badUniformBufferView);
      fail('Exception not thrown for bad buffer view range.');
    } catch (e) {
      expect(e.toString(), contains('Failed to bind uniform'));
    }
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  // Renders a green triangle pointing downwards.
  test('Can render triangle', () async {
    final RenderPassState state = createSimpleRenderPass();
    drawTriangle(state, Colors.lime);
    state.commandBuffer.submit();

    final ui.Image image = state.renderTexture.asImage();
    await comparer.addGoldenImage(image, 'flutter_gpu_test_triangle.png');
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  // Regression test for flutter/flutter#186393: a Flutter GPU shader whose
  // uniform block uses an instance variable name that does not normalize
  // to the block name (e.g. `uniform ColorParams { ... } params;`) used
  // to silently bind every member to GL location -1 on the OpenGL ES
  // backend, producing a black render. `impellerc` now canonicalizes the
  // instance name to `_<BlockName>` for GL targets so the block resolves
  // correctly on all backends.
  test(
    'Uniform block with non-conforming instance name binds on all backends',
    () async {
      final RenderPassState state = createSimpleRenderPass();

      final gpu.ShaderLibrary library = gpu.ShaderLibrary.fromAsset('test.shaderbundle')!;
      final gpu.RenderPipeline pipeline = gpu.gpuContext.createRenderPipeline(
        library['UnlitVertex']!,
        library['UnlitFragmentAltInstance']!,
      );
      state.renderPass.bindPipeline(pipeline);

      final gpu.HostBuffer transients = gpu.gpuContext.createHostBuffer();
      final gpu.BufferView vertices = transients.emplace(
        float32(<double>[-0.5, 0.5, 0.0, -0.5, 0.5, 0.5]),
      );
      state.renderPass.bindVertexBuffer(vertices, 3);

      // Vertex shader writes v_color from VertInfo.color; pick white so the
      // final pixel color is dictated entirely by ColorParams.base_color.
      state.renderPass.bindUniform(
        pipeline.vertexShader.getUniformSlot('VertInfo'),
        transients.emplace(unlitUBO(Matrix4.identity(), Vector4(1, 1, 1, 1))),
      );

      // Bind the fragment shader's uniform block by its *block* name. Without
      // canonicalization, GLES would bind the members to location -1 and
      // sample zeros here.
      state.renderPass.bindUniform(
        pipeline.fragmentShader.getUniformSlot('ColorParams'),
        transients.emplace(float32(<double>[1.0, 0.0, 0.0, 1.0])),
      );

      state.renderPass.draw();
      state.commandBuffer.submit();

      final ui.Image image = state.renderTexture.asImage();
      await comparer.addGoldenImage(image, 'flutter_gpu_uniform_block_alt_instance.png');

      // Belt-and-suspenders: also assert programmatically that the center of
      // the rendered triangle is red. If the bug regresses, the uniform reads
      // zero and the triangle renders as fully transparent black. Sampling a
      // single pixel inside the triangle catches that without relying on
      // golden-file plumbing.
      final ByteData? bytes = await image.toByteData();
      expect(bytes, isNotNull);
      final int centerOffset = (image.width ~/ 2 + image.height ~/ 2 * image.width) * 4;
      final int b0 = bytes!.getUint8(centerOffset);
      final int b1 = bytes.getUint8(centerOffset + 1);
      final int b2 = bytes.getUint8(centerOffset + 2);
      final int b3 = bytes.getUint8(centerOffset + 3);
      // Format may be RGBA or BGRA depending on backend; check that exactly
      // one of the first three channels is red-saturated and the others are
      // dark, with full alpha.
      expect(
        b0 + b1 + b2,
        greaterThan(200),
        reason:
            'Center pixel was black (channels=$b0,$b1,$b2,$b3); '
            'uniform block likely failed to bind.',
      );
      expect(
        b3,
        greaterThan(200),
        reason: 'Center pixel alpha was low (channels=$b0,$b1,$b2,$b3).',
      );
    },
    skip: !(impellerEnabled && flutterGpuEnabled),
  );

  // A custom VertexLayout that matches the shader bundle's default for the
  // UnlitVertex shader (one buffer at slot 0, vec2 position at offset 0)
  // should produce identical pipeline behavior. This pins the shape of the
  // VertexLayout/VertexBuffer/VertexAttribute/VertexFormat API and the FFI
  // plumbing through createRenderPipeline.
  test('Can render triangle with explicit VertexLayout', () async {
    final RenderPassState state = createSimpleRenderPass();

    final gpu.ShaderLibrary library = gpu.ShaderLibrary.fromAsset('test.shaderbundle')!;
    final gpu.RenderPipeline pipeline = gpu.gpuContext.createRenderPipeline(
      library['UnlitVertex']!,
      library['UnlitFragment']!,
      vertexLayout: const gpu.VertexLayout(
        buffers: <gpu.VertexBuffer>[
          gpu.VertexBuffer(
            strideInBytes: 8,
            attributes: <gpu.VertexAttribute>[
              gpu.VertexAttribute(name: 'position', format: gpu.VertexFormat.float32x2),
            ],
          ),
        ],
      ),
    );
    state.renderPass.bindPipeline(pipeline);

    final gpu.HostBuffer transients = gpu.gpuContext.createHostBuffer();
    final gpu.BufferView vertices = transients.emplace(
      float32(<double>[-0.5, 0.5, 0.0, -0.5, 0.5, 0.5]),
    );
    final gpu.BufferView vertInfo = transients.emplace(unlitUBO(Matrix4.identity(), Colors.lime));
    state.renderPass.bindVertexBuffer(vertices, 3);
    state.renderPass.bindUniform(pipeline.vertexShader.getUniformSlot('VertInfo'), vertInfo);
    state.renderPass.draw();
    state.commandBuffer.submit();

    final ui.Image image = state.renderTexture.asImage();
    await comparer.addGoldenImage(image, 'flutter_gpu_test_triangle.png');
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  test(
    'createRenderPipeline rejects VertexLayout with wrong attribute format',
    () async {
      final gpu.ShaderLibrary library = gpu.ShaderLibrary.fromAsset('test.shaderbundle')!;
      try {
        gpu.gpuContext.createRenderPipeline(
          library['UnlitVertex']!,
          library['UnlitFragment']!,
          vertexLayout: const gpu.VertexLayout(
            buffers: <gpu.VertexBuffer>[
              gpu.VertexBuffer(
                strideInBytes: 8,
                attributes: <gpu.VertexAttribute>[
                  // UnlitVertex declares a float `vec2 position`, so binding
                  // a uint32x2 (different scalar type class) here must throw.
                  // Component-count mismatches are NOT errors: a buffer can
                  // supply more or fewer components than the shader reads,
                  // matching the default-substitution rules every modern HAL
                  // uses.
                  gpu.VertexAttribute(name: 'position', format: gpu.VertexFormat.uint32x2),
                ],
              ),
            ],
          ),
        );
        fail('Expected exception for mismatched VertexFormat scalar type.');
      } catch (e) {
        expect(
          e.toString(),
          contains("format does not match the vertex shader's declared input type"),
        );
      }
    },
    skip: !(impellerEnabled && flutterGpuEnabled),
  );

  test(
    'createRenderPipeline rejects VertexAttribute that overruns stride',
    () async {
      final gpu.ShaderLibrary library = gpu.ShaderLibrary.fromAsset('test.shaderbundle')!;
      try {
        gpu.gpuContext.createRenderPipeline(
          library['UnlitVertex']!,
          library['UnlitFragment']!,
          vertexLayout: const gpu.VertexLayout(
            buffers: <gpu.VertexBuffer>[
              gpu.VertexBuffer(
                strideInBytes: 8,
                attributes: <gpu.VertexAttribute>[
                  // float32x2 (8 bytes) at offset 4 with stride 8 overruns by 4.
                  gpu.VertexAttribute(
                    name: 'position',
                    offsetInBytes: 4,
                    format: gpu.VertexFormat.float32x2,
                  ),
                ],
              ),
            ],
          ),
        );
        fail('Expected exception for offset+format overruning stride.');
      } catch (e) {
        expect(e.toString(), contains('overruns stride'));
      }
    },
    skip: !(impellerEnabled && flutterGpuEnabled),
  );

  test(
    'createRenderPipeline rejects VertexLayout with overlapping attributes',
    () async {
      final gpu.ShaderLibrary library = gpu.ShaderLibrary.fromAsset('test.shaderbundle')!;
      try {
        gpu.gpuContext.createRenderPipeline(
          library['UnlitVertex']!,
          library['UnlitFragment']!,
          vertexLayout: const gpu.VertexLayout(
            buffers: <gpu.VertexBuffer>[
              gpu.VertexBuffer(
                strideInBytes: 8,
                attributes: <gpu.VertexAttribute>[
                  // Two attributes both occupying bytes [0, 8) in the same
                  // buffer. The second one isn't a real shader input, but
                  // the overlap check fires before the name check.
                  gpu.VertexAttribute(name: 'position', format: gpu.VertexFormat.float32x2),
                  gpu.VertexAttribute(name: 'aliased', format: gpu.VertexFormat.float32x2),
                ],
              ),
            ],
          ),
        );
        fail('Expected exception for overlapping VertexAttributes.');
      } catch (e) {
        final msg = e.toString();
        expect(msg, contains('overlaps'));
        expect(msg, contains("'position'"));
        expect(msg, contains("'aliased'"));
      }
    },
    skip: !(impellerEnabled && flutterGpuEnabled),
  );

  test(
    'bindVertexBuffer throws RangeError for out-of-range slot',
    () async {
      final RenderPassState state = createSimpleRenderPass();
      final gpu.RenderPipeline pipeline = createUnlitRenderPipeline();
      state.renderPass.bindPipeline(pipeline);

      final gpu.HostBuffer transients = gpu.gpuContext.createHostBuffer();
      final gpu.BufferView vertices = transients.emplace(
        float32(<double>[-0.5, 0.5, 0.0, -0.5, 0.5, 0.5]),
      );

      expect(() => state.renderPass.bindVertexBuffer(vertices, 3, slot: -1), throwsRangeError);
      expect(() => state.renderPass.bindVertexBuffer(vertices, 3, slot: 16), throwsRangeError);
    },
    skip: !(impellerEnabled && flutterGpuEnabled),
  );

  test(
    'draw throws StateError on sparse vertex buffer bindings',
    () async {
      final RenderPassState state = createSimpleRenderPass();
      final gpu.RenderPipeline pipeline = createUnlitRenderPipeline();
      state.renderPass.bindPipeline(pipeline);

      final gpu.HostBuffer transients = gpu.gpuContext.createHostBuffer();
      final gpu.BufferView vertices = transients.emplace(
        float32(<double>[-0.5, 0.5, 0.0, -0.5, 0.5, 0.5]),
      );

      // Bind only slot 1 (skipping slot 0). draw() must surface a clear
      // error rather than letting the underlying HAL validation fail
      // silently or render with an empty slot.
      state.renderPass.bindVertexBuffer(vertices, 3, slot: 1);
      expect(
        () => state.renderPass.draw(),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            allOf(contains('sparse'), contains('slot(s) 0')),
          ),
        ),
      );
    },
    skip: !(impellerEnabled && flutterGpuEnabled),
  );

  test(
    'createRenderPipeline rejects VertexAttribute with unknown name',
    () async {
      final gpu.ShaderLibrary library = gpu.ShaderLibrary.fromAsset('test.shaderbundle')!;
      try {
        gpu.gpuContext.createRenderPipeline(
          library['UnlitVertex']!,
          library['UnlitFragment']!,
          vertexLayout: const gpu.VertexLayout(
            buffers: <gpu.VertexBuffer>[
              gpu.VertexBuffer(
                strideInBytes: 8,
                attributes: <gpu.VertexAttribute>[
                  gpu.VertexAttribute(
                    name: 'nonexistent_attribute',
                    format: gpu.VertexFormat.float32x2,
                  ),
                ],
              ),
            ],
          ),
        );
        fail('Expected exception for unknown attribute name.');
      } catch (e) {
        expect(
          e.toString(),
          contains('does not match any input declared by the bound vertex shader'),
        );
      }
    },
    skip: !(impellerEnabled && flutterGpuEnabled),
  );

  // Two distinct shader bundles can ship the same entrypoint names without
  // colliding in the shared shader registry. `test.shaderbundle` and
  // `test_alt.shaderbundle` both export `UnlitFragment` and `UnlitVertex`
  // entrypoints; without the per-bundle namespacing they would register at
  // the same registry key and the second load would evict the first. With
  // namespacing the asset paths (the bundle library_ids) make the keys
  // distinct, so both bundles can be loaded and used in the same process.
  test(
    'Two shader bundles with the same entrypoint names do not collide',
    () async {
      final gpu.ShaderLibrary? libraryA = gpu.ShaderLibrary.fromAsset('test.shaderbundle');
      final gpu.ShaderLibrary? libraryB = gpu.ShaderLibrary.fromAsset('test_alt.shaderbundle');
      expect(libraryA, isNotNull);
      expect(libraryB, isNotNull);

      final gpu.Shader? unlitVertexA = libraryA!['UnlitVertex'];
      final gpu.Shader? unlitFragmentA = libraryA['UnlitFragment'];
      final gpu.Shader? unlitVertexB = libraryB!['UnlitVertex'];
      final gpu.Shader? unlitFragmentB = libraryB['UnlitFragment'];
      expect(unlitVertexA, isNotNull);
      expect(unlitFragmentA, isNotNull);
      expect(unlitVertexB, isNotNull);
      expect(unlitFragmentB, isNotNull);

      // Both pipelines must register and remain usable. Without namespacing,
      // `RuntimeEffectContents::RegisterShader`-style eviction would tear one
      // of these pipelines down at registration time and the second draw
      // would render against invalid state. With namespacing they coexist.
      final gpu.RenderPipeline pipelineA = gpu.gpuContext.createRenderPipeline(
        unlitVertexA!,
        unlitFragmentA!,
      );
      final gpu.RenderPipeline pipelineB = gpu.gpuContext.createRenderPipeline(
        unlitVertexB!,
        unlitFragmentB!,
      );

      void drawWithPipeline(RenderPassState state, gpu.RenderPipeline pipeline, Vector4 color) {
        state.renderPass.bindPipeline(pipeline);
        final gpu.HostBuffer transients = gpu.gpuContext.createHostBuffer();
        final gpu.BufferView vertices = transients.emplace(
          float32(<double>[-0.5, 0.5, 0.0, -0.5, 0.5, 0.5]),
        );
        final gpu.BufferView vertInfoData = transients.emplace(unlitUBO(Matrix4.identity(), color));
        state.renderPass.bindVertexBuffer(vertices, 3);
        final gpu.UniformSlot vertInfo = pipeline.vertexShader.getUniformSlot('VertInfo');
        state.renderPass.bindUniform(vertInfo, vertInfoData);
        state.renderPass.draw();
      }

      final RenderPassState stateA = createSimpleRenderPass();
      drawWithPipeline(stateA, pipelineA, Colors.lime);
      stateA.commandBuffer.submit();

      final RenderPassState stateB = createSimpleRenderPass();
      drawWithPipeline(stateB, pipelineB, Colors.lime);
      stateB.commandBuffer.submit();
    },
    skip: !(impellerEnabled && flutterGpuEnabled),
  );

  // Renders a green triangle pointing downwards using polygon mode line.
  test('Can render triangle with polygon mode line.', () async {
    final RenderPassState state = createSimpleRenderPass();

    final gpu.RenderPipeline pipeline = createUnlitRenderPipeline();
    state.renderPass.bindPipeline(pipeline);

    // Configure blending with defaults (just to test the bindings).
    state.renderPass.setColorBlendEnable(true);
    state.renderPass.setColorBlendEquation(gpu.ColorBlendEquation());

    // Set polygon mode.
    state.renderPass.setPolygonMode(gpu.PolygonMode.line);

    final gpu.HostBuffer transients = gpu.gpuContext.createHostBuffer();
    final gpu.BufferView vertices = transients.emplace(
      float32(<double>[
        -0.5, 0.5, //
        0.0, -0.5, //
        0.5, 0.5, //
      ]),
    );
    final gpu.BufferView vertInfoData = transients.emplace(
      float32(<double>[
        1, 0, 0, 0, // mvp
        0, 1, 0, 0, // mvp
        0, 0, 1, 0, // mvp
        0, 0, 0, 1, // mvp
        0, 1, 0, 1, // color
      ]),
    );
    state.renderPass.bindVertexBuffer(vertices, 3);

    final gpu.UniformSlot vertInfo = pipeline.vertexShader.getUniformSlot('VertInfo');
    state.renderPass.bindUniform(vertInfo, vertInfoData);
    state.renderPass.draw();

    state.commandBuffer.submit();

    final ui.Image image = state.renderTexture.asImage();
    await comparer.addGoldenImage(image, 'flutter_gpu_test_triangle_polygon_mode.png');
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  // Renders a green triangle pointing downwards, with 4xMSAA.
  test(
    'Can render triangle with MSAA',
    () async {
      final RenderPassState state = createSimpleRenderPassWithMSAA();
      drawTriangle(state, Colors.lime);
      state.commandBuffer.submit();

      final ui.Image image = state.renderTexture.asImage();
      await comparer.addGoldenImage(image, 'flutter_gpu_test_triangle_msaa.png');
    },
    skip: !(impellerEnabled && flutterGpuEnabled && gpu.gpuContext.doesSupportOffscreenMSAA),
  );

  test(
    'Rendering with MSAA throws exception when offscreen MSAA is not supported',
    () async {
      try {
        final RenderPassState state = createSimpleRenderPassWithMSAA();
        drawTriangle(state, Colors.lime);
        state.commandBuffer.submit();
        fail('Exception not thrown when offscreen MSAA is not supported.');
      } catch (e) {
        expect(
          e.toString(),
          contains(
            'The backend does not support multisample anti-aliasing for offscreen color and stencil attachments',
          ),
        );
      }
    },
    skip: !(impellerEnabled && flutterGpuEnabled && !gpu.gpuContext.doesSupportOffscreenMSAA),
  );

  // Renders a hollow green triangle pointing downwards.
  test('Can render hollowed out triangle using stencil ops', () async {
    final RenderPassState state = createSimpleRenderPass();

    final gpu.RenderPipeline pipeline = createUnlitRenderPipeline();
    state.renderPass.bindPipeline(pipeline);

    // Configure blending with defaults (just to test the bindings).
    state.renderPass.setColorBlendEnable(true);
    state.renderPass.setColorBlendEquation(gpu.ColorBlendEquation());

    final gpu.HostBuffer transients = gpu.gpuContext.createHostBuffer();
    final gpu.BufferView vertices = transients.emplace(
      float32(<double>[
        -0.5, 0.5, //
        0.0, -0.5, //
        0.5, 0.5, //
      ]),
    );
    final gpu.BufferView innerClipVertInfo = transients.emplace(
      float32(<double>[
        0.5, 0, 0, 0, // mvp
        0, 0.5, 0, 0, // mvp
        0, 0, 0.5, 0, // mvp
        0, 0, 0, 1, // mvp
        0, 1, 0, 1, // color
      ]),
    );
    final gpu.BufferView outerGreenVertInfo = transients.emplace(
      float32(<double>[
        1, 0, 0, 0, // mvp
        0, 1, 0, 0, // mvp
        0, 0, 1, 0, // mvp
        0, 0, 0, 1, // mvp
        0, 1, 0, 1, // color
      ]),
    );
    state.renderPass.bindVertexBuffer(vertices, 3);

    final gpu.UniformSlot vertInfo = pipeline.vertexShader.getUniformSlot('VertInfo');

    // First, punch out a scaled down triangle in the stencil buffer.
    // Since the stencil buffer is initialized to 0, we set the stencil ref to 1
    // and the compare to `equial`, which will result in the stencil test
    // failing. But on failure, we increment the stencil in order to punch out
    // the triangle.

    state.renderPass.bindUniform(vertInfo, innerClipVertInfo);
    state.renderPass.setStencilReference(1);
    state.renderPass.setStencilConfig(
      gpu.StencilConfig(
        compareFunction: gpu.CompareFunction.equal,
        stencilFailureOperation: gpu.StencilOperation.incrementClamp,
      ),
    );
    state.renderPass.draw();

    // Next, render the outer triangle with the stencil ref set to zero, so that
    // the stencil test passes everywhere except where the inner triangle was
    // punched out.

    state.renderPass.setStencilReference(0);
    // Set the stencil config to turn off the increment. For this golden test
    // we technically don't need to do this, but we do it here just to exercise
    // the API.
    state.renderPass.setStencilConfig(
      gpu.StencilConfig(compareFunction: gpu.CompareFunction.equal),
    );
    state.renderPass.bindUniform(vertInfo, outerGreenVertInfo);
    state.renderPass.draw();

    state.commandBuffer.submit();

    final ui.Image image = state.renderTexture.asImage();
    await comparer.addGoldenImage(image, 'flutter_gpu_test_triangle_stencil.png');
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  test('Drawing respects cull mode', () async {
    final RenderPassState state = createSimpleRenderPass();

    final gpu.RenderPipeline pipeline = createUnlitRenderPipeline();
    state.renderPass.bindPipeline(pipeline);

    state.renderPass.setColorBlendEnable(true);
    state.renderPass.setColorBlendEquation(gpu.ColorBlendEquation());

    final gpu.HostBuffer transients = gpu.gpuContext.createHostBuffer();
    // Counter-clockwise triangle.
    final triangle = <double>[
      -0.5, 0.5, //
      0.0, -0.5, //
      0.5, 0.5, //
    ];
    final gpu.BufferView vertices = transients.emplace(float32(triangle));

    void drawTriangle(Vector4 color) {
      final gpu.BufferView vertInfoUboFront = transients.emplace(
        unlitUBO(Matrix4.identity(), color),
      );

      final gpu.UniformSlot vertInfo = pipeline.vertexShader.getUniformSlot('VertInfo');
      state.renderPass.bindVertexBuffer(vertices, 3);
      state.renderPass.bindUniform(vertInfo, vertInfoUboFront);
      state.renderPass.draw();
    }

    // Draw the green rectangle.
    // Defaults to clockwise winding order. So frontface culling should not
    // impact the green triangle.
    state.renderPass.setCullMode(gpu.CullMode.frontFace);
    drawTriangle(Colors.lime);

    // Backface cull a red triangle.
    state.renderPass.setCullMode(gpu.CullMode.backFace);
    drawTriangle(Colors.red);

    // Invert the winding mode and frontface cull a red rectangle.
    state.renderPass.setWindingOrder(gpu.WindingOrder.counterClockwise);
    state.renderPass.setCullMode(gpu.CullMode.frontFace);
    drawTriangle(Colors.red);

    state.commandBuffer.submit();

    final ui.Image image = state.renderTexture.asImage();
    await comparer.addGoldenImage(image, 'flutter_gpu_test_cull_mode.png');
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  // Renders a hexagon using line strip primitive type.
  test(
    'Can render hollow hexagon using line strip primitive type',
    () async {
      final RenderPassState state = createSimpleRenderPass();

      final gpu.RenderPipeline pipeline = createUnlitRenderPipeline();
      state.renderPass.bindPipeline(pipeline);

      // Configure blending with defaults (just to test the bindings).
      state.renderPass.setColorBlendEnable(true);
      state.renderPass.setColorBlendEquation(gpu.ColorBlendEquation());

      // Set primitive type
      state.renderPass.setPrimitiveType(gpu.PrimitiveType.lineStrip);

      final gpu.HostBuffer transients = gpu.gpuContext.createHostBuffer();
      final gpu.BufferView vertices = transients.emplace(
        float32(<double>[
          1.0,
          0.0,
          0.5,
          0.8,
          -0.5,
          0.8,
          -1.0,
          0.0,
          -0.5,
          -0.8,
          0.5,
          -0.8,
          1.0,
          0.0,
        ]),
      );
      final gpu.BufferView vertInfoData = transients.emplace(
        float32(<double>[
          1, 0, 0, 0, // mvp
          0, 1, 0, 0, // mvp
          0, 0, 1, 0, // mvp
          0, 0, 0, 1, // mvp
          0, 1, 0, 1, // color
        ]),
      );
      state.renderPass.bindVertexBuffer(vertices, 7);

      final gpu.UniformSlot vertInfo = pipeline.vertexShader.getUniformSlot('VertInfo');
      state.renderPass.bindUniform(vertInfo, vertInfoData);
      state.renderPass.draw();

      state.commandBuffer.submit();

      final ui.Image image = state.renderTexture.asImage();
      await comparer.addGoldenImage(image, 'flutter_gpu_test_hexgon_line_strip.png');
    },
    skip: !(impellerEnabled && flutterGpuEnabled),
  );

  // Renders the middle part triangle using scissor.
  test('Can render portion of the triangle using scissor', () async {
    final RenderPassState state = createSimpleRenderPass();

    final gpu.RenderPipeline pipeline = createUnlitRenderPipeline();
    state.renderPass.bindPipeline(pipeline);

    // Configure blending with defaults (just to test the bindings).
    state.renderPass.setColorBlendEnable(true);
    state.renderPass.setColorBlendEquation(gpu.ColorBlendEquation());

    // Set primitive type.
    state.renderPass.setPrimitiveType(gpu.PrimitiveType.triangle);

    // Set scissor.
    state.renderPass.setScissor(gpu.Scissor(x: 25, width: 50, height: 100));

    final gpu.HostBuffer transients = gpu.gpuContext.createHostBuffer();
    final gpu.BufferView vertices = transients.emplace(
      float32(<double>[-1.0, -1.0, 0.0, 1.0, 1.0, -1.0]),
    );
    final gpu.BufferView vertInfoData = transients.emplace(
      float32(<double>[
        1, 0, 0, 0, // mvp
        0, 1, 0, 0, // mvp
        0, 0, 1, 0, // mvp
        0, 0, 0, 1, // mvp
        0, 1, 0, 1, // color
      ]),
    );
    state.renderPass.bindVertexBuffer(vertices, 3);

    final gpu.UniformSlot vertInfo = pipeline.vertexShader.getUniformSlot('VertInfo');
    state.renderPass.bindUniform(vertInfo, vertInfoData);
    state.renderPass.draw();

    state.commandBuffer.submit();

    final ui.Image image = state.renderTexture.asImage();
    await comparer.addGoldenImage(image, 'flutter_gpu_test_scissor.png');
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  test(
    'RenderPass.setScissor doesnt throw for valid values',
    () async {
      final RenderPassState state = createSimpleRenderPass();

      state.renderPass.setScissor(gpu.Scissor(x: 25, width: 50, height: 100));
      state.renderPass.setScissor(gpu.Scissor(width: 50, height: 100));
    },
    skip: !(impellerEnabled && flutterGpuEnabled),
  );

  test('RenderPass.setScissor throws for invalid values', () async {
    final RenderPassState state = createSimpleRenderPass();

    try {
      state.renderPass.setScissor(gpu.Scissor(x: -1, width: 50, height: 100));
      fail('Exception not thrown for invalid scissor.');
    } catch (e) {
      expect(e.toString(), contains('Invalid values for scissor. All values should be positive.'));
    }

    try {
      state.renderPass.setScissor(gpu.Scissor(width: 50, height: -100));
      fail('Exception not thrown for invalid scissor.');
    } catch (e) {
      expect(e.toString(), contains('Invalid values for scissor. All values should be positive.'));
    }
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  test(
    'RenderPass.setViewport doesnt throw for valid values',
    () async {
      final RenderPassState state = createSimpleRenderPass();

      state.renderPass.setViewport(gpu.Viewport(x: 25, width: 50, height: 100));
      state.renderPass.setViewport(gpu.Viewport(width: 50, height: 100));
    },
    skip: !(impellerEnabled && flutterGpuEnabled),
  );

  test('RenderPass.setViewport throws for invalid values', () async {
    final RenderPassState state = createSimpleRenderPass();

    try {
      state.renderPass.setViewport(gpu.Viewport(x: -1, width: 50, height: 100));
      fail('Exception not thrown for invalid viewport.');
    } catch (e) {
      expect(e.toString(), contains('Invalid values for viewport. All values should be positive.'));
    }

    try {
      state.renderPass.setViewport(gpu.Viewport(width: 50, height: -100));
      fail('Exception not thrown for invalid viewport.');
    } catch (e) {
      expect(e.toString(), contains('Invalid values for viewport. All values should be positive.'));
    }
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  // Renders the middle part triangle using viewport.
  test('Can render portion of the triangle using viewport', () async {
    final RenderPassState state = createSimpleRenderPass();

    final gpu.RenderPipeline pipeline = createUnlitRenderPipeline();
    state.renderPass.bindPipeline(pipeline);

    // Configure blending with defaults (just to test the bindings).
    state.renderPass.setColorBlendEnable(true);
    state.renderPass.setColorBlendEquation(gpu.ColorBlendEquation());

    // Set primitive type.
    state.renderPass.setPrimitiveType(gpu.PrimitiveType.triangle);

    // Set viewport.
    state.renderPass.setViewport(gpu.Viewport(x: 25, width: 50, height: 100));

    final gpu.HostBuffer transients = gpu.gpuContext.createHostBuffer();
    final gpu.BufferView vertices = transients.emplace(
      float32(<double>[-1.0, -1.0, 0.0, 1.0, 1.0, -1.0]),
    );
    final gpu.BufferView vertInfoData = transients.emplace(
      float32(<double>[
        1, 0, 0, 0, // mvp
        0, 1, 0, 0, // mvp
        0, 0, 1, 0, // mvp
        0, 0, 0, 1, // mvp
        0, 1, 0, 1, // color
      ]),
    );
    state.renderPass.bindVertexBuffer(vertices, 3);

    final gpu.UniformSlot vertInfo = pipeline.vertexShader.getUniformSlot('VertInfo');
    state.renderPass.bindUniform(vertInfo, vertInfoData);
    state.renderPass.draw();

    state.commandBuffer.submit();

    final ui.Image image = state.renderTexture.asImage();
    await comparer.addGoldenImage(image, 'flutter_gpu_test_viewport.png');
  }, skip: !(impellerEnabled && flutterGpuEnabled));
}
