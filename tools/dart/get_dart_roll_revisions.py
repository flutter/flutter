#!/usr/bin/env python
# Copyright 2019 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# This tool is used to get a list of Dart SDK revisions which have been rolled
# into the flutter/engine repository on GitHub. Revisions are printed in reverse
# chronological order along with the merge date and link to the PR created for
# the roll.
#
# This tool requires the following setup to work:
#   - Run `pip install PyGithub` to install PyGithub (github)
#   - Set the GITHUB_API_KEY environment variable to a Github personal access
#     token (see https://github.com/settings/tokens).

from github import Github
import argparse
import os

DART_REVISION_PATCH_STR = "+  'dart_revision'"
DART_SDK_ROLL = 'Roll src/third_party/dart'
GITHUB_API_KEY = os.getenv('GITHUB_API_KEY')

# Control codes for coloured terminal output.
CGREEN = '\033[92m'
CEND   = '\033[0m'

def get_revision_from_patch(patch):
  revision_line_list = [x for x in patch.splitlines()
                   if DART_REVISION_PATCH_STR in x]
  assert(len(revision_line_list) == 1)
  revision_line = revision_line_list[0]
  return revision_line.split()[-1][:-1].replace("'","")


def print_output(revision, pull):
  msg = CGREEN + 'SDK Revision: ' + CEND
  msg += revision + CGREEN + ' Merged At: ' + CEND
  msg += str(pull.merged_at) + CGREEN + ' PR: ' + CEND + pull.html_url
  print(msg)


def main():
  parser = argparse.ArgumentParser(description='Get Dart SDK revisions which ' +
                                   'have been rolled into flutter/engine from ' +
                                   'GitHub.')
  parser.add_argument('--github-api-key', help='The GitHub API key to be used ' +
                      'for querying the flutter/engine pull requests. Defaults' +
                      ' to the "GITHUB_API_KEY" environment variable if this '  +
                      'option is not provided.')
  parser.add_argument('--max-revisions', help='The maximum number of revisions ' +
                      'of Dart SDKs which have been rolled into flutter/engine ' +
                      'to return (default: 10).', default=10, type=int)

  args = parser.parse_args()

  github_api_key = args.github_api_key
  if not github_api_key:
    github_api_key = GITHUB_API_KEY

  max_revisions = args.max_revisions
  revision_count = 0

  github = Github(github_api_key)
  github_engine_repo = github.get_repo('flutter/engine')
  pulls = github_engine_repo.get_pulls(state='closed',
                                       sort='created',
                                       direction='desc')

  for pull in pulls:
    if DART_SDK_ROLL in pull.title and pull.merged:
      # Get the last commit from the PR. Automated SDK rolls shouldn't have many
      # commits in their PRs, so this shouldn't be too expensive.
      commit = [c for c in pull.get_commits()][-1]
      for f in commit.files:
        if f.filename == 'DEPS':
          print_output(get_revision_from_patch(f.patch), pull)
          revision_count += 1
          if revision_count == max_revisions:
            return
          break


if __name__ == '__main__':
  main()
