import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gallery/demo/pan_and_zoom_demo_transform_interaction.dart';

// TODO(justinmc): Do we care about comprehensive testing for example apps? I
// wrote these tests just to help myself during development. I can clean them up
// and add more if needed.
void main() {
  test('fromViewport: Origin identity matrix', () {
    final Offset sceneOffset = TransformInteractionState.fromViewport(
      const Offset(0, 0),
      Matrix4.identity(),
    );
    expect(sceneOffset, const Offset(0,0));
  });

  test('fromViewport: Origin scale 2.0', () {
    final Offset sceneOffset = TransformInteractionState.fromViewport(
      const Offset(0, 0),
      Matrix4.identity()..scale(2.0),
    );
    expect(sceneOffset, const Offset(0, 0));
  });

  test('fromViewport: Origin scale 0.8', () {
    final Offset sceneOffset = TransformInteractionState.fromViewport(
      const Offset(0, 0),
      Matrix4.identity()..scale(0.8),
    );
    expect(sceneOffset, const Offset(0, 0));
  });

  test('fromViewport: SP off origin identity matrix', () {
    final Offset sceneOffset = TransformInteractionState.fromViewport(
      const Offset(100, 100),
      Matrix4.identity(),
    );
    expect(sceneOffset, const Offset(100, 100));
  });

  test('fromViewport: SP off origin, scale 2.0', () {
    final Offset sceneOffset = TransformInteractionState.fromViewport(
      const Offset(100, 100),
      Matrix4.identity()..scale(2.0),
    );
    expect(sceneOffset, const Offset(50, 50));
  });

  test('fromViewport: SP off origin, translated, scale 2.0', () {
    final Offset sceneOffset = TransformInteractionState.fromViewport(
      const Offset(100, 100),
      Matrix4.identity()..scale(2.0)..translate(-25.0, -25.0),
    );
    expect(sceneOffset, const Offset(75, 75));
  });

  test('fromViewport: SP off origin, translated, scale 0.5', () {
    final Offset sceneOffset = TransformInteractionState.fromViewport(
      const Offset(100, 100),
      Matrix4.identity()..scale(0.5)..translate(-25.0, -25.0),
    );
    expect(sceneOffset, const Offset(225, 225));
  });

  test('fromViewport: SP off origin unevenly, translated, scale 0.5', () {
    final Offset sceneOffset = TransformInteractionState.fromViewport(
      const Offset(11, 6),
      Matrix4.identity()..scale(0.5)..translate(-25.0, -25.0),
    );
    expect(sceneOffset, const Offset(47, 37));
  });

  test('fromViewport: SP on origin, translated unevenly, scale 0.5', () {
    final Offset sceneOffset = TransformInteractionState.fromViewport(
      const Offset(0, 0),
      Matrix4.identity()..scale(0.5)..translate(-16.0, -18.0),
    );
    expect(sceneOffset, const Offset(16, 18));
  });

  test('fromViewport: Slightly off origin unevenly, scale 0.5', () {
    final Offset sceneOffset = TransformInteractionState.fromViewport(
      const Offset(11, 6),
      Matrix4.identity()..scale(0.5)..translate(5.0, 6.0),
    );
    expect(sceneOffset.dx, closeTo(17, .1));
    expect(sceneOffset.dy, closeTo(6, .1));
  });

  test('fromViewport: Real, no rotation', () {
    final Offset sceneOffset = TransformInteractionState.fromViewport(
      const Offset(12.6, -8.35),
      Matrix4.identity()..scale(0.8)..translate(55.6, 76.1), // * 0.8 = -44.48, -60.88
    );
    // translation * scale = -44.48, -60.88
    // + offset from center of screen = -31.88 , -69.23
    // / scale = -39.85, -86.5375
    expect(sceneOffset.dx, closeTo(-39.85, .1));
    expect(sceneOffset.dy, closeTo(-86.5375, .1));
  });

  test('fromViewport: Tapping on the origin with scale and translation', () {
    final Offset sceneOffset = TransformInteractionState.fromViewport(
      const Offset(-80, -80),
      Matrix4.identity()..scale(0.8)..translate(-100.0, -100.0),
    );
    expect(sceneOffset.dx, closeTo(0, .1));
    expect(sceneOffset.dy, closeTo(0, .1));
  });

  test('fromViewport: SP off origin, translated, scale 2.0, rotated 180deg', () {
    final Offset sceneOffset = TransformInteractionState.fromViewport(
      const Offset(100, 100),
      Matrix4.identity()..scale(2.0)..translate(-25.0, -25.0)..rotateZ(math.pi),
    );
    expect(sceneOffset.dx, closeTo(-75, .1));
    expect(sceneOffset.dy, closeTo(-75, .1));
  });

  test('fromViewport: SP off origin, translated, scale 2.0, rotated 90deg', () {
    final Offset sceneOffset = TransformInteractionState.fromViewport(
      const Offset(100, 100),
      Matrix4.identity()..scale(2.0)..translate(-25.0, -25.0)..rotateZ(-math.pi / 2),
    );
    expect(sceneOffset.dx, closeTo(-75, .1));
    expect(sceneOffset.dy, closeTo(75, .1));
  });
}
