// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer' as developer;
import 'dart:io' show File, Platform;
import 'dart:typed_data';
import 'dart:ui';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' as vms;
import 'package:vm_service/vm_service_io.dart';

import '../impeller_enabled.dart';

Future<void> _performReload(String assetKey) async {
  final developer.ServiceProtocolInfo info = await developer.Service.getInfo();
  vms.VmService? vmService;

  try {
    if (info.serverUri == null) {
      fail('This test must not be run with --disable-vm-service.');
    }

    vmService = await vmServiceConnectUri(
      'ws://localhost:${info.serverUri!.port}${info.serverUri!.path}ws',
    );
    final vms.VM vm = await vmService.getVM();

    expect(vm.isolates!.isNotEmpty, true);
    for (final vms.IsolateRef isolateRef in vm.isolates!) {
      final vms.Response response = await vmService.callServiceExtension(
        'ext.ui.window.reinitializeShader',
        isolateId: isolateRef.id,
        args: <String, Object>{'assetKey': assetKey},
      );
      expect(response.type == 'Success', true);
    }
  } finally {
    await vmService?.dispose();
  }
}

void main() {
  test('simple iplr shader can be re-initialized', () async {
    if (impellerEnabled) {
      // Needs https://github.com/flutter/flutter/issues/129659
      return;
    }
    FragmentShader? shader;
    try {
      final FragmentProgram program = await FragmentProgram.fromAsset('functions.frag.iplr');
      shader = program.fragmentShader()..setFloat(0, 1.0);
      _use(shader);
      await _performReload('functions.frag.iplr');
    } finally {
      shader?.dispose();
    }
  });

  test('reorder uniforms', () async {
    if (impellerEnabled) {
      // Needs https://github.com/flutter/flutter/issues/129659
      return;
    }
    final testAssetName =
        'test_reorder_uniforms_${DateTime.now().millisecondsSinceEpoch}.frag.iplr';
    final String buildDir = Platform.environment['FLUTTER_BUILD_DIRECTORY']!;
    final String assetsDir = path.join(buildDir, 'gen/flutter/lib/ui/assets');
    final String shaderSrcA = path.join(assetsDir, 'uniforms.frag.iplr');
    final String shaderSrcB = path.join(assetsDir, 'uniforms_reordered.frag.iplr');
    final String shaderSrcC = path.join(assetsDir, testAssetName);

    final fileC = File(shaderSrcC);
    final Uint8List sourceA = File(shaderSrcA).readAsBytesSync();
    final Uint8List sourceB = File(shaderSrcB).readAsBytesSync();

    fileC.writeAsBytesSync(sourceA, flush: true);

    try {
      final FragmentProgram program = await FragmentProgram.fromAsset(testAssetName);
      final FragmentShader shader = program.fragmentShader();
      final UniformFloatSlot slot = shader.getUniformFloat('iVec2Uniform');
      expect(slot.shaderIndex, 1);

      fileC.writeAsBytesSync(sourceB, flush: true);
      await _performReload(testAssetName);
      expect(slot.shaderIndex, 5);
    } finally {
      if (fileC.existsSync()) {
        fileC.deleteSync();
      }
    }
  });

  test('insert uniforms', () async {
    if (impellerEnabled) {
      // Needs https://github.com/flutter/flutter/issues/129659
      return;
    }
    final testAssetName = 'test_insert_uniforms_${DateTime.now().millisecondsSinceEpoch}.frag.iplr';
    final String buildDir = Platform.environment['FLUTTER_BUILD_DIRECTORY']!;
    final String assetsDir = path.join(buildDir, 'gen/flutter/lib/ui/assets');
    final String shaderSrcA = path.join(assetsDir, 'uniforms.frag.iplr');
    final String shaderSrcB = path.join(assetsDir, 'uniforms_inserted.frag.iplr');
    final String shaderSrcC = path.join(assetsDir, testAssetName);

    final fileC = File(shaderSrcC);
    final Uint8List sourceA = File(shaderSrcA).readAsBytesSync();
    final Uint8List sourceB = File(shaderSrcB).readAsBytesSync();

    fileC.writeAsBytesSync(sourceA, flush: true);

    try {
      final FragmentProgram program = await FragmentProgram.fromAsset(testAssetName);
      final FragmentShader shader = program.fragmentShader();
      final UniformFloatSlot slot = shader.getUniformFloat('iMat2Uniform', 3);
      expect(slot.shaderIndex, 6);

      fileC.writeAsBytesSync(sourceB, flush: true);
      await _performReload(testAssetName);
      expect(slot.shaderIndex, 7);
      // Make sure there is no crash here.
      slot.set(1.0);
    } finally {
      if (fileC.existsSync()) {
        fileC.deleteSync();
      }
    }
  });

  test('rename uniforms', () async {
    if (impellerEnabled) {
      // Needs https://github.com/flutter/flutter/issues/129659
      return;
    }
    final testAssetName = 'test_rename_uniforms_${DateTime.now().millisecondsSinceEpoch}.frag.iplr';
    final String buildDir = Platform.environment['FLUTTER_BUILD_DIRECTORY']!;
    final String assetsDir = path.join(buildDir, 'gen/flutter/lib/ui/assets');
    final String shaderSrcA = path.join(assetsDir, 'uniforms.frag.iplr');
    final String shaderSrcB = path.join(assetsDir, 'uniforms_renamed.frag.iplr');
    final String shaderSrcC = path.join(assetsDir, testAssetName);

    final fileC = File(shaderSrcC);
    final Uint8List sourceA = File(shaderSrcA).readAsBytesSync();
    final Uint8List sourceB = File(shaderSrcB).readAsBytesSync();

    fileC.writeAsBytesSync(sourceA, flush: true);

    try {
      final FragmentProgram program = await FragmentProgram.fromAsset(testAssetName);
      final FragmentShader shader = program.fragmentShader();
      final UniformFloatSlot slotA = shader.getUniformFloat('iFloatUniform');
      slotA.set(1.0);

      fileC.writeAsBytesSync(sourceB, flush: true);
      await _performReload(testAssetName);

      final UniformFloatSlot slotB = shader.getUniformFloat('iFloatUniformRenamed');
      // Make sure this doesn't break.
      slotB.set(0.0);
    } finally {
      if (fileC.existsSync()) {
        fileC.deleteSync();
      }
    }
  });

  test('reorder samplers', () async {
    if (impellerEnabled) {
      // Needs https://github.com/flutter/flutter/issues/129659
      return;
    }
    final testAssetName =
        'test_reorder_samplers_${DateTime.now().millisecondsSinceEpoch}.frag.iplr';
    final String buildDir = Platform.environment['FLUTTER_BUILD_DIRECTORY']!;
    final String assetsDir = path.join(buildDir, 'gen/flutter/lib/ui/assets');
    final String shaderSrcA = path.join(assetsDir, 'double_sampler.frag.iplr');
    final String shaderSrcB = path.join(assetsDir, 'double_sampler_swapped.frag.iplr');
    final String shaderSrcC = path.join(assetsDir, testAssetName);

    final fileC = File(shaderSrcC);
    final Uint8List sourceA = File(shaderSrcA).readAsBytesSync();
    final Uint8List sourceB = File(shaderSrcB).readAsBytesSync();

    fileC.writeAsBytesSync(sourceA, flush: true);

    try {
      final FragmentProgram program = await FragmentProgram.fromAsset(testAssetName);
      final FragmentShader shader = program.fragmentShader();
      final ImageSamplerSlot slot = shader.getImageSampler('tex_a');
      expect(slot.shaderIndex, 0);

      fileC.writeAsBytesSync(sourceB, flush: true);
      await _performReload(testAssetName);
      expect(slot.shaderIndex, 1);
    } finally {
      if (fileC.existsSync()) {
        fileC.deleteSync();
      }
    }
  });
}

void _use(Shader shader) {}
