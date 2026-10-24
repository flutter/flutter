# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The engine's `flatbuffers()` GN template as a Bazel macro.

`flatbuffers("x") { flatbuffers = [ "x.fbs" ] }` (build/secondary/flutter/
third_party/flatbuffers/flatbuffers.gni) runs `flatc` on each schema,
writing `<stem>_flatbuffers.h` into the target's generated directory, and
wraps the headers in a source_set that depends on the flatbuffers library.
Dependents include the headers by their path under the generated tree
(`impeller/runtime_stage/runtime_stage_flatbuffers.h`), which the include
directories of their configs resolve in the output tree.
"""

load("@rules_cc//cc:defs.bzl", "cc_library")

# flatc's arguments, as flatbuffers.gni passes them.
_FLATC_ARGS = [
    "--warnings-as-errors",
    "--cpp",
    "--cpp-std",
    "c++17",
    "--cpp-static-reflection",
    "--gen-object-api",
    "--filename-suffix",
    "_flatbuffers",
]

def _flatc_impl(ctx):
    outputs = []
    for schema in ctx.files.srcs:
        stem = schema.basename[:-len(schema.extension) - 1] if schema.extension else schema.basename
        header = ctx.actions.declare_file(stem + "_flatbuffers.h")
        outputs.append(header)
        ctx.actions.run(
            executable = ctx.executable._flatc,
            arguments = _FLATC_ARGS + ["-o", header.dirname, schema.path],
            inputs = [schema] + ctx.files.includes,
            outputs = [header],
            mnemonic = "Flatc",
            progress_message = "flatc %{input}",
        )
    return [DefaultInfo(files = depset(outputs))]

_flatc = rule(
    implementation = _flatc_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".fbs"],
            mandatory = True,
            doc = "The schemas (GN's `flatbuffers`).",
        ),
        "includes": attr.label_list(
            allow_files = [".fbs"],
            doc = "Schemas the sources may `include` (flatc looks beside the including file).",
        ),
        "_flatc": attr.label(
            default = "@flatbuffers//:flatc",
            executable = True,
            cfg = "exec",
        ),
    },
)

def flatbuffers(name, flatbuffers, deps = [], **kwargs):
    """The generated headers of the given schemas, as a library.

    Args:
      name: the target name; `flatc_<name>` runs the compiler.
      flatbuffers: the `.fbs` schemas.
      deps: GN's `deps` and `public_deps`; the flatbuffers library is added.
      **kwargs: the rest (`testonly`, `visibility`), for the library.
    """
    _flatc(
        name = "flatc_" + name,
        srcs = flatbuffers,
        # A schema may `include` another of its package (runtime_stage.fbs
        # includes runtime_stage_types.fbs); GN left that to the checkout.
        includes = native.glob(["*.fbs"]),
        testonly = kwargs.get("testonly"),
        visibility = ["//visibility:private"],
    )

    # GN's template adds the flatbuffers library to whatever the invoker
    # listed, which often names it too; Bazel refuses a duplicate.
    all_deps = {}
    for dep in deps + ["@flatbuffers"]:
        all_deps["@flatbuffers" if dep == "@flatbuffers//:flatbuffers" else dep] = None
    cc_library(
        name = name,
        hdrs = [":flatc_" + name],
        deps = all_deps.keys(),
        **kwargs
    )
