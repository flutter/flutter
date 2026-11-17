// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:vector_math/vector_math.dart' show Vector4;

// Uses the engine's lib/ui/fixtures/shaders test.shaderbundle. A compute pass
// writes initially zero vertices, then a render pass consumes them. CPU-generated
// vertices cannot make this pass. Displaying the image also exercises the GTK
// embedder's backing stores; the native runner can snapshot the GTK widget.
Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  final report = <String, Object?>{'pid': pid, 'dispatch_tested': false};
  try {
    final context = gpu.gpuContext;
    report['supports_compute'] = context.supportsCompute;
    report['max_workgroup_invocations'] = context.maxComputeWorkgroupInvocations;
    report['max_shared_memory_bytes'] = context.maxComputeSharedMemorySizeInBytes;
    report['max_workgroup_size'] = [
      context.maxComputeWorkgroupSize.x,
      context.maxComputeWorkgroupSize.y,
      context.maxComputeWorkgroupSize.z,
    ];
    report['max_workgroup_count'] = [
      context.maxComputeWorkgroupCount.x,
      context.maxComputeWorkgroupCount.y,
      context.maxComputeWorkgroupCount.z,
    ];
    report['create_compute_pass_rejected'] = false;
    final library = (await gpu.ShaderLibrary.fromAsset('test.shaderbundle'))!;
    final pipeline = context.createComputePipeline(library['ComputeTriangle']!);
    final vertices = context.createDeviceBufferWithCopy(ByteData(3 * 2 * 4));
    final view = gpu.BufferView(vertices, offsetInBytes: 0, lengthInBytes: vertices.sizeInBytes);
    final host = context.createHostBuffer();
    final commands = context.createCommandBuffer();
    final compute = commands.createComputePass();
    compute.bindPipeline(pipeline);
    compute.bindUniform(
      pipeline.shader.getUniformSlot('TriangleInfo'),
      host.emplace(Float32List.fromList([1, 0, 0, 0]).buffer.asByteData()),
    );
    compute.bindStorageBuffer(pipeline.shader.getStorageBufferSlot('Vertices'), view);
    compute.dispatch(1);
    final texture = context.createTexture(gpu.StorageMode.devicePrivate, 100, 100);
    final render = commands.createRenderPass(
      gpu.RenderTarget.singleColor(
        gpu.ColorAttachment(texture: texture, clearValue: Vector4(1, 0, 0, 1)),
      ),
    );
    final graphics = context.createRenderPipeline(
      library['UnlitVertex']!,
      library['UnlitFragment']!,
    );
    render.bindPipeline(graphics);
    render.bindVertexBuffer(view);
    render.bindUniform(
      graphics.vertexShader.getUniformSlot('VertInfo'),
      host.emplace(
        Float32List.fromList([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 1]).buffer
            .asByteData(),
      ),
    );
    render.draw(3);
    final completion = Completer<void>();
    commands.submit(
      completionCallback: (success) {
        if (success) {
          completion.complete();
        } else {
          completion.completeError(StateError('Compute/render submission failed'));
        }
      },
    );
    await completion.future;
    final image = texture.asImage();
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final samples = <int>[];
    for (final (x, y) in [(1, 1), (98, 1), (1, 98), (98, 98), (50, 50)]) {
      samples.add(bytes.getUint32((y * 100 + x) * 4));
    }
    report['pixels_rgba'] = samples;
    report['dispatch_tested'] = true;
    report['compute_pixels_passed'] = samples.every((pixel) => pixel == 0x00ff00ff);
    Widget content = RawImage(image: image, fit: BoxFit.fill);
    if (arguments.contains('--pixel-buffer-texture')) {
      final id = await const MethodChannel('compute-probe/pixels').invokeMethod<int>('register');
      if (id == null || id < 0) throw StateError('Pixel-buffer texture registration failed');
      content = Texture(textureId: id, filterQuality: FilterQuality.none);
      report['pixel_buffer_texture_tested'] = true;
    }
    runApp(Directionality(textDirection: ui.TextDirection.ltr, child: content));
    final frame = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => frame.complete());
    await frame.future;
    // Allow native presentation/snapshot callbacks to observe the computed image.
    await Future<void>.delayed(const Duration(milliseconds: 500));
  } catch (error, stack) {
    report['error'] = '$error';
    report['stack'] = '$stack';
    runApp(const SizedBox());
  }
  final output = Platform.environment['COMPUTE_PROBE_OUTPUT'];
  if (output != null) {
    final file = File('$output.tmp');
    await file.writeAsString(jsonEncode(report), flush: true);
    await file.rename(output);
  }
  print('COMPUTE_PROBE ${jsonEncode(report)}');
}
