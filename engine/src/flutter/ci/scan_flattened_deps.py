#!/usr/bin/env python3
#
# Usage: scan_flattened_deps.py --flat-deps <flat DEPS file> --output <vulnerability report>
#
# This script parses the flattened, fully qualified dependencies,
# and uses the OSV API to check for known vulnerabilities
# for the given hash of the dependency

import argparse
import json
import os
import sys
import subprocess
import time
import requests

SCRIPT_DIR = os.path.dirname(sys.argv[0])
CHECKOUT_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..'))
UPSTREAM_PREFIX = 'upstream_'

HELP_STR = 'To find complete information on this vulnerability, navigate to '
# TODO -- use prefix matching for this rather than always to OSV
OSV_VULN_DB_URL = 'https://osv.dev/vulnerability/'
DEPS = os.path.join(CHECKOUT_ROOT, 'DEPS')

failed_deps = []  # deps which fail to be be cloned or git-merge based
old_deps = []  # deps which have not been updated in more than 1 year

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
      }, 'defaultConfiguration': {'level': 'error'}, 'properties': {
          'problem.severity': 'error', 'security-severity': '9.8',
          'tags': ['supply-chain', 'dependency']
      }
  }


def parse_deps_file(deps_flat_file):
  """
  Takes input of fully qualified dependencies,
  for each dep find the common ancestor commit SHA
  from the upstream and query OSV API using that SHA

  If the commit cannot be found or the dep cannot be
  compared to an upstream, prints list of those deps
  """
  queries = []  # list of queries to submit in bulk request to OSV API
  deps = open(deps_flat_file, 'r')
  lines = deps.readlines()

  headers = {
      'Content-Type': 'application/json',
  }
  osv_url = 'https://api.osv.dev/v1/querybatch'

  os.mkdir(
      CHECKOUT_ROOT + '/clone-test'
  )  #clone deps with upstream into temporary dir

  # Extract commit hash, save in dictionary
  for line in lines:
    os.chdir(CHECKOUT_ROOT + '/clone-test')
    dep = line.strip().split(
        '@'
    )  # separate fully qualified dep into name + pinned hash

    common_commit = get_common_ancestor_commit(dep)
    if common_commit is not None:
      queries.append({'commit': common_commit})
    else:
      failed_deps.append(dep[0])

  print(
      'Dependencies that could not be parsed for ancestor commits: ' +
      ', '.join(failed_deps)
  )
  print(
      'Dependencies that have not been rolled in at least 1 year: ' +
      ', '.join(old_deps)
  )

  # Query OSV API using common ancestor commit for each dep
  # return any vulnerabilities found
  responses = requests.post(
      osv_url, headers=headers, json={'queries': queries}, allow_redirects=True
  )
  if responses.status_code != 200:
    print('Request error')
  elif responses.json() == {}:
    print('Found no vulnerabilities')
  elif responses.json().get('results'):
    results = responses.json().get('results')
    filtered_results = list(filter(lambda vuln: vuln != {}, results))
    if len(filtered_results) > 0:
      print(
          'Found {vuln_count} vulnerabilit(y/ies), adding to report'.format(
              vuln_count=str(len(filtered_results))
          )
      )
      print(' '.join(filtered_results))
      return filtered_results
    print('Found no vulnerabilities')
  return {}


def get_common_ancestor_commit(dep):
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
  with open(DEPS, 'r', encoding='utf-8') as file:
    local_scope = {}
    global_scope = {'Var': lambda x: x}  # dummy lambda
    # Read the content.
    with open(DEPS, 'r') as file:
      deps_content = file.read()

    # Eval the content.
    exec(deps_content, global_scope, local_scope)

    # Extract the deps and filter.
    deps = local_scope.get('vars')

    if UPSTREAM_PREFIX + dep_name in deps:
      try:
        # get the upstream URL from the mapping in DEPS file
        upstream = deps.get(UPSTREAM_PREFIX + dep_name)
        # clone dependency from mirror
        # print(f'attempting: git clone --quiet {dep_name}')
        # os.system(f'git clone {dep[0]} --quiet {dep_name}')
        os.system(
            'git clone {depUrl} --quiet {dep_name}'.format(
                depUrl=dep[0], dep_name=dep_name
            )
        )
        os.chdir('./{dep_name}'.format(dep_name=dep_name))

        # check how old pinned commit is
        dep_roll_date = subprocess.check_output(
            'git show -s --format=%ct {dep}'.format(dep=dep[1]), shell=True
        ).decode()
        print(
            'dep roll date is {dep_roll_date}'.format(
                dep_roll_date=dep_roll_date
            )
        )
        years = (
            time.time() - int(dep_roll_date)
        ) / 31556952  # convert to years since last roll
        if years >= 1:
          print(
              'Old dep found: {depUrl} is from {dep_roll_date}'.format(
                  depUrl=dep[0], dep_roll_date=dep_roll_date
              )
          )
          old_deps.append(dep[0])

        # create branch that will track the upstream dep
        print(
            'attempting to add upstream remote from: {upstream}'.format(
                upstream=upstream
            )
        )
        os.system(
            'git remote add upstream {upstream}'.format(upstream=upstream)
        )
        os.system('git fetch --quiet upstream')

        # get name of default branch for upstream
        default_branch = subprocess.check_output(
            'git remote show upstream ' + "| sed -n \'/HEAD branch/s/.*: //p\'",
            shell=True
        ).decode()
        print(
            'default_branch found: {default_branch}'.format(
                default_branch=default_branch
            )
        )
        # make upstream branch track the upstream dep
        os.system(
            'git checkout -b upstream --track upstream/{default_branch}'.format(
                default_branch=default_branch
            )
        )

        # get the most recent commit from defaul branch of upstream
        commit = subprocess.check_output(
            'git for-each-ref ' +
            "--format=\'%(objectname:short)\' refs/heads/upstream",
            shell=True
        )
        commit = commit.decode().strip()
        print('commit found:' + commit)
        print(
            'git merge-base {commit} {depUrl}'.format(
                commit=commit, depUrl=dep[1]
            )
        )

        # perform merge-base on most recent default branch commit and pinned mirror commit
        ancestor_commit = subprocess.check_output(
            'git merge-base {commit} {depUrl}'.format(
                commit=commit, depUrl=dep[1]
            ),
            shell=True
        )
        ancestor_commit = ancestor_commit.decode().strip()
        print('FOUND ANCESTOR COMMIT: ' + ancestor_commit)
        return ancestor_commit
      except SyntaxError as syntax_error:
        print("SyntaxError '{0}' occured.".format(syntax_error.text))
      except Exception as error:
        print("Error '{0}' occured.".format(str(error)))
    else:
      print('did not find dep: ' + dep_name)
    return {}


def write_sarif(responses, manifest_file):
  """
  Creates a full SARIF report based on the OSV API response which
  may contain several vulnerabilities

  Combines a rule with a result in order to construct the report

  If an empty vulnerability response is passed to this method
  do not produce any SARIF report
  """
  if responses != {}:
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
  rule['help']['text'].join(vuln['id'])
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
