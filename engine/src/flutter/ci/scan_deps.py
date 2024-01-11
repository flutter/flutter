#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Usage: scan_deps.py --osv-lockfile <lockfile> --output <parsed lockfile>
#
# This script parses the dependencies provided in lockfile format for
# osv-scanner so that the common ancestor commits from the mirrored and
# upstream for each dependency are provided in the lockfile
# It is expected that the osv-lockfile input is updated by this script
# and then uploaded using GitHub actions to be used by the osv-scanner
# reusable action.

import argparse
import json
import os
import shutil
import subprocess
import sys
from compatibility_helper import byte_str_decode

SCRIPT_DIR = os.path.dirname(sys.argv[0])
CHECKOUT_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..'))
DEP_CLONE_DIR = CHECKOUT_ROOT + '/clone-test'
DEPS = os.path.join(CHECKOUT_ROOT, 'DEPS')
UPSTREAM_PREFIX = 'upstream_'

failed_deps = []  # Deps which fail to be cloned or git-merge based.


def parse_deps_file(lockfile, output_file):
  """
  Takes input of fully qualified dependencies,
  for each dep find the common ancestor commit SHA
  from the upstream and query OSV API using that SHA

  If the commit cannot be found or the dep cannot be
  compared to an upstream, prints list of those deps
  """
  deps_list = []
  with open(DEPS, 'r') as file:
    local_scope = {}
    global_scope = {'Var': lambda x: x}  # Dummy lambda.
    # Read the content.
    deps_content = file.read()

    # Eval the content.
    exec(deps_content, global_scope, local_scope)

    # Extract the deps and filter.
    deps_list = local_scope.get('vars')

  with open(lockfile, 'r') as file:
    data = json.load(file)

  results = data['results']

  if not os.path.exists(DEP_CLONE_DIR):
    os.mkdir(DEP_CLONE_DIR)  # Clone deps with upstream into temporary dir.

  # Extract commit hash, save in dictionary.
  for result in results:
    packages = result['packages']
    for package in packages:
      mirror_url = package['package']['name']
      commit = package['package']['commit']
      ancestor_result = get_common_ancestor([mirror_url, commit], deps_list)
      if ancestor_result:
        common_commit, upstream = ancestor_result
        package['package']['commit'] = common_commit
        package['package']['name'] = upstream

  try:
    # Clean up cloned upstream dependency directory.
    shutil.rmtree(
        DEP_CLONE_DIR
    )  # Use shutil.rmtree since dir could be non-empty.
  except OSError as clone_dir_error:
    print(
        'Error cleaning up clone directory: %s : %s' %
        (DEP_CLONE_DIR, clone_dir_error.strerror)
    )

  # Write common ancestor commit data to new file to be
  # used in next github action step with osv-scanner.
  # The output_file name defaults to converted-osv-lockfile.json
  with open(output_file, 'w') as file:
    json.dump(data, file)


def get_common_ancestor(dep, deps_list):
  """
  Given an input of a mirrored dep,
  compare to the mapping of deps to their upstream
  in DEPS and find a common ancestor
  commit SHA value.

  This is done by first cloning the mirrored dep,
  then a branch which tracks the upstream.
  From there,  git merge-base operates using the HEAD
  commit SHA of the upstream branch and the pinned
  SHA value of the mirrored branch
  """
  # dep[0] contains the mirror repo.
  # dep[1] contains the mirror's pinned SHA.
  # upstream is the origin repo.
  dep_name = dep[0].split('/')[-1].split('.')[0]
  if UPSTREAM_PREFIX + dep_name not in deps_list:
    print('did not find dep: ' + dep_name)
    return None
  try:
    # Get the upstream URL from the mapping in DEPS file.
    upstream = deps_list.get(UPSTREAM_PREFIX + dep_name)
    temp_dep_dir = DEP_CLONE_DIR + '/' + dep_name
    # Clone dependency from mirror.
    subprocess.check_output(['git', 'clone', '--quiet', '--', dep[0], dep_name],
                            cwd=DEP_CLONE_DIR)

    # Create branch that will track the upstream dep.
    print(
        'attempting to add upstream remote from: {upstream}'.format(
            upstream=upstream
        )
    )
    subprocess.check_output(['git', 'remote', 'add', 'upstream', upstream],
                            cwd=temp_dep_dir)
    subprocess.check_output(['git', 'fetch', '--quiet', 'upstream'],
                            cwd=temp_dep_dir)
    # Get name of the default branch for upstream (e.g. main/master/etc.).
    default_branch = subprocess.check_output(
        'git remote show upstream ' + "| sed -n \'/HEAD branch/s/.*: //p\'",
        cwd=temp_dep_dir,
        shell=True
    )
    default_branch = byte_str_decode(default_branch)
    default_branch = default_branch.strip()

    # Make upstream branch track the upstream dep.
    subprocess.check_output([
        'git', 'checkout', '--force', '-b', 'upstream', '--track',
        'upstream/' + default_branch
    ],
                            cwd=temp_dep_dir)
    # Get the most recent commit from default branch of upstream.
    commit = subprocess.check_output(
        'git for-each-ref ' +
        "--format=\'%(objectname:short)\' refs/heads/upstream",
        cwd=temp_dep_dir,
        shell=True
    )
    commit = byte_str_decode(commit)
    commit = commit.strip()

    # Perform merge-base on most recent default branch commit and pinned mirror commit.
    ancestor_commit = subprocess.check_output(
        'git merge-base {commit} {depUrl}'.format(commit=commit, depUrl=dep[1]),
        cwd=temp_dep_dir,
        shell=True
    )
    ancestor_commit = byte_str_decode(ancestor_commit)
    ancestor_commit = ancestor_commit.strip()
    print('Ancestor commit: ' + ancestor_commit)
    return ancestor_commit, upstream
  except subprocess.CalledProcessError as error:
    print(
        "Subprocess command '{0}' failed with exit code: {1}.".format(
            error.cmd, str(error.returncode)
        )
    )
    if error.output:
      print("Subprocess error output: '{0}'".format(error.output))
  return None


def parse_args(args):
  args = args[1:]
  parser = argparse.ArgumentParser(
      description='A script to find common ancestor commit SHAs'
  )

  parser.add_argument(
      '--osv-lockfile',
      '-d',
      type=str,
      help='Input osv-scanner compatible lockfile of dependencies to parse.',
      default=os.path.join(CHECKOUT_ROOT, 'osv-lockfile.json')
  )
  parser.add_argument(
      '--output',
      '-o',
      type=str,
      help='Output osv-scanner compatible deps file.',
      default=os.path.join(CHECKOUT_ROOT, 'converted-osv-lockfile.json')
  )

  return parser.parse_args(args)


def main(argv):
  args = parse_args(argv)
  parse_deps_file(args.osv_lockfile, args.output)
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))
