// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter GPU shader hot reload tests.
// The flutter_gpu package is located at //flutter/impeller/lib/gpu.

// ignore_for_file: avoid_relative_lib_imports

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

import '../../lib/gpu/lib/gpu.dart' as gpu;

import 'impeller_enabled.dart';

ByteData float32(List<double> values) {
  return Float32List.fromList(values).buffer.asByteData();
}

// Fetches a bundled asset's raw bytes through the asset platform channel.
// `ShaderLibrary.fromBytes`/`reinitializeFromBytes` take bytes the caller has
// already fetched, so the tests resolve a fixture's bytes the same way an
// asset load would and feed them in directly.
Future<ByteData> loadAssetBytes(String assetKey) {
  final Uint8List encodedKey = utf8.encode(Uri(path: Uri.encodeFull(assetKey)).path);
  final result = Completer<ByteData>();
  PlatformDispatcher.instance.sendPlatformMessage(
    'flutter/assets',
    encodedKey.buffer.asByteData(),
    (ByteData? data) {
      if (data == null) {
        result.completeError(Exception('Asset "$assetKey" not found.'));
        return;
      }
      result.complete(data);
    },
  );
  return result.future;
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
    final gpu.ShaderLibrary? a = await gpu.ShaderLibrary.fromAsset('test.shaderbundle');
    final gpu.ShaderLibrary? b = await gpu.ShaderLibrary.fromAsset('test.shaderbundle');
    expect(a, isNotNull);
    expect(identical(a, b), isTrue);
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  // A load failure comes back through the returned Future rather than as a
  // synchronous throw, so callers can uniformly `await` the loader.
  test('ShaderLibrary.fromAsset surfaces load failure through the Future', () async {
    final Future<gpu.ShaderLibrary?> future = gpu.ShaderLibrary.fromAsset(
      'does_not_exist.shaderbundle',
    );
    await expectLater(future, throwsA(isA<Exception>()));
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
    final gpu.ShaderLibrary library = (await gpu.ShaderLibrary.fromAsset('test_alt.shaderbundle'))!;
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
    final gpu.ShaderLibrary library = (await gpu.ShaderLibrary.fromAsset('test.shaderbundle'))!;
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
    final gpu.ShaderLibrary library = (await gpu.ShaderLibrary.fromAsset('test.shaderbundle'))!;
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
    final gpu.ShaderLibrary library = (await gpu.ShaderLibrary.fromAsset('test.shaderbundle'))!;
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

  // `fromBytes` loads a shader bundle handed in directly as bytes, rather than
  // resolved from the asset manifest like `fromAsset`. The bytes feed the same
  // parse path, so a library loaded this way yields usable shaders.
  test('ShaderLibrary.fromBytes loads a usable library from bundle bytes', () async {
    final ByteData bytes = await loadAssetBytes('test.shaderbundle');
    final gpu.ShaderLibrary library = (await gpu.ShaderLibrary.fromBytes(bytes))!;
    final gpu.Shader? vertex = library['UnlitVertex'];
    final gpu.Shader? fragment = library['UnlitFragment'];
    expect(vertex, isNotNull);
    expect(fragment, isNotNull);
    // The shaders register into a usable pipeline.
    gpu.gpuContext.createRenderPipeline(vertex!, fragment!);
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  // Bytes that are not a parseable shader bundle fail through the returned
  // Future, the same way `fromAsset` reports a bad bundle.
  test('ShaderLibrary.fromBytes surfaces a parse failure through the Future', () async {
    final ByteData garbage = Uint8List.fromList(<int>[0, 1, 2, 3]).buffer.asByteData();
    await expectLater(gpu.ShaderLibrary.fromBytes(garbage), throwsA(isA<Exception>()));
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  // The bytes counterpart to the `debugReinitializeFromAsset` reload test: a
  // `fromBytes` library has no asset path to re-fetch, so it refreshes in place
  // from a new set of bytes. Reloading a bundle whose `UnlitFragment` source
  // changed (but whose `UnlitVertex` did not) preserves the library and shader
  // identities and marks only the changed fragment dirty.
  test('reinitializeFromBytes reparses in place and marks only changed shaders dirty', () async {
    final ByteData bytes = await loadAssetBytes('test.shaderbundle');
    final gpu.ShaderLibrary library = (await gpu.ShaderLibrary.fromBytes(bytes))!;
    final gpu.Shader vertex = library['UnlitVertex']!;
    final gpu.Shader fragment = library['UnlitFragment']!;
    gpu.gpuContext.createRenderPipeline(vertex, fragment);
    expect(vertex.debugIsDirty, isFalse);
    expect(fragment.debugIsDirty, isFalse);

    // test_reload.shaderbundle shares the same vertex source but a different
    // fragment source.
    final ByteData reloadBytes = await loadAssetBytes('test_reload.shaderbundle');
    final String? error = library.reinitializeFromBytes(reloadBytes);
    expect(error, isNull);
    expect(identical(library['UnlitVertex'], vertex), isTrue);
    expect(identical(library['UnlitFragment'], fragment), isTrue);
    expect(vertex.debugIsDirty, isFalse, reason: 'unchanged vertex should stay clean');
    expect(fragment.debugIsDirty, isTrue, reason: 'changed fragment should be dirty');
  }, skip: !(impellerEnabled && flutterGpuEnabled));

  // After an in-place reload from bytes, pipelines built with the refreshed
  // shaders must still draw. Exercises the dirty-bit eviction path
  // (`Shader::RegisterSync`) through the bytes reload entry point.
  test('reinitializeFromBytes evicts and re-registers shader functions cleanly', () async {
    final ByteData bytes = await loadAssetBytes('test.shaderbundle');
    final gpu.ShaderLibrary library = (await gpu.ShaderLibrary.fromBytes(bytes))!;
    final gpu.Shader vertex = library['UnlitVertex']!;
    final gpu.Shader fragment = library['UnlitFragment']!;

    final gpu.RenderPipeline before = gpu.gpuContext.createRenderPipeline(vertex, fragment);
    drawUnlitTriangle(createSimpleRenderPass(), before);

    final ByteData reloadBytes = await loadAssetBytes('test_reload.shaderbundle');
    library.reinitializeFromBytes(reloadBytes);
    expect(identical(library['UnlitVertex'], vertex), isTrue);
    expect(identical(library['UnlitFragment'], fragment), isTrue);

    final gpu.RenderPipeline after = gpu.gpuContext.createRenderPipeline(vertex, fragment);
    drawUnlitTriangle(createSimpleRenderPass(), after);
    expect(fragment.debugIsDirty, isFalse, reason: 'rebuild should re-register and clean');
  }, skip: !(impellerEnabled && flutterGpuEnabled));
}
