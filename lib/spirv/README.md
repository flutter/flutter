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
- Control flow is prohibited aside from function calls and `return`.
  `if`, `while`, `for`, `switch`, etc.
- No inputs from other shader stages.
- Only float, float-vector types, and square float-matrix types.
- Only square matrices are supported.
- Only built-in functions present in GLSL ES 100 are used.
- Debug symbols must be stripped, you can use the `spirv-opt` `--strip-debug` flag.

These rules may become less strict in future versions. Confirmant SPIR-V should succesfully transpile from the current version onwards.  In other words, a spir-v shader you use now that meets these rules should keep working, but the output of the transpiler may change for that shader.

Support for textures, control flow, and structured types is planned, but not currently included.

## Testing

## Exception Tests

These tests rely on the `.spvasm` (SPIR-V Assembly)  and `.glsl` files contained under `test/exception_shaders` in this directory. They are compiled to binary SPIR-V using `spirv-asm`, from the SwiftShader dependency. They are tested by testing/dart/spirv_exception_test.dart as part of the normal suite of dart tests. The purpose of these tests is to exercise every explicit failure path for shader transpilation. Each `glsl` or `spvasm` file should include a comment describing the failure that it is testing. The given files should be valid apart from the single failure case they are testing.

## Pixel Tests

Pixel test are not yet checked in, and should run as part of unit-testing for each implementation of `dart:ui`. These tests aim to validate the correctness of transpilation to each target language. Each shader should render the color green #00FF00 for a correct transpilation, and any other color for failure. They will be a combination of `.spvasm` files and more-readable GLSL files that are compiled to SPIR-V via `glslang`, provided by the SwiftShader dependency. Information for pixel tests will be expanded in a follow-up PR.

These tests will be able to be run alone by executing `./ui_unittests` in the build-output directory.

