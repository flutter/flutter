// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:litetest/litetest.dart';
import 'package:path/path.dart' as path;

import 'shader_test_file_utils.dart';

void main() {
  test('throws exception for invalid shader', () async {
    final ByteBuffer invalidBytes = Uint8List.fromList(<int>[1, 2, 3, 4, 5]).buffer;
    try {
      await FragmentProgram.compile(spirv: invalidBytes);
      fail('expected compile to throw an exception');
    } catch (_) {
    }
  });

  test('simple shader renders correctly', () async {
    final Uint8List shaderBytes = await spvFile('general_shaders', 'functions.frag.spirv').readAsBytes();
    final FragmentProgram program = await FragmentProgram.compile(
      spirv: shaderBytes.buffer,
    );
    final Shader shader = program.shader(
      floatUniforms: Float32List.fromList(<double>[1]),
    );
    _expectShaderRendersGreen(shader);
  });

  test('shader with functions renders green', () async {
    final ByteBuffer spirv = spvFile('general_shaders', 'functions.frag.spirv').readAsBytesSync().buffer;
    final FragmentProgram program = await FragmentProgram.compile(
      spirv: spirv,
    );
    final Shader shader = program.shader(
      floatUniforms: Float32List.fromList(<double>[1]),
    );
    _expectShaderRendersGreen(shader);
  });

  test('blue-green image renders green', () async {
    final ByteBuffer spirv = spvFile('general_shaders', 'blue_green_sampler.frag.spirv').readAsBytesSync().buffer;
    final FragmentProgram program = await FragmentProgram.compile(
      debugPrint: true,
      spirv: spirv,
    );
    final Image blueGreenImage = await _createBlueGreenImage();
    final ImageShader imageShader = ImageShader(
        blueGreenImage, TileMode.clamp, TileMode.clamp, _identityMatrix);
    final Shader shader = program.shader(
      samplerUniforms: <ImageShader>[imageShader],
    );
    await _expectShaderRendersGreen(shader);
  });

  test('shader with uniforms renders correctly', () async {
    final Uint8List shaderBytes = await spvFile('general_shaders', 'uniforms.frag.spirv').readAsBytes();
    final FragmentProgram program = await FragmentProgram.compile(spirv: shaderBytes.buffer);

    final Shader shader = program.shader(
        floatUniforms: Float32List.fromList(<double>[
      0.0, // iFloatUniform
      0.25, // iVec2Uniform.x
      0.75, // iVec2Uniform.y
      0.0, // iMat2Uniform[0][0]
      0.0, // iMat2Uniform[0][1]
      0.0, // iMat2Uniform[1][0]
      1.0, // iMat2Uniform[1][1]
    ]));

    final ByteData renderedBytes = (await _imageByteDataFromShader(
      shader: shader,
    ))!;

    expect(toFloat(renderedBytes.getUint8(0)), closeTo(0.0, epsilon));
    expect(toFloat(renderedBytes.getUint8(1)), closeTo(0.25, epsilon));
    expect(toFloat(renderedBytes.getUint8(2)), closeTo(0.75, epsilon));
    expect(toFloat(renderedBytes.getUint8(3)), closeTo(1.0, epsilon));
  });

  // Test all supported GLSL ops. See lib/spirv/lib/src/constants.dart
  final Map<String, ByteBuffer> supportedGLSLOpShaders =
      _loadSpv('supported_glsl_op_shaders');
  expect(supportedGLSLOpShaders.isNotEmpty, true);
  _expectShadersRenderGreen(supportedGLSLOpShaders);
  _expectShadersHaveOp(supportedGLSLOpShaders, true /* glsl ops */);

  // Test all supported instructions. See lib/spirv/lib/src/constants.dart
  final Map<String, ByteBuffer> supportedOpShaders =
      _loadSpv('supported_op_shaders');
  expect(supportedOpShaders.isNotEmpty, true);
  _expectShadersRenderGreen(supportedOpShaders);
  _expectShadersHaveOp(supportedOpShaders, false /* glsl ops */);

  test('equality depends on floatUniforms', () async {
    final ByteBuffer spirv = spvFile('general_shaders', 'simple.frag.spirv')
        .readAsBytesSync().buffer;
    final FragmentProgram program = await FragmentProgram.compile(spirv: spirv);
    final Float32List ones = Float32List.fromList(<double>[1]);
    final Float32List zeroes = Float32List.fromList(<double>[0]);

    {
      final Shader a = program.shader(floatUniforms: ones);
      final Shader b = program.shader(floatUniforms: ones);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    }

    {
      final Shader a = program.shader(floatUniforms: ones);
      final Shader b = program.shader(floatUniforms: zeroes);
      expect(a, notEquals(b));
      expect(a.hashCode, notEquals(b.hashCode));
    }
  });

  test('equality depends on spirv', () async {
    final ByteBuffer spirvA = spvFile('general_shaders', 'simple.frag.spirv')
        .readAsBytesSync().buffer;
    final ByteBuffer spirvB = spvFile('general_shaders', 'uniforms.frag.spirv')
        .readAsBytesSync().buffer;
    final FragmentProgram programA = await FragmentProgram.compile(spirv: spirvA);
    final FragmentProgram programB = await FragmentProgram.compile(spirv: spirvB);
    final Shader a = programA.shader();
    final Shader b = programB.shader();

    expect(a, notEquals(b));
    expect(a.hashCode, notEquals(b.hashCode));
  });

  test('Compilation does not create a Timer object', () async {
    final ByteBuffer spirvA = spvFile('general_shaders', 'simple.frag.spirv')
        .readAsBytesSync().buffer;
    bool createdTimer = false;
    final ZoneSpecification specification = ZoneSpecification(createTimer: (Zone self, ZoneDelegate parent, Zone zone, Duration duration, void Function() f) {
      createdTimer = true;
      return parent.createTimer(zone, duration, f);
    });
    await runZoned(() async {
       await FragmentProgram.compile(spirv: spirvA);
    }, zoneSpecification: specification);

    expect(createdTimer, false);
  });
}

// Expect that all of the spirv shaders in this folder render green.
// Keeping the outer loop of the test synchronous allows for easy printing
// of the file name within the test case.
void _expectShadersRenderGreen(Map<String, ByteBuffer> shaders) {
  for (final String key in shaders.keys) {
    test('$key renders green', () async {
      final FragmentProgram program = await FragmentProgram.compile(
        spirv: shaders[key]!,
      );
      final Shader shader = program.shader(
        floatUniforms: Float32List.fromList(<double>[1]),
      );
      _expectShaderRendersGreen(shader);
    });
  }
}

void _expectShadersHaveOp(Map<String, ByteBuffer> shaders, bool glsl) {
  for (final String key in shaders.keys) {
    test('$key contains opcode', () {
      _expectShaderHasOp(shaders[key]!, key, glsl);
    });
  }
}

const int _opExtInst = 12;

// Expects that a spirv shader has the op code identified by its file name.
void _expectShaderHasOp(ByteBuffer spirv, String filename, bool glsl) {
  final Uint32List words = spirv.asUint32List();
  final List<String> sections = filename.split('_');
  expect(sections.length, greaterThan(1));
  final int op = int.parse(sections.first);

  // skip the header
  int position = 5;

  bool found = false;
  while (position < words.length) {
    final int word = words[position];
    final int currentOpCode = word & 0xFFFF;
    if (glsl) {
      if (currentOpCode == _opExtInst && words[position + 4] == op) {
        found = true;
        break;
      }
    } else {
      if (currentOpCode == op) {
        found = true;
        break;
      }
    }
    final int advance = word >> 16;
    if (advance <= 0) {
      break;
    }
    position += advance;
  }

  expect(found, true);
}

// Expects that a spirv shader only outputs the color green.
Future<void> _expectShaderRendersGreen(Shader shader) async {
  final ByteData renderedBytes = (await _imageByteDataFromShader(
    shader: shader,
    imageDimension: _shaderImageDimension,
  ))!;
  for (final int color in renderedBytes.buffer.asUint32List()) {
    expect(toHexString(color), toHexString(_greenColor.value));
  }
}

Future<ByteData?> _imageByteDataFromShader({
  required Shader shader,
  int imageDimension = 100,
}) async {
  final PictureRecorder recorder = PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  final Paint paint = Paint()..shader = shader;
  canvas.drawPaint(paint);
  final Picture picture = recorder.endRecording();
  final Image image = await picture.toImage(
    imageDimension,
    imageDimension,
  );
  return image.toByteData();
}

// Loads the path and spirv content of the files at
// $FLUTTER_BUILD_DIRECTORY/gen/flutter/lib/spirv/test/$leafFolderName
// This is synchronous so that tests can be inside of a loop with
// the proper test name.
Map<String, ByteBuffer> _loadSpv(String leafFolderName) {
  final Map<String, ByteBuffer> out = SplayTreeMap<String, ByteBuffer>();

  final Directory directory = spvDirectory(leafFolderName);
  if (!directory.existsSync()) {
    return out;
  }

  directory
      .listSync()
      .where((FileSystemEntity entry) => path.extension(entry.path) == '.spirv')
      .forEach((FileSystemEntity entry) {
    final String key = path.basenameWithoutExtension(entry.path);
    out[key] = (entry as File).readAsBytesSync().buffer;
  });
  return out;
}

// Arbitrary, but needs to be greater than 1 for frag coord tests.
const int _shaderImageDimension = 4;

const Color _greenColor = Color(0xFF00FF00);
const Color _blueColor = Color(0xFF0000FF);

// Precision for checking uniform values.
const double epsilon = 0.5 / 255.0;

// Maps an int value from 0-255 to a double value of 0.0 to 1.0.
double toFloat(int v) => v.toDouble() / 255.0;

String toHexString(int color) => '#${color.toRadixString(16)}';

// 10x10 image where the left half is blue and the right half is
// green.
Future<Image> _createBlueGreenImage() async {
  final int length = 10;
  final int bytesPerPixel = 4;
  final Uint8List pixels = Uint8List(length * length * bytesPerPixel);
  int i = 0;
  for (int y = 0; y < length; y++) {
    for (int x = 0; x < length; x++) {
      if (x < length/2) {
        pixels[i+2] = 0xFF;  // blue channel
      } else {
        pixels[i+1] = 0xFF;  // green channel
      }
      pixels[i+3] = 0xFF;  // alpha channel
      i += bytesPerPixel;
    }
  }
  final ImageDescriptor descriptor = ImageDescriptor.raw(
    await ImmutableBuffer.fromUint8List(pixels),
    width: length,
    height: length,
    pixelFormat: PixelFormat.rgba8888,
  );
  final Codec codec = await descriptor.instantiateCodec();
  final FrameInfo frame = await codec.getNextFrame();
  return frame.image;
}

// A single uniform with value 1.
final Float32List _singleUniform = Float32List.fromList(<double>[1]);

final Float64List _identityMatrix = Float64List.fromList(<double>[
  1, 0, 0, 0,
  0, 1, 0, 0,
  0, 0, 1, 0,
  0, 0, 0, 1,
]);

