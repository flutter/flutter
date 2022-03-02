# SPIR-V Transpiler

Note: This library is currently considered experimental until shader compilation is verified by engine unit tests, see the Testing section below for more details.

A dart library for transpiling a subset of SPIR-V to the shader languages used by Flutter internally.

- [SkSL](https://skia.org/docs/user/sksl/)
- [GLSL ES 100](https://www.khronos.org/files/opengles_shading_language.pdf)
- [GLSL ES 300](https://www.khronos.org/registry/OpenGL/specs/es/3.0/GLSL_ES_Specification_3.00.pdf)

All exported symbols are documented in `lib/spirv.dart`.

The supported subset of SPIR-V is specified in `lib/src/constants.dart`.

If you're using GLSL to generate SPIR-V with `glslangValidator` or `shaderc`,
the code will need to adhere to the following rules.

- There must be a single vec4 output at location 0.
- The output can only be written to from the main function.
- `gl_FragCoord` can only be read from the main function, and its z and w components
  have no meaning.
- `if`, `else`, and `for` and function calls are the only permitted control
  flow operations. `for` loops must initialize a float variable to a constant
  value, compare it against a constant value, and increment/modify it by a
  constant value.
- `while` and `switch` statements are not supported.
- No inputs from other shader stages.
- Only sampler2D, bool, float, float-vector types, and square float-matrix types.
- Only square matrices are supported.
- Only built-in functions present in GLSL ES 100 are used.
- Only the `texture` function is supported for sampling from a sampler2D object.

These rules may become less strict in future versions. Conformant SPIR-V should successfully transpile from the current version onwards.  In other words, a SPIR-V shader you use now that meets these rules should keep working, but the output of the transpiler may change for that shader.

Support for control flow and structured types is planned but not currently included.

## Testing

### Exception Tests

These tests rely on the `.spvasm` (SPIR-V Assembly)  and `.glsl` files contained under `test/exception_shaders` in this directory. They are compiled to binary SPIR-V using `spirv-asm`, from the SwiftShader dependency. They are tested by testing/dart/spirv_exception_test.dart as part of the normal suite of dart tests. The purpose of these tests is to exercise every explicit failure path for shader transpilation. Each `glsl` or `spvasm` file should include a comment describing the failure that it is testing. The given files should be valid apart from the single failure case they are testing.

To test the exception tests directly: `./testing/run_tests.py --type dart --dart-filter spirv_exception_test.dart`

### Pixel Tests

Pixel tests should run as part of unit-testing for each implementation of `dart:ui`. Currently, FragmentShader is only supported in C++. These tests aim to validate the correctness of transpilation to each target language. Each shader should render the color green for a correct transpilation, and any other color for failure. They will be a GLSL files that are compiled to SPIR-V via `shaderc`. Therefore, the `fragColor` should resolve to `vec4(0.0, 1.0, 0.0, 1.0)`
for all tests.

In each test, the uniform `a` is initialized with the value of 1.0.
This is important so that expressions are not simplified during GLSL to SPIR-V compilation, which may result in the removal of the op being tested.

To test the pixel tests directly: `./testing/run_tests.py --type dart --dart-filter fragment_shader_test.dart`

#### A Note on Test Isolation

Even the simplest GLSL program tests several instructions, so no test is completely isolated
to a single op. Also, some of the GLSL 450 op tests will use addition and subtraction, along with the
actual op being tested. However, the GLSL program for each test file is kept as simple as possible,
to satisfy these conditions: pass if the op works, and fail if the op does not work. In some tests,
it is sufficient to only call the GLSL op once, while other may need more calls to more completely
test the op. Many ops support scalars, vectors, or a combination as parameters. Most tests default
to using scalars as params, but vec2, vec3, and vec4 parameters are also tested.

- vec2 is tested as a parameter in glsl_op_normalize.glsl
- vec3 is tested as a parameter in glsl_op_cross.glsl
- vec4 is tested as a parameter in glsl_op_length.glsl

### Adding New Tests

To add a new test, add a glsl (fragment shader tests) or spvasm (spirv exception tests) src file to a `lib/spirv/test/` subfolder, and add the file as a source to the corresponding `BUILD.gn`.

- New files in `exception_shaders` are automatically tested in `testing/dart/spirv_exception_test`.
- New files in `supported_op_shaders` and `supported_glsl_op_shaders` are automatically tested in `testing/dart/fragment_shader_test`.
- New files in `general_shaders` are not automatically tested and must add a new manual test case in `testing/dart/fragment_shader_test`.
