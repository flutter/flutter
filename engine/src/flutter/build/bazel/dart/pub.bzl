# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The repository's pub packages as Bazel repositories, from pubspec.lock.

`pub get` resolves the repository's pub workspace (the root pubspec.yaml's
`workspace:` members: packages/flutter, flutter_test, dev/bots, ...) into
`.dart_tool/package_config.json`, whose hosted packages live in the user's
pub cache (~/.pub-cache/hosted/pub.dev/<name>-<version>). A Bazel action
cannot read that cache: it is outside the workspace and differs per machine.
`pubspec.lock` pins every hosted package by version and by the sha256 of its
archive, which is all a fetch needs.

The `pub` module extension turns the lock -- as gen_pub_lock.dart mirrors it
into pub.lock.bzl, with each package's dependencies -- into one repository
per hosted package (`pub__<name>`: its archive downloaded from the pub
server, `<url>/api/archives/<name>-<version>.tar.gz`, verified against the
lock's sha256 and extracted) and the hub @pub, whose package `<name>` aliases
the files of each (`@pub//<name>:sources`, `@pub//<name>:pubspec`). Bazel
fetches a repository when a target first reaches it, so a build fetches the
packages it uses and no other (the lock has 174; a framework test reaches
about a third), in parallel, and the repository cache holds the archives.

pub_package_config writes a `package_config.json` -- the file the frontend
server and the VM take as `--packages` -- over the closure of some packages'
dependencies (`roots`: a workspace package's `dependencies`, and the
`dev_roots`' `dev_dependencies` too, followed through the hosted packages'
own; pub_closure walks pub.lock.bzl's graph at loading time), each with the
language version its pubspec's SDK constraint implies, as pub derives it.
The workspace's own packages in the closure are given as `packages` (a label
of a package's files, or of a rule that builds one, like the engine's
sky_engine) and the ones the compile never needs as `without`; the macro
fails over a package of the closure that is neither. Root URIs are relative
to the configuration file, which is written for one of two layouts: an
action's execroot (the compile) or a test's runfiles tree (the run). The
rule provides the packages' files as PubPackageConfigInfo.sources, for a
compile's inputs.
"""

load(
    "//engine/src/flutter/build/bazel/dart:pub.lock.bzl",
    "PUB_HOSTED",
    "PUB_OTHER_SOURCES",
    "PUB_WORKSPACE",
)

PubPackageConfigInfo = provider(
    doc = "A package_config.json and the files of the packages it names.",
    fields = {
        "sources": "depset of File: every file of every package in the configuration, for a compile that may read them.",
    },
)

_PACKAGE_BUILD = '''# A pub package fetched by the pub module extension (pub.bzl).

package(default_visibility = ["//visibility:public"])

filegroup(
    name = "sources",
    srcs = glob(
        ["**"],
        exclude = [
            "test/**",
            "example/**",
            "doc/**",
            "benchmark/**",
            "tool/**",
            ".dart_tool/**",
        ],
    ),
)

exports_files(["pubspec.yaml"])
'''

_ARCHIVE = "_archive.tar.gz"

def _pub_package_impl(rctx):
    rctx.download(
        url = rctx.attr.url,
        output = _ARCHIVE,
        sha256 = rctx.attr.sha256,
    )
    script = rctx.path(rctx.attr._extract)
    rctx.watch(script)
    result = rctx.execute([rctx.path(rctx.attr._python), script, _ARCHIVE, "."])
    if result.return_code != 0:
        fail("pub package %s %s: extracting %s failed:\n%s%s" % (
            rctx.attr.package,
            rctx.attr.version,
            rctx.attr.url,
            result.stdout,
            result.stderr,
        ))
    rctx.delete(_ARCHIVE)
    rctx.file("BUILD.bazel", _PACKAGE_BUILD)

pub_package = repository_rule(
    implementation = _pub_package_impl,
    doc = "One hosted package of pubspec.lock: its archive fetched, verified and extracted.",
    attrs = {
        "package": attr.string(mandatory = True, doc = "The package's name."),
        "version": attr.string(mandatory = True, doc = "The version the lock pins."),
        "url": attr.string(mandatory = True, doc = "The archive's URL."),
        "sha256": attr.string(mandatory = True, doc = "The archive's sha256, from the lock."),
        "_extract": attr.label(default = "//engine/src/flutter/build/bazel/dart:extract_archive.py"),
        # The synced Python, as the build's own actions use (Bazel's extractor
        # rejects some pub archives; extract_archive.py says why).
        "_python": attr.label(default = "@cpython3//:bin/python3"),
    },
)

_HUB_PACKAGE_BUILD = '''# {name} {version}: the repository pub__{name}, fetched when first reached (pub.bzl).

package(default_visibility = ["//visibility:public"])

alias(
    name = "sources",
    actual = "@pub__{name}//:sources",
)

alias(
    name = "pubspec",
    actual = "@pub__{name}//:pubspec.yaml",
)
'''

def _pub_hub_impl(rctx):
    rctx.file("BUILD.bazel", "# The hub of the pub module extension (pub.bzl): one package per hosted package of pubspec.lock.\n")
    for name in PUB_HOSTED:
        rctx.file(name + "/BUILD.bazel", _HUB_PACKAGE_BUILD.format(name = name, version = PUB_HOSTED[name].version))

_pub_hub = repository_rule(
    implementation = _pub_hub_impl,
    doc = "The hub @pub: an alias package per hosted package, over the pub__<name> repositories.",
)

def _pub_impl(mctx):
    for name in PUB_HOSTED:
        package = PUB_HOSTED[name]
        pub_package(
            name = "pub__" + name,
            package = name,
            version = package.version,
            url = package.url,
            sha256 = package.sha256,
        )
    _pub_hub(name = "pub")
    root = mctx.modules[0] if mctx.modules else None
    if root != None and root.is_root:
        return mctx.extension_metadata(
            root_module_direct_deps = ["pub"],
            root_module_direct_dev_deps = [],
            reproducible = True,
        )
    return mctx.extension_metadata(reproducible = True)

pub = module_extension(
    implementation = _pub_impl,
    doc = "The repository's pub packages (pubspec.lock) as the repositories pub__<name> behind the hub @pub.",
)

def pub_closure(roots, dev_roots = [], without = []):
    """The packages some roots reach through their dependencies, by kind.

    Args:
      roots: package names (hosted or the workspace's) whose `dependencies`
        are followed, transitively through every package reached.
      dev_roots: workspace package names whose `dev_dependencies` are
        followed too (a package's tests reach them; only the roots' own dev
        dependencies count, as for pub).
      without: package names not followed: left out with everything only
        they reach.

    Returns:
      A struct of sorted name lists: `hosted` (pub.lock.bzl's PUB_HOSTED),
      `workspace` (PUB_WORKSPACE) and `other` (neither: the SDK's and git
      packages of PUB_OTHER_SOURCES, or a name the lock does not know).
    """
    seen = {name: True for name in without}
    pending = []
    for name in list(roots) + list(dev_roots):
        if name not in seen:
            seen[name] = True
            pending.append(name)
    hosted = {}
    workspace = {}
    other = {}

    # Every name is queued once (marked when queued), so the walk takes at
    # most one step per package; Starlark has no unbounded loop.
    for _ in range(len(PUB_HOSTED) + len(PUB_WORKSPACE) + len(PUB_OTHER_SOURCES) + len(pending) + 1):
        if not pending:
            break
        name = pending.pop()
        deps = []
        if name in PUB_HOSTED:
            hosted[name] = True
            deps = PUB_HOSTED[name].deps
        elif name in PUB_WORKSPACE:
            workspace[name] = True
            deps = list(PUB_WORKSPACE[name].deps)
            if name in dev_roots:
                deps += PUB_WORKSPACE[name].dev_deps
        else:
            other[name] = True
        for dep in deps:
            if dep not in seen:
                seen[dep] = True
                pending.append(dep)
    if pending:
        fail("pub_closure: the walk did not finish (%d names pending)" % len(pending))
    return struct(
        hosted = sorted(hosted.keys()),
        workspace = sorted(workspace.keys()),
        other = sorted(other.keys()),
    )

# The two layouts a package configuration is written for.
EXECROOT = "execroot"
RUNFILES = "runfiles"

def _pub_package_config_impl(ctx):
    args = ctx.actions.args()
    args.add(ctx.file._script)
    args.add("--output", ctx.outputs.out)
    args.add("--layout", ctx.attr.layout)
    inputs = []

    # Every pubspec goes as `<name>=<path to read>=<path in the layout>`: the
    # action reads the file where it is in the execroot and writes the root
    # URI for where the file sits in the layout -- the same path for the
    # execroot, the runfiles path (external repositories under ../) for a
    # test's tree.
    def location(f):
        if ctx.attr.layout == EXECROOT:
            return f.path
        return f.short_path

    # A package's root is its pubspec's directory: the shallowest pubspec.yaml
    # among its files (a package may carry another in a subdirectory).
    sources = []
    for target, name in ctx.attr.hosted.items() + ctx.attr.packages.items():
        pubspecs = [f for f in target[DefaultInfo].files.to_list() if f.basename == "pubspec.yaml"]
        if not pubspecs:
            fail("%s: %s should provide a pubspec.yaml among its files" % (ctx.label, target.label))
        pubspec = sorted(pubspecs, key = lambda f: len(f.path))[0]
        args.add("--package", "%s=%s=%s" % (name, pubspec.path, location(pubspec)))
        inputs.append(pubspec)
        sources.append(target[DefaultInfo].files)
    args.add("--output-location", ctx.attr.location or location(ctx.outputs.out))
    ctx.actions.run(
        executable = ctx.executable._python,
        arguments = [args],
        inputs = depset(
            inputs + [ctx.file._script],
            transitive = [ctx.attr._python_runtime[DefaultInfo].files],
        ),
        outputs = [ctx.outputs.out],
        env = {"PYTHONDONTWRITEBYTECODE": "1"},
        mnemonic = "PubPackageConfig",
        progress_message = "Writing %s" % ctx.outputs.out.short_path,
    )
    return [
        DefaultInfo(files = depset([ctx.outputs.out])),
        PubPackageConfigInfo(sources = depset(transitive = sources)),
    ]

_pub_package_config = rule(
    implementation = _pub_package_config_impl,
    doc = "A package_config.json over hosted packages of @pub and workspace packages.",
    attrs = {
        "out": attr.output(
            mandatory = True,
            doc = "The configuration file to write.",
        ),
        "hosted": attr.label_keyed_string_dict(
            allow_files = True,
            doc = "The hosted packages: each one's files (@pub//<name>:sources) to its name.",
        ),
        "packages": attr.label_keyed_string_dict(
            allow_files = True,
            doc = "The workspace's own packages: the files of each (its pubspec.yaml among them) to " +
                  "the package's name.",
        ),
        "layout": attr.string(
            default = EXECROOT,
            values = [EXECROOT, RUNFILES],
            doc = "Whose paths the root URIs are relative to: an action's execroot (the compile) " +
                  "or a test's runfiles tree (the run).",
        ),
        "location": attr.string(
            doc = "Where in the layout the configuration is read from, when not at its own output " +
                  "path: a test's runfiles place it at the package's .dart_tool/package_config.json " +
                  "(dart_test), and the root URIs are relative to that.",
        ),
        "_script": attr.label(
            default = "//engine/src/flutter/build/bazel/dart:package_config.py",
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

def pub_package_config(name, out, roots, dev_roots = [], packages = {}, without = [], layout = EXECROOT, location = None, **kwargs):
    """A package_config.json over the closure of some packages' dependencies.

    Args:
      name: the target's name.
      out: the configuration file to write.
      roots: the package names whose `dependencies` the configuration covers,
        transitively (pub_closure).
      dev_roots: the workspace packages whose `dev_dependencies` it covers too.
      packages: the workspace's own packages: the files of each (a label; its
        pubspec.yaml among them) to the package's name. Every workspace
        package of the closure must be here or in `without`.
      without: packages of the closure left out, with what only they reach
        (sky_engine: dart:ui is the platform's; nothing imports it).
      layout: `execroot` (a compile's) or `runfiles` (a test's run).
      location: the path in the layout the configuration is read from, when
        a rule places it elsewhere than its output (dart_test: the package's
        `.dart_tool/package_config.json`).
      **kwargs: the rule's other attributes (visibility, tags).

    Also declares `<name>_sources`, a filegroup of the packages' files.
    """
    closure = pub_closure(roots, dev_roots, without)
    given = {package: label for label, package in packages.items()}
    missing = [package for package in closure.workspace + closure.other if package not in given]
    if missing:
        fail("%s: the closure of %s reaches packages that are not hosted; give each as `packages` or `without`: %s" % (
            name,
            roots + dev_roots,
            ", ".join(missing),
        ))
    unreached = [package for package in without if package in given]
    if unreached:
        fail("%s: `without` and `packages` both name %s" % (name, ", ".join(unreached)))
    hosted = {"@pub//%s:sources" % package: package for package in closure.hosted}
    _pub_package_config(
        name = name,
        out = out,
        hosted = hosted,
        packages = packages,
        layout = layout,
        location = location,
        **kwargs
    )

    # The packages' files, for a run that loads them from source (a test
    # that spawns the Dart VM on a script).
    native.filegroup(
        name = name + "_sources",
        srcs = hosted.keys() + packages.keys(),
        visibility = kwargs.get("visibility"),
        tags = kwargs.get("tags", []),
    )
