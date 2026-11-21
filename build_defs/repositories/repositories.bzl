# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Repository rules that give Bazel access to the engine's dependencies.

Two kinds of repositories are needed while the engine build migrates from GN
to Bazel:

* `synced_repository`: a repository backed by a directory that `gclient sync`
  populated inside this checkout (a git dependency or a CIPD package from
  `DEPS`). The directory is consumed in place -- it is symlinked, never
  copied -- so GN and Bazel always build the exact same sources, and nothing
  is downloaded twice. An overlay `BUILD` file can be supplied for trees that
  ship no Bazel build files or whose upstream ones should not be used; or
  the engine's GN build files for the tree can be converted into `BUILD`
  files at fetch time (`gn_build_files`), so that a dependency roll that
  changes the GN side (Skia's source lists, say) needs no regeneration.

  A checkout that was never synced has no such directory. The repository
  then reads what Bazel fetched in its place (`fetched`): a source tree's
  `fetched_tree` (git_deps.bzl: the revision DEPS pins, laid out as gclient
  lays it), a tool's `fetched_archive` (fetched_archive.bzl: the CIPD
  package DEPS names) -- exactly as it reads a synced directory.

* `cipd_package`: a repository populated by downloading a CIPD package over
  HTTPS (the same mechanism Skia uses). It needs no `cipd` client and no
  `gclient sync`; the pins come from `deps.lock.bzl`.

Both produce the same layout, so a dependency can move from one to the other
without touching the targets that use it.

A third, `engine_version_repository`, holds no sources: it writes the version
strings `tools/gn` would compute at gen time (shell/version) as a `.bzl` of
constants. Skia's and Dart's revisions come from DEPS. The checkout's own
revision and content hash are fixed words unless the build is stamped
(`--config=stamp`), which reads them from git at fetch time as `tools/gn` does.
"""

load(":git_deps.bzl", "FETCHED_TREE_DIRECTORY")

_BUILD_FILE_NAMES = ("BUILD", "BUILD.bazel")
_BOUNDARY_FILE_NAMES = ("MODULE.bazel", "REPO.bazel", "WORKSPACE", "WORKSPACE.bazel")
_BAZEL_FILE_NAMES = _BUILD_FILE_NAMES + _BOUNDARY_FILE_NAMES

# The engine module's MODULE.bazel, whichever repository the module is in.
_MODULE_FILE = Label("//:MODULE.bazel")

def checkout_root(rctx):
    """The checkout's root directory: the engine module's own.

    Not `rctx.workspace_root`, which is the main module's: the engine is a
    dependency of the Fuchsia spike's module
    (engine/src/flutter/build/bazel/toolchains/fuchsia), and the synced
    trees, the prebuilt Dart SDK and the converter are where the engine is.
    """
    return rctx.path(_MODULE_FILE).dirname

# Upper bound on the directories a synced tree may contain. Starlark has no
# unbounded loops; this is only reached when a symlink cycle makes the tree
# infinite (the largest tree today, the Dart SDK, has about 12,000).
_MAX_DIRECTORIES = 100000

def _write_build_file(rctx, build_file, build_file_content):
    if build_file != None:
        rctx.file("BUILD.bazel", rctx.read(build_file))
    elif build_file_content:
        rctx.file("BUILD.bazel", build_file_content)

def _mark_repository_boundary(rctx):
    # A boundary file keeps Bazel from treating any upstream WORKSPACE or
    # MODULE.bazel file as meaningful and makes the repository root explicit.
    if not rctx.path("REPO.bazel").exists:
        rctx.file("REPO.bazel", "")

def _join(directory, name):
    return directory + "/" + name if directory else name

def _directories_with_bazel_files(source):
    """Finds the directories of `source` that contain an upstream Bazel file.

    Returns them together with all of their ancestors, as a set of paths
    relative to `source` ("" for the root).

    The listings are read without registering watches: the rule is `local`,
    so it is re-run at every server start anyway, and watching every
    directory of a large tree is not free (on the Dart SDK's 12,000
    directories it doubled the fetch time and produced a 2 MB marker file).
    The price is that a dependency roll which adds a Bazel file deep inside
    an overlaid tree is only picked up at the next server start.
    """
    found = {}
    pending = [(source, "")]
    for _ in range(_MAX_DIRECTORIES):
        if not pending:
            return found
        directory, relative = pending.pop()
        for child in directory.readdir(watch = "no"):
            if child.is_dir:
                pending.append((child, _join(relative, child.basename)))
            elif child.basename in _BAZEL_FILE_NAMES:
                parts = relative.split("/") if relative else []
                for depth in range(len(parts) + 1):
                    found["/".join(parts[:depth])] = True
    fail("synced_repository: %s has more than %d directories; is there a symlink cycle?" % (source, _MAX_DIRECTORIES))

def _is_within(path, directory):
    """Whether `path` is `directory` or inside it."""
    return path == directory or path.startswith(directory + "/")

def _directory_at(source, mounted, relative):
    """The directory that stands at `relative` in the tree of `source`.

    Returns it and whether it belongs to one of `mounted` (path to the
    directory put there) rather than to `source` itself.
    """
    for path, directory in mounted.items():
        if relative == path:
            return directory, True
        if relative.startswith(path + "/"):
            return directory.get_child(relative[len(path) + 1:]), True
    return (source.get_child(relative) if relative else source), False

def _link_tree(rctx, source, overlaying, exclude, links, packages = [], directories = {}):
    """Populates the repository with symlinks to the contents of `source`.

    Entries are symlinked whole, with four exceptions, all re-created as real
    directories whose entries are symlinked one by one:

    * the root of the tree, so that the overlay BUILD file and the repository
      boundary marker can be written next to the upstream files;
    * when an overlay replaces the upstream Bazel build, every directory that
      contains an upstream BUILD, WORKSPACE or MODULE file (and its
      ancestors), with those files left out. Otherwise such a directory would
      be a package (or repository) of its own, and the overlay's globs could
      not see the files in it -- ICU, for example, ships
      `source/common/BUILD.bazel` for its own data-generation build;
    * the ancestors of each entry in `exclude` (paths relative to `source`),
      with the entry itself left out: what another build writes into a
      synced tree and Bazel must not see -- the Emscripten SDK's cache, which
      GN's wasm toolchain runs with the cache unfrozen, so that emcc builds
      system library variants into it and writes its symbol lists, lock
      files and a machine-specific `sanity.txt` beside the prebuilt sysroot,
      and the `__pycache__` directories of its Python. Exposed as directory
      inputs, those would change every wasm action's inputs with the first
      GN link (and vanish under Bazel's feet while it fingerprints the
      directory). These ancestors are listed without a watch, since their
      entries are exactly what the other build adds and removes;
    * each directory in `packages` (paths relative to `source`) and its
      ancestors: the directories below the root that get a BUILD file of
      their own (the packages of a tree whose GN files are converted one by
      one, SwiftShader's `src/Vulkan`), which has to land in the repository
      -- written into a directory symlinked whole, it would land in the
      synced tree.

    `links` (path to label) puts a directory of another repository at a path
    of the tree, in place of whatever the synced tree has there: the LTO
    system libraries built at fetch time (toolchains/emscripten/
    lto_libraries.bzl) where emcc's frozen cache looks for them. The label
    names the directory, in a repository whose root holds a BUILD file.
    `directories` (path to directory) does the same for a directory already
    at hand: a DEPS entry inside the tree that the checkout lacks, from its
    fetched_tree. Such a directory is part of the tree like any other: where
    the rules above would have re-created a directory of the synced one
    (cpu_features' `src` has upstream Bazel files, which the overlay hides),
    they re-create it here, from the fetched tree's entries.
    """
    expanded = _directories_with_bazel_files(source) if overlaying else {}
    expanded[""] = True
    excluded = {}
    unwatched = {}

    # The directories of `directories` that are not linked whole: those with
    # a Bazel file or a package inside.
    mounted = {}
    for path, directory in directories.items():
        inside = _directories_with_bazel_files(directory) if overlaying else {}
        if inside or [package for package in packages if _is_within(package, path)]:
            mounted[path] = directory
            for relative in inside.keys():
                expanded[_join(path, relative) if relative else path] = True
    for path in exclude + links.keys() + directories.keys():
        parts = path.split("/")
        for depth in range(len(parts)):
            ancestor = "/".join(parts[:depth])
            if ancestor not in expanded:
                unwatched[ancestor] = True
            expanded[ancestor] = True
        excluded[path] = True
    for path in packages:
        parts = path.split("/")
        for depth in range(len(parts) + 1):
            expanded["/".join(parts[:depth])] = True
    for path, label in links.items():
        target = Label(label)
        root = rctx.path(target.relative(":BUILD.bazel")).dirname
        rctx.symlink(root.get_child(target.name), path)
    for path, directory in directories.items():
        if path not in mounted:
            rctx.symlink(directory, path)

    # The tree's own entry at such a path is left out (`excluded`); the
    # directory that stands there is walked in its place.
    pending = [""] + mounted.keys()
    for _ in range(_MAX_DIRECTORIES):
        if not pending:
            return
        relative = pending.pop()
        directory, fetched = _directory_at(source, mounted, relative)

        # readdir() also registers a watch on the directory's entries, so adding
        # or removing one (for example after a roll) refreshes the repository
        # (except under an excluded entry's ancestors, see above, and inside
        # a fetched tree, which does not change). Changes inside the entries
        # are tracked like any source file.
        for child in directory.readdir(watch = "no" if fetched or relative in unwatched else "auto"):
            name = child.basename
            if name in _BOUNDARY_FILE_NAMES:
                continue
            if overlaying and name in _BUILD_FILE_NAMES:
                # The overlay replaces the upstream build files. Without an
                # overlay, upstream BUILD files remain visible as packages.
                continue
            child_relative = _join(relative, name)
            if child_relative in excluded:
                continue
            if child_relative in expanded:
                pending.append(child_relative)
            else:
                rctx.symlink(child, child_relative)

# For repository rules of this package's kind elsewhere (flutter_bin_cache.bzl).
link_tree = _link_tree

# ---------------------------------------------------------------------------
# A checkout without the synced trees
# ---------------------------------------------------------------------------

# Set (to anything but 0, false or no) to take every source tree from its
# fetched_tree even where the checkout has the directory: what a checkout
# without `gclient sync` builds, in one that has been synced.
_FETCH_SOURCES_ENV = "FLUTTER_BAZEL_FETCH_SOURCES"

def in_checkout(rctx, path, marker = "", source_tree = True):
    """Whether the checkout's directory `path` is what a repository reads.

    False when the checkout has no such directory (no `gclient sync`) -- or
    has it without `marker` in it --, and for every source tree when
    FLUTTER_BAZEL_FETCH_SOURCES is set.

    Args:
      rctx: the repository context.
      path: a directory DEPS populates, relative to the checkout's root.
      marker: a file of what DEPS puts there, relative to `path`, without
        which the directory does not count: for one the repository itself
        has files in (third_party/ninja's README).
      source_tree: whether `path` is a source tree, which
        FLUTTER_BAZEL_FETCH_SOURCES takes from its fetch.

    Returns:
      True when a repository reads the checkout's directory.
    """
    if source_tree and rctx.getenv(_FETCH_SOURCES_ENV, "") not in ("", "0", "false", "no"):
        return False
    directory = checkout_root(rctx).get_child(path)
    if not directory.exists or not directory.is_dir:
        return False
    return not marker or directory.get_child(marker).exists

def fetched_tree_directory(rctx, build_file):
    """The tree of a fetched_tree or fetched_archive, which this fetches if need be.

    Args:
      rctx: the repository context.
      build_file: the label of the BUILD file of the fetched repository.

    Returns:
      The tree's directory.
    """
    return rctx.path(build_file).dirname.get_child(FETCHED_TREE_DIRECTORY)

def _within(path, trees):
    """Whether `path` is one of `trees` (paths) or inside one."""
    for tree in trees:
        if path == tree or path.startswith(tree + "/"):
            return True
    return False

def checkout_view(rctx, name, trees, directories = [], skip = []):
    """Lays the directory `name` of the repository out as the checkout, with fetched trees in it.

    What a tool that reads the checkout by its layout sees where the
    checkout lacks its synced trees: the GN conversion (its GN root is
    engine/src, and a GN file imports another tree's by path), pub (the
    engine's pub workspace names its packages by path). Symlinks into the
    checkout, a directory whole wherever nothing below it differs.

    Args:
      rctx: the repository context.
      name: the directory to lay out, relative to the repository; replaced
        if it exists.
      trees: directories to put at paths of the checkout (path relative to
        the checkout's root, to the directory) in place of what the checkout
        has there: the fetched trees. One inside another is the outer one's
        own (a fetched tree holds the dependencies nested in it).
      directories: paths, relative to the checkout's root, made directories
        of the view with the checkout's entries linked one by one: where the
        tool writes beside what it reads.
      skip: names left out of every directory the view lists entry by entry:
        what the tool writes there itself.
    """
    rctx.delete(name)
    placed = {
        path: directory
        for path, directory in trees.items()
        if not _within(path.rpartition("/")[0], trees)
    }
    expanded = {"": True}
    for path in placed.keys():
        parts = path.split("/")
        for depth in range(1, len(parts)):
            expanded["/".join(parts[:depth])] = True
    for path in directories:
        parts = path.split("/")
        for depth in range(1, len(parts) + 1):
            expanded["/".join(parts[:depth])] = True
    for path, directory in placed.items():
        rctx.symlink(directory, name + "/" + path)

    root = checkout_root(rctx)
    pending = [""]
    for _ in range(_MAX_DIRECTORIES):
        if not pending:
            return
        relative = pending.pop()
        directory = root.get_child(relative) if relative else root
        if not directory.exists:
            # A directory only the synced trees make (third_party/pkg).
            continue
        for child in directory.readdir(watch = "no"):
            if child.basename in skip:
                continue
            child_relative = _join(relative, child.basename)
            if child_relative in placed:
                continue
            if child_relative in expanded:
                pending.append(child_relative)
            else:
                rctx.symlink(child, name + "/" + child_relative)
    fail("checkout_view(%s): more than %d directories" % (name, _MAX_DIRECTORIES))

# ---------------------------------------------------------------------------
# synced_repository
# ---------------------------------------------------------------------------

_CONVERTER = "engine/src/flutter/tools/gn_to_bazel"
_GN_ROOT = "engine/src"

# The engine's package configuration, which resolves the converter's own
# imports: `gclient sync` writes it (DEPS' pub_get_offline hook).
_ENGINE_PACKAGE_CONFIG = "engine/src/flutter/.dart_tool/package_config.json"

# What populates a synced directory, for the error when it is absent -- and
# what needs none of them: a checkout without `gclient sync` is a framework
# developer's, whose tests run on the prebuilt engine.
_MISSING_HINT = (
    "`gclient sync`; run it from the repository root (see DEPS). The framework's and the tool's " +
    "tests need no engine checkout: --config=prebuilt_engine takes the engine `flutter precache` downloads"
)

# The directory of the repository that is the conversion's view of the
# checkout while the converter runs (checkout_view), where the checkout
# lacks a tree the conversion reads.
_GN_VIEW = "gn_checkout_view"

# How the converter names a tree it was told the checkout lacks and finds it
# needs (tools/gn_to_bazel's --absent-tree), and how many it may name, one
# run each, before the conversion gives up.
_ABSENT_TREE_MARKER = "[absent-tree: "
_MAX_ABSENT_TREES = 32

def _gn_packages(rctx):
    """The directories below the root that `gn_build_files` makes packages.

    Paths relative to `path`: the directory of each GN file inside the synced
    tree, other than the tree's root (a GN file of the secondary source tree
    stands in for the root).
    """
    prefix = rctx.attr.path + "/"
    packages = []
    for file in rctx.attr.gn_build_files:
        directory = file.rpartition("/")[0]
        if directory.startswith(prefix):
            packages.append(directory[len(prefix):])
    return packages

def _gn_directory(path):
    """The GN directory of a checkout path under the GN root (`//flutter/third_party/zlib`), or None."""
    prefix = _GN_ROOT + "/"
    return "//" + path[len(prefix):] if path.startswith(prefix) else None

def _convert_gn(rctx, fetched):
    """Runs tools/gn_to_bazel over `gn_build_files`, writing into the repository.

    The converter is the checkout's own, run by DEPS' prebuilt Dart SDK with
    DEPS' `gn` (the tool repositories, `dart` and `gn`: the checkout's, or
    the packages where it has none). Every GN file it read (the depfile) and
    the converter's sources are watched, so a roll that changes a `.gni` or
    an edit to the converter re-runs the conversion on the next build.

    GN files name each other by path from the GN root, across trees
    (freetype's reads zlib's and libpng's). Where the checkout lacks a tree
    the conversion reads -- its own (`fetched`: path relative to the
    checkout's root, to the fetched tree) or another (`gn_trees`) -- the
    converter runs on a view of the checkout that has the fetched trees at
    their paths (checkout_view). A tree that `gn_trees` does not name and a
    GN file turns out to need is not silently missed: the converter is told
    which trees are absent, stops at the first path inside one that it
    cannot find, and the conversion fetches that tree and runs again.
    """
    checkout = checkout_root(rctx)

    # Each package's directory is the repository's own (_link_tree's
    # `packages`): a BUILD file written through a symlink would be one more
    # file of the synced tree, which GN and git see (or of a fetched tree,
    # which other repositories read).
    foreign = [str(checkout.realpath)] + [str(tree.realpath) for tree in fetched.values()]
    for package in _gn_packages(rctx):
        real = str(rctx.path(package).realpath)
        for root in foreign:
            if real.startswith(root + "/"):
                fail("synced_repository(%s): %s is a symlink out of the repository (into %s); its BUILD file would be written there" % (rctx.name, package, root))

    converter = checkout.get_child(_CONVERTER)
    packages = checkout.get_child(_ENGINE_PACKAGE_CONFIG)
    if not packages.exists:
        # No `gclient sync`, so no pub_get_offline hook: the same
        # configuration, resolved over the fetched packages.
        packages = rctx.path(rctx.attr.engine_package_config)

    fetchable = {path: label for label, path in rctx.attr.fetchable.items()}
    trees = dict(fetched)
    for path in rctx.attr.gn_trees:
        if path not in fetchable:
            fail("synced_repository(%s): gn_trees names %s, which is no git dependency of DEPS" % (rctx.name, path))
        if not in_checkout(rctx, path):
            trees[path] = fetched_tree_directory(rctx, fetchable[path])

    depfile = rctx.path("gn_to_bazel.d")
    view = rctx.path(_GN_VIEW)
    converted = False
    for _ in range(_MAX_ABSENT_TREES):
        if trees:
            checkout_view(rctx, _GN_VIEW, trees)
        base = view if trees else checkout
        absent = [
            _gn_directory(path)
            for path in sorted(fetchable.keys())
            if _gn_directory(path) and not _within(path, trees) and not in_checkout(rctx, path)
        ]
        arguments = [
            rctx.path(rctx.attr.dart),
            "--packages=%s" % packages,
            converter.get_child("bin/gn_to_bazel.dart"),
            "--root",
            base.get_child(_GN_ROOT),
            "--gn",
            rctx.path(rctx.attr.gn),
            "--out-dir",
            rctx.path(""),
            "--repository",
            rctx.attr.gn_repository,
            "--depfile",
            depfile,
            "--buildifier",
            "none",
        ] + [
            "--absent-tree=" + directory
            for directory in absent
        ] + [
            base.get_child(file)
            for file in rctx.attr.gn_build_files
        ]
        result = rctx.execute(arguments, timeout = 600)
        if result.return_code == 0:
            converted = True
            break

        # A tree the conversion needs and the checkout lacks, which gn_trees
        # does not name (a roll's new import): fetched, and noted so that
        # the next conversion need not find it the slow way.
        needed = result.stderr.partition(_ABSENT_TREE_MARKER)[2].partition("]")[0]
        path = _GN_ROOT + "/" + needed[2:] if needed.startswith("//") else ""
        if path not in fetchable or _within(path, trees):
            fail("synced_repository(%s): gn_to_bazel failed:\n%s%s" % (rctx.name, result.stdout, result.stderr))
        print("synced_repository(%s): the conversion reads %s, which is not in the checkout and not among its gn_trees (build_defs/repositories/extensions.bzl); fetching it." % (rctx.name, path))  # buildifier: disable=print
        trees[path] = fetched_tree_directory(rctx, fetchable[path])
    if not converted:
        fail("synced_repository(%s): gn_to_bazel asked for more than %d trees the checkout lacks" % (rctx.name, _MAX_ABSENT_TREES))

    prefix = str(view) + "/"
    for line in rctx.read(depfile).splitlines():
        if not line:
            continue
        if line.startswith(prefix):
            # A file read through the view: the checkout's own (watched
            # where it is), or a fetched tree's, which does not change.
            relative = line[len(prefix):]
            if _within(relative, trees):
                continue
            line = str(checkout.get_child(relative))
        rctx.watch(line)
    rctx.delete(depfile)
    rctx.delete(_GN_VIEW)
    rctx.watch_tree(converter.get_child("lib"))
    rctx.watch_tree(converter.get_child("bin"))

def _source_tree(rctx):
    """Where the repository's tree is, in a checkout with or without it.

    Returns the directory `path` stands for; the DEPS entries inside it that
    the checkout lacks, as directories to put at their paths (relative to
    `path`); and every tree taken from a fetched_tree, by its path relative
    to the checkout's root (for the GN conversion's view of the checkout).
    """
    members = {relative: label for label, relative in rctx.attr.fetched.items()}
    path = rctx.attr.path
    checkout = checkout_root(rctx)
    if "." in members:
        # `path` is a dependency of DEPS: the checkout's directory, or the
        # fetched tree, whole (with what DEPS nests in it).
        rctx.watch(checkout.get_child(path))
        if in_checkout(rctx, path, rctx.attr.marker, rctx.attr.source_tree):
            return checkout.get_child(path), {}, {}
        tree = fetched_tree_directory(rctx, members["."])
        return tree, {}, {path: tree}

    # `path` is a directory of the checkout with DEPS entries inside it
    # (third_party/cpu_features: the engine's BUILD.gn over DEPS' `src`).
    directories = {}
    fetched = {}
    for relative, label in members.items():
        member = path + "/" + relative
        rctx.watch(checkout.get_child(member))
        if not in_checkout(rctx, member, source_tree = rctx.attr.source_tree):
            tree = fetched_tree_directory(rctx, label)
            directories[relative] = tree
            fetched[member] = tree
    return checkout.get_child(path), directories, fetched

def _synced_repository_impl(rctx):
    if rctx.attr.build_file != None and rctx.attr.build_file_content:
        fail("synced_repository(%s): specify at most one of build_file and build_file_content" % rctx.name)
    converting = bool(rctx.attr.gn_build_files)
    if converting and (rctx.attr.build_file != None or rctx.attr.build_file_content):
        fail("synced_repository(%s): gn_build_files and an overlay BUILD file are mutually exclusive" % rctx.name)
    if converting != bool(rctx.attr.gn_repository):
        fail("synced_repository(%s): gn_build_files and gn_repository go together" % rctx.name)
    overlaying = converting or rctx.attr.build_file != None or bool(rctx.attr.build_file_content)

    if rctx.attr.fetched:
        source, directories, fetched = _source_tree(rctx)
    else:
        source, directories, fetched = checkout_root(rctx).get_child(rctx.attr.path), {}, {}
    if not source.exists or not source.is_dir:
        fail(
            "synced_repository(%s): %s does not exist. It is populated by " % (rctx.name, source) +
            (rctx.attr.missing_hint or _MISSING_HINT) + ".",
        )

    _link_tree(rctx, source, overlaying, rctx.attr.exclude, rctx.attr.links, _gn_packages(rctx), directories)
    if converting:
        _link_secondary(rctx)
        _convert_gn(rctx, fetched)
    else:
        _write_build_file(rctx, rctx.attr.build_file, rctx.attr.build_file_content)
    _mark_repository_boundary(rctx)

def _link_secondary(rctx):
    """Mirrors what sits beside a secondary-tree BUILD.gn into the repository.

    GN's secondary source tree (`//flutter/build/secondary/`) holds build
    files for directories that cannot carry their own; files beside such a
    BUILD.gn (expat's `expat_config/`) belong to the directory it stands in
    for, which is this repository. The converter maps their GN paths the
    same way.
    """
    if not rctx.attr.gn_secondary_dir:
        return
    secondary = checkout_root(rctx).get_child(rctx.attr.gn_secondary_dir)
    for child in secondary.readdir():
        name = child.basename
        if name in _BUILD_FILE_NAMES or name == "BUILD.gn" or name.endswith(".gni"):
            continue
        if rctx.path(name).exists:
            fail("synced_repository(%s): %s exists both in the synced tree and beside its secondary BUILD.gn" % (rctx.name, name))
        rctx.symlink(child, name)

synced_repository = repository_rule(
    implementation = _synced_repository_impl,
    doc = "A repository whose contents are a directory populated by `gclient sync`, consumed in place.",
    attrs = {
        "path": attr.string(
            mandatory = True,
            doc = "Directory relative to the repository root, as listed in DEPS (for example `engine/src/flutter/third_party/icu`).",
        ),
        "build_file": attr.label(
            allow_single_file = True,
            doc = "Overlay BUILD file for the repository root. Replaces the upstream root BUILD file, if " +
                  "any, and hides upstream BUILD files in subdirectories.",
        ),
        "build_file_content": attr.string(
            doc = "Inline overlay BUILD file content; mutually exclusive with `build_file`.",
        ),
        "gn_build_files": attr.string_list(
            doc = "GN build files (relative to the repository root) that tools/gn_to_bazel converts into " +
                  "this repository's BUILD files at fetch time; hides upstream BUILD files like an overlay.",
        ),
        "gn_repository": attr.string(
            doc = "With gn_build_files: `@name=//gn/dir` naming this repository and the GN directory " +
                  "that is its root (the converter's --repository). The converted files become the " +
                  "repository's packages.",
        ),
        "gn_secondary_dir": attr.string(
            doc = "With gn_build_files: the directory of GN's secondary source tree that stands in for " +
                  "the repository's root, whose files other than build files are mirrored into the " +
                  "repository.",
        ),
        "exclude": attr.string_list(
            doc = "Entries of the synced tree (paths relative to `path`) left out of the repository: " +
                  "what another build writes into the tree and Bazel must not see (see _link_tree).",
        ),
        "links": attr.string_dict(
            doc = "Directories of other repositories put at paths of the tree (path relative to `path` " +
                  "to the directory's label), in place of the synced tree's entry (see _link_tree).",
        ),
        "missing_hint": attr.string(
            doc = "What populates `path`, for the error when it is absent; `gclient sync` by default.",
        ),
        "fetched": attr.label_keyed_string_dict(
            doc = "What Bazel fetches of the dependencies of DEPS that `path` is or holds, read where " +
                  "the checkout lacks the directory: the BUILD file of each fetched repository " +
                  "(git_deps.bzl's fetched_tree, fetched_archive.bzl's fetched_archive), to the " +
                  "dependency's path relative to `path` (`.` for `path` itself).",
        ),
        "gn_trees": attr.string_list(
            doc = "With gn_build_files: the other dependencies of DEPS whose GN files the conversion " +
                  "reads (paths relative to the repository root, keys of `fetchable`), fetched for it " +
                  "where the checkout lacks them.",
        ),
        "fetchable": attr.label_keyed_string_dict(
            doc = "With gn_build_files: every git dependency of DEPS that has a fetched tree (the BUILD " +
                  "file of the tree's repository, to the dependency's path relative to the repository " +
                  "root): what the conversion can fetch, and what it tells the converter is absent.",
        ),
        "dart": attr.label(
            doc = "With gn_build_files: the `dart` that runs the converter (DEPS' prebuilt SDK for the host).",
        ),
        "gn": attr.label(
            doc = "With gn_build_files: the `gn` the converter parses GN files with (DEPS').",
        ),
        "engine_package_config": attr.label(
            doc = "With gn_build_files: the engine's package configuration for a checkout that has none " +
                  "(engine_packages.bzl), which resolves the converter's imports.",
        ),
        "marker": attr.string(
            doc = "A file of what DEPS puts at `path`, relative to it, without which the checkout's " +
                  "directory does not count as synced and `fetched` is read: for a directory the " +
                  "repository itself has files in (third_party/ninja, whose README is checked in beside " +
                  "where DEPS puts the package).",
        ),
        "source_tree": attr.bool(
            doc = "The repository is a source tree, which FLUTTER_BAZEL_FETCH_SOURCES takes from its " +
                  "fetched trees even where the checkout has the directory.",
        ),
    },
    # The repository only symlinks -- into the checkout, or into what Bazel
    # fetched in its place, which is a repository of its own for this reason
    # -- so it must be re-created when the checkout layout changes rather
    # than restored from a cache.
    local = True,
)

# ---------------------------------------------------------------------------
# cipd_package
# ---------------------------------------------------------------------------

_CIPD_DOWNLOAD_URL = "https://chrome-infra-packages.appspot.com/dl/{package}/+/{version}"

def cipd_download_url(package, version):
    """Returns the HTTPS URL that serves `version` of the CIPD `package` as a zip archive.

    Args:
      package: fully resolved CIPD package name (no `${platform}` template).
      version: an instance id, a ref, or a `key:value` tag.
    """
    if "${" in package:
        fail("cipd_download_url: unresolved template in package name %r" % package)

    # Colons would end up in Bazel's download cache file name, which breaks on
    # Windows; CIPD accepts the encoded form.
    return _CIPD_DOWNLOAD_URL.format(package = package, version = version.replace(":", "%3A"))

def _cipd_package_impl(rctx):
    if rctx.attr.build_file != None and rctx.attr.build_file_content:
        fail("cipd_package(%s): specify at most one of build_file and build_file_content" % rctx.name)

    url = cipd_download_url(rctx.attr.package, rctx.attr.version)
    download = rctx.download_and_extract(
        url = url,
        type = "zip",
        sha256 = rctx.attr.sha256,
        canonical_id = url,
        stripPrefix = rctx.attr.strip_prefix,
    )

    _write_build_file(rctx, rctx.attr.build_file, rctx.attr.build_file_content)
    _mark_repository_boundary(rctx)

    if rctx.attr.sha256:
        return None

    # Tell Bazel how to make this fetch reproducible (printed with --verbose).
    attrs = {name: getattr(rctx.attr, name) for name in _CIPD_PACKAGE_ATTRS if getattr(rctx.attr, name)}
    attrs["name"] = rctx.name
    attrs["sha256"] = download.sha256
    return attrs

_CIPD_PACKAGE_ATTRS = {
    "package": attr.string(
        mandatory = True,
        doc = "Fully resolved CIPD package name, for example `fuchsia/third_party/clang/linux-amd64`.",
    ),
    "version": attr.string(
        mandatory = True,
        doc = "CIPD instance id, ref, or `key:value` tag, exactly as written in DEPS.",
    ),
    "sha256": attr.string(
        doc = "sha256 of the zip archive CIPD serves for this instance. Optional, but " +
              "without it the download is not shared through the repository cache.",
    ),
    "build_file": attr.label(
        allow_single_file = True,
        doc = "BUILD file for the repository root.",
    ),
    "build_file_content": attr.string(
        doc = "Inline BUILD file content; mutually exclusive with `build_file`.",
    ),
    "strip_prefix": attr.string(
        doc = "A directory of the archive that becomes the repository's root (the Mac's JDK bundle: " +
              "`Contents/Home`); the archive's root by default.",
    ),
}

cipd_package = repository_rule(
    implementation = _cipd_package_impl,
    doc = "A repository populated by downloading one CIPD package instance over HTTPS.",
    attrs = _CIPD_PACKAGE_ATTRS,
)

# ---------------------------------------------------------------------------
# engine_version_repository
# ---------------------------------------------------------------------------

_VERSION_BZL = """\
# Generated by engine_version_repository (build_defs/repositories/repositories.bzl); do not edit.

\"\"\"The engine's version strings: shell/version/version.gni's arguments.\"\"\"

ENGINE_VERSION = {engine_version}
CONTENT_HASH = {content_hash}
PREBUILT_ENGINE_VERSION = {prebuilt_engine_version}
SKIA_VERSION = {skia_version}
DART_VERSION = {dart_version}
ENGINE_REALM = {engine_realm}
"""

_VERSION_BUILD = """\
# Generated by engine_version_repository (build_defs/repositories/repositories.bzl); do not edit.

package(default_visibility = ["//visibility:public"])

exports_files(["version.bzl"])
"""

# Whether the build carries the checkout's revision: `--config=stamp` (the
# root .bazelrc's `--repo_env=FLUTTER_BAZEL_STAMP=1`, which a bot's
# `--config=ci` includes). Unstamped, the default, the two strings that
# change with every commit -- the revision and the content hash -- are fixed
# words: nothing of git is read and nothing of it watched, so a commit, a
# rebase or a switch of branches re-runs no action for the version's sake
# (shell/version's compile and every link behind it, the frameworks'
# Info.plist, the archives' readmes, the Maven artifacts named by the
# revision), and a link is a cache hit across commits. Stamped, a build
# says what a GN build says: tools/gn asks git every time it generates one.
# A setting of this rule rather than Bazel's own --stamp because the
# revision names output files (the Maven artifacts' `1.0.0-<revision>`),
# which a value known only when an action runs cannot do.
_STAMP_ENV = "FLUTTER_BAZEL_STAMP"

# An unstamped build's revision and content hash: a revision's shape -- forty
# hexadecimal digits -- for whatever reads one (the tool's engine.stamp, a
# Maven version).
_UNSTAMPED = "0" * 40

# Override the values read from the checkout (a build without git, or one
# that must reproduce another's version strings), stamped or not.
_ENGINE_VERSION_ENV = "FLUTTER_BAZEL_ENGINE_VERSION"
_CONTENT_HASH_ENV = "FLUTTER_BAZEL_CONTENT_HASH"

# The engine artifacts' storage realm: Cocoon's FLUTTER_REALM on a bot
# (flutter_archives_v2 for a presubmit's engine, which is not in the release
# bucket; bin/internal/update_engine_version.sh writes it to
# bin/cache/engine.realm, which the tool reads under the storage base URL),
# empty elsewhere.
_ENGINE_REALM_ENV = "FLUTTER_REALM"

def _git(rctx, root, args):
    result = rctx.execute(["git", "-C", str(root)] + args)
    if result.return_code != 0:
        fail("engine_version: git %s failed in %s: %s" % (" ".join(args), root, result.stderr))
    return result.stdout.strip()

def _watch_head(rctx, root):
    """Re-runs the rule when HEAD moves: .git/HEAD, the ref it names, packed-refs."""
    git_dir = rctx.path(_git(rctx, root, ["rev-parse", "--absolute-git-dir"]))
    common_dir = rctx.path(_git(rctx, root, ["rev-parse", "--path-format=absolute", "--git-common-dir"]))
    head = git_dir.get_child("HEAD")
    rctx.watch(head)
    content = rctx.read(head).strip()
    if content.startswith("ref: "):
        rctx.watch(rctx.path(str(common_dir) + "/" + content[len("ref: "):]))
    rctx.watch(common_dir.get_child("packed-refs"))

def _content_hash(rctx, root):
    script = root.get_child("bin", "internal", "content_aware_hash")
    if rctx.os.name.lower().startswith("windows"):
        command = ["powershell.exe", "-ExecutionPolicy", "Bypass", str(script) + ".ps1"]
    else:
        command = [str(script) + ".sh"]
    result = rctx.execute(command, working_directory = str(root))
    if result.return_code != 0:
        fail("engine_version: %s failed: %s" % (command[-1], result.stderr))
    return result.stdout.strip()

def _prebuilt_engine_version(rctx, root):
    """The engine in bin/cache: bin/cache/engine.stamp's revision, or empty without one.

    What the tool wrote when it fetched the prebuilt engine (the commit a
    bot was given, a developer's content hash's build). A facsimile under
    --config=prebuilt_engine stamps the artifacts it still takes from the
    tree (the Android shard's gen_snapshots) with this rather than the
    build's own revision, so that every stamp of the facsimile's cache agrees
    with the engine.stamp it lays from bin/cache.
    """
    stamp = root.get_child("bin", "cache", "engine.stamp")
    rctx.watch(stamp)
    if not stamp.exists:
        return ""
    return rctx.read(stamp).strip()

def _engine_realm(rctx, root):
    """The engine artifacts' realm: FLUTTER_REALM, else the checkout's bin/cache/engine.realm, else empty.

    What the tool's SDK facsimile writes as its bin/cache/engine.realm
    (bin/internal:engine_realm): a tool test that downloads an engine
    artifact at run time (`flutter build ios` of the integration shard's
    ios_app_with_extensions_test) then looks in the bucket the checkout's
    own tool looks in -- without it, a presubmit's engine (realm
    flutter_archives_v2) is a 404 in the release bucket (the Mac
    tool_integration_tests_10 shard, 11-05).
    """
    realm = rctx.getenv(_ENGINE_REALM_ENV)
    if realm != None:
        return realm.strip()
    realm_file = root.get_child("bin", "cache", "engine.realm")
    rctx.watch(realm_file)
    if not realm_file.exists:
        return ""
    return rctx.read(realm_file).strip()

def _stamped(rctx):
    """Whether the build is stamped: FLUTTER_BAZEL_STAMP set, to anything but an empty word, 0, false or no."""
    value = rctx.getenv(_STAMP_ENV)
    return value != None and value.lower() not in ("", "0", "false", "no")

def _engine_version_repository_impl(rctx):
    root = checkout_root(rctx)
    engine_version = rctx.getenv(_ENGINE_VERSION_ENV)
    content_hash = rctx.getenv(_CONTENT_HASH_ENV)
    if _stamped(rctx) and (engine_version == None or content_hash == None):
        _watch_head(rctx, root)
        if engine_version == None:
            engine_version = _git(rctx, root, ["rev-parse", "HEAD"])
        if content_hash == None:
            content_hash = _content_hash(rctx, root)
    if engine_version == None:
        engine_version = _UNSTAMPED
    if content_hash == None:
        content_hash = _UNSTAMPED
    rctx.file("BUILD.bazel", _VERSION_BUILD)
    rctx.file("version.bzl", _VERSION_BZL.format(
        engine_version = repr(engine_version),
        content_hash = repr(content_hash),
        skia_version = repr(rctx.attr.skia_version),
        dart_version = repr(rctx.attr.dart_version),
        engine_realm = repr(_engine_realm(rctx, root)),
        prebuilt_engine_version = repr(_prebuilt_engine_version(rctx, root)),
    ))
    rctx.file("REPO.bazel", "")

engine_version_repository = repository_rule(
    implementation = _engine_version_repository_impl,
    doc = """The engine's version strings as a `version.bzl` of constants.

`tools/gn` sets shell/version/version.gni's arguments when it generates a GN
build: `engine_version` is the checkout's `git rev-parse HEAD`,
`content_hash` the output of bin/internal/content_aware_hash, and
`skia_version` and `dart_version` the HEADs of the synced Skia and Dart
trees, which are their DEPS pins. This rule does the same at fetch time for a
stamped build (`--config=stamp`, FLUTTER_BAZEL_STAMP in the repository
environment): the first two from git, re-read when HEAD moves. An unstamped
build, the default, has forty zeros for both and reads nothing of git.
`FLUTTER_BAZEL_ENGINE_VERSION` and `FLUTTER_BAZEL_CONTENT_HASH` in the
environment override either. The last two come from deps.lock.bzl through
the attributes. Besides: ENGINE_REALM, the
artifacts' storage realm (FLUTTER_REALM, else the checkout's
bin/cache/engine.realm, else empty), for the tool's SDK facsimile; and
PREBUILT_ENGINE_VERSION, bin/cache/engine.stamp's revision (empty without
one), for the facsimile's stamps under --config=prebuilt_engine.""",
    attrs = {
        "skia_version": attr.string(mandatory = True, doc = "Skia's DEPS revision."),
        "dart_version": attr.string(mandatory = True, doc = "The Dart SDK's DEPS revision."),
    },
    # Read from the checkout; re-created at every server start rather than
    # restored from a cache.
    local = True,
)
