// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final RendererBinding binding = RenderingFlutterBinding.ensureInitialized();

  test('TextureBox registers with binding on attach', () {
    final textureBox = TextureBox(textureId: 42);
    final owner = PipelineOwner();

    // Before attach, texture should not be registered
    expect(binding.textureRegistry.containsKey(42), isFalse);

    // Attach the texture
    textureBox.attach(owner);
    expect(binding.textureRegistry[42], equals(textureBox));

    // Detach the texture
    textureBox.detach();
    expect(binding.textureRegistry.containsKey(42), isFalse);
  });

  test('TextureBox re-registers when textureId changes', () {
    final textureBox = TextureBox(textureId: 1);
    final owner = PipelineOwner();

    textureBox.attach(owner);
    expect(binding.textureRegistry[1], equals(textureBox));
    expect(binding.textureRegistry.containsKey(2), isFalse);

    // Change texture ID
    textureBox.textureId = 2;
    expect(binding.textureRegistry.containsKey(1), isFalse);
    expect(binding.textureRegistry[2], equals(textureBox));

    textureBox.detach();
    expect(binding.textureRegistry.containsKey(2), isFalse);
  });

  test('TextureBox is marked dirty when texture frame is available', () {
    final flutterView = FakeFlutterView(viewId: 1);
    final renderView = RenderView(view: flutterView);
    final owner = PipelineOwner()..rootNode = renderView;
    binding.rootPipelineOwner.adoptChild(owner);
    binding.addRenderView(renderView);
    renderView.prepareInitialFrame();

    // Create and attach a TextureBox
    final textureBox = TextureBox(textureId: 100);
    final container = RenderConstrainedBox(
      additionalConstraints: const BoxConstraints.tightFor(width: 100, height: 100),
      child: textureBox,
    );
    renderView.child = container;

    // Initial frame
    binding.handleBeginFrame(Duration.zero);
    binding.handleDrawFrame();

    expect(flutterView.renderedScenes, hasLength(1));

    // After initial frame, nothing is dirty
    binding.handleBeginFrame(Duration.zero);
    binding.handleDrawFrame();

    // No new frame rendered because nothing was dirty
    expect(flutterView.renderedScenes, hasLength(1));

    // Simulate texture frame availability notification
    binding.handleTextureFrameAvailable(100);

    // Now the texture should be marked as needing paint
    expect(owner.needsPaint, isTrue);

    // Next frame should render
    binding.handleBeginFrame(Duration.zero);
    binding.handleDrawFrame();

    expect(flutterView.renderedScenes, hasLength(2));

    // Cleanup
    renderView.child = null;
    binding.removeRenderView(renderView);
  });

  test('PipelineOwner.needsPaint reflects dirty state', () {
    final flutterView = FakeFlutterView(viewId: 1);
    final renderView = RenderView(view: flutterView);
    final owner = PipelineOwner()..rootNode = renderView;
    binding.rootPipelineOwner.adoptChild(owner);
    binding.addRenderView(renderView);
    renderView.prepareInitialFrame();

    // After prepareInitialFrame, the view needs paint
    expect(owner.needsPaint, isTrue);

    // After frame, nothing needs paint
    binding.handleBeginFrame(Duration.zero);
    binding.handleDrawFrame();
    expect(owner.needsPaint, isFalse);

    // Mark needs paint
    renderView.markNeedsPaint();
    expect(owner.needsPaint, isTrue);

    // After frame, nothing needs paint again
    binding.handleBeginFrame(Duration.zero);
    binding.handleDrawFrame();
    expect(owner.needsPaint, isFalse);

    binding.removeRenderView(renderView);
  });
}

class FakeFlutterView extends Fake implements FlutterView {
  FakeFlutterView({
    this.viewId = 100,
    this.devicePixelRatio = 2.5,
    this.physicalSize = const Size(400, 600),
    this.padding = FakeViewPadding.zero,
  });

  @override
  final int viewId;
  @override
  double devicePixelRatio;
  @override
  Size physicalSize;
  @override
  ViewConstraints get physicalConstraints => ViewConstraints.tight(physicalSize);
  @override
  ViewPadding padding;

  List<Scene> renderedScenes = <Scene>[];

  @override
  void render(Scene scene, {Size? size}) {
    renderedScenes.add(scene);
  }
}
