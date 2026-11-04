# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Runs a GN build inside a Bazel action.

This is the action behind the `gn_build` rule (gn_build.bzl); read that file
first. The rule hands over one JSON parameter file and this script:

  1. assembles a GN source root in a scratch directory, made of symlinks to
     the action's inputs, laid out as `gn` expects them (`.gn`, `build/`,
     `flutter/third_party/dart/`, ...);
  2. writes `args.gn` and runs `gn gen` on that root for one root target;
  3. runs `ninja` on the target;
  4. copies the requested build products to the declared outputs, and
     creates one archive per requested GN library target from the object
     files of its dependency closure.

Everything is addressed relative to the action's working directory (the
execution root), so no path outside it ends up in a command line, in
`build.ninja` or in an output.
"""

import hashlib
import json
import os
import pwd
import re
import shutil
import subprocess
import sys
import time

_OUT_DIR_NAME = "bazel"  # //out/bazel inside the scratch root.


def _log(message):
    print(message, file=sys.stderr)


def _run(argv, cwd=None, log_path=None, env=None):
    """Runs a command; on failure prints its output and exits."""
    if log_path:
        with open(log_path, "w") as log:
            result = subprocess.run(argv, cwd=cwd, stdout=log, stderr=subprocess.STDOUT, env=env)
        if result.returncode != 0:
            with open(log_path, errors="replace") as log:
                tail = log.readlines()[-200:]
            _log("".join(tail))
    else:
        result = subprocess.run(argv, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=env)
        if result.returncode != 0:
            _log(result.stdout.decode(errors="replace"))
    if result.returncode != 0:
        _log("gn_build: command failed (%d): %s" % (result.returncode, " ".join(argv)))
        sys.exit(1)


# ---------------------------------------------------------------------------
# Remote compilation through reclient
# ---------------------------------------------------------------------------


class Reproxy:
    """reclient's proxy, started around the wrapped build when the parameters ask for RBE (gn_build.bzl's rbe).

    What the recipe does around a GN build on a bot (the rbe recipe module:
    `bootstrap --re_proxy=reproxy --cfg=reclient-<os>.cfg`, the environment,
    `bootstrap --shutdown`), done here around ninja, so that the wrapped
    build's compiles go to the workers through the rewrapper GN puts in
    front of the compiler (`use_rbe`: build/toolchain/rbe.gni). The proxy
    listens on a socket of its own under /tmp (a sandboxed action's /tmp is
    its own; the path has to be short, a Unix socket's limit being 108
    bytes), logs and keeps its dependency cache under the scratch
    directory, and authenticates as the configuration says -- Application
    Default Credentials: a bot's metadata server, a developer's gcloud login
    where HOME reaches the action. When it cannot start, the build goes on
    without it, locally, and says so: a developer's sandbox has no
    credentials, and a wrapped build is better slow than failed.
    """

    def __init__(self, params, scratch):
        self.params = params
        self.bootstrap = os.path.abspath(os.path.join(params["reclient_dir"], "bootstrap"))
        self.reproxy = os.path.abspath(os.path.join(params["reclient_dir"], "reproxy"))
        self.cfg = os.path.abspath(params["bootstrap_cfg"])
        logs = os.path.abspath(os.path.join(scratch, "reproxy"))
        tmp = os.path.join(logs, "tmp")
        os.makedirs(tmp, exist_ok=True)
        # The scanner refuses a temporary directory others could read.
        os.chmod(tmp, 0o700)
        self.logs = logs
        self.env = dict(os.environ)
        if not self.env.get("USER"):
            # The strict action environment has no USER; the scanner compares
            # it with the owner of its files.
            self.env["USER"] = pwd.getpwuid(os.getuid()).pw_name
        self.env.update({
            "RBE_server_address": "unix:///tmp/reproxy-%d.sock" % os.getpid(),
            "RBE_log_dir": logs,
            "RBE_proxy_log_dir": logs,
            "RBE_output_dir": logs,
            "RBE_cache_dir": os.path.join(logs, "deps_cache"),
            "RBE_log_format": "reducedtext",
            # The dependency scanner's temporary files: left to itself it
            # picks the user's runtime directory (/run/user/<uid>), which a
            # sandbox mounts read-only, and every compile then falls back to
            # the machine ("Failed to execute compiler to get c++ system
            # include paths"); the directory must be the user's alone (0700).
            "GOMA_TMP_DIR": tmp,
            "TMPDIR": tmp,
        })
        self.started = False

    def start(self):
        """Starts the proxy; True when it runs."""
        argv = [self.bootstrap, "--re_proxy=" + self.reproxy, "--cfg=" + self.cfg]
        result = subprocess.run(argv, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=self.env)
        if result.returncode != 0:
            _log("gn_build: reproxy did not start (%d); the build runs without RBE:\n%s" % (
                result.returncode, result.stdout.decode(errors="replace")[-4000:]))
            return False
        self.started = True
        return True

    def stop(self):
        """Stops the proxy and logs what it did (rbe_metrics.txt)."""
        if not self.started:
            return
        self.started = False
        argv = [self.bootstrap, "--shutdown", "--cfg=" + self.cfg]
        result = subprocess.run(argv, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=self.env)
        if result.returncode != 0:
            _log("gn_build: reproxy shutdown failed (%d):\n%s" % (
                result.returncode, result.stdout.decode(errors="replace")[-4000:]))
        metrics = os.path.join(self.logs, "rbe_metrics.txt")
        if os.path.exists(metrics):
            _log("gn_build: reproxy: " + _metrics_summary(metrics))


def _metrics_summary(path):
    """rbe_metrics.txt's record count and CompletionStatus counts as one line (a text proto: stats { name counts_by_value { name count } })."""
    records = None
    statuses = {}
    stat = None
    value = None
    with open(path, errors="replace") as f:
        for line in f:
            match = re.match(r'^num_records: (\d+)', line)
            if match:
                records = int(match.group(1))
                continue
            match = re.match(r'^\tname: "([^"]+)"', line)
            if match:
                stat = match.group(1)
                continue
            match = re.match(r'^\t\tname: "([^"]+)"', line)
            if match:
                value = match.group(1)
                continue
            match = re.match(r'^\t\tcount: (\d+)', line)
            if match and stat == "CompletionStatus" and value:
                statuses[value] = int(match.group(1))
    return "%s records; %s" % (
        records, ", ".join("%s %d" % item for item in sorted(statuses.items())) or "no completion statuses")


# ---------------------------------------------------------------------------
# Source root
# ---------------------------------------------------------------------------


def _prune_tree(root, expected, keep=()):
    """Removes links under `root` that are not in `expected`, and the directories left empty.

    Entries of `root` named in `keep` (the build directory) are not entered.
    """
    removed = 0
    directories = []
    # Top-down, so that dropping names from `dirnames` prunes the walk.
    for dirpath, dirnames, filenames in os.walk(root):
        if dirpath == root:
            dirnames[:] = [d for d in dirnames if d not in keep]
        directories.append(dirpath)
        # Symlinks to directories are listed in dirnames but not entered.
        for name in filenames + [d for d in dirnames if os.path.islink(os.path.join(dirpath, d))]:
            full = os.path.join(dirpath, name)
            if full not in expected:
                os.unlink(full)
                removed += 1
    for directory in reversed(directories):
        if directory != root and not os.listdir(directory):
            os.rmdir(directory)
    return removed


def _link_tree(root, tree):
    """Creates or refreshes the GN source root: a symlink per input file.

    Each entry of `tree` maps the files of one Bazel target (`files`, below
    the execution-root-relative directory `base`) to a path under the root.
    Linking file by file rather than directory by directory means that the GN
    build sees exactly the action's declared inputs, whether or not the
    action is sandboxed. Links that are already right are kept, so that a
    persistent root (unsandboxed runs) is refreshed rather than rebuilt.

    Returns the set of link paths.
    """
    links = set()
    made_dirs = set()
    for entry in tree:
        base = entry["base"]
        dest_base = os.path.join(root, entry["path"]) if entry["path"] else root
        for path in entry["files"]:
            if path == base:
                link = dest_base
            else:
                if not path.startswith(base + "/"):
                    raise SystemExit("gn_build: %s is not under %s" % (path, base))
                link = os.path.join(dest_base, path[len(base) + 1:])
            link_dir = os.path.dirname(link)
            if link_dir not in made_dirs:
                os.makedirs(link_dir, exist_ok=True)
                made_dirs.add(link_dir)
            target = os.path.relpath(path, link_dir)
            if os.path.lexists(link):
                if os.path.islink(link) and os.readlink(link) == target:
                    links.add(link)
                    continue
                if os.path.isdir(link) and not os.path.islink(link):
                    shutil.rmtree(link)
                else:
                    os.unlink(link)
            os.symlink(target, link)
            links.add(link)
    return links


# Files up to this size are digested whole; a larger one (a sysroot's or
# clang's binaries, a gigabyte between them) by its size and its first and
# last 64 KiB, which keeps the diagnostic to a few seconds. The files that
# could differ between two tasks on a bot are small.
_WHOLE_DIGEST_LIMIT = 1 << 20
_SAMPLE = 1 << 16


def _file_digest(path):
    size = os.path.getsize(path)
    digest = hashlib.sha256()
    with open(path, "rb") as f:
        if size <= _WHOLE_DIGEST_LIMIT:
            digest.update(f.read())
        else:
            digest.update(str(size).encode())
            digest.update(f.read(_SAMPLE))
            f.seek(-_SAMPLE, os.SEEK_END)
            digest.update(f.read(_SAMPLE))
    return digest.digest()


def _input_digests(tree):
    """One line per tree and per first-level directory of it: file count, digest of (path, content) pairs.

    Printed with the timing line so that two runs of the action on the bots
    can be compared: the wrapped builds never hit the bots' disk cache across
    tasks (PR #195825, 11-03) where the same inputs hit it across output bases
    on a workstation, and the lines name the directory whose contents differ.
    Costs a read of every input (a few seconds); to be removed once the cause
    is found.
    """
    lines = []
    for entry in tree:
        base = entry["base"]
        groups = {}
        for path in sorted(entry["files"]):
            rel = path[len(base) + 1:] if path.startswith(base + "/") else os.path.basename(path)
            group = rel.split("/", 1)[0] if "/" in rel else "."
            digest = hashlib.sha256()
            try:
                if os.path.isdir(path):
                    for dirpath, dirnames, filenames in os.walk(path):
                        dirnames.sort()
                        for name in sorted(filenames):
                            file_path = os.path.join(dirpath, name)
                            digest.update(os.path.relpath(file_path, path).encode())
                            digest.update(_file_digest(file_path))
                else:
                    digest.update(_file_digest(path))
            except OSError as error:
                digest.update(("unreadable: %s" % error).encode())
            count, tree_digest = groups.get(group, (0, hashlib.sha256()))
            tree_digest.update(rel.encode() + b"\0" + digest.digest())
            groups[group] = (count + 1, tree_digest)
        whole = hashlib.sha256()
        for group in sorted(groups):
            whole.update(groups[group][1].digest())
        lines.append("gn_build inputs %s: %d files %s" % (
            entry["path"] or ".", sum(c for c, _ in groups.values()), whole.hexdigest()[:16]))
        if len(groups) > 1:
            for group in sorted(groups):
                count, tree_digest = groups[group]
                lines.append("  %s/%s: %d %s" % (entry["path"] or ".", group, count, tree_digest.hexdigest()[:16]))
    return lines


def _root_path(root, tree, path):
    """Where an input appears inside the source root, or None if it is not linked there."""
    for entry in tree:
        base = entry["base"]
        if path == base:
            return os.path.join(root, entry["path"])
        if path.startswith(base + "/") and path in entry["files"]:
            return os.path.join(root, entry["path"], path[len(base) + 1:])
    return None


def _write_args(out_dir, args):
    lines = ["%s = %s" % (name, value) for name, value in sorted(args.items())]
    content = "\n".join(lines) + "\n"
    path = os.path.join(out_dir, "args.gn")
    if os.path.exists(path) and open(path).read() == content:
        return
    with open(path, "w") as f:
        f.write(content)


# ---------------------------------------------------------------------------
# Archives
# ---------------------------------------------------------------------------

_OBJECT_TARGET_TYPES = ("source_set", "static_library")
_FOLLOWED_TARGET_TYPES = _OBJECT_TARGET_TYPES + ("group", "action", "action_foreach", "copy", "generated_file")


def _strip_toolchain(label):
    return label.split("(", 1)[0]


def _closure(label, desc, stop_labels, stop_prefixes):
    """The targets whose objects belong to `label`'s archive.

    Walks `deps` from `label`, not entering other exported labels or targets
    whose label starts with one of `stop_prefixes` (those come from Bazel
    dependencies of the archive's facade) and not following executables and
    shared libraries, which are build products of their own.
    """
    result = []
    seen = set()
    pending = [label]
    while pending:
        current = _strip_toolchain(pending.pop())
        if current in seen:
            continue
        seen.add(current)
        target = desc.get(current)
        if target is None:
            raise SystemExit("gn_build: %s (reached from %s) is not in the GN build" % (current, label))
        kind = target["type"]
        if kind not in _FOLLOWED_TARGET_TYPES:
            continue
        if kind in _OBJECT_TARGET_TYPES:
            result.append(current)
        for dep in target.get("deps", []):
            stripped = _strip_toolchain(dep)
            if stripped in stop_labels or stripped.startswith(stop_prefixes):
                continue
            pending.append(dep)
    return result


def _gn_desc(gn, gn_switches, out_dir, what):
    """`gn desc` of every target, as JSON. Needs the switches `gn gen` ran with."""
    argv = [gn, "desc", out_dir, "*"] + ([what] if what else []) + gn_switches + ["--format=json"]
    result = subprocess.run(argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode != 0:
        _log(result.stderr.decode(errors="replace"))
        raise SystemExit("gn_build: gn desc failed")
    return json.loads(result.stdout)


def _make_archives(params, gn, gn_switches, out_dir):
    archives = params["archives"]
    if not archives:
        return
    desc = _gn_desc(gn, gn_switches, out_dir, None)
    source_outputs = _gn_desc(gn, gn_switches, out_dir, "source_outputs")
    exported = {_strip_toolchain(spec["label"]) for spec in archives.values()}
    stop_prefixes = tuple(params["archive_boundaries"])

    claimed = {}
    for output, spec in sorted(archives.items()):
        label = _strip_toolchain(spec["label"])
        objects = []
        for target in _closure(label, desc, exported - {label}, stop_prefixes):
            for outputs in source_outputs.get(target, {}).get("source_outputs", {}).values():
                for path in outputs:
                    if path.endswith(".o"):
                        objects.append(path)
                        owner = claimed.setdefault(path, label)
                        if owner != label:
                            raise SystemExit(
                                "gn_build: %s is reached from both %s and %s; export the GN "
                                "target that owns it as an archive of its own so that neither "
                                "contains it twice" % (path, owner, label))
        if not objects:
            raise SystemExit("gn_build: no object files for %s" % label)
        # Object paths are relative to the build directory, so ar runs there.
        response = os.path.basename(output) + ".objects"
        with open(os.path.join(out_dir, response), "w") as f:
            f.write("\n".join(sorted(objects)) + "\n")
        if os.path.lexists(output):
            os.unlink(output)
        # D: deterministic (zeroed uids and timestamps); c: create; s: index.
        _run([os.path.abspath(params["ar"]), "rcsD", os.path.abspath(output), "@" + response], cwd=out_dir)
        # The archive holds every object: an archiver that quietly skipped
        # them (an 8-byte `!<arch>` with 404 objects listed, the Mac's T11)
        # would leave a link to fail far from here.
        listing = subprocess.run(
            [os.path.abspath(params["ar"]), "t", os.path.abspath(output)],
            cwd=out_dir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        members = [m for m in listing.stdout.decode(errors="replace").splitlines() if m]
        if listing.returncode != 0 or len(members) != len(objects):
            missing = [o for o in objects if not os.path.exists(os.path.join(out_dir, o))]
            raise SystemExit(
                "gn_build: %s holds %d members for %d objects of %s (ar t exit %d; %d of the objects "
                "do not exist: %s)" % (
                    os.path.basename(output), len(members), len(objects), label, listing.returncode,
                    len(missing), " ".join(missing[:5])))
        _log("  %s: %d objects from %s" % (os.path.basename(output), len(objects), label))


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def _copy_output(src, dest):
    if os.path.lexists(dest):
        os.unlink(dest)
    shutil.copyfile(src, dest)
    shutil.copymode(src, dest)


def main(argv):
    with open(argv[1]) as f:
        params = json.load(f)

    cpus = os.cpu_count() or 1
    jobs = cpus
    scratch = params["scratch"]
    root = os.path.join(scratch, "root")
    out_dir = os.path.join(root, "out", _OUT_DIR_NAME)
    os.makedirs(out_dir, exist_ok=True)

    started = time.monotonic()
    links = _link_tree(root, params["tree"])
    _prune_tree(root, links, keep=("out",))
    linked = time.monotonic()
    digest_lines = _input_digests(params["tree"])
    digested = time.monotonic()

    args = dict(params["gn_args"])
    env = None
    reproxy = None
    if params.get("rbe"):
        reproxy = Reproxy(params["rbe"], scratch)
        if reproxy.start():
            # The compiles on the workers: the recipe's job count (80 a core)
            # and GN's RBE arguments (use_rbe, the rewrapper's configuration
            # and strategy, from gn_build.bzl).
            args.update(params["rbe"]["gn_args"])
            jobs = cpus * 80
            env = reproxy.env
        else:
            reproxy = None
    args.setdefault("concurrent_toolchain_jobs", str(cpus))
    _write_args(out_dir, args)
    try:
        return _build(params, scratch, root, out_dir, jobs, env, started, linked, digested, links, digest_lines)
    finally:
        # Whatever happens to the build, the proxy does not outlive the action.
        if reproxy:
            reproxy.stop()


def _build(params, scratch, root, out_dir, jobs, env, started, linked, digested, links, digest_lines):
    """`gn gen`, ninja, the outputs, the archives and the timing line; the exit status."""

    # GN records the script interpreter's path relative to the build
    # directory when it is inside the root, so it is used through the symlink
    # tree when the tree contains it. (GN resolves its own path for the
    # regeneration rule, so there is no point in doing the same for gn.)
    gn = params["gn"]
    python = _root_path(root, params["tree"], params["python"]) or params["python"]
    gn_switches = [
        "--root=" + root,
        "--root-target=" + params["root_target"],
        "--script-executable=" + os.path.relpath(python, out_dir),
    ]
    _run([gn, "gen", out_dir] + gn_switches + ["--export-compile-commands", "--fail-on-unused-args"])
    generated = time.monotonic()

    _run(
        [params["ninja"], "-C", out_dir, "-j", str(jobs), params["ninja_target"]],
        log_path=os.path.join(scratch, "ninja.log"),
        env=env,
    )
    built = time.monotonic()

    for output, path in params["outputs"].items():
        _copy_output(os.path.join(out_dir, path), output)
        install_name = params.get("install_names", {}).get(output)
        if install_name:
            # A dynamic library's install name, rewritten on the copy (see
            # gn_build.bzl's install_names).
            _run([params["install_name_tool"], "-id", install_name, output])
    _make_archives(params, gn, gn_switches, out_dir)

    if params.get("compile_commands"):
        # GN writes the absolute build directory, and //build/config/gcc's
        # relative_paths config puts the absolute source root into every
        # command (-fdebug-prefix-map). Both are rewritten relative to the
        # execution root, which keeps the file reproducible and free of
        # paths outside it; consumers prefix the execution root themselves.
        execroot_prefix = os.getcwd() + "/"
        with open(os.path.join(out_dir, "compile_commands.json")) as f:
            commands = json.load(f)
        for command in commands:
            command["directory"] = out_dir
            command["command"] = command["command"].replace(execroot_prefix, "")
        with open(params["compile_commands"], "w") as f:
            json.dump(commands, f, indent=2)
    finished = time.monotonic()

    _log("gn_build %s: %d links %.1fs, input digests %.1fs, gn gen %.1fs, ninja -j%d%s %.0fs, outputs %.1fs" % (
        params["root_target"], len(links), linked - started, digested - linked, generated - digested,
        jobs, " with RBE" if env else "", built - generated, finished - built))
    for line in digest_lines:
        _log(line)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
