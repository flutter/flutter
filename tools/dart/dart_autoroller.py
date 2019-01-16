#!/usr/bin/env python
# Copyright 2019 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# This script automates the steps required to fully roll a recent version of the
# Dart SDK into the Flutter engine (and can easily be extended to roll into the
# Flutter framework as well).
#
# The following steps are completed as part of the roll:
#   - The Dart buildbots are queried to determine which SDK revision should be
#     used. Only revisions which have finished all VM and Flutter builds will be
#     considered, and revisions with < 90% of the VM bots green are ignored. See
#     dart_buildbot_helper.py for more details.
#   - dart_roll_helper.py is run with the chosen revision. This performs all the
#     interesting parts of the roll including running tests. If the steps all
#     complete successfully, dart_roll_helper.py exits with code 0. Other
#     possible statuses are listed in dart_roll_utils.py, and will cause this
#     script to exit with a non-zero exit code. dart_roll_helper.py can also be
#     run manually to perform a Dart SDK roll with specific parameters.
#   - The commit created by dart_roll_helper.py is pushed to a branch in
#     flutter/engine and a pull request is created. Once all PR checks are
#     complete, the PR is either merged or closed and all state created by this
#     script is cleaned up.
#
# In order for this script to work, the following environment variables much be
# set:
#   - GITHUB_API_KEY: A GitHub personal access token for the GitHub account to
#     be used for uploading the SDK roll changes (see
#     https://github.com/settings/tokens)
#   - FLUTTER_HOME: the absolute path to the 'flutter' directory
#   - ENGINE_HOME: the absolute path to the 'engine/src' directory
#   - DART_SDK_HOME: the absolute path to the root of a Dart SDK project
#
# Finally, the following pip commands need to be run:
#   - `pip install gitpython` for GitPython (git)
#   - `pip install PyGithub` for PyGithub (github)

from dart_buildbot_helper import get_most_recent_green_build
from dart_roll_utils import *
from git import Repo
from github import Github, GithubException
import argparse
import datetime
import os
import shutil
import subprocess
import sys
import time

GITHUB_STATUS_FAILURE = 'failure'
GITHUB_STATUS_PENDING = 'pending'
GITHUB_STATUS_SUCCESS = 'success'

PULL_REQUEST_DESCRIPTION = (
  'This is an automated pull request which will automatically merge once '
  'checks pass.'
)

FLAG_skip_wait_for_artifacts = False

def run_dart_roll_helper(most_recent_commit, extra_args):
  args = ['python',
          os.path.join(os.path.dirname(__file__), 'dart_roll_helper.py'),
          '--create-commit',
          '--no-hot-reload',
          most_recent_commit] + extra_args
  p = subprocess.Popen(args)
  return p.wait()


# TODO(bkonyi): uncomment if we decide to roll into the framework.
# def get_engine_version_path(flutter_repo_path):
#  return os.path.join(flutter_repo_path,
#                      'bin',
#                      'internal',
#                      'engine.version')
#
#
# def get_current_engine_version(flutter_repo_path):
#   with open(get_engine_version_path(flutter_repo_path), 'r') as f:
#     return f.readline().strip()
#
#
# def update_engine_version(flutter_repo_path, sha):
#   with open(get_engine_version_path(flutter_repo_path), 'w') as f:
#     f.write(sha)
#
#
# def run_engine_roll_helper(engine_local_repo,
#                           flutter_repo_path,
#                           flutter_local_repo,
#                           flutter_github_repo):
#  clean_and_update_repo(engine_local_repo)
#  engine_commits  = list(engine_local_repo.iter_commits())[:2]
#  pre_roll_commit = engine_commits[1].hexsha
#  roll_commit     = engine_commits[0].hexsha
#  current_engine_version = get_current_engine_version(flutter_repo_path)
#
#  # Run `flutter doctor` until artifacts are uploaded to cloud.
#  wait_for_engine_artifacts(flutter_repo_path, roll_commit)
#
#  # Update the engine repo again to get any changes that may have gone in while
#  # waiting for the artifacts to build.
#  clean_and_update_repo(engine_local_repo)
#
#  if not is_ancestor_commit(current_engine_version,
#                            roll_commit,
#                            engine_flutter_path()):
#    print_status(('Existing revision {} already contains the Dart SDK roll. '
#                  'No more work to do!').format(current_engine_version))
#    sys.exit(ERROR_ROLL_SUCCESS)
#
#  current_date = datetime.datetime.today().strftime('%Y-%m-%d')
#  branch_name = 'dart-sdk-roll-{}'.format(current_date)
#  engine_version_path = get_engine_version_path(flutter_repo_path)
#  pr_name = 'Dart SDK roll for {}'.format(current_date)
#
#  if pre_roll_commit != current_engine_version:
#    # Update the engine version to the commit before the Dart SDK roll.
#    # This ensures that the Dart SDK version bump is the only change in
#    # the engine roll.
#    update_engine_version(flutter_repo_path, pre_roll_commit)
#    create_commit(flutter_local_repo,
#                  branch_name,
#                  'Roll engine ahead of Dart SDK roll',
#                  [engine_version_path])
#
#  # Actually update the engine version to include the Dart SDK version bump.
#  update_engine_version(flutter_repo_path, roll_commit)
#  create_commit(flutter_local_repo,
#                branch_name,
#                'Roll engine with Dart SDK roll',
#                [engine_version_path])
#
#  pull_request = create_pull_request(flutter_github_repo,
#                                     flutter_local_repo,
#                                     pr_name,
#                                     branch_name)
#
#  merge_on_success(flutter_github_repo, pull_request)
#
#
# def wait_for_engine_artifacts(flutter_repo_path, engine_revision):
#  if FLAG_skip_wait_for_artifacts:
#    print_warning('Skipping wait for Flutter engine artifacts.')
#    return
#
#  flutter_tools = os.path.join(flutter_repo_path, 'bin', 'flutter')
#  cache_path    = os.path.join(flutter_repo_path, 'bin', 'cache')
#
#  # Run `flutter doctor` until it can successfully find the engine artifacts
#  args = [flutter_tools,
#          'doctor',
#          '--check-for-remote-artifacts',
#          engine_revision]
#  while True:
#    result = subprocess.Popen(args, stdout=subprocess.DEVNULL).wait()
#    if result == 0:
#      break
#    time.sleep(15)
#
#
# def create_commit(local_repo, branch, message, files):
#  local_repo.create_head(branch)
#  local_repo.git.checkout(branch)
#  index = local_repo.index
#  index.add(files)
#  index.commit(message)


def clean_and_update_repo(local_repo):
  local_repo.git.checkout('.')
  local_repo.git.clean('-xdf')
  local_repo.git.checkout('master')
  local_repo.git.pull()


def delete_local_branch(local_repo, branch):
  print_status('Deleting local branch {} in: {}'.format(
      branch,
      local_repo.working_tree_dir))
  local_repo.git.checkout('master')
  local_repo.delete_head(branch, '-D')


def delete_remote_branch(github_repo, branch):
  print_status('Deleting remote branch on {}: {}'.format(github_repo.full_name,
                                                         branch))
  github_repo.get_git_ref('heads/{}'.format(branch)).delete()


def get_most_recent_commit(local_repo):
  commits = list(local_repo.iter_commits())[:1]
  return commits[0]


def get_pr_title(local_repo):
  commit = get_most_recent_commit(local_repo)
  return commit.message.splitlines()[0].rstrip()


def create_pull_request(github_repo, local_repo, title, branch):
  local_repo.create_head(branch)
  local_repo.git.checkout(branch)
  local_repo.git.push('origin', branch)
  commit = get_most_recent_commit(local_repo)
  description = PULL_REQUEST_DESCRIPTION + '\n\n' + commit.message
  try:
    return github_repo.create_pull(title, description, 'master', branch)
  except GithubException as e:
    delete_remote_branch(github_repo, branch)
    raise DartAutorollerException(e.data['errors'][0]['message'])
  finally:
    print_status('Cleaning up local branch: {}'.format(branch))
    delete_local_branch(local_repo, branch)
    # Remove the commit from the local master branch.
    local_repo.git.reset('--hard','origin/master')


def merge_on_success(github_repo, local_repo, pull_request):
  sha = pull_request.head.sha
  commit = github_repo.get_commit(sha=sha)

  # TODO(bkonyi): Handle case where Flutter tree is red and we're trying to
  # merge into flutter/flutter.
  should_merge = wait_for_status(commit)
  if should_merge:
    pull_request.create_issue_comment('Checks successful, automatically merging.')
    merge_status = pull_request.merge(merge_method='rebase').merged
    if not merge_status:
      print_error('Merge failed! Aborting roll.')
      sys.exit(1)
    print_status('Merge was successful!')
  else:
    pull_request.create_issue_comment('Checks failed, abandoning roll.')
    pull_request.edit(state='closed')
    print_error('Checks failed. Abandoning roll.')
  delete_remote_branch(github_repo, pull_request.head.ref)


# TODO(bkonyi): Check to see if the Flutter build is green for flutter/flutter
# if we decide to roll the engine into the framework.
# def flutter_build_passing(commit):
#   FLUTTER_BUILD = 'flutter-build'
#   statuses = commit.get_statuses()
#   for status in statuses:
#     if status.context == FLUTTER_BUILD:
#       return (status.state == GITHUB_STATUS_SUCCESS)
# If flutter-build isn't a valid status, the PR checks don't require the
# Flutter framework to be green to submit.
#   return True


def wait_for_status(commit):
  if FLAG_skip_wait_for_artifacts:
    return True

  print_status('Sleeping for 30 seconds to allow for Cirrus to start...')

  # Give Cirrus a chance to start. The GitHub statuses posted by Cirrus go
  # through some weird states when the PR is created and can be marked as
  # failing temporarily, causing this check to return False if we don't wait.
  # This delay can probably be reduced, but the checks won't finish any faster
  # than 30 seconds anyway.
  time.sleep(30)

  print_status('Starting PR status checks (this may take awhile).')

  # Ensure all checks pass.
  while True:
    status = commit.get_combined_status().state
    if status == GITHUB_STATUS_SUCCESS:
      break
    elif status == GITHUB_STATUS_FAILURE:
      return False
    time.sleep(5)

  # TODO(bkonyi): Re-enable this check if we decide to roll the engine into the
  # framework.
  # Once all checks are passing, wait for the Flutter build to be green.
  # while not flutter_build_passing(commit):
  #   print_status('Waiting for Flutter build to pass...')
  #   time.sleep(60)
  # print_status('Flutter build passing!')
  return True


def main():
  global FLAG_skip_wait_for_artifacts

  parser = argparse.ArgumentParser(description='Dart SDK autoroller for Flutter.')
  parser.add_argument('--dart-sdk-revision',
                      help='Provide a Dart SDK revision to roll instead of '
                        'choosing one automatically')
  parser.add_argument('--no-update-repos',
                      help='Skip cleaning and updating local repositories',
                      action='store_true')
  parser.add_argument('--skip-roll',
                      help='Skip running dart_roll_helper.py',
                      action='store_true')
  parser.add_argument('--skip-tests',
                      help='Skip running Flutter tests',
                      action='store_true')
  parser.add_argument('--skip-build',
                      help='Skip building all configurations',
                      action='store_true')
  parser.add_argument('--skip-update-deps',
                      help='Skip updating the Dart SDK dependencies',
                      action='store_true')
  parser.add_argument('--skip-wait-for-artifacts',
                      help="Don't wait for PR statuses to pass or for engine" +
                      " artifacts to be uploaded to the cloud",
                      action='store_true', default=False)
  parser.add_argument('--skip-update-licenses',
                      help='Skip updating the licenses for the Flutter engine',
                      action='store_true')
  args = parser.parse_args()
  FLAG_skip_wait_for_artifacts = args.skip_wait_for_artifacts

  github_api_key = os.getenv('GITHUB_API_KEY')
  dart_sdk_path  = os.getenv('DART_SDK_HOME')
  flutter_path   = os.getenv('FLUTTER_HOME')
  engine_path    = os.getenv('ENGINE_HOME')
  local_dart_sdk_repo       = Repo(dart_sdk_path)
  local_flutter_repo        = Repo(flutter_path)
  local_engine_flutter_repo = Repo(os.path.join(engine_path, 'flutter'))
  assert(not local_dart_sdk_repo.bare)
  assert(not local_flutter_repo.bare)
  assert(not local_engine_flutter_repo.bare)

  github = Github(github_api_key)
  github_engine_repo  = github.get_repo('flutter/engine')
  github_flutter_repo = github.get_repo('flutter/flutter')

  if not args.no_update_repos:
    print_status('Cleaning and updating local trees...')
    clean_and_update_repo(local_dart_sdk_repo)
    clean_and_update_repo(local_flutter_repo)
    clean_and_update_repo(local_engine_flutter_repo)
  else:
    print_warning('Skipping cleaning and updating of local trees')

  # Use the most recent Dart SDK commit for the roll.
  if not args.skip_roll:
    print_status('Starting Dart roll helper')
    most_recent_commit = ''
    dart_roll_helper_args = []
    if args.skip_update_deps:
      dart_roll_helper_args.append('--no-update-deps')
    elif args.dart_sdk_revision != None:
      most_recent_commit = args.dart_sdk_revision
    else:
      # Get the most recent commit that is a reasonable candidate.
      most_recent_commit = get_most_recent_green_build(success_threshold=0.9)
    if args.skip_tests:
      dart_roll_helper_args.append('--no-test')
    if args.skip_build:
      dart_roll_helper_args.append('--no-build')
    if args.skip_update_licenses:
      dart_roll_helper_args.append('--no-update-licenses')


    # Will exit with code ERROR_OLD_COMMIT_PROVIDED if `most_recent_commit` is
    # older than the current revision of the SDK used by Flutter.
    result = run_dart_roll_helper(most_recent_commit, dart_roll_helper_args)
    if result != 0:
      sys.exit(result)
  else:
    print_warning('Skipping roll step!')

  # If the local roll was successful, try to merge into the engine.
  print_status('Creating flutter/engine pull request')
  current_date = datetime.datetime.today().strftime('%Y-%m-%d')

  try:
    pr = create_pull_request(github_engine_repo,
                        local_engine_flutter_repo,
                        get_pr_title(local_engine_flutter_repo),
                        'dart-sdk-roll-{}'.format(current_date))
  except DartAutorollerException as e:
    print_error(('Error while creating flutter/engine pull request: {}.'
                 ' Aborting roll.').format(e))
    sys.exit(1)

  if not FLAG_skip_wait_for_artifacts:
    print_status('Waiting for PR checks to complete...')
    merge_on_success(github_engine_repo, local_engine_flutter_repo, pr)
    print_status('PR checks complete!')
  else:
    print_warning('Skipping wait for PR checks!')

  # TODO(bkonyi): uncomment if we decide to roll the engine into the framework.
  # print_status('Starting roll of flutter/engine into flutter/flutter')
  # If the roll into the engine succeeded, prep the roll into the framework.
  # run_engine_roll_helper(local_engine_flutter_repo,
  #                        flutter_path,
  #                        local_flutter_repo,
  #                        github_flutter_repo)

  # Status code should be 0 anyway, but let's make sure our exit status is
  # consistent throughout the tool on a successful roll.
  sys.exit(ERROR_ROLL_SUCCESS)

if __name__ == '__main__':
  main()
