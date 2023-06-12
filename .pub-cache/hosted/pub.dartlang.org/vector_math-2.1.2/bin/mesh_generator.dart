// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:convert';
import 'package:vector_math/vector_math_geometry.dart';

typedef GenerateFunction = MeshGeometry? Function(List<String> args);

MeshGeometry? generateCube(List<String> args) {
  if (args.length != 3) {
    return null;
  }
  final width = double.parse(args[0]);
  final height = double.parse(args[1]);
  final depth = double.parse(args[2]);
  final generator = CubeGenerator();
  return generator.createCube(width, height, depth);
}

MeshGeometry? generateSphere(List<String> args) {
  if (args.length != 1) {
    return null;
  }
  final radius = double.parse(args[0]);
  final generator = SphereGenerator();
  return generator.createSphere(radius);
}

MeshGeometry? generateCircle(List<String> args) {
  if (args.length != 1) {
    return null;
  }
  final radius = double.parse(args[0]);
  final generator = CircleGenerator();
  return generator.createCircle(radius);
}

MeshGeometry? generateCylinder(List<String> args) {
  if (args.length != 3) {
    return null;
  }
  final topRadius = double.parse(args[0]);
  final bottomRadius = double.parse(args[1]);
  final height = double.parse(args[2]);
  final generator = CylinderGenerator();
  return generator.createCylinder(topRadius, bottomRadius, height);
}

MeshGeometry? generateRing(List<String> args) {
  if (args.length != 2) {
    return null;
  }
  final innerRadius = double.parse(args[0]);
  final outerRadius = double.parse(args[1]);
  final generator = RingGenerator();
  return generator.createRing(innerRadius, outerRadius);
}

Map<String, GenerateFunction> generators = <String, GenerateFunction>{
  'cube': generateCube,
  'sphere': generateSphere,
  'circle': generateCircle,
  'cylinder': generateCylinder,
  'ring': generateRing
};

void main(List<String> args) {
  final fixedArgs = List<String>.unmodifiable(args);

  if (fixedArgs.isEmpty) {
    print('mesh_generator.dart <type> [<arg0> ... <argN>]');
    print('');
    print('<type> = cube, sphere, cylinder');
    print('mesh_generator.dart cube width height depth');
    print('mesh_generator.dart sphere radius');
    print('mesh_generator.dart circle radius');
    print('mesh_generator.dart cylinder topRadius bottomRadius height');
    print('mesh_generator.dart ring innerRadius outerRadius');
    print('');
    return;
  }
  final type = fixedArgs.removeAt(0);
  final generator = generators[type];
  if (generator == null) {
    print('Could not find generator for $type');
    return;
  }
  final geometry = generator(fixedArgs);
  if (geometry == null) {
    print('Error generating geometry for $type');
    return;
  }
  print(jsonEncode(geometry));
}
