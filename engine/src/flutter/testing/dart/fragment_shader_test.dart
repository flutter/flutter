// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert' as convert;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'goldens.dart';
import 'impeller_enabled.dart';
import 'shader_test_file_utils.dart';

void main() async {
  test('impellerc produces reasonable JSON encoded IPLR files', () async {
    final Directory directory = shaderDirectory('iplr-json');
    final Object? rawData = convert.json.decode(
      File(path.join(directory.path, 'ink_sparkle.frag.iplr')).readAsStringSync(),
    );

    expect(rawData is Map<String, Object?>, true);

    final data = rawData! as Map<String, Object?>;
    expect(data.keys.toList(), <String>['format_version', 'sksl']);
    expect(data['sksl'] is Map<String, Object?>, true);

    final skslData = data['sksl']! as Map<String, Object?>;
    expect(skslData['uniforms'] is List<Object?>, true);

    final Object? rawUniformData = (skslData['uniforms']! as List<Object?>)[0];

    expect(rawUniformData is Map<String, Object?>, true);

    final uniformData = rawUniformData! as Map<String, Object?>;

    expect(uniformData['location'] is int, true);
  });

  test('FragmentProgram objects are cached.', () async {
    final FragmentProgram programA = await FragmentProgram.fromAsset(
      'blue_green_sampler.frag.iplr',
    );
    final FragmentProgram programB = await FragmentProgram.fromAsset(
      'blue_green_sampler.frag.iplr',
    );

    expect(identical(programA, programB), true);
  });

  group('getUniformFloat slots', () {
    late FragmentShader shader;

    setUpAll(() async {
      final FragmentProgram program = await FragmentProgram.fromAsset('uniforms.frag.iplr');
      shader = program.fragmentShader();
    });

    _runSkiaTest('FragmentProgram uniform info', () async {
      final List<UniformFloatSlot> slots = [
        shader.getUniformFloat('iFloatUniform'),
        shader.getUniformFloat('iVec2Uniform', 0),
        shader.getUniformFloat('iVec2Uniform', 1),
        shader.getUniformFloat('iMat2Uniform', 0),
        shader.getUniformFloat('iMat2Uniform', 1),
        shader.getUniformFloat('iMat2Uniform', 2),
        shader.getUniformFloat('iMat2Uniform', 3),
      ];
      for (var i = 0; i < slots.length; ++i) {
        expect(slots[i].shaderIndex, equals(i));
      }
    });
  });

  group('FragmentShader uniforms', () {
    late Map<Type, FragmentShader> shaderMap;

    setUpAll(() async {
      shaderMap = {
        UniformFloatSlot: (await FragmentProgram.fromAsset(
          'float_uniform.frag.iplr',
        )).fragmentShader(),
        UniformVec2Slot: (await FragmentProgram.fromAsset(
          'vec2_uniform.frag.iplr',
        )).fragmentShader(),
        UniformVec3Slot: (await FragmentProgram.fromAsset(
          'vec3_uniform.frag.iplr',
        )).fragmentShader(),
        UniformVec4Slot: (await FragmentProgram.fromAsset(
          'vec4_uniform.frag.iplr',
        )).fragmentShader(),
        UniformArray<UniformFloatSlot>: (await FragmentProgram.fromAsset(
          'float_array_uniform.frag.iplr',
        )).fragmentShader(),
        UniformArray<UniformVec2Slot>: (await FragmentProgram.fromAsset(
          'vec2_array_uniform.frag.iplr',
        )).fragmentShader(),
        UniformArray<UniformVec3Slot>: (await FragmentProgram.fromAsset(
          'vec3_array_uniform.frag.iplr',
        )).fragmentShader(),
        UniformArray<UniformVec4Slot>: (await FragmentProgram.fromAsset(
          'vec4_array_uniform.frag.iplr',
        )).fragmentShader(),
      };
    });

    group('float', () {
      test('set using setUniformFloat', () async {
        final FragmentShader shader = shaderMap[UniformFloatSlot]!;
        const color = Color.fromARGB(255, 255, 0, 0);
        shader.setFloat(0, color.r);
        _expectShaderRendersColor(shader, color);
      });

      test('set using getUniformFloat', () async {
        final FragmentShader shader = shaderMap[UniformFloatSlot]!;
        const color = Color.fromARGB(255, 50, 0, 0);
        shader.getUniformFloat('color_r').set(color.r);
        _expectShaderRendersColor(shader, color);
      });

      test('getUniformFloat offset overflow', () async {
        final FragmentShader shader = shaderMap[UniformFloatSlot]!;
        expect(
          () => shader.getUniformFloat('color_r', 2),
          throwsA(
            isA<IndexError>().having(
              (e) => e.message,
              'message',
              contains('Index `2` out of bounds for `color_r`.'),
            ),
          ),
        );
      });

      test('getUniformFloat offset underflow', () async {
        final FragmentShader shader = shaderMap[UniformFloatSlot]!;
        expect(
          () => shader.getUniformFloat('color_r', -1),
          throwsA(
            isA<IndexError>().having(
              (e) => e.message,
              'message',
              contains('Index `-1` out of bounds for `color_r`.'),
            ),
          ),
        );
      });
    });
    group('vec2', () {
      test('set using setFloat', () async {
        final FragmentShader shader = shaderMap[UniformVec2Slot]!;
        const color = Color.fromARGB(255, 255, 255, 0);
        shader.setFloat(0, color.r);
        shader.setFloat(1, color.g);
        _expectShaderRendersColor(shader, color);
      });

      test('set using getUniformVec2', () async {
        final FragmentShader shader = shaderMap[UniformVec2Slot]!;
        const color = Color.fromARGB(255, 50, 50, 0);
        shader.getUniformVec2('color_rg').set(color.r, color.g);
        _expectShaderRendersColor(shader, color);
      });

      test('wrong datatype', () async {
        final FragmentShader shader = shaderMap[UniformVec3Slot]!;
        expect(
          () => shader.getUniformVec2('color_rgb'),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('`color_rgb` has size 3, not size 2.'),
            ),
          ),
        );
      });
    });
    group('vec3', () {
      test('set using setFloat', () async {
        final FragmentShader shader = shaderMap[UniformVec3Slot]!;
        const color = Color.fromARGB(255, 67, 42, 12);
        shader.setFloat(0, color.r);
        shader.setFloat(1, color.g);
        shader.setFloat(2, color.b);
        // Note: The original test also called getUniformVec3 after setFloat.
        // Assuming this was intentional to test idempotency or a specific interaction.
        shader.getUniformVec3('color_rgb').set(color.r, color.g, color.b);
        _expectShaderRendersColor(shader, color);
      });

      test('set using getUniformVec3', () async {
        final FragmentShader shader = shaderMap[UniformVec3Slot]!;
        const color = Color.fromARGB(255, 42, 67, 12);
        shader.getUniformVec3('color_rgb').set(color.r, color.g, color.b);
        _expectShaderRendersColor(shader, color);
      });

      test('wrong datatype', () async {
        final FragmentShader shader = shaderMap[UniformVec2Slot]!;
        expect(
          () => shader.getUniformVec3('color_rg'),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('`color_rg` has size 2, not size 3.'),
            ),
          ),
        );
      });
    });

    group('vec4', () {
      test('set using setFloat', () async {
        const color = Color.fromARGB(255, 67, 42, 12);
        final FragmentShader shader = shaderMap[UniformVec4Slot]!;
        shader.setFloat(0, color.r);
        shader.setFloat(1, color.g);
        shader.setFloat(2, color.b);
        shader.setFloat(3, color.a);
        _expectShaderRendersColor(shader, color);
      });

      test('set using getUniformFloat', () async {
        const color = Color.fromARGB(255, 12, 37, 27);
        final FragmentShader shader = shaderMap[UniformVec4Slot]!;
        shader.getUniformVec4('color_rgba').set(color.r, color.g, color.b, color.a);
        _expectShaderRendersColor(shader, color);
      });

      test('wrong datatype', () async {
        final FragmentShader shader = shaderMap[UniformVec3Slot]!;
        expect(
          () => shader.getUniformVec4('color_rgb'),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('`color_rgb` has size 3, not size 4.'),
            ),
          ),
        );
      });
    });

    group('float array', () {
      test('set using setFloat', () {
        const color = Color.fromARGB(255, 11, 22, 96);
        final FragmentShader shader = shaderMap[UniformArray<UniformFloatSlot>]!;
        shader.setFloat(0, color.r);
        shader.setFloat(1, color.g);
        shader.setFloat(2, color.b);
        shader.setFloat(3, color.a);
        _expectShaderRendersColor(shader, color);
      });

      test('set using getUniformFloatArray', () async {
        const color = Color.fromARGB(255, 96, 11, 22);
        final FragmentShader shader = shaderMap[UniformArray<UniformFloatSlot>]!;
        final UniformArray<UniformFloatSlot> colorRgba = shader.getUniformFloatArray('color_array');
        colorRgba[0].set(color.r);
        colorRgba[1].set(color.g);
        colorRgba[2].set(color.b);
        colorRgba[3].set(color.a);
        _expectShaderRendersColor(shader, color);
      });
    });

    group('vec2 array', () {
      test('set using setFloat', () async {
        const color = Color.fromARGB(255, 67, 42, 12);
        final FragmentShader shader = shaderMap[UniformArray<UniformVec2Slot>]!;
        shader.setFloat(0, color.r);
        shader.setFloat(1, color.g);
        shader.setFloat(2, color.b);
        shader.setFloat(3, color.a);
        _expectShaderRendersColor(shader, color);
      });

      test('set using getUniformVec2Array', () async {
        const color = Color.fromARGB(255, 1, 73, 26);
        final FragmentShader shader = shaderMap[UniformArray<UniformVec2Slot>]!;
        final UniformArray<UniformVec2Slot> colorRgba = shader.getUniformVec2Array('color_array');
        colorRgba[0].set(color.r, color.g);
        colorRgba[1].set(color.b, color.a);
        _expectShaderRendersColor(shader, color);
      });

      test('wrong datatype', () async {
        final FragmentShader shader = shaderMap[UniformVec3Slot]!;
        expect(
          () => shader.getUniformVec2Array('color_rgb'),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Uniform size (3) for "color_rgb" is not a multiple of 2.'),
            ),
          ),
        );
      });
    });

    group('vec3 array', () {
      test('set using setFloat', () async {
        const cpuColors = [Color.fromARGB(255, 67, 42, 12), Color.fromARGB(255, 11, 22, 96)];
        final FragmentShader shader = shaderMap[UniformArray<UniformVec3Slot>]!;
        shader.setFloat(0, 2);
        shader.setFloat(1, 2);
        shader.setFloat(2, cpuColors[0].r);
        shader.setFloat(3, cpuColors[0].g);
        shader.setFloat(4, cpuColors[0].b);
        shader.setFloat(5, cpuColors[1].r);
        shader.setFloat(6, cpuColors[1].g);
        shader.setFloat(7, cpuColors[1].b);
        _expectShaderRendersBarcode(shader, cpuColors);
      });

      test('set using getUniformVec3Array', () async {
        const cpuColors = [Color.fromARGB(255, 11, 22, 96), Color.fromARGB(255, 67, 42, 12)];
        final FragmentShader shader = shaderMap[UniformArray<UniformVec3Slot>]!;
        shader.getUniformVec2('u_size').set(2, 2);
        final UniformArray<UniformVec3Slot> gpuColors = shader.getUniformVec3Array('color_array');
        gpuColors[0].set(cpuColors[0].r, cpuColors[0].g, cpuColors[0].b);
        gpuColors[1].set(cpuColors[1].r, cpuColors[1].g, cpuColors[1].b);
        _expectShaderRendersBarcode(shader, cpuColors);
      });

      test('wrong datatype', () async {
        final FragmentShader shader = shaderMap[UniformVec4Slot]!;
        expect(
          () => shader.getUniformVec3Array('color_rgba'),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Uniform size (4) for "color_rgba" is not a multiple of 3.'),
            ),
          ),
        );
      });
    });

    group('vec4 array', () {
      test('set using setFloat', () async {
        const cpuColors = [Color.fromARGB(77, 67, 42, 12), Color.fromARGB(51, 11, 22, 96)];
        final FragmentShader shader = shaderMap[UniformArray<UniformVec4Slot>]!;
        // 'u_size'
        shader.setFloat(0, 2);
        shader.setFloat(1, 2);
        shader.setFloat(2, cpuColors[0].r);
        shader.setFloat(3, cpuColors[0].g);
        shader.setFloat(4, cpuColors[0].b);
        shader.setFloat(5, cpuColors[0].a);
        shader.setFloat(6, cpuColors[1].r);
        shader.setFloat(7, cpuColors[1].g);
        shader.setFloat(8, cpuColors[1].b);
        shader.setFloat(9, cpuColors[1].a);
        _expectShaderRendersBarcode(shader, cpuColors);
      });

      test('set using getUniformVec4Array', () async {
        const cpuColors = [Color.fromARGB(51, 11, 22, 96), Color.fromARGB(77, 67, 42, 12)];
        final FragmentShader shader = shaderMap[UniformArray<UniformVec4Slot>]!;
        shader.getUniformVec2('u_size').set(2, 2);
        final UniformArray<UniformVec4Slot> colors = shader.getUniformVec4Array('color_array');
        colors[0].set(cpuColors[0].r, cpuColors[0].g, cpuColors[0].b, cpuColors[0].a);
        colors[1].set(cpuColors[1].r, cpuColors[1].g, cpuColors[1].b, cpuColors[1].a);
        _expectShaderRendersBarcode(shader, cpuColors);
      });

      test('wrong datatype', () async {
        final FragmentShader shader = shaderMap[UniformVec3Slot]!;
        expect(
          () => shader.getUniformVec4Array('color_rgb'),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Uniform size (3) for "color_rgb" is not a multiple of 4.'),
            ),
          ),
        );
      });
    });

    group('all uniforms', () {
      late FragmentProgram program;
      late List<Color> cpuColors;
      final random = Random(1337);
      setUpAll(() async {
        program = await FragmentProgram.fromAsset('all_uniforms.frag.iplr');
      });

      setUp(() async {
        cpuColors = List<Color>.empty(growable: true);
        // uFloat
        cpuColors.add(Color.fromARGB(255, random.nextInt(255), 0, 0));
        // uVec2
        cpuColors.add(Color.fromARGB(255, random.nextInt(255), random.nextInt(255), 0));
        // uVec3
        cpuColors.add(
          Color.fromARGB(255, random.nextInt(255), random.nextInt(255), random.nextInt(255)),
        );
        // uVec4
        cpuColors.add(
          Color.fromARGB(
            random.nextInt(255),
            random.nextInt(255),
            random.nextInt(255),
            random.nextInt(255),
          ),
        );
        for (var i = 0; i < 10; ++i) {
          cpuColors.add(Color.fromARGB(255, random.nextInt(255), 0, 0));
        }

        for (var i = 0; i < 10; ++i) {
          cpuColors.add(Color.fromARGB(255, random.nextInt(255), random.nextInt(255), 0));
        }

        for (var i = 0; i < 10; ++i) {
          cpuColors.add(
            Color.fromARGB(255, random.nextInt(255), random.nextInt(255), random.nextInt(255)),
          );
        }
        for (var i = 0; i < 10; ++i) {
          cpuColors.add(
            Color.fromARGB(
              random.nextInt(255),
              random.nextInt(255),
              random.nextInt(255),
              random.nextInt(255),
            ),
          );
        }
      });

      test('set using setFloat', () async {
        final FragmentShader shader = program.fragmentShader();
        // uFloat
        shader.setFloat(0, cpuColors[0].r);
        //uVec2
        shader.setFloat(1, cpuColors[1].r);
        shader.setFloat(2, cpuColors[1].g);
        //uVec3
        shader.setFloat(3, cpuColors[2].r);
        shader.setFloat(4, cpuColors[2].g);
        shader.setFloat(5, cpuColors[2].b);
        //uVec4
        shader.setFloat(6, cpuColors[3].r);
        shader.setFloat(7, cpuColors[3].g);
        shader.setFloat(8, cpuColors[3].b);
        shader.setFloat(9, cpuColors[3].a);

        var shaderOffset = 10;
        var colorOffset = 4;

        for (var i = 0; i < 10; ++i) {
          shader.setFloat(shaderOffset++, cpuColors[colorOffset++].r);
        }
        for (var i = 0; i < 10; ++i) {
          shader.setFloat(shaderOffset++, cpuColors[colorOffset].r);
          shader.setFloat(shaderOffset++, cpuColors[colorOffset++].g);
        }
        for (var i = 0; i < 10; ++i) {
          shader.setFloat(shaderOffset++, cpuColors[colorOffset].r);
          shader.setFloat(shaderOffset++, cpuColors[colorOffset].g);
          shader.setFloat(shaderOffset++, cpuColors[colorOffset++].b);
        }
        for (var i = 0; i < 10; ++i) {
          shader.setFloat(shaderOffset++, cpuColors[colorOffset].r);
          shader.setFloat(shaderOffset++, cpuColors[colorOffset].g);
          shader.setFloat(shaderOffset++, cpuColors[colorOffset].b);
          shader.setFloat(shaderOffset++, cpuColors[colorOffset++].a);
        }
        _expectShaderRendersBarcode(shader, cpuColors);
      });

      test('set using getUniform*', () async {
        final FragmentShader shader = program.fragmentShader();
        shader.getUniformFloat('uFloat').set(cpuColors[0].r);
        shader.getUniformVec2('uVec2').set(cpuColors[1].r, cpuColors[1].g);
        shader.getUniformVec3('uVec3').set(cpuColors[2].r, cpuColors[2].g, cpuColors[2].b);
        shader
            .getUniformVec4('uVec4')
            .set(cpuColors[3].r, cpuColors[3].g, cpuColors[3].b, cpuColors[3].a);

        final UniformArray<UniformFloatSlot> floatArray = shader.getUniformFloatArray(
          'uFloatArray',
        );
        final UniformArray<UniformVec2Slot> vec2Array = shader.getUniformVec2Array('uVec2Array');
        final UniformArray<UniformVec3Slot> vec3Array = shader.getUniformVec3Array('uVec3Array');
        final UniformArray<UniformVec4Slot> vec4Array = shader.getUniformVec4Array('uVec4Array');

        var colorOffset = 4;

        for (var i = 0; i < 10; ++i) {
          floatArray[i].set(cpuColors[colorOffset++].r);
        }
        for (var i = 0; i < 10; ++i) {
          vec2Array[i].set(cpuColors[colorOffset].r, cpuColors[colorOffset].g);
          ++colorOffset;
        }
        for (var i = 0; i < 10; ++i) {
          vec3Array[i].set(
            cpuColors[colorOffset].r,
            cpuColors[colorOffset].g,
            cpuColors[colorOffset].b,
          );
          ++colorOffset;
        }
        for (var i = 0; i < 10; ++i) {
          vec4Array[i].set(
            cpuColors[colorOffset].r,
            cpuColors[colorOffset].g,
            cpuColors[colorOffset].b,
            cpuColors[colorOffset].a,
          );
          ++colorOffset;
        }
        _expectShaderRendersBarcode(shader, cpuColors);
      });
    });
  });

  test('FragmentProgram getImageSampler', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset('uniform_ordering.frag.iplr');
    final FragmentShader shader = program.fragmentShader();
    final Image blueGreenImage = await _createBlueGreenImage();
    final ImageSamplerSlot slot = shader.getImageSampler('u_texture');
    slot.set(blueGreenImage);
    expect(slot.shaderIndex, equals(0));
  });

  test('FragmentProgram getImageSampler unknown', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset('uniform_ordering.frag.iplr');
    final FragmentShader shader = program.fragmentShader();
    try {
      shader.getImageSampler('unknown');
      fail('Unreachable');
    } catch (e) {
      expect(e.toString(), contains('No uniform named "unknown".'));
    }
  });

  test('FragmentShader setSampler throws with out-of-bounds index', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset('blue_green_sampler.frag.iplr');
    final Image blueGreenImage = await _createBlueGreenImage();
    final FragmentShader fragmentShader = program.fragmentShader();

    try {
      fragmentShader.setImageSampler(1, blueGreenImage);
      fail('Unreachable');
    } catch (e) {
      expect(e, contains('Sampler index out of bounds'));
    } finally {
      fragmentShader.dispose();
      blueGreenImage.dispose();
    }
  });

  test(
    'FragmentShader with sampler asserts if sampler is missing when assigned to paint',
    () async {
      final FragmentProgram program = await FragmentProgram.fromAsset(
        'blue_green_sampler.frag.iplr',
      );
      final FragmentShader fragmentShader = program.fragmentShader();

      try {
        Paint().shader = fragmentShader;
        fail('Expected to throw');
      } catch (err) {
        expect(err.toString(), contains('Invalid FragmentShader blue_green_sampler.frag.iplr'));
      } finally {
        fragmentShader.dispose();
      }
    },
  );

  test('FragmentShader setImageSampler asserts if image is disposed', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset('blue_green_sampler.frag.iplr');
    final Image blueGreenImage = await _createBlueGreenImage();
    final FragmentShader fragmentShader = program.fragmentShader();

    try {
      blueGreenImage.dispose();
      expect(
        () {
          fragmentShader.setImageSampler(0, blueGreenImage);
        },
        throwsA(
          isA<AssertionError>().having(
            (AssertionError e) => e.message,
            'message',
            contains('Image has been disposed'),
          ),
        ),
      );
    } finally {
      fragmentShader.dispose();
    }
  });

  test('Disposed FragmentShader on Paint', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset('blue_green_sampler.frag.iplr');
    final Image blueGreenImage = await _createBlueGreenImage();

    final FragmentShader shader = program.fragmentShader()..setImageSampler(0, blueGreenImage);
    shader.dispose();
    expect(
      () {
        Paint().shader = shader;
      },
      throwsA(
        isA<AssertionError>().having(
          (AssertionError e) => e.message,
          'message',
          contains('Attempted to set a disposed shader'),
        ),
      ),
    );
    blueGreenImage.dispose();
  });

  test('Disposed FragmentShader setFloat', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset('uniforms.frag.iplr');
    final FragmentShader shader = program.fragmentShader()..setFloat(0, 0.0);
    shader.dispose();

    expect(
      () {
        shader.setFloat(0, 0.0);
      },
      throwsA(
        isA<AssertionError>().having(
          (AssertionError e) => e.message,
          'message',
          contains('Tried to accesss uniforms on a disposed Shader'),
        ),
      ),
    );
  });

  test('Disposed FragmentShader setImageSampler', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset('blue_green_sampler.frag.iplr');
    final Image blueGreenImage = await _createBlueGreenImage();

    final FragmentShader shader = program.fragmentShader()..setImageSampler(0, blueGreenImage);
    shader.dispose();
    expect(
      () {
        shader.setImageSampler(0, blueGreenImage);
      },
      throwsA(
        isA<AssertionError>().having(
          (AssertionError e) => e.message,
          'message',
          contains('Tried to access uniforms on a disposed Shader'),
        ),
      ),
    );
    blueGreenImage.dispose();
  });

  test('Disposed FragmentShader dispose', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset('uniforms.frag.iplr');
    final FragmentShader shader = program.fragmentShader()..setFloat(0, 0.0);
    shader.dispose();
    expect(
      () {
        shader.dispose();
      },
      throwsA(
        isA<AssertionError>().having(
          (AssertionError e) => e.message,
          'message',
          contains('Shader cannot be disposed more than once'),
        ),
      ),
    );
  });

  test('Reused FragmentShader simple shader renders correctly', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset('functions.frag.iplr');
    final FragmentShader shader = program.fragmentShader()..setFloat(0, 1.0);
    await _expectShaderRendersGreen(shader);

    shader.setFloat(0, 0.0);
    await _expectShaderRendersBlack(shader);

    shader.dispose();
  });

  test('FragmentShader blue-green image renders green', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset('blue_green_sampler.frag.iplr');
    final Image blueGreenImage = await _createBlueGreenImage();
    final FragmentShader shader = program.fragmentShader()..setImageSampler(0, blueGreenImage);
    await _expectShaderRendersGreen(shader);
    shader.dispose();
    blueGreenImage.dispose();
  });

  test('FragmentShader blue-green image renders green - GPU image', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset('blue_green_sampler.frag.iplr');
    final Image blueGreenImage = _createBlueGreenImageSync();
    final FragmentShader shader = program.fragmentShader()..setImageSampler(0, blueGreenImage);
    await _expectShaderRendersGreen(shader);
    shader.dispose();
    blueGreenImage.dispose();
  });

  test('FragmentShader Uniforms are sorted correctly', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset('uniforms_sorted.frag.iplr');

    // The shader will not render green if the compiler doesn't keep the
    // uniforms in the right order.
    final FragmentShader shader = program.fragmentShader();
    for (var i = 0; i < 32; i++) {
      shader.setFloat(i, i.toDouble());
    }

    await _expectShaderRendersGreen(shader);

    shader.dispose();
  });

  test('FragmentShader Uniforms with interleaved textures are sorted ', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset('uniform_ordering.frag.iplr');

    // The shader will not render green if the compiler doesn't keep the
    // uniforms in the right order.
    final FragmentShader shader = program.fragmentShader();
    shader.setFloat(0, 1);
    shader.setFloat(1, 2);
    shader.setFloat(2, 3);

    final Image blueGreenImage = _createBlueGreenImageSync();
    shader.setImageSampler(0, blueGreenImage);

    await _expectShaderRendersGreen(shader);

    shader.dispose();
  });

  test('fromAsset throws an exception on invalid assetKey', () async {
    var throws = false;
    try {
      await FragmentProgram.fromAsset('<invalid>');
    } catch (e) {
      throws = true;
    }
    expect(throws, equals(true));
  });

  test('fromAsset throws an exception on invalid data', () async {
    var throws = false;
    try {
      await FragmentProgram.fromAsset('DashInNooglerHat.jpg');
    } catch (e) {
      throws = true;
    }
    expect(throws, equals(true));
  });

  test('FragmentShader user defined functions do not redefine builtins', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset(
      'no_builtin_redefinition.frag.iplr',
    );
    final FragmentShader shader = program.fragmentShader()..setFloat(0, 1.0);
    await _expectShaderRendersGreen(shader);
    shader.dispose();
  });

  test('FragmentShader fromAsset accepts a shader with no uniforms', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset('no_uniforms.frag.iplr');
    final FragmentShader shader = program.fragmentShader();
    await _expectShaderRendersGreen(shader);
    shader.dispose();
  });

  _runSkiaTest('FragmentProgram getImageSampler wrong type', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset('uniform_ordering.frag.iplr');
    final FragmentShader shader = program.fragmentShader();
    try {
      shader.getImageSampler('b');
      fail('Unreachable');
    } catch (e) {
      expect(e.toString(), contains('Uniform "b" is not an image sampler.'));
    }
  });

  final ImageComparer comparer = await ImageComparer.create();
  for (final (filterQuality, goldenFilename) in [
    (FilterQuality.none, 'fragment_shader_texture_with_quality_none.png'),
    (FilterQuality.low, 'fragment_shader_texture_with_quality_low.png'),
    (FilterQuality.medium, 'fragment_shader_texture_with_quality_medium.png'),
    (FilterQuality.high, 'fragment_shader_texture_with_quality_high.png'),
  ]) {
    test('FragmentShader renders sampler with filter quality ${filterQuality.name}', () async {
      final FragmentProgram program = await FragmentProgram.fromAsset('texture.frag.iplr');
      final Image image = _createOvalGradientImage(imageDimension: 16);
      final FragmentShader shader = program.fragmentShader()
        ..setImageSampler(0, image, filterQuality: filterQuality);
      shader.setFloat(0, 300);
      shader.setFloat(1, 300);
      // TODO(180595): Switch these to the getUniformFloat API.
      // shader.getUniformFloat('u_size', 0).set(300);
      // shader.getUniformFloat('u_size', 1).set(300);

      final Image shaderImage = await _imageFromShader(shader: shader, imageDimension: 300);

      await comparer.addGoldenImage(shaderImage, goldenFilename);
      shader.dispose();
      image.dispose();
    });
  }

  test('FragmentShader simple shader renders correctly', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset('functions.frag.iplr');
    final FragmentShader shader = program.fragmentShader()..setFloat(0, 1.0);
    await _expectShaderRendersGreen(shader);
    shader.dispose();
  });

  test('FragmentShader with uniforms renders correctly', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset('uniforms.frag.iplr');

    final FragmentShader shader = program.fragmentShader()
      ..setFloat(0, 0.0)
      ..setFloat(1, 0.25)
      ..setFloat(2, 0.75)
      ..setFloat(3, 0.0)
      ..setFloat(4, 0.0)
      ..setFloat(5, 0.0)
      ..setFloat(6, 1.0);

    final ByteData renderedBytes = (await _imageByteDataFromShader(shader: shader))!;

    expect(toFloat(renderedBytes.getUint8(0)), closeTo(0.0, epsilon));
    expect(toFloat(renderedBytes.getUint8(1)), closeTo(0.25, epsilon));
    expect(toFloat(renderedBytes.getUint8(2)), closeTo(0.75, epsilon));
    expect(toFloat(renderedBytes.getUint8(3)), closeTo(1.0, epsilon));

    shader.dispose();
  });

  test('FragmentShader shader with mat2 uniform renders correctly', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset('uniform_mat2.frag.iplr');

    final FragmentShader shader = program.fragmentShader();

    shader.setFloat(0, 4.0); // m00
    shader.setFloat(1, 8.0); // m01
    shader.setFloat(2, 16.0); // m10
    shader.setFloat(3, 32.0); // m11

    await _expectShaderRendersGreen(shader);
    shader.dispose();
  });

  _runImpellerTest(
    'ImageFilter.shader errors if shader does not have correct uniform layout',
    () async {
      const List<({String file, bool floatError, bool samplerError})> testCases = [
        (file: 'no_uniforms.frag.iplr', floatError: true, samplerError: true),
        (file: 'missing_size.frag.iplr', floatError: true, samplerError: false),
        (file: 'missing_texture.frag.iplr', floatError: false, samplerError: true),
      ];

      for (final testCase in testCases) {
        final FragmentProgram program = await FragmentProgram.fromAsset(testCase.file);
        final FragmentShader shader = program.fragmentShader();

        Object? error;
        try {
          ImageFilter.shader(shader);
        } catch (err) {
          error = err;
        }
        expect(error, isA<StateError>());
        final errorMessage = error.toString();
        if (testCase.floatError) {
          expect(errorMessage, contains('shader has fewer than two float'));
        }
        if (testCase.samplerError) {
          expect(errorMessage, contains('shader is missing a sampler uniform'));
        }
      }
    },
  );

  _runImpellerTest('ImageFilter.shader can be applied to canvas operations', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset('filter_shader.frag.iplr');
    final FragmentShader shader = program.fragmentShader();
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawPaint(
      Paint()
        ..color = const Color(0xFFFF0000)
        ..imageFilter = ImageFilter.shader(shader),
    );
    final Image image = await recorder.endRecording().toImage(1, 1);

    // Image's byte data consists of color values for each pixel in RGBA format. The image is 1
    // pixel, so the byte data is expected to be 4 bytes.
    final ByteData data = (await image.toByteData())!;
    expect(data.lengthInBytes, 4);

    final Uint8List colorComponentsRGBA = data.buffer.asUint8List();
    final color = Color.fromARGB(
      colorComponentsRGBA[3],
      colorComponentsRGBA[0],
      colorComponentsRGBA[1],
      colorComponentsRGBA[2],
    );
    // filter_shader.frag swaps red and blue color channels. The drawn color is red, so the expected
    // result color is blue.
    expect(color, const Color(0xFF0000FF));
  });

  // For an explaination of the problem see https://github.com/flutter/flutter/issues/163302 .
  _runImpellerTest('ImageFilter.shader equality checks consider uniform values', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset('filter_shader.frag.iplr');
    final FragmentShader shader = program.fragmentShader();
    final filter = ImageFilter.shader(shader);

    expect(filter, filter);
    expect(identical(filter, filter), true);

    final filter_2 = ImageFilter.shader(shader);
    expect(filter, filter_2);
    expect(identical(filter, filter_2), false);

    shader.setFloat(0, 1);
    final filter_3 = ImageFilter.shader(shader);

    expect(filter, isNot(filter_3));
    expect(identical(filter, filter_3), false);
  });

  test('FragmentShader The ink_sparkle shader is accepted', () async {
    final FragmentProgram program = await FragmentProgram.fromAsset('ink_sparkle.frag.iplr');
    final FragmentShader shader = program.fragmentShader();

    await _imageByteDataFromShader(shader: shader);

    // Testing that no exceptions are thrown. Tests that the ink_sparkle shader
    // produces the correct pixels are in the framework.
    shader.dispose();
  });

  if (!impellerEnabled) {
    // Test all supported GLSL ops. See lib/spirv/lib/src/constants.dart
    final Map<String, FragmentProgram> iplrSupportedGLSLOpShaders = await _loadShaderAssets(
      path.join('supported_glsl_op_shaders', 'iplr'),
      '.iplr',
    );
    _expectFragmentShadersRenderGreen(iplrSupportedGLSLOpShaders);

    // Test all supported instructions. See lib/spirv/lib/src/constants.dart
    final Map<String, FragmentProgram> iplrSupportedOpShaders = await _loadShaderAssets(
      path.join('supported_op_shaders', 'iplr'),
      '.iplr',
    );
    _expectFragmentShadersRenderGreen(iplrSupportedOpShaders);
  }
}

////////////////////////////////////////////////////////////////////////////////
// Helper Functions ////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void _runSkiaTest(String name, Future<void> Function() callback) {
  test(name, () async {
    if (impellerEnabled) {
      print('Skipped for Impeller.');
      return;
    }
    await callback();
  });
}

void _runImpellerTest(String name, Future<void> Function() callback, {Object? skip}) {
  test(name, () async {
    if (!impellerEnabled) {
      print('Skipped for Skia.');
      return;
    }
    await callback();
  }, skip: skip);
}

// Expect that all of the shaders in this folder render green.
// Keeping the outer loop of the test synchronous allows for easy printing
// of the file name within the test case.
void _expectFragmentShadersRenderGreen(Map<String, FragmentProgram> programs) {
  if (programs.isEmpty) {
    fail('No shaders found.');
  }
  for (final String key in programs.keys) {
    test('FragmentProgram $key renders green', () async {
      final FragmentProgram program = programs[key]!;
      final FragmentShader shader = program.fragmentShader()..setFloat(0, 1.0);
      await _expectShaderRendersGreen(shader);
      shader.dispose();
    });
  }
}

Future<void> _expectShaderRendersBarcode(Shader shader, List<Color> barcodeColors) async {
  final ByteData renderedBytes = (await _imageByteDataFromShader(
    shader: shader,
    imageDimension: barcodeColors.length,
  ))!;

  expect(renderedBytes.lengthInBytes % 4, 0);
  final List<Color> renderedColors = List.generate(barcodeColors.length, (int xCoord) {
    return Color.fromARGB(
      renderedBytes.getUint8(xCoord * 4 + 3),
      renderedBytes.getUint8(xCoord * 4),
      renderedBytes.getUint8(xCoord * 4 + 1),
      renderedBytes.getUint8(xCoord * 4 + 2),
    );
  });

  for (var i = 0; i < barcodeColors.length; ++i) {
    final Color renderedColor = renderedColors[i];
    final Color expectedColor = barcodeColors[i];
    final reasonString =
        'Comparison failed on color $i. \nExpected: $expectedColor.\nActual: $renderedColor.';
    expect(renderedColor.r.clamp(-1, 1), closeTo(expectedColor.r, 0.06), reason: reasonString);
    expect(renderedColor.g.clamp(-1, 1), closeTo(expectedColor.g, 0.06), reason: reasonString);
    expect(renderedColor.b.clamp(-1, 1), closeTo(expectedColor.b, 0.06), reason: reasonString);
    expect(renderedColor.a.clamp(-1, 1), closeTo(expectedColor.a, 0.06), reason: reasonString);
  }
}

Future<void> _expectShaderRendersColor(Shader shader, Color color) async {
  final ByteData renderedBytes = (await _imageByteDataFromShader(
    shader: shader,
    imageDimension: _shaderImageDimension,
  ))!;

  expect(renderedBytes.lengthInBytes % 4, 0);
  for (var byteOffset = 0; byteOffset < renderedBytes.lengthInBytes; byteOffset += 4) {
    final pixelColor = Color.fromARGB(
      renderedBytes.getUint8(byteOffset + 3),
      renderedBytes.getUint8(byteOffset),
      renderedBytes.getUint8(byteOffset + 1),
      renderedBytes.getUint8(byteOffset + 2),
    );

    expect(pixelColor, color);
  }
}

// Expects that a shader only outputs the color green.
Future<void> _expectShaderRendersGreen(Shader shader) {
  return _expectShaderRendersColor(shader, _greenColor);
}

Future<void> _expectShaderRendersBlack(Shader shader) {
  return _expectShaderRendersColor(shader, _blackColor);
}

Future<ByteData?> _imageByteDataFromShader({
  required Shader shader,
  int imageDimension = 100,
}) async {
  final Image image = await _imageFromShader(shader: shader, imageDimension: imageDimension);
  return image.toByteData();
}

Future<Image> _imageFromShader({required Shader shader, required int imageDimension}) {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..shader = shader;
  canvas.drawPaint(paint);
  final Picture picture = recorder.endRecording();
  return picture.toImage(imageDimension, imageDimension);
}

// Loads the path and spirv content of the files at
// $FLUTTER_BUILD_DIRECTORY/gen/flutter/lib/spirv/test/$leafFolderName
// This is synchronous so that tests can be inside of a loop with
// the proper test name.
Future<Map<String, FragmentProgram>> _loadShaderAssets(String leafFolderName, String ext) async {
  final Map<String, FragmentProgram> out = SplayTreeMap<String, FragmentProgram>();

  final Directory directory = shaderDirectory(leafFolderName);
  if (!directory.existsSync()) {
    return out;
  }

  await Future.forEach(
    directory.listSync().where((FileSystemEntity entry) => path.extension(entry.path) == ext),
    (FileSystemEntity entry) async {
      final String key = path.basenameWithoutExtension(entry.path);
      out[key] = await FragmentProgram.fromAsset(path.basename(entry.path));
    },
  );
  return out;
}

// Arbitrary, but needs to be greater than 1 for frag coord tests.
const int _shaderImageDimension = 4;

const Color _greenColor = Color(0xFF00FF00);
const Color _blackColor = Color(0xFF000000);

// Precision for checking uniform values.
const double epsilon = 0.5 / 255.0;

// Maps an int value from 0-255 to a double value of 0.0 to 1.0.
double toFloat(int v) => v.toDouble() / 255.0;

// 10x10 image where the left half is blue and the right half is
// green.
Future<Image> _createBlueGreenImage() async {
  const length = 10;
  const bytesPerPixel = 4;
  final pixels = Uint8List(length * length * bytesPerPixel);
  var i = 0;
  for (var y = 0; y < length; y++) {
    for (var x = 0; x < length; x++) {
      if (x < length / 2) {
        pixels[i + 2] = 0xFF; // blue channel
      } else {
        pixels[i + 1] = 0xFF; // green channel
      }
      pixels[i + 3] = 0xFF; // alpha channel
      i += bytesPerPixel;
    }
  }
  final descriptor = ImageDescriptor.raw(
    await ImmutableBuffer.fromUint8List(pixels),
    width: length,
    height: length,
    pixelFormat: PixelFormat.rgba8888,
  );
  final Codec codec = await descriptor.instantiateCodec();
  final FrameInfo frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}

// A 10x10 image where the left half is blue and the right half is green.
Image _createBlueGreenImageSync() {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 5, 10), Paint()..color = const Color(0xFF0000FF));
  canvas.drawRect(const Rect.fromLTWH(5, 0, 5, 10), Paint()..color = const Color(0xFF00FF00));
  final Picture picture = recorder.endRecording();
  try {
    return picture.toImageSync(10, 10);
  } finally {
    picture.dispose();
  }
}

// Image of an oval painted with a linear gradient.
Image _createOvalGradientImage({required int imageDimension}) {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawPaint(Paint()..color = const Color(0xFF000000));
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(imageDimension * 0.5, imageDimension * 0.5),
      width: imageDimension * 0.6,
      height: imageDimension * 0.9,
    ),
    Paint()
      ..shader = Gradient.linear(
        Offset.zero,
        Offset(imageDimension.toDouble(), imageDimension.toDouble()),
        [const Color(0xFFFF0000), const Color(0xFF00FF00)],
      ),
  );
  final Picture picture = recorder.endRecording();
  try {
    return picture.toImageSync(imageDimension, imageDimension);
  } finally {
    picture.dispose();
  }
}
