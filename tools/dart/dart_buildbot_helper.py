# Copyright 2019 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

from dart_roll_utils import *
import json
import pprint
import requests
import subprocess
import sys

BUILDBUCKET_LIST_BUILDERS = 'https://cr-buildbucket.appspot.com/_ah/api/swarmbucket/v1/builders'
BUILDBUCKET_SEARCH        = 'https://cr-buildbucket.appspot.com/_ah/api/buildbucket/v1/search'
LUCI_DART_BUCKET          = 'luci.dart.ci.sandbox'

class BuildStatus:
  def __init__(self, builder, raw_state):
    self._builder_name = builder
    self._state = raw_state
    self._parameters = json.loads(raw_state['parameters_json'])
    self._results = json.loads(raw_state['result_details_json'])


  @property
  def builder_name(self):
    return self._results['properties']['buildername']


  @property
  def build_number(self):
    if 'properties' in self._results:
      return self._results['properties']['buildnumber']
    return None


  @property
  def revision(self):
    return self._parameters['properties']['revision']


  # Checks to ensure that a valid status was returned. Invalid statuses can be
  # returned when the build infrastructure is broken.
  def is_valid_status(self):
    try:
      self.builder_name
      self.build_number
      self.revision
      return True
    except KeyError:
      return False


  def is_completed(self):
    return self._state['status'] == 'COMPLETED'


  def is_started(self):
    return self._state['status'] == 'STARTED'


  def is_success(self):
    if not 'result' in self._state:
      return False
    return self._state['result'] == 'SUCCESS'


  def is_failure(self):
    if not 'result' in self._state:
      return False
    return self._state['result'] == 'FAILURE'


def filter_builders(name, filter_by_list):
  in_list = False
  for f in filter_by_list:
    if f in name:
      in_list = True
      break
  return (in_list and
          ('dev' not in name) and # Ignore dev builders (try bots?)
          ('stable' not in name)) # Ignore stable builders (try bots?)


def update_dart_sdk_repo():
  subprocess.check_output(['git', 'pull', '--rebase'], cwd=DART_SDK_HOME)


def get_builder_names(filter_by_list=['flutter-', 'vm-', 'app-kernel', 'analyzer']):
  payload = {
    'bucket': LUCI_DART_BUCKET
  }
  r = requests.get(BUILDBUCKET_LIST_BUILDERS, params=payload)
  builders = r.json()['buckets'][0]['builders']
  names = [builder['name'] for builder in builders
           if filter_builders(builder['name'], filter_by_list)]
  return names


def get_buildbot_states(builder_name):
  payload = {
    'bucket': LUCI_DART_BUCKET,
    'tag': 'builder:{}'.format(builder_name),
    'max_builds': '15'
  }
  r = requests.get(BUILDBUCKET_SEARCH, params=payload)
  if 'builds' not in r.json():
    return []
  return [BuildStatus(builder_name, b) for b in r.json()['builds']]


def get_dart_sdk_commits_in_range(start, end):
  args = ['git', 'log', '--pretty=oneline', '{}..{}'.format(start, end)]
  output = subprocess.check_output(args, cwd=DART_SDK_HOME)
  commits = [x.split(' ')[0] for x in output.splitlines()]
  return commits


def get_commit_timestamp(commit):
  args = ['git', 'show', '-s', '--format=%at', commit]
  return int(subprocess.check_output(args, cwd=DART_SDK_HOME))


def bucket_states_by_commit(builder_states):
  commit_buckets = {}
  for builder_state in builder_states:
    previous_revision = None
    for state in reversed(builder_state):
      revisions = []
      # The build bot API doesn't return a list of revisions for a build so
      # we'll have to associate commits to builds manually.
      if previous_revision == None:
        revisions.append(state.revision)
      else:
        revisions = get_dart_sdk_commits_in_range(previous_revision, state.revision)
      for rev in revisions:
        if rev not in commit_buckets:
          commit_buckets[rev] = [state]
        else:
          commit_buckets[rev].append(state)
      previous_revision = state.revision
  bots_completed = max([len(v) for k,v in commit_buckets.items()])

  # We only care about commits that have been built and tested on all
  # configurations.
  commit_buckets = { k: v for k, v in commit_buckets.items() if len(v) == bots_completed }
  return commit_buckets


def get_most_recent_green_build(success_threshold=0.95):
  names = get_builder_names()
  builders = [get_buildbot_states(name) for name in names]
  states_by_commit = bucket_states_by_commit(builders)

  commit_timestamps = {commit: get_commit_timestamp(commit) for commit in states_by_commit.iterkeys()}
  sorted_commits = [x[0] for x in reversed(sorted(commit_timestamps.items(), key=lambda x: x[1]))]

  for commit in sorted_commits:
    commit_states = states_by_commit[commit]

    # Ignore revisions that returned bad state. This could be due to the bots
    # being purple or some other infrastructure issues.
    valid_states = bool(reduce(lambda x, prev: x.is_valid_status() and prev, commit_states))
    if not valid_states:
      continue

    in_progress = sum(map((lambda state: int(not state.is_completed())), commit_states))
    if in_progress > 0:
      continue

    # Only consider builds where the Dart-Engine-Flutter bots are green.
    flutter_builder_states = list(filter(lambda x: ('flutter' in x.builder_name), commit_states))
    flutter_builder_success = bool(reduce(lambda x, prev: (x.is_success() and prev), flutter_builder_states))
    if not flutter_builder_success:
      continue
    successes = map((lambda state: int(state.is_success())), commit_states)
    percent_success = float(sum(successes)) / len(commit_states)
    if percent_success >= success_threshold:
      print_status('Choosing {} for Dart SDK roll (% green: {} threshold: {}).'
                   .format(commit, percent_success * 100, success_threshold * 100))
      return commit
  print_error('Could not find a suitable commit. Aborting roll.')
  sys.exit(ERROR_NO_SUITABLE_COMMIT)
