# Impeller's shader pipeline

## Impeller's shader pipeline

Every Impeller library with shaders invokes `impeller_shaders()`
(impeller/tools/shaders.gni); the converter emits the invocation as a call
of the macro in `build_defs/impeller/shaders.bzl`, whose body is the template's,
rewritten once: for each backend (GLES 2, GLES 3, Vulkan; Metal on the
Apple platforms) `impellerc_compile` runs
`//engine/src/flutter/impeller/compiler:impellerc`
once per shader, `shader_archive` packs the compiled shaders with
`shader_archiver`, `embed_blob` turns the archive into a C++ array with
`impeller/tools/xxd.py`, and `cc_library` wraps the blob and the reflection
headers. The targets keep GN's names (`impellerc_vk_entity_shaders`,
`embed_gles3_entity_shaders`, ...) so the two trees read alike; the oracle
knows them as the template's inner targets.

Which backends a build has is args.gni's `impeller_enable_metal`,
`impeller_enable_opengles` and `impeller_enable_vulkan`, each a tri-state
flag in `impeller/tools` (`--//engine/src/flutter/impeller/tools:enable_metal=auto|true|false`):
`auto`, the default, is GN's formula over the target platform -- Metal on
macOS and iOS, Vulkan on the desktops and Android, OpenGL ES on those and the
web -- and `true`/`false` a build's override, as GN's args allow; the wasm
platform's own flags spell the web's out. The generated files `select()` on
`:metal`, `:opengles` and `:vulkan`, which hold for `true` and for `auto`
where the formula does, so a plain `bazel build` on a Mac has Metal as GN's
does without any `--config`.

The Metal backend (`mtl_<name>`) is shaders_mtl.gni's:
impellerc with `--metal-desktop`, `--metal-version` (1.2 unless the
invocation says) and `IMPELLER_TARGET_METAL(_DESKTOP)` writes the `.metal`
sources and the reflection; `metal_library` compiles them into one
`shaders/<name>.metallib` through `impeller/tools/metal_library.py`, which
runs Xcode's `xcrun -sdk macosx metal` (with `-g -frecord-sources` in the
debug and profile runtime modes, impeller_debug; a `.metallibsym` beside the
library otherwise) -- the one tool of the pipeline that is not the build's
own, the same Xcode `@macos_sdk` is a view of (DEVELOPER_DIR reaches it
through `--action_env`); `embed_blob` embeds the library as
`impeller_<name>_shaders_data` (`mtl/<name>_shaders.h`). Where Metal is on,
Metal's reflection headers are the public ones (shaders_vk.gni: "Metal
reflectors generate a superset of information") and Vulkan's move under
`vk/`, which is why `impellerc_compile` declares its outputs at analysis
time from a platform-selected `subdir` rather than predeclaring them: one
rule instance, either layout, no two rules claiming
`impeller/entity/solid_fill.vert.h`. Off the Apple platforms the Metal
targets are incompatible and a wildcard build skips them.

The tools run in Bazel's exec configuration -- GN's `host_toolchain` for
`compiled_action` -- which on a host build means `impellerc`'s closure
(Skia, SPIRV-Tools, glslang, shaderc) is compiled a second time, in
`bazel-out/*-exec-*`, where GN compiles it once because its default
toolchain is the host's. That is the cost of a build that can also cross
compile; a remote or disk cache absorbs it.

The test fixtures invoke the inner template, `impellerc()`
(impeller/tools/compiler.gni), directly: runtime stages (`--iplr`, one
run per shader) and Flutter GPU shader bundles (`--shader-bundle`, one run
over a JSON that names the shaders by path). The macro of the same name
in `impeller/shaders.bzl` declares GN's outputs
(`<intermediates_subdir>/<shader>.<sl_file_extension>`, or the bundle) and
runs `impellerc_run`, which builds the command line as the template does;
the bundle's paths, which GN wrote with `rebase_path`, are the converter's
`$(src ...)` tokens (`gn_action.bzl`'s `expand_gn_paths`), so the JSON is
the same text on every machine. GN's `mnemonic` becomes the action's,
reduced to letters and digits (`IMPELLERC_IPLR` is not a Bazel mnemonic).

`embed_blob()` (impeller/tools/embed_blob.gni) is invoked directly too, by
`impeller/toolkit/interop` for the ICU data of the standalone library; the
converter emits it as `embed_blob_library`, the `embed_blob` rule plus the
`cc_library` the template declares around the generated pair. The blob is
`@icu//:flutter/icudtl.dat`, the trimmed data file GN names, which the ICU
overlay exports beside `common/icudtl.dat`.
