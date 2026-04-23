// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

int _nextViewId = 1;

void main() {
  final RendererBinding binding = RenderingFlutterBinding.ensureInitialized();

  _TextureScene buildScene({required int textureId}) {
    final flutterView = FakeFlutterView(viewId: _nextViewId++);
    final renderView = RenderView(view: flutterView);
    final owner = PipelineOwner()..rootNode = renderView;
    binding.rootPipelineOwner.adoptChild(owner);
    binding.addRenderView(renderView);
    renderView.prepareInitialFrame();

    final textureBox = TextureBox(textureId: textureId);
    renderView.child = RenderConstrainedBox(
      additionalConstraints: const BoxConstraints.tightFor(width: 100, height: 100),
      child: textureBox,
    );

    // Flush the initial frame so nothing is dirty.
    binding.handleBeginFrame(Duration.zero);
    binding.handleDrawFrame();

    return _TextureScene(flutterView, renderView, owner, textureBox);
  }

  void tearDownScene(RenderView renderView) {
    renderView.child = null;
    binding.removeRenderView(renderView);
  }

  test('TextureBox becomes dirty when its textureId fires', () {
    final _TextureScene scene = buildScene(textureId: 42);
    expect(scene.owner.needsPaint, isFalse);

    binding.handleTextureFrameAvailable(42);
    expect(scene.owner.needsPaint, isTrue);

    tearDownScene(scene.renderView);
  });

  test('TextureBox ignores frames for other textures', () {
    final _TextureScene scene = buildScene(textureId: 42);
    expect(scene.owner.needsPaint, isFalse);

    binding.handleTextureFrameAvailable(99);
    expect(scene.owner.needsPaint, isFalse);

    tearDownScene(scene.renderView);
  });

  test('Changing textureId re-targets the handler', () {
    final _TextureScene scene = buildScene(textureId: 1);
    scene.textureBox.textureId = 2;
    // Setting textureId marks the box for paint — drain that frame.
    binding.handleBeginFrame(Duration.zero);
    binding.handleDrawFrame();
    expect(scene.owner.needsPaint, isFalse);

    binding.handleTextureFrameAvailable(1);
    expect(scene.owner.needsPaint, isFalse);

    binding.handleTextureFrameAvailable(2);
    expect(scene.owner.needsPaint, isTrue);

    tearDownScene(scene.renderView);
  });

  test('Multiple TextureBoxes sharing an id are all dirtied', () {
    final _TextureScene scene1 = buildScene(textureId: 99);
    final _TextureScene scene2 = buildScene(textureId: 99);
    expect(scene1.owner.needsPaint, isFalse);
    expect(scene2.owner.needsPaint, isFalse);

    binding.handleTextureFrameAvailable(99);
    expect(scene1.owner.needsPaint, isTrue);
    expect(scene2.owner.needsPaint, isTrue);

    tearDownScene(scene1.renderView);
    tearDownScene(scene2.renderView);
  });

  test('handleTextureFrameAvailable triggers a rendered scene end-to-end', () {
    final _TextureScene scene = buildScene(textureId: 100);
    expect(scene.flutterView.renderedScenes, hasLength(1));

    binding.handleBeginFrame(Duration.zero);
    binding.handleDrawFrame();
    expect(scene.flutterView.renderedScenes, hasLength(1));

    binding.handleTextureFrameAvailable(100);
    expect(scene.owner.needsPaint, isTrue);

    binding.handleBeginFrame(Duration.zero);
    binding.handleDrawFrame();
    expect(scene.flutterView.renderedScenes, hasLength(2));

    tearDownScene(scene.renderView);
  });

  test('addTextureFrameAvailableHandler / removeTextureFrameAvailableHandler', () {
    final received = <int>[];
    void handler(int id) => received.add(id);

    binding.addTextureFrameAvailableHandler(handler);
    binding.handleTextureFrameAvailable(7);
    binding.handleTextureFrameAvailable(11);
    expect(received, <int>[7, 11]);

    binding.removeTextureFrameAvailableHandler(handler);
    binding.handleTextureFrameAvailable(13);
    expect(received, <int>[7, 11]);
  });

  test('PipelineOwner.needsPaint reflects dirty state', () {
    final flutterView = FakeFlutterView(viewId: _nextViewId++);
    final renderView = RenderView(view: flutterView);
    final owner = PipelineOwner()..rootNode = renderView;
    binding.rootPipelineOwner.adoptChild(owner);
    binding.addRenderView(renderView);
    renderView.prepareInitialFrame();

    expect(owner.needsPaint, isTrue);

    binding.handleBeginFrame(Duration.zero);
    binding.handleDrawFrame();
    expect(owner.needsPaint, isFalse);

    renderView.markNeedsPaint();
    expect(owner.needsPaint, isTrue);

    binding.handleBeginFrame(Duration.zero);
    binding.handleDrawFrame();
    expect(owner.needsPaint, isFalse);

    binding.removeRenderView(renderView);
  });
}

class _TextureScene {
  _TextureScene(this.flutterView, this.renderView, this.owner, this.textureBox);
  final FakeFlutterView flutterView;
  final RenderView renderView;
  final PipelineOwner owner;
  final TextureBox textureBox;
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
