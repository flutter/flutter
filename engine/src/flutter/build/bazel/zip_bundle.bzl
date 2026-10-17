# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""GN's zip_bundle template: an archive under zip_archives/, made by build/zip.py.

//flutter/build/zip_bundle.gni packages the engine's artifacts: an action
running build/zip.py over a list of `{ source, destination }` scopes, writing
`$root_build_dir/zip_archives/<output>`, with a generated
`LICENSE.<target>.md` first in every archive that points at the engine's
license and the bundle's source directory at the engine's version.

zip_bundle does the same under Bazel: the same script, under the synced
Python (@cpython3; GN runs it under depot_tools' vpython3) through
zip_bundle.py, which hands it the files the sandbox's input symlinks name,
over the files of `files`, the readme written by the rule from the version
@engine_version//:version.bzl carries, and the archive at
`zip_archives/<output>` under the package. Every value of `files` is one
file for now (a directory source is the artifact phase's: zip.py walks it
and keeps symlinks, which a tree artifact would stand for).

The converter does not read the template yet: a GN zip_bundle is skipped in
its file's manifest entry and written here by hand where something needs the
archive -- run_tests.py --type font-subset checks font-subset.zip.
"""

load("@engine_version//:version.bzl", "ENGINE_VERSION")

def _zip_bundle_impl(ctx):
    output = ctx.actions.declare_file("zip_archives/" + ctx.attr.output)

    # zip_bundle.gni's generated_file, byte for byte: the directory of the
    # bundle's BUILD file relative to //flutter, the license's path, both at
    # the engine's version on GitHub. The title is the generated_file's own
    # name -- the template reads `target_name` inside that block.
    package = ctx.label.package
    prefix = "engine/src/flutter/"
    if not package.startswith(prefix):
        fail("%s: a zip_bundle belongs under //engine/src/flutter" % ctx.label)
    source_path = package[len(prefix):]
    license_path = "sky/packages/sky_engine/LICENSE"
    git_url = "https://github.com/flutter/engine/tree/" + ENGINE_VERSION
    sky_engine_url = "https://storage.googleapis.com/flutter_infra_release/flutter/" + ENGINE_VERSION + "/sky_engine.zip"
    readme_name = "LICENSE.%s.md" % ctx.label.name
    readme = ctx.actions.declare_file(readme_name)
    ctx.actions.write(
        output = readme,
        content = "\n".join([
            "# _%s_license_md" % ctx.label.name,
            "",
            "This bundle is part of the the Flutter SDK.",
            "",
            "The source code is hosted at [flutter/engine/%s](%s/%s)." % (source_path, git_url, source_path),
            "The license for this bundle is hosted at [flutter/engine/%s](%s/%s) " % (license_path, git_url, license_path),
            "and [sky_engine.zip](%s)." % sky_engine_url,
            "",
        ]),
    )

    # zip.py stores a symlink as a symlink entry (a macOS framework's), and
    # every input of a sandboxed action is one; GN hands it the build
    # directory's real files. zip_bundle.py resolves each source to the file
    # it names before zip.py sees it.
    args = ctx.actions.args()
    args.add_all([ctx.file._wrapper, ctx.file._script])
    args.add("-o", output)
    args.add_all(["-i", readme, readme_name])
    inputs = [readme]
    for destination, target in ctx.attr.files.items():
        files = target[DefaultInfo].files.to_list()
        if len(files) != 1:
            fail("%s: %s should be one file for %s, is %s" % (ctx.label, target.label, destination, files))
        args.add_all(["-i", files[0], destination])
        inputs.append(files[0])

    ctx.actions.run(
        executable = ctx.executable._python,
        arguments = [args],
        inputs = depset(
            inputs + [ctx.file._wrapper, ctx.file._script],
            transitive = [ctx.attr._python_runtime[DefaultInfo].files],
        ),
        outputs = [output],
        env = {"PYTHONDONTWRITEBYTECODE": "1"},
        mnemonic = "ZipBundle",
        progress_message = "Zipping %{output}",
    )
    return [DefaultInfo(files = depset([output]))]

zip_bundle = rule(
    implementation = _zip_bundle_impl,
    doc = "GN's zip_bundle: `zip_archives/<output>` made by build/zip.py from `files`, LICENSE.<name>.md first.",
    attrs = {
        "output": attr.string(
            mandatory = True,
            doc = "The archive's path under zip_archives/ (`linux-x64/font-subset.zip`).",
        ),
        "files": attr.string_keyed_label_dict(
            allow_files = True,
            mandatory = True,
            doc = "The archive's entries: each destination path mapped to the target of the one file placed there.",
        ),
        "_script": attr.label(
            default = "//engine/src/flutter/build:zip.py",
            allow_single_file = True,
        ),
        "_wrapper": attr.label(
            default = "//engine/src/flutter/build/bazel:zip_bundle.py",
            allow_single_file = True,
        ),
        "_python": attr.label(
            default = "@cpython3//:bin/python3",
            executable = True,
            cfg = "exec",
            allow_single_file = True,
        ),
        "_python_runtime": attr.label(default = "@cpython3//:runtime"),
    },
)
