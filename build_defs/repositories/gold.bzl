# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""`gold_expectations`: what Flutter Gold accepts, fetched for the golden tests.

A golden test of the framework renders an image and asks whether it is one
Flutter Gold (https://flutter-gold.skia.org) holds as correct for that test.
Outside Bazel the test asks Gold itself: `flutter test` on a developer's
machine requests a baseline image for every comparison, and the bots upload
every image with `goldctl`, which passes one whose digest is among the
test's positive digests. A test under Bazel has no network.

This repository is Gold's answer fetched beforehand: `expectations.json`,
the response of Gold's `/json/v2/expectations` -- every test's digests with
their triage status (1.3 MB for 4,200 tests in November 2026). flutter_test
(build_defs/dart/flutter_test.bzl) hands each test that compares goldens the
part for its own tests, and flutter_goldens' FlutterOfflineFileComparator
decides as `goldctl` does: an image passes when its digest is positive for
its test. A digest is the MD5 of the image's pixels, so the images
themselves are not needed to decide.

What Gold accepts changes whenever someone triages an image, and it is the
state of the head of the repository's main branch: there is no version of
it to pin. So the fetch is not reproducible, and is made again

- when HEAD moves (a pull brings tests whose new images have been triaged
  since; a snapshot older than the checkout fails them);
- when FLUTTER_GOLD_REFRESH (`--repo_env`) changes, to any other value;
- after `bazel clean --expunge` or `bazel fetch --force`.

For a pull request's run, FLUTTER_GOLD_CHANGELIST (`--repo_env`) is the pull
request's number: Gold then answers with the main branch's expectations and
the triage done on that pull request, so that an image accepted there passes
when the run is made again. dev/bots/bazel.dart sets it in a LUCI presubmit,
where the images a run fails are sent to Gold for that triage.

Without the network the file holds no test, and a comparison then passes
with a note, which is what the tests did under Bazel before there was this.
"""

_EXPECTATIONS = "expectations.json"

# The response for no test, in Gold's shape.
_NO_EXPECTATIONS = '{"primary": {}}\n'

def _watch_head(rctx):
    """Re-runs the rule when the checkout's HEAD moves, where it is a git checkout."""
    root = str(rctx.path(Label("//:MODULE.bazel")).dirname)
    git = rctx.which("git")
    if git == None:
        return
    directories = rctx.execute([git, "-C", root, "rev-parse", "--absolute-git-dir", "--path-format=absolute", "--git-common-dir"])
    if directories.return_code != 0:
        return
    git_dir, common_dir = [rctx.path(line) for line in directories.stdout.strip().splitlines()]
    head = git_dir.get_child("HEAD")
    rctx.watch(head)
    content = rctx.read(head).strip()
    if content.startswith("ref: "):
        rctx.watch(rctx.path(str(common_dir) + "/" + content[len("ref: "):]))
    rctx.watch(common_dir.get_child("packed-refs"))

def _gold_expectations_impl(rctx):
    rctx.getenv("FLUTTER_GOLD_REFRESH")
    _watch_head(rctx)
    url = rctx.attr.url
    changelist = rctx.getenv("FLUTTER_GOLD_CHANGELIST")
    if changelist:
        if not changelist.isdigit():
            fail("FLUTTER_GOLD_CHANGELIST is a pull request's number, not %r" % changelist)
        url = "%s?issue=%s&crs=github" % (url, changelist)
    result = rctx.download(
        url = url,
        output = _EXPECTATIONS,
        allow_fail = True,
    )
    if not result.success:
        # Noted, since the golden comparisons then compare nothing.
        print("gold_expectations: %s could not be fetched; the golden tests will compare nothing." % url)  # buildifier: disable=print
        rctx.file(_EXPECTATIONS, _NO_EXPECTATIONS)
    rctx.file("BUILD.bazel", """\
# What Flutter Gold accepts for each golden test, as fetched
# (build_defs/repositories/gold.bzl).
exports_files(["{file}"])
""".format(file = _EXPECTATIONS))
    rctx.file("REPO.bazel", "")

gold_expectations = repository_rule(
    implementation = _gold_expectations_impl,
    doc = "Flutter Gold's expectations (the triage status of every test's digests), fetched for the " +
          "golden tests to compare with: expectations.json.",
    attrs = {
        "url": attr.string(
            default = "https://flutter-gold.skia.org/json/v2/expectations",
            doc = "Where Gold serves its expectations.",
        ),
    },
)

def _gold_impl(mctx):
    gold_expectations(name = "gold_expectations")

    # The definition is the same everywhere (what is fetched is not), so
    # nothing needs recording in MODULE.bazel.lock.
    root = mctx.modules[0] if mctx.modules else None
    if root != None and root.is_root and root.name == "flutter":
        return mctx.extension_metadata(
            root_module_direct_deps = ["gold_expectations"],
            root_module_direct_dev_deps = [],
            reproducible = True,
        )
    return mctx.extension_metadata(reproducible = True)

gold = module_extension(
    implementation = _gold_impl,
    doc = "Flutter Gold's expectations as a repository (@gold_expectations).",
)
