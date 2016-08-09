#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Sets environment variables needed to run a chromium unit test."""

import os
import stat
import subprocess
import sys

# This is hardcoded to be src/ relative to this script.
ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

CHROME_SANDBOX_ENV = 'CHROME_DEVEL_SANDBOX'
CHROME_SANDBOX_PATH = '/opt/chromium/chrome_sandbox'


def get_sandbox_env(env):
  """Returns the environment flags needed for the SUID sandbox to work."""
  extra_env = {}
  chrome_sandbox_path = env.get(CHROME_SANDBOX_ENV, CHROME_SANDBOX_PATH)
  # The above would silently disable the SUID sandbox if the env value were
  # an empty string. We don't want to allow that. http://crbug.com/245376
  # TODO(jln): Remove this check once it's no longer possible to disable the
  # sandbox that way.
  if not chrome_sandbox_path:
    chrome_sandbox_path = CHROME_SANDBOX_PATH
  extra_env[CHROME_SANDBOX_ENV] = chrome_sandbox_path

  return extra_env


def trim_cmd(cmd):
  """Removes internal flags from cmd since they're just used to communicate from
  the host machine to this script running on the swarm slaves."""
  sanitizers = ['asan', 'lsan', 'msan', 'tsan']
  internal_flags = frozenset('--%s=%d' % (name, value)
                             for name in sanitizers
                             for value in [0, 1])
  return [i for i in cmd if i not in internal_flags]


def fix_python_path(cmd):
  """Returns the fixed command line to call the right python executable."""
  out = cmd[:]
  if out[0] == 'python':
    out[0] = sys.executable
  elif out[0].endswith('.py'):
    out.insert(0, sys.executable)
  return out


def get_sanitizer_env(cmd, asan, lsan, msan, tsan):
  """Returns the envirnoment flags needed for sanitizer tools."""

  extra_env = {}

  # Instruct GTK to use malloc while running sanitizer-instrumented tests.
  extra_env['G_SLICE'] = 'always-malloc'

  extra_env['NSS_DISABLE_ARENA_FREE_LIST'] = '1'
  extra_env['NSS_DISABLE_UNLOAD'] = '1'

  # TODO(glider): remove the symbolizer path once
  # https://code.google.com/p/address-sanitizer/issues/detail?id=134 is fixed.
  symbolizer_path = os.path.abspath(os.path.join(ROOT_DIR, 'third_party',
      'llvm-build', 'Release+Asserts', 'bin', 'llvm-symbolizer'))

  if lsan or tsan:
    # LSan is not sandbox-compatible, so we can use online symbolization. In
    # fact, it needs symbolization to be able to apply suppressions.
    symbolization_options = ['symbolize=1',
                             'external_symbolizer_path=%s' % symbolizer_path]
  elif (asan or msan) and sys.platform not in ['win32', 'cygwin']:
    # ASan uses a script for offline symbolization, except on Windows.
    # Important note: when running ASan with leak detection enabled, we must use
    # the LSan symbolization options above.
    symbolization_options = ['symbolize=0']
    # Set the path to llvm-symbolizer to be used by asan_symbolize.py
    extra_env['LLVM_SYMBOLIZER_PATH'] = symbolizer_path
  else:
    symbolization_options = []

  if asan:
    asan_options = symbolization_options[:]
    if lsan:
      asan_options.append('detect_leaks=1')

    if asan_options:
      extra_env['ASAN_OPTIONS'] = ' '.join(asan_options)

    if sys.platform == 'darwin':
      isolate_output_dir = os.path.abspath(os.path.dirname(cmd[0]))
      # This is needed because the test binary has @executable_path embedded in
      # it that the OS tries to resolve to the cache directory and not the
      # mapped directory.
      extra_env['DYLD_LIBRARY_PATH'] = str(isolate_output_dir)

  if lsan:
    if asan or msan:
      lsan_options = []
    else:
      lsan_options = symbolization_options[:]
    if sys.platform == 'linux2':
      # Use the debug version of libstdc++ under LSan. If we don't, there will
      # be a lot of incomplete stack traces in the reports.
      extra_env['LD_LIBRARY_PATH'] = '/usr/lib/x86_64-linux-gnu/debug:'

    extra_env['LSAN_OPTIONS'] = ' '.join(lsan_options)

  if msan:
    msan_options = symbolization_options[:]
    if lsan:
      msan_options.append('detect_leaks=1')
    extra_env['MSAN_OPTIONS'] = ' '.join(msan_options)

  if tsan:
    tsan_options = symbolization_options[:]
    extra_env['TSAN_OPTIONS'] = ' '.join(tsan_options)

  return extra_env


def get_sanitizer_symbolize_command(json_path=None, executable_path=None):
  """Construct the command to invoke offline symbolization script."""
  script_path = '../tools/valgrind/asan/asan_symbolize.py'
  cmd = [sys.executable, script_path]
  if json_path is not None:
    cmd.append('--test-summary-json-file=%s' % json_path)
  if executable_path is not None:
    cmd.append('--executable-path=%s' % executable_path)
  return cmd


def get_json_path(cmd):
  """Extract the JSON test summary path from a command line."""
  json_path_flag = '--test-launcher-summary-output='
  for arg in cmd:
    if arg.startswith(json_path_flag):
      return arg.split(json_path_flag).pop()
  return None


def symbolize_snippets_in_json(cmd, env):
  """Symbolize output snippets inside the JSON test summary."""
  json_path = get_json_path(cmd)
  if json_path is None:
    return

  try:
    symbolize_command = get_sanitizer_symbolize_command(
        json_path=json_path, executable_path=cmd[0])
    p = subprocess.Popen(symbolize_command, stderr=subprocess.PIPE, env=env)
    (_, stderr) = p.communicate()
  except OSError as e:
      print 'Exception while symbolizing snippets: %s' % e

  if p.returncode != 0:
    print "Error: failed to symbolize snippets in JSON:\n"
    print stderr


def run_executable(cmd, env):
  """Runs an executable with:
    - environment variable CR_SOURCE_ROOT set to the root directory.
    - environment variable LANGUAGE to en_US.UTF-8.
    - environment variable CHROME_DEVEL_SANDBOX set
    - Reuses sys.executable automatically.
  """
  extra_env = {}
  # Many tests assume a English interface...
  extra_env['LANG'] = 'en_US.UTF-8'
  # Used by base/base_paths_linux.cc as an override. Just make sure the default
  # logic is used.
  env.pop('CR_SOURCE_ROOT', None)
  extra_env.update(get_sandbox_env(env))

  # Copy logic from  tools/build/scripts/slave/runtest.py.
  asan = '--asan=1' in cmd
  lsan = '--lsan=1' in cmd
  msan = '--msan=1' in cmd
  tsan = '--tsan=1' in cmd
  if sys.platform in ['win32', 'cygwin']:
    # Symbolization works in-process on Windows even when sandboxed.
    use_symbolization_script = False
  else:
    # LSan doesn't support sandboxing yet, so we use the in-process symbolizer.
    # Note that ASan and MSan can work together with LSan.
    use_symbolization_script = (asan or msan) and not lsan

  if asan or lsan or msan or tsan:
    extra_env.update(get_sanitizer_env(cmd, asan, lsan, msan, tsan))

  if lsan or tsan:
    # LSan and TSan are not sandbox-friendly.
    cmd.append('--no-sandbox')

  cmd = trim_cmd(cmd)

  # Ensure paths are correctly separated on windows.
  cmd[0] = cmd[0].replace('/', os.path.sep)
  cmd = fix_python_path(cmd)

  print('Additional test environment:\n%s\n'
        'Command: %s\n' % (
        '\n'.join('    %s=%s' %
            (k, v) for k, v in sorted(extra_env.iteritems())),
        ' '.join(cmd)))
  env.update(extra_env or {})
  try:
    # See above comment regarding offline symbolization.
    if use_symbolization_script:
      # Need to pipe to the symbolizer script.
      p1 = subprocess.Popen(cmd, env=env, stdout=subprocess.PIPE,
                            stderr=sys.stdout)
      p2 = subprocess.Popen(
          get_sanitizer_symbolize_command(executable_path=cmd[0]),
          env=env, stdin=p1.stdout)
      p1.stdout.close()  # Allow p1 to receive a SIGPIPE if p2 exits.
      p1.wait()
      p2.wait()
      # Also feed the out-of-band JSON output to the symbolizer script.
      symbolize_snippets_in_json(cmd, env)
      return p1.returncode
    else:
      return subprocess.call(cmd, env=env)
  except OSError:
    print >> sys.stderr, 'Failed to start %s' % cmd
    raise


def main():
  return run_executable(sys.argv[1:], os.environ.copy())


if __name__ == '__main__':
  sys.exit(main())
