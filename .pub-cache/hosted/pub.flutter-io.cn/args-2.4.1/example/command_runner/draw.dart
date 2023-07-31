// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:args/command_runner.dart';

void main(List<String> args) async {
  final runner = CommandRunner<String>('draw', 'Draws shapes')
    ..addCommand(SquareCommand())
    ..addCommand(CircleCommand())
    ..addCommand(TriangleCommand());
  runner.argParser.addOption('char', help: 'The character to use for drawing');
  final output = await runner.run(args);
  print(output);
}

class SquareCommand extends Command<String> {
  SquareCommand() {
    argParser.addOption('size', help: 'Size of the square');
  }

  @override
  String get name => 'square';

  @override
  String get description => 'Draws a square';

  @override
  List<String> get aliases => ['s'];

  @override
  FutureOr<String>? run() {
    final size = int.parse(argResults?['size'] ?? '20');
    final char = (globalResults?['char'] as String?)?[0] ?? '#';
    return draw(size, size, char, (x, y) => true);
  }
}

class CircleCommand extends Command<String> {
  CircleCommand() {
    argParser.addOption('radius', help: 'Radius of the circle');
  }

  @override
  String get name => 'circle';

  @override
  String get description => 'Draws a circle';

  @override
  List<String> get aliases => ['c'];

  @override
  FutureOr<String>? run() {
    final size = 2 * int.parse(argResults?['radius'] ?? '10');
    final char = (globalResults?['char'] as String?)?[0] ?? '#';
    return draw(size, size, char, (x, y) => x * x + y * y < 1);
  }
}

class TriangleCommand extends Command<String> {
  TriangleCommand() {
    addSubcommand(EquilateralTriangleCommand());
    addSubcommand(IsoscelesTriangleCommand());
  }

  @override
  String get name => 'triangle';

  @override
  String get description => 'Draws a triangle';

  @override
  List<String> get aliases => ['t'];
}

class EquilateralTriangleCommand extends Command<String> {
  EquilateralTriangleCommand() {
    argParser.addOption('size', help: 'Size of the triangle');
  }

  @override
  String get name => 'equilateral';

  @override
  String get description => 'Draws an equilateral triangle';

  @override
  List<String> get aliases => ['e'];

  @override
  FutureOr<String>? run() {
    final size = int.parse(argResults?['size'] ?? '20');
    final char = (globalResults?['char'] as String?)?[0] ?? '#';
    return drawTriangle(size, size * sqrt(3) ~/ 2, char);
  }
}

class IsoscelesTriangleCommand extends Command<String> {
  IsoscelesTriangleCommand() {
    argParser.addOption('width', help: 'Width of the triangle');
    argParser.addOption('height', help: 'Height of the triangle');
  }

  @override
  String get name => 'isosceles';

  @override
  String get description => 'Draws an isosceles triangle';

  @override
  List<String> get aliases => ['i'];

  @override
  FutureOr<String>? run() {
    final width = int.parse(argResults?['width'] ?? '50');
    final height = int.parse(argResults?['height'] ?? '10');
    final char = (globalResults?['char'] as String?)?[0] ?? '#';
    return drawTriangle(width, height, char);
  }
}

String draw(
    int width, int height, String char, bool Function(double, double) pixel) {
  final out = StringBuffer();
  for (var y = 0; y <= height; ++y) {
    final ty = 2 * y / height - 1;
    for (var x = 0; x <= width; ++x) {
      final tx = 2 * x / width - 1;
      out.write(pixel(tx, ty) ? char : ' ');
    }
    out.write('\n');
  }
  return out.toString();
}

String drawTriangle(int width, int height, String char) {
  return draw(width, height, char, (x, y) => x.abs() <= (1 + y) / 2);
}
