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

void main() async {
  test('simple shader renders correctly', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset(
      'functions.frag.iplr',
    );
    final Shader shader = program.shader(
      floatUniforms: Float32List.fromList(<double>[1]),
    );
    _expectShaderRendersGreen(shader);
  });

  test('blue-green image renders green', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset(
      'blue_green_sampler.frag.iplr',
    );
    final Image blueGreenImage = await _createBlueGreenImage();
    final ImageShader imageShader = ImageShader(
        blueGreenImage, TileMode.clamp, TileMode.clamp, _identityMatrix);
    final Shader shader = program.shader(
      floatUniforms: Float32List.fromList(<double>[]),
      samplerUniforms: <ImageShader>[imageShader],
    );
    await _expectShaderRendersGreen(shader);
  });

  test('shader with uniforms renders correctly', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset(
      'uniforms.frag.iplr',
    );

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

  test('shader with array uniforms renders correctly', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset(
      'uniform_arrays.frag.iplr',
    );

    final List<double> floatArray = List<double>.generate(
      24, (int i) => i.toDouble(),
    );
    final Shader shader = program.shader(
      floatUniforms: Float32List.fromList(<double>[
        ...floatArray,
    ]));

    await _expectShaderRendersGreen(shader);
  });

  test('The ink_sparkle shader is accepted', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset(
      'ink_sparkle.frag.iplr',
    );
    final Shader shader = program.shader(
      floatUniforms: Float32List(32),
    );

    await _imageByteDataFromShader(shader: shader);

    // Testing that no exceptions are thrown. Tests that the ink_sparkle shader
    // produces the correct pixels are in the framework.
  });

  test('Uniforms are sorted correctly', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset(
      'uniforms_sorted.frag.iplr',
    );

    // The shader will not render green if the compiler doesn't keep the
    // uniforms in the right order.
    final Shader shader = program.shader(
      floatUniforms: Float32List.fromList(
        List<double>.generate(32, (int i) => i.toDouble()),
      ),
    );

    await _expectShaderRendersGreen(shader);
  });

  test('fromAsset throws an exception on invalid assetKey', () async {
    bool throws = false;
    try {
      await FragmentProgram.fromAsset(
        '<invalid>',
      );
    } catch (e) {
      throws = true;
    }
    expect(throws, equals(true));
  });

  test('fromAsset throws an exception on invalid data', () async {
    bool throws = false;
    try {
      await FragmentProgram.fromAsset(
        'DashInNooglerHat.jpg',
      );
    } catch (e) {
      throws = true;
    }
    expect(throws, equals(true));
  });

  test('user defined functions do not redefine builtins', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset(
      'no_builtin_redefinition.frag.iplr',
    );
    final Shader shader = program.shader(
      floatUniforms: Float32List.fromList(<double>[1.0]),
    );
    await _expectShaderRendersGreen(shader);
  });

  test('fromAsset accepts a shader with no uniforms', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset(
      'no_uniforms.frag.iplr',
    );
    final Shader shader = program.shader();
    await _expectShaderRendersGreen(shader);
  });

  // Test all supported GLSL ops. See lib/spirv/lib/src/constants.dart
  final Map<String, FragmentProgram> iplrSupportedGLSLOpShaders = await _loadShaderAssets(
    path.join('supported_glsl_op_shaders', 'iplr'),
    '.iplr',
  );
  expect(iplrSupportedGLSLOpShaders.isNotEmpty, true);
  _expectIplrShadersRenderGreen(iplrSupportedGLSLOpShaders);

  // Test all supported instructions. See lib/spirv/lib/src/constants.dart
  final Map<String, FragmentProgram> iplrSupportedOpShaders = await _loadShaderAssets(
    path.join('supported_op_shaders', 'iplr'),
    '.iplr',
  );
  expect(iplrSupportedOpShaders.isNotEmpty, true);
  _expectIplrShadersRenderGreen(iplrSupportedOpShaders);

  test('Equality depends on floatUniforms', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset(
      'simple.frag.iplr',
    );
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

  test('Equality depends on data', () async {
    final FragmentProgram programA = await FragmentProgram.fromAsset(
      'simple.frag.iplr',
    );
    final FragmentProgram programB = await FragmentProgram.fromAsset(
      'uniforms.frag.iplr',
    );
    final Shader a = programA.shader();
    final Shader b = programB.shader();

    expect(a, notEquals(b));
    expect(a.hashCode, notEquals(b.hashCode));
  });
}

// Expect that all of the shaders in this folder render green.
// Keeping the outer loop of the test synchronous allows for easy printing
// of the file name within the test case.
void _expectIplrShadersRenderGreen(Map<String, FragmentProgram> shaders) {
  for (final String key in shaders.keys) {
    test('iplr $key renders green', () async {
      final FragmentProgram program = shaders[key]!;
      final Shader shader = program.shader(
        floatUniforms: Float32List.fromList(<double>[1]),
      );
      _expectShaderRendersGreen(shader);
    });
  }
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
Future<Map<String, FragmentProgram>> _loadShaderAssets(
    String leafFolderName,
    String ext,
  ) async {
  final Map<String, FragmentProgram> out = SplayTreeMap<String, FragmentProgram>();

  final Directory directory = shaderDirectory(leafFolderName);
  if (!directory.existsSync()) {
    return out;
  }

  await Future.forEach(
    directory
      .listSync()
      .where((FileSystemEntity entry) => path.extension(entry.path) == ext),
    (FileSystemEntity entry) async {
      final String key = path.basenameWithoutExtension(entry.path);
      out[key] = await FragmentProgram.fromAsset(
        path.basename(entry.path),
      );
    },
  );
  return out;
}

// Arbitrary, but needs to be greater than 1 for frag coord tests.
const int _shaderImageDimension = 4;

const Color _greenColor = Color(0xFF00FF00);

// Precision for checking uniform values.
const double epsilon = 0.5 / 255.0;

// Maps an int value from 0-255 to a double value of 0.0 to 1.0.
double toFloat(int v) => v.toDouble() / 255.0;

String toHexString(int color) => '#${color.toRadixString(16)}';

// 10x10 image where the left half is blue and the right half is
// green.
Future<Image> _createBlueGreenImage() async {
  const int length = 10;
  const int bytesPerPixel = 4;
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

final Float64List _identityMatrix = Float64List.fromList(<double>[
  1, 0, 0, 0,
  0, 1, 0, 0,
  0, 0, 1, 0,
  0, 0, 0, 1,
]);
