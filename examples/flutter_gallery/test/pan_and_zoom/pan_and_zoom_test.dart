import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gallery/demo/pan_and_zoom_demo.dart';

Offset getOffsetNext(Offset offset, Offset focalPointScene, Offset focalPointSceneNext) {
  return Offset(
    offset.dx + focalPointScene.dx - focalPointSceneNext.dx,
    offset.dy + focalPointScene.dy - focalPointSceneNext.dy,
  );
}

void main() {
  const Size SCREEN_SIZE = Size(411.4, 774.9);

  test('Origin scale 1.0', () {
    const Offset focalPoint = Offset.zero;
    const double rotation = 0.0;
    final Offset sceneOffset = BoardInteractionState.fromScreen(
      Offset(SCREEN_SIZE.width / 2, SCREEN_SIZE.height / 2),
      const Offset(0, 0),
      1.0,
      rotation,
      SCREEN_SIZE,
      focalPoint,
    );
    expect(sceneOffset, const Offset(0,0));
  });

  test('Origin scale 2.0', () {
    const Offset focalPoint = Offset.zero;
    const double rotation = 0.0;
    final Offset sceneOffset = BoardInteractionState.fromScreen(
      Offset(SCREEN_SIZE.width / 2, SCREEN_SIZE.height / 2),
      const Offset(0, 0),
      2.0,
      rotation,
      SCREEN_SIZE,
      focalPoint,
    );
    expect(sceneOffset, const Offset(0, 0));
  });

  test('Origin scale 0.8', () {
    const Offset focalPoint = Offset.zero;
    const double rotation = 0.0;
    final Offset sceneOffset = BoardInteractionState.fromScreen(
      Offset(SCREEN_SIZE.width / 2, SCREEN_SIZE.height / 2),
      const Offset(0, 0),
      0.8,
      rotation,
      SCREEN_SIZE,
      focalPoint,
    );
    expect(sceneOffset, const Offset(0, 0));
  });

  test('SP off origin scale 1.0', () {
    const Offset focalPoint = Offset.zero;
    const double rotation = 0.0;
    final Offset sceneOffset = BoardInteractionState.fromScreen(
      Offset(SCREEN_SIZE.width / 2 + 100, SCREEN_SIZE.height / 2 + 100),
      const Offset(0, 0),
      1.0,
      rotation,
      SCREEN_SIZE,
      focalPoint,
    );
    expect(sceneOffset, const Offset(100, 100));
  });

  test('SP off origin, scale 2.0', () {
    const Offset focalPoint = Offset.zero;
    const double rotation = 0.0;
    final Offset sceneOffset = BoardInteractionState.fromScreen(
      Offset(SCREEN_SIZE.width / 2 + 100, SCREEN_SIZE.height / 2 + 100),
      const Offset(0, 0),
      2.0,
      rotation,
      SCREEN_SIZE,
      focalPoint,
    );
    expect(sceneOffset, const Offset(50, 50));
  });

  test('SP off origin, translated, scale 2.0', () {
    const Offset focalPoint = Offset.zero;
    const double rotation = 0.0;
    final Offset sceneOffset = BoardInteractionState.fromScreen(
      Offset(SCREEN_SIZE.width / 2 + 100, SCREEN_SIZE.height / 2 + 100),
      const Offset(-25, -25),
      2.0,
      rotation,
      SCREEN_SIZE,
      focalPoint,
    );
    expect(sceneOffset, const Offset(75, 75));
  });

  test('SP off origin, translated, scale 0.5', () {
    const Offset focalPoint = Offset.zero;
    const double rotation = 0.0;
    final Offset sceneOffset = BoardInteractionState.fromScreen(
      Offset(SCREEN_SIZE.width / 2 + 100, SCREEN_SIZE.height / 2 + 100),
      const Offset(-25, -25),
      0.5,
      rotation,
      SCREEN_SIZE,
      focalPoint,
    );
    expect(sceneOffset, const Offset(225, 225));
  });

  test('SP off origin unevenly, translated, scale 0.5', () {
    const Offset focalPoint = Offset.zero;
    const double rotation = 0.0;
    final Offset sceneOffset = BoardInteractionState.fromScreen(
      Offset(SCREEN_SIZE.width / 2 + 11, SCREEN_SIZE.height / 2 + 6),
      const Offset(-25, -25),
      0.5,
      rotation,
      SCREEN_SIZE,
      focalPoint,
    );
    expect(sceneOffset, const Offset(47, 37));
  });

  test('SP on origin, translated unevenly, scale 0.5', () {
    const Offset focalPoint = Offset.zero;
    const double rotation = 0.0;
    final Offset sceneOffset = BoardInteractionState.fromScreen(
      Offset(SCREEN_SIZE.width / 2, SCREEN_SIZE.height / 2),
      const Offset(-16, -18),
      0.5,
      rotation,
      SCREEN_SIZE,
      focalPoint,
    );
    expect(sceneOffset, const Offset(16, 18));
  });

  test('Slightly off origin unevenly, scale 0.5', () {
    const Offset focalPoint = Offset.zero;
    const double rotation = 0.0;
    final Offset sceneOffset = BoardInteractionState.fromScreen(
      Offset(SCREEN_SIZE.width / 2 + 11, SCREEN_SIZE.height / 2 + 6),
      const Offset(5, 6),
      0.5,
      rotation,
      SCREEN_SIZE,
      focalPoint,
    );
    expect(sceneOffset.dx, closeTo(17, .1));
    expect(sceneOffset.dy, closeTo(6, .1));
  });

  test('Real, no rotation', () {
    const Offset focalPoint = Offset.zero;
    const double rotation = 0.0;
    final Offset sceneOffset = BoardInteractionState.fromScreen(
      Offset(SCREEN_SIZE.width / 2 + 12.6, SCREEN_SIZE.height / 2 - 8.35),
      const Offset(55.6, 76.1), // * 0.8 = -44.48, -60.88
      0.8,
      rotation,
      SCREEN_SIZE,
      focalPoint,
    );
    // translation * scale = -44.48, -60.88
    // + offset from center of screen = -31.88 , -69.23
    // / scale = -39.85, -86.5375
    expect(sceneOffset.dx, closeTo(-39.85, .1));
    expect(sceneOffset.dy, closeTo(-86.5375, .1));
  });

  test('Tapping on the origin with scale and translation', () {
    const Offset focalPoint = Offset.zero;
    const double rotation = 0.0;
    final Offset sceneOffset = BoardInteractionState.fromScreen(
      Offset(SCREEN_SIZE.width / 2 - 80, SCREEN_SIZE.height / 2 - 80),
      const Offset(-100, -100),
      0.8,
      rotation,
      SCREEN_SIZE,
      focalPoint,
    );
    expect(sceneOffset.dx, closeTo(0, .1));
    expect(sceneOffset.dy, closeTo(0, .1));
  });

  test('SP off origin, translated, scale 2.0, rotated 180deg', () {
    const Offset focalPoint = Offset.zero;
    const double rotation = math.pi;
    final Offset sceneOffset = BoardInteractionState.fromScreen(
      Offset(SCREEN_SIZE.width / 2 + 100, SCREEN_SIZE.height / 2 + 100),
      const Offset(-25, -25),
      2.0,
      rotation,
      SCREEN_SIZE,
      focalPoint,
    );
    expect(sceneOffset.dx, closeTo(-75, .1));
    expect(sceneOffset.dy, closeTo(-75, .1));
  });

  test('SP off origin, translated, scale 2.0, rotated 90deg', () {
    const Offset focalPoint = Offset.zero;
    const double rotation = math.pi / 2;
    final Offset sceneOffset = BoardInteractionState.fromScreen(
      Offset(SCREEN_SIZE.width / 2 + 100, SCREEN_SIZE.height / 2 + 100),
      const Offset(-25, -25),
      2.0,
      rotation,
      SCREEN_SIZE,
      focalPoint,
    );
    expect(sceneOffset.dx, closeTo(-75, .1));
    expect(sceneOffset.dy, closeTo(75, .1));
  });

  test('Origin, rotated 90deg with focalPoint', () {
    const Offset focalPoint = Offset(100, 100);
    const double rotation = math.pi / 2;
    final Offset sceneOffset = BoardInteractionState.fromScreen(
      Offset(SCREEN_SIZE.width / 2, SCREEN_SIZE.height / 2),
      const Offset(0, 0),
      1.0,
      rotation,
      SCREEN_SIZE,
      focalPoint,
    );
    expect(sceneOffset.dx, closeTo(200, .1));
    expect(sceneOffset.dy, closeTo(0, .1));
  });

  test('SP off origin, rotated 90deg with focalPoint', () {
    const Offset focalPoint = Offset(100, 100);
    const double rotation = math.pi / 2;
    final Offset sceneOffset = BoardInteractionState.fromScreen(
      Offset(SCREEN_SIZE.width / 2 - 10, SCREEN_SIZE.height / 2 - 20),
      const Offset(0, 0),
      1.0,
      rotation,
      SCREEN_SIZE,
      focalPoint,
    );
    expect(sceneOffset.dx, closeTo(220, .1));
    expect(sceneOffset.dy, closeTo(-10, .1));
  });
}
