# The Impeller Shader Compiler & Reflector

Host side tooling that consumes [GLSL 4.60 (Core
Profile)](https://www.khronos.org/registry/OpenGL/specs/gl/GLSLangSpec.4.60.pdf)
shaders and generates libraries suitable for consumption by an Impeller backend.
Along with said libraries, the reflector generates code and meta-data to
construct rendering and compute pipelines at runtime.

# Invocation

To invoke `impellerc` by itself, [compile the engine](https://github.com/flutter/flutter/blob/master/docs/engine/contributing/Compiling-the-engine.md) and run the binary via 
```
`find engine/src/out/host_debug_unopt_arm64 -name impellerc` --input=path/to/shader.frag --input-type=frag --entry-point=main`
```
