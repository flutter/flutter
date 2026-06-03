// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter GPU shader hot reload tests.
// The flutter_gpu package is located at //flutter/impeller/lib/gpu.

// ignore_for_file: avoid_relative_lib_imports

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

import '../../lib/gpu/lib/gpu.dart' as gpu;

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

class RenderPassState {
  RenderPassState(this.commandBuffer, this.renderPass);

  final gpu.CommandBuffer commandBuffer;
  final gpu.RenderPass renderPass;
}

RenderPassState createSimpleRenderPass() {
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
    gpu.ColorAttachment(texture: renderTexture),
    depthStencilAttachment: gpu.DepthStencilAttachment(texture: depthStencilTexture),
  );
  final gpu.RenderPass renderPass = commandBuffer.createRenderPass(renderTarget);
  return RenderPassState(commandBuffer, renderPass);
}

void drawUnlitTriangle(RenderPassState state, gpu.RenderPipeline pipeline) {
  state.renderPass.bindPipeline(pipeline);
  final gpu.HostBuffer transients = gpu.gpuContext.createHostBuffer();
  state.renderPass.bindVertexBuffer(
    transients.emplace(float32(<double>[-0.5, 0.5, 0.0, -0.5, 0.5, 0.5])),
  );
  state.renderPass.bindUniform(
    pipeline.vertexShader.getUniformSlot('VertInfo'),
    transients.emplace(unlitUBO(Matrix4.identity(), Vector4(0, 1, 0, 1))),
  );
  state.renderPass.draw(3);
  state.commandBuffer.submit();
}

void main() {
  // Repeated `fromAsset` calls for the same asset path return the same
  // `ShaderLibrary` instance. The cache backs hot reload: the
  // `reinitializeShaderLibrary` service extension looks the library up by
  // asset path and reloads into the existing instance.
  test('ShaderLibrary.fromAsset caches by asset path', () async {
    final gpu.ShaderLibrary? a = gpu.ShaderLibrary.fromAsset('test.shaderbundle');
    final gpu.ShaderLibrary? b = gpu.ShaderLibrary.fromAsset('test.shaderbundle');
    expect(a, isNotNull);
    expect(identical(a, b), isTrue);
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  // `reinitialize` with an asset that hasn't been loaded yet must no-op.
  // The next `fromAsset` will pick up the fresh bytes on its own.
  test('ShaderLibrary.reinitialize is a no-op for an unknown asset key', () async {
    expect(
      () => gpu.ShaderLibrary.reinitialize('never_loaded_asset.shaderbundle'),
      returnsNormally,
    );
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  // Directly exercises the Shader dirty-bit lifecycle (Shader::IsDirty /
  // SetClean): freshly parsed shaders start dirty, and registering them with
  // a pipeline clears the bit. Uses test_alt.shaderbundle, which no other
  // test in this file loads, so the bit reflects a fresh load.
  test('shaders start dirty and are cleaned by registration', () async {
    final gpu.ShaderLibrary library = gpu.ShaderLibrary.fromAsset('test_alt.shaderbundle')!;
    final gpu.Shader vertex = library['UnlitVertex']!;
    final gpu.Shader fragment = library['UnlitFragment']!;
    expect(vertex.debugIsDirty, isTrue, reason: 'freshly parsed shaders start dirty');
    expect(fragment.debugIsDirty, isTrue, reason: 'freshly parsed shaders start dirty');

    gpu.gpuContext.createRenderPipeline(vertex, fragment);
    expect(vertex.debugIsDirty, isFalse, reason: 'registration clears the dirty bit');
    expect(fragment.debugIsDirty, isFalse, reason: 'registration clears the dirty bit');
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  // A shader bundle is the unit of asset distribution: a one-shader edit
  // ships a whole new bundle. `Shader::ResetFrom` dedupes by code-byte
  // comparison so unchanged shaders stay clean across reload. Reloading
  // identical bytes must leave every shader clean.
  test('reinitialize with unchanged bytes leaves shaders clean', () async {
    final gpu.ShaderLibrary library = gpu.ShaderLibrary.fromAsset('test.shaderbundle')!;
    final gpu.Shader vertex = library['UnlitVertex']!;
    final gpu.Shader fragment = library['UnlitFragment']!;
    // Force registration so the dirty bit is observable as false before reload.
    gpu.gpuContext.createRenderPipeline(vertex, fragment);
    expect(vertex.debugIsDirty, isFalse);
    expect(fragment.debugIsDirty, isFalse);

    gpu.ShaderLibrary.reinitialize('test.shaderbundle');
    expect(vertex.debugIsDirty, isFalse, reason: 'identical bytes should not flip dirty');
    expect(fragment.debugIsDirty, isFalse, reason: 'identical bytes should not flip dirty');
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  // Reloading a bundle whose `UnlitFragment` source changed (but whose
  // `UnlitVertex` source did not) must mark only the fragment dirty. This is
  // the other half of the `Shader::ResetFrom` dedupe: unchanged shaders stay
  // clean, changed shaders flip dirty so the next pipeline build evicts and
  // re-registers them.
  test('reinitialize marks only changed shaders dirty', () async {
    final gpu.ShaderLibrary library = gpu.ShaderLibrary.fromAsset('test.shaderbundle')!;
    final gpu.Shader vertex = library['UnlitVertex']!;
    final gpu.Shader fragment = library['UnlitFragment']!;
    gpu.gpuContext.createRenderPipeline(vertex, fragment);
    expect(vertex.debugIsDirty, isFalse);
    expect(fragment.debugIsDirty, isFalse);

    // test_reload.shaderbundle shares the same vertex source but a different
    // fragment source.
    final String? error = library.debugReinitializeFromAsset('test_reload.shaderbundle');
    expect(error, isNull);
    expect(identical(library['UnlitVertex'], vertex), isTrue);
    expect(identical(library['UnlitFragment'], fragment), isTrue);
    expect(vertex.debugIsDirty, isFalse, reason: 'unchanged vertex should stay clean');
    expect(fragment.debugIsDirty, isTrue, reason: 'changed fragment should be dirty');
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  // After reloading a shader bundle in place, pipelines built with the
  // freshly-fetched shaders must still draw correctly. Exercises the
  // dirty-bit + eviction path in `Shader::RegisterSync`: a dirty registered
  // function runs `UnregisterFunction` + `RemovePipelinesWithEntryPoint`
  // before re-registering.
  test('reinitialize evicts and re-registers shader functions cleanly', () async {
    final gpu.ShaderLibrary library = gpu.ShaderLibrary.fromAsset('test.shaderbundle')!;
    final gpu.Shader vertex = library['UnlitVertex']!;
    final gpu.Shader fragment = library['UnlitFragment']!;

    final gpu.RenderPipeline before = gpu.gpuContext.createRenderPipeline(vertex, fragment);
    drawUnlitTriangle(createSimpleRenderPass(), before);

    // Reload with a changed fragment so the eviction path actually runs, then
    // rebuild and draw. Identity of the library and shaders is preserved.
    library.debugReinitializeFromAsset('test_reload.shaderbundle');
    expect(identical(library['UnlitVertex'], vertex), isTrue);
    expect(identical(library['UnlitFragment'], fragment), isTrue);

    final gpu.RenderPipeline after = gpu.gpuContext.createRenderPipeline(vertex, fragment);
    drawUnlitTriangle(createSimpleRenderPass(), after);
    expect(fragment.debugIsDirty, isFalse, reason: 'rebuild should re-register and clean');
  }, skip: !(impellerEnabled && flutterGpuEnabled));
}
