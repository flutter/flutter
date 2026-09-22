#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

'''
Sets up githooks.
'''

import argparse
import os
import subprocess
import sys

SRC_ROOT = os.path.dirname(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
)
FLUTTER_DIR = os.path.join(SRC_ROOT, 'flutter')


def IsWindows():
  os_id = sys.platform
  return os_id.startswith('win32') or os_id.startswith('cygwin')


def is_worktree(git: str, cwd: str) -> bool:
  try:
    git_dir = subprocess.check_output(
        [git, 'rev-parse', '--git-dir'], cwd=cwd, text=True
    ).strip()
    common_dir = subprocess.check_output(
        [git, 'rev-parse', '--git-common-dir'], cwd=cwd, text=True
    ).strip()
    return os.path.abspath(os.path.join(cwd, git_dir)) != os.path.abspath(
        os.path.join(cwd, common_dir)
    )
  except (subprocess.CalledProcessError, OSError):
    return False


def get_repo_root(git: str, cwd: str) -> str:
  try:
    return subprocess.check_output(
        [git, 'rev-parse', '--show-toplevel'], cwd=cwd, text=True
    ).strip()
  except (subprocess.CalledProcessError, OSError):
    return ''


def Main(argv):
  parser = argparse.ArgumentParser()

  parser.add_argument('--unset', action=argparse.BooleanOptionalAction, default=False)

  args = parser.parse_args()

  git = 'git'
  if IsWindows():
    git = 'git.bat'

  in_worktree = is_worktree(git, FLUTTER_DIR)
  if in_worktree:
    # In environments with multiple Git worktrees, the repository configuration
    # (.git/config) is shared across all worktrees. Setting core.hooksPath
    # globally in .git/config would affect all worktrees, even those where
    # engine dependencies (such as the Dart SDK fetched via gclient sync) have
    # not been installed. Git operations like `git push` or `git rebase` in those
    # uninitialized worktrees (or the root repository) would then fail when the
    # hooks attempt to run non-existent binaries.
    #
    # Enabling extensions.worktreeConfig allows scoping core.hooksPath strictly
    # to this worktree using `git config --worktree`, keeping other worktrees and
    # the main repository unaffected.
    subprocess.run(
        [git, 'config', 'extensions.worktreeConfig', 'true'],
        cwd=FLUTTER_DIR,
        check=True,
    )

  command = [
      git,
      'config',
  ]
  if in_worktree:
    command.append('--worktree')

  if args.unset:
    command += [
        '--unset',
        'core.hooksPath',
    ]
    print('Uninstalling Git Hooks')
  else:
    githooks = os.path.join(FLUTTER_DIR, 'tools', 'githooks')
    repo_root = get_repo_root(git, FLUTTER_DIR)
    hooks_path = os.path.relpath(githooks, repo_root) if repo_root else githooks
    hooks_path = hooks_path.replace(os.sep, '/')
    command += [
        'core.hooksPath',
        hooks_path,
    ]
    print(f'Installing Git Hooks at {hooks_path}')

  result = subprocess.run(command, cwd=FLUTTER_DIR)
  return result.returncode


if __name__ == '__main__':
  sys.exit(Main(sys.argv))
