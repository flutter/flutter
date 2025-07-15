// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This script takes a json file that comes from the `debugJsonOutput` of an
// `EngineScene` object and generates a function that builds a scene with the
// same dimensions and layering. This makes it easier to take a complex scene
// rendered by an app and whittle it down to a minimal test case.

import 'dart:convert';
import 'dart:io';

// A bunch of visually unique colors to cycle through.
const List<String> colorStrings = [
  '0xFF7090da',
  '0xFF9cb835',
  '0xFF7c64d4',
  '0xFF5fc250',
  '0xFFc853be',
  '0xFF4e8d2b',
  '0xFFdb3f80',
  '0xFF54bd7b',
  '0xFFd2404e',
  '0xFF53c4ad',
  '0xFFd34a2a',
  '0xFF46aed7',
  '0xFFdc7a2d',
  '0xFF6561a8',
  '0xFFc0ab39',
  '0xFFa44c8c',
  '0xFF408147',
  '0xFFd18dce',
  '0xFF707822',
  '0xFFae4462',
  '0xFF308870',
  '0xFFd99a37',
  '0xFF935168',
  '0xFF9eb46b',
  '0xFFe1808a',
  '0xFF627037',
  '0xFFda815c',
  '0xFF8e6c2b',
  '0xFF9f4f30',
  '0xFFd4a66f',
];
int colorIndex = 0;

String getNextColor() {
  final colorString = colorStrings[colorIndex];
  colorIndex++;
  colorIndex %= colorStrings.length;
  return colorString;
}

String getColorAsString() {
  return 'const ui.Color(${getNextColor()})';
}

String offsetAsString(Object? offset) {
  offset as Map<String, Object?>?;
  offset!;
  final num x = offset['x']! as num;
  final num y = offset['y']! as num;
  if (x == 0 && y == 0) {
    return 'ui.Offset.zero';
  }
  return 'const ui.Offset($x, $y)';
}

String rRectAsString(Object? rRect) {
  rRect as Map<String, Object?>?;
  rRect!;
  return 'ui.RRect.fromLTRBAndCorners('
      '${rRect['left']}, '
      '${rRect['top']}, '
      '${rRect['right']}, '
      '${rRect['bottom']}, '
      'topLeft: const ui.Radius.elliptical(${rRect['tlRadiusX']}, ${rRect['tlRadiusY']}), '
      'topRight: const ui.Radius.elliptical(${rRect['trRadiusX']}, ${rRect['trRadiusY']}), '
      'bottomRight: const ui.Radius.elliptical(${rRect['brRadiusX']}, ${rRect['brRadiusY']}), '
      'bottomLeft: const ui.Radius.elliptical(${rRect['blRadiusX']}, ${rRect['blRadiusY']}))';
}

String rectAsString(Object? rect) {
  rect as Map<String, Object?>?;
  rect!;
  final num left = rect['left']! as num;
  final num top = rect['top']! as num;
  final num right = rect['right']! as num;
  final num bottom = rect['bottom']! as num;

  if (left == 0 && top == 0 && right == 0 && bottom == 0) {
    return 'ui.Rect.zero';
  }
  return 'const ui.Rect.fromLTRB($left, $top, $right, $bottom)';
}

void emitShaderMaskOperation(Map<String, Object?> operation, String indent) {
  // TODO(jacksongardner): implement
  throw UnimplementedError();
}

void emitTransformOperation(Map<String, Object?> operation, String indent) {
  final matrixValues = operation['matrix']! as List<Object?>;
  print('${indent}builder.pushTransform(Float64List.fromList([${matrixValues.join(', ')}]));');
}

void emitOpacityOperation(Map<String, Object?> operation, String indent) {
  final offset = operation['offset']! as Map<String, Object?>;
  print('${indent}builder.pushOpacity(${operation['alpha']}, offset: ${offsetAsString(offset)});');
}

void emitOffsetOperation(Map<String, Object?> operation, String indent) {
  final offset = operation['offset']! as Map<String, Object?>;
  print('${indent}builder.pushOffset(${offset['x']}, ${offset['y']});');
}

void emitImageFilterOperation(Map<String, Object?> operation, String indent) {
  // TODO(jacksongardner): implement
  throw UnimplementedError();
}

void emitColorFilterOperation(Map<String, Object?> operation, String indent) {
  // TODO(jacksongardner): implement
  throw UnimplementedError();
}

void emitClipRRectOperation(Map<String, Object?> operation, String indent) {
  print(
    '${indent}builder.pushClipRRect(${rRectAsString(operation['rrect'])}, clipBehavior: ui.Clip.${operation['clip']});',
  );
}

void emitClipRectOperation(Map<String, Object?> operation, String indent) {
  print(
    '${indent}builder.pushClipRect(${rectAsString(operation['rect'])}, clipBehavior: ui.Clip.${operation['clip']});',
  );
}

void emitClipPathOperation(Map<String, Object?> operation, String indent) {
  print(
    '${indent}builder.pushClipPath(ui.Path()..addRect(${rectAsString(operation['pathBounds'])}), clipBehavior: ui.Clip.${operation['clip']});',
  );
}

void emitBackdropFilterOperation(Map<String, Object?> operation, String indent) {
  // TODO(jacksongardner): implement
  throw UnimplementedError();
}

void emitOperation(Object? operation, String indent) {
  operation as Map<String, Object?>?;
  operation!;
  switch (operation['type']) {
    case 'backdropFilter':
      emitBackdropFilterOperation(operation, indent);
    case 'clipPath':
      emitClipPathOperation(operation, indent);
    case 'clipRect':
      emitClipRectOperation(operation, indent);
    case 'clipRRect':
      emitClipRRectOperation(operation, indent);
    case 'colorFilter':
      emitColorFilterOperation(operation, indent);
    case 'imageFilter':
      emitImageFilterOperation(operation, indent);
    case 'offset':
      emitOffsetOperation(operation, indent);
    case 'opacity':
      emitOpacityOperation(operation, indent);
    case 'transform':
      emitTransformOperation(operation, indent);
    case 'shaderMask':
      emitShaderMaskOperation(operation, indent);
    default:
      throw ArgumentError('invalid operation type: ${operation['type']}');
  }
}

void emitLayer(Map<String, Object?> command, String indent) {
  final layer = command['layer']! as Map<String, Object?>;
  print('$indent{');
  final String innerIndent = '  $indent';
  emitOperation(layer['operation'], innerIndent);
  emitCommands(layer['commands'], innerIndent);
  print('${innerIndent}builder.pop();');
  print('$indent}');
}

void emitPlatformView(Map<String, Object?> command, String indent) {
  final localBounds = command['localBounds']! as Map<String, Object?>;
  final left = localBounds['left']! as double;
  final top = localBounds['top']! as double;
  final right = localBounds['right']! as double;
  final bottom = localBounds['bottom']! as double;
  print(
    '${indent}builder.addPlatformView(1, offset: const ui.Offset($left, $top), width: ${right - left}, height: ${bottom - top});',
  );
}

void emitPicture(Map<String, Object?> command, String indent) {
  print(
    '${indent}builder.addPicture(${offsetAsString(command['offset'])}, drawPicture(${rectAsString(command['localBounds'])}, ${getColorAsString()}));',
  );
}

void emitCommands(Object? commands, String indent) {
  commands as List<Object?>?;
  commands!;
  for (final Object? command in commands) {
    command as Map<String, Object?>?;
    command!;
    switch (command['type']) {
      case 'picture':
        emitPicture(command, indent);
      case 'platformView':
        emitPlatformView(command, indent);
      case 'layer':
        emitLayer(command, indent);
    }
  }
}

int main(List<String> args) {
  if (args.length != 1) {
    stderr.write('Usage: dart generate_scene_test.dart <path_to_json>.\n');
    return 1;
  }

  final jsonFile = File(args[0]);
  if (!jsonFile.existsSync()) {
    stderr.write('Json file at path ${jsonFile.path} not found.\n');
  }

  final fileString = jsonFile.readAsStringSync();
  final sceneJson = jsonDecode(fileString) as Map<String, Object?>;
  final rootLayer = sceneJson['rootLayer']! as Map<String, Object?>;
  print('''
// This file was generated from a JSON file using the `web_ui/dev/generate_scene_test.dart`.

import 'dart:typed_data';
import 'package:ui/ui.dart' as ui;

ui.Picture drawPicture(ui.Rect bounds, ui.Color color) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(bounds, ui.Paint()..color = color);
  return recorder.endRecording();
}

ui.Scene buildScene() {
  final ui.SceneBuilder builder = ui.SceneBuilder();''');
  emitCommands(rootLayer['commands'], '  ');
  print('''

  return builder.build();
}''');
  return 0;
}
