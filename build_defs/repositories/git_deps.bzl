# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""`fetched_tree`: a tree of DEPS fetched by Bazel, laid out as `gclient sync` lays it.

A checkout without `gclient sync` has none of the directories DEPS names.
`synced_repository` (repositories.bzl) takes such a directory from a
fetched_tree instead: the dependency's git revision (a shallow fetch of the
one commit DEPS pins), the dependencies DEPS nests inside it (the Dart
tree's `third_party/pkg/*`; its bootstrap SDK, a CIPD package), and what
gclient and its hooks would have written into the tree (`files`, `hooks`).
The result is a directory that could have been a synced checkout's, so that
everything that reads a synced tree -- the overlays, the fetch-time GN
conversion, the wrapped GN builds -- reads this one unchanged.

A nested dependency is fetched in place (`nested`) where the tree runs
hooks, which want a tree they can write into and resolve paths in (the Dart
tree's read their own location through symlinks). Elsewhere it is the
nested dependency's own fetched_tree, linked in place (`linked`): the
vulkan-deps directory holds ten dependencies that are repositories of their
own, and nothing is fetched twice.

The pins are deps.lock.bzl's, generated from DEPS: one place says what a
revision is, whoever fetches it.

The tree is the repository's `tree/` directory rather than its root: the
repository's own BUILD and REPO files then sit beside the tree's files and
not among them (abseil's root has a BUILD.bazel of its own, which its
synced_repository reads).

The rule is in a file of its own, which loads no other: a repository is
fetched again when the file that defines its rule changes, or one that file
loads, and these are the expensive ones (the Dart tree alone is well over
a gigabyte).
"""

# The directory of a fetched_tree's repository that holds the tree.
FETCHED_TREE_DIRECTORY = "tree"

_TIMEOUT = 3600

# How often a fetch is tried before the repository fails: the servers answer
# a burst of requests (a cold build fetches dozens of trees at once) with
# the odd refusal.
_FETCH_ATTEMPTS = 3

# What a hook's `dart pub get` records as the pub cache (the Dart tree's
# package configuration names it): a path that is the same on every machine
# and is no directory, where gclient's hook writes the user's ~/.pub-cache.
# The packages are all path dependencies; nothing is read from a cache.
_PUB_CACHE = "/dev/null/pub-cache"

def _execute(rctx, arguments, what, environment = {}, working_directory = ""):
    result = rctx.execute(
        arguments,
        timeout = _TIMEOUT,
        environment = environment,
        working_directory = working_directory,
    )
    if result.return_code != 0:
        fail("fetched_tree(%s): %s failed (exit %d):\n%s%s" % (
            rctx.name,
            what,
            result.return_code,
            result.stdout,
            result.stderr,
        ))

def _fetch_git(rctx, git, directory, url, revision):
    """One commit of `url` checked out into `directory`, as a shallow clone.

    What `gclient sync --no-history` leaves: a work tree with its `.git`,
    HEAD detached at the revision. The server is asked for the commit by
    its id (every host of DEPS allows that), so the fetch is the size of one
    tree whatever the repository's history.
    """
    environment = {"GIT_TERMINAL_PROMPT": "0"}
    _execute(rctx, [git, "init", "-q", directory], "git init", environment)
    fetch = [git, "-C", directory, "fetch", "-q", "--no-tags", "--depth=1", url, revision]
    sleep = rctx.which("sleep")
    fetched = False
    for attempt in range(1, _FETCH_ATTEMPTS):
        if rctx.execute(fetch, timeout = _TIMEOUT, environment = environment).return_code == 0:
            fetched = True
            break
        if sleep != None:
            rctx.execute([sleep, str(10 * attempt)])
    if not fetched:
        # The last attempt, whose failure is the repository's.
        _execute(rctx, fetch, "git fetch %s %s" % (url, revision), environment)

    # -f: a nested dependency's directory may hold files of the tree around
    # it (the Dart tree has a README where its devtools go).
    _execute(
        rctx,
        [git, "-C", directory, "-c", "advice.detachedHead=false", "checkout", "-q", "-f", "FETCH_HEAD"],
        "git checkout %s" % revision,
        environment,
    )

def _fetched_tree_impl(rctx):
    git = rctx.which("git")
    if git == None:
        fail("fetched_tree(%s): git is not on PATH; it fetches %s, which this checkout does not have " % (rctx.name, rctx.attr.url) +
             "(`gclient sync` populates it, see DEPS)")

    # Noted, since it is the build that downloads here and not gclient.
    print("fetched_tree(%s): fetching %s (%s at %s), which is not read from the checkout." % (
        rctx.name,
        rctx.attr.path,
        rctx.attr.url,
        rctx.attr.revision,
    ))  # buildifier: disable=print

    tree = rctx.path(FETCHED_TREE_DIRECTORY)
    rctx.report_progress("Fetching %s" % rctx.attr.path)
    _fetch_git(rctx, git, str(tree), rctx.attr.url, rctx.attr.revision)

    # Parents before children: a nested dependency may hold another.
    for relative in sorted(rctx.attr.nested.keys()):
        url, _, revision = rctx.attr.nested[relative].rpartition("@")
        rctx.report_progress("Fetching %s/%s" % (rctx.attr.path, relative))
        _fetch_git(rctx, git, str(tree.get_child(relative)), url, revision)

    for build_file, relative in rctx.attr.linked.items():
        place = tree.get_child(relative)
        if place.exists:
            # The tree may name the dependency as a submodule, whose place a
            # checkout leaves an empty directory; anything else there would
            # be lost under the link.
            if not place.is_dir or place.readdir(watch = "no"):
                fail("fetched_tree(%s): %s holds files of the tree where DEPS puts a dependency of its own; fetch it in place (nested)" % (rctx.name, relative))
            rctx.delete(place)
        rctx.symlink(
            rctx.path(build_file).dirname.get_child(FETCHED_TREE_DIRECTORY),
            FETCHED_TREE_DIRECTORY + "/" + relative,
        )

    for relative in sorted(rctx.attr.cipd.keys()):
        rctx.report_progress("Downloading %s/%s" % (rctx.attr.path, relative))
        url = rctx.attr.cipd[relative]
        output = FETCHED_TREE_DIRECTORY + "/" + relative
        rctx.download_and_extract(
            url = url,
            output = output,
            type = "zip",
            sha256 = rctx.attr.cipd_sha256.get(relative, ""),
            canonical_id = url,
        )

        # The archive's own manifest, which `cipd ensure` does not install.
        rctx.delete(output + "/.cipdpkg")

    for relative, content in rctx.attr.files.items():
        rctx.file(FETCHED_TREE_DIRECTORY + "/" + relative, content)

    if rctx.attr.hooks:
        python = rctx.path(rctx.attr._python)
        home = rctx.path("home")
        for hook in rctx.attr.hooks:
            rctx.report_progress("Running %s/%s" % (rctx.attr.path, hook))
            _execute(
                rctx,
                [python, hook],
                hook,
                environment = {"HOME": str(home), "PUB_CACHE": _PUB_CACHE},
                working_directory = str(tree),
            )
        rctx.delete(home)

    rctx.file("BUILD.bazel", "# A tree of DEPS fetched by Bazel (build_defs/repositories/git_deps.bzl): %s/.\n" % FETCHED_TREE_DIRECTORY)
    rctx.file("REPO.bazel", "")

fetched_tree = repository_rule(
    implementation = _fetched_tree_impl,
    doc = "A git dependency of DEPS, with the dependencies nested in it, fetched as `gclient sync` lays " +
          "them out: for a checkout that has no such directory.",
    attrs = {
        "path": attr.string(
            mandatory = True,
            doc = "The dependency's directory as DEPS names it, for messages.",
        ),
        "url": attr.string(
            mandatory = True,
            doc = "The git repository.",
        ),
        "revision": attr.string(
            mandatory = True,
            doc = "The commit DEPS pins, in full.",
        ),
        "nested": attr.string_dict(
            doc = "The git dependencies DEPS puts inside this one that are fetched in place: path relative " +
                  "to the tree to `<url>@<revision>`.",
        ),
        "linked": attr.label_keyed_string_dict(
            doc = "The git dependencies DEPS puts inside this one that are linked in from fetched trees " +
                  "of their own: the BUILD file of each one's repository, to its path relative to the tree.",
        ),
        "cipd": attr.string_dict(
            doc = "The CIPD packages DEPS puts inside the tree: path relative to the tree to the package's " +
                  "download URL (repositories.bzl's cipd_download_url).",
        ),
        "cipd_sha256": attr.string_dict(
            doc = "The sha256 of a package of `cipd`, by its path; without it the download is unverified " +
                  "and not shared through the repository cache.",
        ),
        "files": attr.string_dict(
            doc = "Files gclient itself writes into the tree (its gclient_gn_args_file): path relative to " +
                  "the tree to the content.",
        ),
        "hooks": attr.string_list(
            doc = "Python scripts of the tree that DEPS runs as hooks after a sync, relative to the tree, " +
                  "run in order from the tree's root once everything is fetched.",
        ),
        "_python": attr.label(
            default = "@cpython3//:bin/python3",
            doc = "The interpreter of the hooks: DEPS' own Python.",
        ),
    },
)
