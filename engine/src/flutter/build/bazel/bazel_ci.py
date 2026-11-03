#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The engine's CI on Bazel without a change to its recipe (see ci.md).

The engine_v2 recipe builds a builder file's build by running three scripts
of this repository: `tools/gn <flags>`, then the checkout's `ninja -C
out/<dir> <targets>`, then the build's test steps (`testing/run_tests.py
--variant <dir> --type ...` among them). With `--bazel` among the flags,
tools/gn writes no GN build: it looks the flags up among the builder files'
builds (builds.json beside this module, which the converter generates with
ci/builders/BUILD.bazel) and writes a `build.ninja` into the build directory
whose one edge runs the build's Bazel install target (`bazel_ci.py install
<dir>`: `bazelisk run --config=<name> //engine/src/flutter/ci/builders:<name>
-- <dir>`, which builds what the ninja targets build and lays it into the
directory as GN would) -- with a phony edge per ninja target, so that the
recipe's `ninja -C out/<dir> <targets>` runs the Bazel build. It also writes
`bazel.json` beside it, which the edge reads and from which run_tests.py
knows to run each `--type` as `bazelisk test --config=<name> <the type's
suites>` rather than from the directory.

This module is what both scripts share: the builds' table, the match of a
flag list against it, the files written into the build directory, and the
commands. It runs under the Python the recipe runs tools/gn with (python3,
the standard library alone).
"""

import json
import os
import shutil
import subprocess
import sys

# The flags of a build that say where it runs rather than what it builds:
# the recipe appends `--no-goma --no-rbe` to an official build's; `--bazel`
# is this mode's own. They are left out when a flag list is matched against
# the builder files'.
INFRA_FLAGS = frozenset(['--bazel', '--rbe', '--no-rbe', '--goma', '--no-goma'])

# The value flags of the same kind: the recipe appends reproxy's address
# (`--rbe-server-address=unix://...`) to a build with --rbe.
_INFRA_VALUE_FLAGS = ('--rbe-server-address',)

# `--gn-args=engine_version="<rev>"` is what the recipe adds to a monorepo
# build (the engine's version string); a Bazel build stamps the version from
# the checkout (@engine_version), so the flag is matched away too.
_IGNORED_GN_ARGS = ('engine_version=',)

# What the recipe appends under its `no_lto` property (cocoon sets it on a
# release builder's presubmit builds: a try build without LTO is a faster
# one): a build whose own flags lack it matches without it and runs with
# LTO off -- the Bazel setting the converter maps `--no-lto` to
# (build/bazel/BUILD.bazel's `lto`, on in the configuration otherwise).
NO_LTO_FLAG = '--no-lto'
LTO_OFF_OPTION = '--//engine/src/flutter/build/bazel:lto=false'

# Where the build directory's Bazel files go.
NINJA_FILE = 'build.ninja'
BAZEL_JSON = 'bazel.json'
STAMP = 'bazel_install.stamp'

# The Bazel configuration every CI invocation adds (the root .bazelrc's
# `ci` config: plain output for a log, failures spelled out).
CI_CONFIG = 'ci'


class BazelCiError(Exception):
  """A reason the Bazel build cannot stand in for the GN one, for the user."""


def host_os():
  """The host as the builder files' table keys it: `linux` or `mac`."""
  if sys.platform == 'darwin':
    return 'mac'
  if sys.platform.startswith('linux'):
    return 'linux'
  raise BazelCiError(f'tools/gn --bazel runs on Linux and macOS hosts; this is {sys.platform}')


def repo_root(engine_src):
  """The flutter/flutter checkout that holds `engine/src` (the Bazel workspace)."""
  return os.path.dirname(os.path.dirname(os.path.abspath(engine_src)))


def builds_table(engine_src):
  """The path of the converter's table of the builder files' builds."""
  return os.path.join(engine_src, 'flutter', 'build', 'bazel', 'builds.json')


def load_builds(engine_src, host=None):
  """The builds of the host from build/bazel/builds.json."""
  with open(builds_table(engine_src), encoding='utf-8') as table_file:
    table = json.load(table_file)
  return table['builds'][host or host_os()]


def normalized_flags(flags):
  """A flag list as it is matched: `--x=v` split into `--x v`, the infrastructure flags out.

  The order is kept: the recipe passes the builder file's flags as written,
  with its own appended, and the table holds the file's.
  """
  out = []
  for flag in flags:
    if flag in INFRA_FLAGS:
      continue
    if flag.startswith('--gn-args=') and flag[len('--gn-args='):].startswith(_IGNORED_GN_ARGS):
      continue
    if flag.split('=', 1)[0] in _INFRA_VALUE_FLAGS:
      continue
    if flag.startswith('--') and '=' in flag:
      name, value = flag.split('=', 1)
      out.extend([name, value])
    else:
      out.append(flag)
  return out


def _target_dir(flags):
  """The `--target-dir` value among normalized flags, if any."""
  for i, flag in enumerate(flags):
    if flag == '--target-dir' and i + 1 < len(flags):
      return flags[i + 1]
  return None


def match_build(builds, flags):
  """The build of `builds` whose tools/gn flags are `flags` (infrastructure flags aside).

  The build is returned with an `options` list: the Bazel options the
  flags add to its configuration (LTO off when the recipe appended
  `--no-lto` to a build that has it on). Raises BazelCiError when none
  matches (naming the builds of the same build directory, if any, and
  their flags), or when the matching builds disagree about their Bazel
  configuration.
  """
  wanted = normalized_flags(flags)
  options = []
  matches = [build for build in builds if normalized_flags(build['gn']) == wanted]
  if not matches and NO_LTO_FLAG in wanted:
    without = [flag for flag in wanted if flag != NO_LTO_FLAG]
    matches = [build for build in builds if normalized_flags(build['gn']) == without]
    if matches:
      options.append(LTO_OFF_OPTION)
  if not matches:
    directory = _target_dir(wanted)
    nearest = [build for build in builds if directory and build.get('build_directory') == directory]
    lines = [
        'tools/gn --bazel: no build of the builder files (ci/builders/*.json, as '
        'build/bazel/builds.json lists them) has these flags:',
        '  ' + ' '.join(wanted),
    ]
    if nearest:
      lines.append(f'The builds of the same directory ({directory}) have:')
      for build in nearest:
        lines.append(
            f"  {build['file']}'s {build['name']}: {' '.join(normalized_flags(build['gn']))}"
        )
    lines.append(
        'A Bazel build of other flags is `et build --backend bazel` (a local engine); '
        'a new builder build needs the converter rerun (tools/gn_to_bazel) for its table.'
    )
    raise BazelCiError('\n'.join(lines))
  configs = {(build['config'], build['install']) for build in matches}
  if len(configs) != 1:
    names = ', '.join(f"{build['file']}'s {build['name']}" for build in matches)
    raise BazelCiError(
        f'tools/gn --bazel: {names} have the same flags but different Bazel '
        f'configurations ({sorted(configs)}); the converter should have refused them'
    )
  build = matches[0]
  if build['config'] is None:
    raise BazelCiError(
        f"tools/gn --bazel: {build['file']}'s {build['name']} has no Bazel configuration: " +
        '; '.join(build['unsupported'])
    )
  if build['install'] is None:
    raise BazelCiError(
        f"tools/gn --bazel: {build['file']}'s {build['name']} has no install target "
        '(nothing among its ninja targets has a Bazel counterpart' + (
            f"; not built: {', '.join(build['ninja_targets_not_built'])}"
            if build['ninja_targets_not_built'] else ''
        ) + ')'
    )
  return {**build, 'options': options}


def find_bazelisk(engine_src):
  """bazelisk: DEPS' (download_bazelisk; third_party/bazelisk), else the one on PATH."""
  exe = 'bazelisk.exe' if sys.platform.startswith('win') else 'bazelisk'
  synced = os.path.join(engine_src, 'flutter', 'third_party', 'bazelisk', exe)
  if os.path.isfile(synced):
    return synced
  on_path = shutil.which('bazelisk')
  if on_path:
    return on_path
  raise BazelCiError(
      'tools/gn --bazel needs bazelisk: sync with the gclient variable download_bazelisk '
      f'set (DEPS puts it at {synced}) or install it on PATH '
      '(https://github.com/bazelbuild/bazelisk#installation)'
  )


def on_bot():
  """Whether this runs on a LUCI bot (the recipe sets LUCI_CONTEXT)."""
  return 'LUCI_CONTEXT' in os.environ


def bazel_home(engine_src):
  """The directory that keeps Bazel's state for a build of this checkout.

  On a bot, the task's temporary directory (`TMPDIR`, which the recipe
  engine sets for every step of a build; swarming removes it with the
  task), under `bazel_ci`. Nothing under the checkout outlives a build there: the recipe
  force-mounts the `builder` cache at the start of every build, clobbering
  the checkout and whatever is beneath it -- and an output root left
  beneath it made the next build's clobber take an hour (the first
  presubmit runs, PR #195825). A developer's state goes under the
  checkout's `.bazel_ci/` (ignored by git), where it persists; BAZEL_CI_HOME
  overrides both. The output root is under it, and so is bazelisk's
  download of Bazel.
  """
  override = os.environ.get('BAZEL_CI_HOME')
  if override:
    return override
  if on_bot():
    # The recipe engine points TMPDIR at the task's temporary directory;
    # failing that, LUCI_CONTEXT names a file in it.
    task_tmp = os.environ.get('TMPDIR') or os.path.dirname(
        os.path.abspath(os.environ['LUCI_CONTEXT'])
    )
    return os.path.join(task_tmp, 'bazel_ci')
  return os.path.join(repo_root(engine_src), '.bazel_ci')


def bazel_environment(engine_src):
  """The environment variables the Bazel commands set."""
  return {'BAZELISK_HOME': os.path.join(bazel_home(engine_src), 'bazelisk')}


# How long a bot's Bazel server outlives its last command. The recipe's
# process cleanup does not know the server (a detached JVM of several
# gigabytes), which would otherwise idle for hours into the bot's next
# task; the steps of one build (install, then the tests) are minutes apart.
BOT_SERVER_IDLE_SECS = 300


def startup_options(engine_src):
  """Bazel's startup options: the output root under bazel_home; a bot's server idle limit."""
  options = ['--output_user_root=' + os.path.join(bazel_home(engine_src), 'output')]
  if on_bot():
    options.append(f'--max_idle_secs={BOT_SERVER_IDLE_SECS}')
  return options


# The cap on the disk cache under .bazel_ci (Bazel's idle server collects
# the cache down to it): room for the builders' configurations' exec
# closures and a build's worth of objects.
DISK_CACHE_GC_MAX_SIZE = '40G'


def build_options(engine_src):
  """The options of every build command: a developer's disk cache under .bazel_ci.

  A developer runs a builder file's builds one after another in one
  checkout, and the flags that tell them apart -- asan, unoptimized,
  dart_debug -- reach the exec configuration too (Bazel keeps a build
  setting's value across the exec transition), whose output directory
  does not spell them: each switch overwrites the host tools' outputs
  (impellerc's closure: half of a cold build) and the next build of the
  other value compiles them again. The first end-to-end run of the
  recipe's sequence paid it (10-31: the second install of
  ci/host_debug_unopt after ci/host_debug rebuilt the exec configuration,
  10 minutes). A disk cache under .bazel_ci -- the checkout's, persisting
  with it, bounded -- serves every such repeat; the root .bazelrc's
  home-directory cache is the developer's own builds'. A bot builds one
  build per task from nothing and keeps nothing (bazel_home): no cache.
  """
  if on_bot():
    return bot_sandbox_options()
  return [
      '--disk_cache=' + os.path.join(bazel_home(engine_src), 'disk_cache'),
      '--experimental_disk_cache_gc_max_size=' + DISK_CACHE_GC_MAX_SIZE,
  ]


# Where a bot's sandboxes go when the machine has the memory for it: a
# tmpfs, so that the symlink forest every sandboxed action lays and the
# stash Bazel keeps of them cost no disk operations. A bot's disk is a
# network one whose metadata rate is low: the presubmit runs of PR #195825
# spent 20 minutes and more removing an output root (the first ones in the
# recipe's clobber of the checkout, then in swarming's cleanup of the task
# directory), most of it the sandboxes' trees.
BOT_SANDBOX_BASE = '/dev/shm'
BOT_SANDBOX_BASE_MIN_BYTES = 16 * 1024**3


def bot_sandbox_options():
  """`--sandbox_base=/dev/shm` when the bot has a tmpfs of 16 GB or more there."""
  if not os.path.isdir(BOT_SANDBOX_BASE):
    return []
  if shutil.disk_usage(BOT_SANDBOX_BASE).total < BOT_SANDBOX_BASE_MIN_BYTES:
    return []
  return ['--sandbox_base=' + BOT_SANDBOX_BASE]


def ninja_escape(text):
  """`text` as a ninja path or identifier: `$`, `:` and spaces escaped."""
  return text.replace('$', '$$').replace(':', '$:').replace(' ', '$ ')


def shell_quote(text):
  """`text` as one word of a POSIX shell command."""
  if text and all(c.isalnum() or c in '-_./=+:@%' for c in text):
    return text
  return "'" + text.replace("'", "'\\''") + "'"


def described_command(description, command, arguments):
  """A Bazel command of a build directory's description (bazel.json).

  `bazelisk <startup options> <command> --config=ci <build options>
  --config=<name> <options> <arguments>`. The description holds the
  options as tools/gn computed them from the checkout -- the output root
  and the disk cache under its .bazel_ci -- so
  that the install and the tests run in one output root: computing them
  again from the description's repo_root is what put run_tests.py's
  output root two directories above the checkout (repo_root of a root).
  """
  return ([description['bazelisk']] + list(description['startup_options']) +
          [command, '--config=' + CI_CONFIG] + list(description['build_options']) +
          ['--config=' + description['config']] + list(description.get('options', [])) +
          list(arguments))


def install_command(description):
  """`bazelisk run --config=<name> <options> <install> -- <dir>` of a description."""
  return described_command(
      description, 'run', [description['install'], '--', description['out_dir']]
  )


def run_install(out_dir):
  """Runs the install of the build directory `out_dir` (its bazel.json); the exit status.

  This is what the edge of the directory's build.ninja runs, through this
  module rather than a shell: ninja learns that a console-pool command is
  done when the write end of a pipe it hands the child is closed by
  everyone who holds it, and the Bazel server the client starts inherits
  what the client has and lives on after the command (its idle timeout is
  hours) -- the first end-to-end run hung on a finished install (10-31).
  Python's subprocess closes every descriptor above stderr in the child
  (close_fds), so the server never holds ninja's pipe. (A shell loop over
  `exec N>&-` did the same on a host whose /bin/sh is bash; the bots' is
  dash, which has no descriptors above 9: "exec: 10: not found".)
  """
  description = read_build_directory(out_dir)
  if description is None:
    print(
        f'{BAZEL_JSON} not found in {out_dir}: not a directory tools/gn --bazel wrote',
        file=sys.stderr
    )
    return 1
  command = install_command(description)
  print(' '.join(shell_quote(w) for w in command), flush=True)
  result = subprocess.run(
      command,
      cwd=description['repo_root'],
      env={**os.environ, **description['environment']},
      close_fds=True,
      check=False,
  )
  if result.returncode == 0:
    with open(os.path.join(out_dir, STAMP), 'w', encoding='utf-8'):
      pass
  return result.returncode


def ninja_file(engine_src, build, out_dir, bazelisk):
  """The build.ninja that runs the build's install: one edge, a phony per ninja target."""
  del engine_src, bazelisk  # In bazel.json, which the edge's command reads.
  run = [sys.executable or 'python3', os.path.abspath(__file__), 'install', out_dir]
  command = ' '.join(shell_quote(w) for w in run)
  lines = [
      f"# Written by flutter/tools/gn --bazel for {build['file']}'s {build['name']}: `ninja -C",
      f'# {out_dir} <targets>` runs the Bazel build of the configuration',
      f"# {build['config']} and lays its files here ({build['install']}); see",
      '# flutter/build/bazel/ci.md.',
      'ninja_required_version = 1.3',
      '',
      'rule bazel_install',
      '  command = ' + command.replace('$', '$$'),
      f"  description = bazel run --config={build['config']} "
      f"{' '.join(build.get('options', []) + [build['install']])} -- {out_dir}",
      '  pool = console',
      '',
      f'build {ninja_escape(STAMP)}: bazel_install',
  ]
  for target in build['ninja_targets']:
    lines.append(f'build {ninja_escape(target)}: phony {ninja_escape(STAMP)}')
  lines.append(f'default {ninja_escape(STAMP)}')
  return '\n'.join(lines) + '\n'


def write_build_directory(engine_src, build, out_dir, bazelisk):
  """Writes build.ninja and bazel.json into `out_dir`; returns the paths written."""
  os.makedirs(out_dir, exist_ok=True)
  # The install's edge has no inputs ninja could compare -- Bazel knows what
  # changed -- so its stamp alone would keep ninja from running it again
  # ("no work to do") in a build directory that outlives one run: the bots'
  # checkout persists between builds, as does a developer's. tools/gn runs
  # before ninja in every build, and removing the stamp here makes each
  # one's ninja run the install once.
  stamp = os.path.join(out_dir, STAMP)
  if os.path.lexists(stamp):
    os.remove(stamp)
  ninja_path = os.path.join(out_dir, NINJA_FILE)
  with open(ninja_path, 'w', encoding='utf-8') as ninja:
    ninja.write(ninja_file(engine_src, build, out_dir, bazelisk))
  description = {
      '_comment':
          'Written by flutter/tools/gn --bazel; read by testing/run_tests.py '
          '(flutter/build/bazel/ci.md).',
      'file': build['file'],
      'name': build['name'],
      'config': build['config'],
      'options': build.get('options', []),
      'install': build['install'],
      'tests': build['tests'],
      'bazelisk': bazelisk,
      'repo_root': repo_root(engine_src),
      'startup_options': startup_options(engine_src),
      'build_options': build_options(engine_src),
      'environment': bazel_environment(engine_src),
      'out_dir': out_dir,
  }
  json_path = os.path.join(out_dir, BAZEL_JSON)
  with open(json_path, 'w', encoding='utf-8') as out:
    json.dump(description, out, indent=2)
    out.write('\n')
  return [ninja_path, json_path]


def read_build_directory(out_dir):
  """The bazel.json of a build directory tools/gn --bazel wrote, or None for a GN one."""
  path = os.path.join(out_dir, BAZEL_JSON)
  if not os.path.isfile(path):
    return None
  with open(path, encoding='utf-8') as description:
    return json.load(description)


def test_suites(description, types):
  """The Bazel suites of run_tests.py's `types` for a build directory's description.

  `engine`, `dart`, ... are the build's run_tests.py types; `binaries` the
  test executables its steps run from the build directory. A type the
  build does not run, or has no Bazel test for, is an error: run_tests.py
  would have run something there.
  """
  tests = description['tests']
  suites = []
  unknown = []
  for test_type in types:
    labels = tests['binaries'] if test_type == 'binaries' else tests['types'].get(test_type)
    if labels is None:
      unknown.append(test_type)
      continue
    for label in labels:
      if label not in suites:
        suites.append(label)
  if unknown:
    raise BazelCiError(
        f"run_tests.py: {description['file']}'s {description['name']} runs no "
        f"{', '.join(unknown)} tests under Bazel (its types: "
        f"{', '.join(sorted(tests['types'])) or 'none'})"
    )
  if tests['missing']:
    print(
        'run_tests.py: not run, no Bazel test yet: ' + ', '.join(tests['missing']),
        file=sys.stderr,
    )
  return suites


def copy_failed_test_logs(description, logs_dir):
  """Copies the test.log of every test that did not pass into `logs_dir`.

  bazel-testlogs/<package>/<name>/test.log, under a name that keeps the
  package: CI's log collection uploads the directory.
  """
  result = subprocess.run(
      described_command(description, 'info', ['bazel-testlogs']),
      cwd=description['repo_root'],
      env={**os.environ, **description['environment']},
      capture_output=True,
      text=True,
      check=False,
  )
  if result.returncode != 0:
    return
  testlogs = result.stdout.strip()
  copied = 0
  for directory, _, files in os.walk(testlogs):
    if 'test.log' not in files:
      continue
    # test.cache_status / test.xml: the status is in the XML; the quick
    # test is whether test.log mentions a failure summary.
    xml = os.path.join(directory, 'test.xml')
    passed = False
    if os.path.isfile(xml):
      with open(xml, encoding='utf-8', errors='replace') as report:
        head = report.read(4096)
      passed = 'failures="0"' in head and 'errors="0"' in head
    if passed:
      continue
    relative = os.path.relpath(directory, testlogs).replace(os.sep, '_')
    os.makedirs(logs_dir, exist_ok=True)
    shutil.copy(os.path.join(directory, 'test.log'), os.path.join(logs_dir, relative + '.test.log'))
    copied += 1
  if copied:
    print(f'run_tests.py: {copied} test log(s) copied to {logs_dir}', file=sys.stderr)


def run_tests(description, types, logs_dir=None, extra_arguments=()):
  """`bazelisk test --config=<name> <suites>` for run_tests.py's `types`; the exit status."""
  suites = test_suites(description, types)
  if not suites:
    print('run_tests.py: nothing to run under Bazel for ' + ', '.join(types), file=sys.stderr)
    return 0
  command = described_command(description, 'test', list(extra_arguments) + suites)
  print('run_tests.py: ' + ' '.join(shell_quote(w) for w in command), file=sys.stderr)
  sys.stderr.flush()
  result = subprocess.run(
      command,
      cwd=description['repo_root'],
      env={**os.environ, **description['environment']},
      check=False,
  )
  if logs_dir:
    copy_failed_test_logs(description, logs_dir)
  return result.returncode


def main(argv):
  """`bazel_ci.py install <dir>`: the install of a build directory tools/gn --bazel wrote."""
  if len(argv) == 3 and argv[1] == 'install':
    return run_install(argv[2])
  print(f'usage: {argv[0]} install <build directory>', file=sys.stderr)
  return 2


if __name__ == '__main__':
  sys.exit(main(sys.argv))
