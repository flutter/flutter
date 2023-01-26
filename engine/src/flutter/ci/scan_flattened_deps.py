#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Usage: scan_flattened_deps.py --flat-deps <flat DEPS file> --output <vulnerability report>
#
# This script parses the flattened, fully qualified dependencies,
# and uses the OSV API to check for known vulnerabilities
# for the given hash of the dependency

import argparse
import json
import os
import shutil
import subprocess
import sys
from urllib import request
from compatibility_helper import byte_str_decode

SCRIPT_DIR = os.path.dirname(sys.argv[0])
CHECKOUT_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..'))
DEP_CLONE_DIR = CHECKOUT_ROOT + '/clone-test'
DEPS = os.path.join(CHECKOUT_ROOT, 'DEPS')
HELP_STR = 'To find complete information on this vulnerability, navigate to '
OSV_VULN_DB_URL = 'https://osv.dev/vulnerability/'
SECONDS_PER_YEAR = 31556952
UPSTREAM_PREFIX = 'upstream_'

failed_deps = []  # deps which fail to be cloned or git-merge based

sarif_log = {
    '$schema':
        'https://json.schemastore.org/sarif-2.1.0.json', 'version':
            '2.1.0', 'runs': [{
                'tool': {'driver': {'name': 'OSV Scan', 'rules': []}},
                'results': []
            }]
}


def sarif_result():
  """
  Returns the template for a result entry in the Sarif log,
  which is populated with CVE findings from OSV API
  """
  return {
      'ruleId':
          'N/A', 'message': {'text': 'OSV Scan Finding'}, 'locations': [{
              'physicalLocation': {
                  'artifactLocation': {
                      'uri': 'No location associated with this finding'
                  },
                  'region': {'startLine': 1, 'startColumn': 1, 'endColumn': 1}
              }
          }]
  }


def sarif_rule():
  """
  Returns the template for a rule entry in the Sarif log,
  which is populated with CVE findings from OSV API
  """
  return {
      'id': 'OSV Scan', 'name': 'OSV Scan Finding',
      'shortDescription': {'text': 'Insert OSV id'}, 'fullDescription': {
          'text': 'Vulnerability found by scanning against the OSV API'
      }, 'help': {
          'text':
              'More details in the OSV DB at: https://osv.dev/vulnerability/'
      }, 'defaultConfiguration': {'level': 'error'},
      'properties': {'tags': ['supply-chain', 'dependency']}
  }


def parse_deps_file(deps_flat_file):
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
    global_scope = {'Var': lambda x: x}  # dummy lambda
    # Read the content.
    deps_content = file.read()

    # Eval the content.
    exec(deps_content, global_scope, local_scope)

    # Extract the deps and filter.
    deps_list = local_scope.get('vars')
  queries = []  # list of queries to submit in bulk request to OSV API
  with open(deps_flat_file, 'r') as file:
    lines = file.readlines()

  headers = {
      'Content-Type': 'application/json',
  }
  osv_url = 'https://api.osv.dev/v1/querybatch'

  if not os.path.exists(DEP_CLONE_DIR):
    os.mkdir(DEP_CLONE_DIR)  #clone deps with upstream into temporary dir

  # Extract commit hash, save in dictionary
  for line in lines:
    dep = line.strip().split(
        '@'
    )  # separate fully qualified dep into name + pinned hash

    common_commit = get_common_ancestor_commit(dep, deps_list)
    if isinstance(common_commit, str):
      queries.append({'commit': common_commit})
    else:
      failed_deps.append(dep[0])

  print(
      'Dependencies that could not be parsed for ancestor commits: ' +
      ', '.join(failed_deps)
  )
  try:
    # clean up cloned upstream dependency directory
    shutil.rmtree(
        DEP_CLONE_DIR
    )  # use shutil.rmtree since dir could be non-empty
  except OSError as clone_dir_error:
    print(
        'Error cleaning up clone directory: %s : %s' %
        (DEP_CLONE_DIR, clone_dir_error.strerror)
    )
  # Query OSV API using common ancestor commit for each dep
  # return any vulnerabilities found.
  data = json.dumps({'queries': queries}).encode('utf-8')
  req = request.Request(osv_url, data, headers=headers)
  with request.urlopen(req) as resp:
    res_body = resp.read()
    results_json = json.loads(res_body.decode('utf-8'))
    if resp.status != 200:
      print('Request error')
    elif results_json['results'] == [{}]:
      print('Found no vulnerabilities')
    else:
      results = results_json['results']
      filtered_results = list(filter(lambda vuln: vuln != {}, results))
      if len(filtered_results) > 0:
        print(
            'Found vulnerability on {vuln_count} dependenc(y/ies), adding to report'
            .format(vuln_count=str(len(filtered_results)))
        )
        print(*filtered_results)
        return filtered_results
      print('Found no vulnerabilities')
  return {}


def get_common_ancestor_commit(dep, deps_list):
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
  # dep[0] contains the mirror repo
  # dep[1] contains the mirror's pinned SHA
  # upstream is the origin repo
  dep_name = dep[0].split('/')[-1].split('.')[0]
  if UPSTREAM_PREFIX + dep_name not in deps_list:
    print('did not find dep: ' + dep_name)
    return {}
  try:
    # get the upstream URL from the mapping in DEPS file
    upstream = deps_list.get(UPSTREAM_PREFIX + dep_name)
    temp_dep_dir = DEP_CLONE_DIR + '/' + dep_name
    # clone dependency from mirror
    subprocess.check_output([
        'git', 'clone', '--quiet', '--', dep[0], temp_dep_dir
    ])

    # create branch that will track the upstream dep
    print(
        'attempting to add upstream remote from: {upstream}'.format(
            upstream=upstream
        )
    )
    subprocess.check_output([
        'git', '--git-dir', temp_dep_dir + '/.git', 'remote', 'add', 'upstream',
        upstream
    ])
    subprocess.check_output([
        'git', '--git-dir', temp_dep_dir + '/.git', 'fetch', '--quiet',
        'upstream'
    ])
    # get name of the default branch for upstream (e.g. main/master/etc.)
    default_branch = subprocess.check_output(
        'git --git-dir ' + temp_dep_dir + '/.git remote show upstream ' +
        "| sed -n \'/HEAD branch/s/.*: //p\'",
        shell=True
    )
    default_branch = byte_str_decode(default_branch)
    default_branch = default_branch.strip()
    print(
        'default_branch found: {default_branch}'.format(
            default_branch=default_branch
        )
    )
    # make upstream branch track the upstream dep
    subprocess.check_output([
        'git', '--git-dir', temp_dep_dir + '/.git', 'checkout', '-b',
        'upstream', '--track', 'upstream/' + default_branch
    ])
    # get the most recent commit from default branch of upstream
    commit = subprocess.check_output(
        'git --git-dir ' + temp_dep_dir + '/.git for-each-ref ' +
        "--format=\'%(objectname:short)\' refs/heads/upstream",
        shell=True
    )
    commit = byte_str_decode(commit)
    commit = commit.strip()

    # perform merge-base on most recent default branch commit and pinned mirror commit
    ancestor_commit = subprocess.check_output(
        'git --git-dir {temp_dep_dir}/.git merge-base {commit} {depUrl}'.format(
            temp_dep_dir=temp_dep_dir, commit=commit, depUrl=dep[1]
        ),
        shell=True
    )
    ancestor_commit = byte_str_decode(ancestor_commit)
    ancestor_commit = ancestor_commit.strip()
    print('Ancestor commit: ' + ancestor_commit)
    return ancestor_commit
  except subprocess.CalledProcessError as error:
    print("Subprocess error '{0}' occured.".format(error.output))
  return {}


def write_sarif(responses, manifest_file):
  """
  Creates a full SARIF report based on the OSV API response which
  may contain several vulnerabilities

  Combines a rule with a result in order to construct the report
  """
  data = sarif_log
  for response in responses:
    for vuln in response['vulns']:
      new_rule = create_rule_entry(vuln)
      data['runs'][0]['tool']['driver']['rules'].append(new_rule)
      data['runs'][0]['results'].append(create_result_entry(vuln))
  with open(manifest_file, 'w') as out:
    json.dump(data, out)


def create_rule_entry(vuln):
  """
  Creates a Sarif rule entry from an OSV finding.
  Vuln object follows OSV Schema and is required to have 'id' and 'modified'
  """
  rule = sarif_rule()
  rule['id'] = vuln['id']
  rule['shortDescription']['text'] = vuln['id']
  rule['help']['text'] += vuln['id']
  return rule


def create_result_entry(vuln):
  """
  Creates a Sarif res entry from an OSV entry.
  Rule finding linked to the associated rule metadata via ruleId
  """
  result = sarif_result()
  result['ruleId'] = vuln['id']
  return result


def parse_args(args):
  args = args[1:]
  parser = argparse.ArgumentParser(
      description='A script to scan a flattened DEPS file using OSV API.'
  )

  parser.add_argument(
      '--flat-deps',
      '-d',
      type=str,
      help='Input flattened DEPS file.',
      default=os.path.join(CHECKOUT_ROOT, 'deps_flatten.txt')
  )
  parser.add_argument(
      '--output',
      '-o',
      type=str,
      help='Output SARIF log of vulnerabilities found in OSV database.',
      default=os.path.join(CHECKOUT_ROOT, 'osvReport.sarif')
  )

  return parser.parse_args(args)


def main(argv):
  args = parse_args(argv)
  osv_scans = parse_deps_file(args.flat_deps)
  write_sarif(osv_scans, args.output)
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))
