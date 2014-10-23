#!/usr/bin/env python

import requests
import re
from in_file import InFile

BRANCH_FORMAT = "https://src.chromium.org/blink/branches/chromium/%s/%s"
TRUNK_PATH = "engine/platform/RuntimeEnabledFeatures.in"
TRUNK_URL = "https://src.chromium.org/blink/trunk/%s" % TRUNK_PATH


def features_path(branch):
    # RuntimeEnabledFeatures has only existed since April 2013:
    if branch <= 1453:
        return None
    # engine/core/page/RuntimeEnabledFeatures.in existed by 1547
    # but was in an old format without status= arguments.
    if branch <= 1547:
        return None
    if branch <= 1650:
        return "Source/core/page/RuntimeEnabledFeatures.in"
    # Modern location:
    return TRUNK_PATH


def parse_features_file(features_text):
    valid_values = {
        'status': ['stable', 'experimental', 'test'],
    }
    defaults = {
        'condition': None,
        'depends_on': [],
        'custom': False,
        'status': None,
    }

    # FIXME: in_file.py manually calls str.strip so conver to str here.
    features_lines = str(features_text).split("\n")
    return InFile(features_lines, defaults, valid_values)


def stable_features(in_file):
    return [feature['name'] for feature in in_file.name_dictionaries if feature['status'] == 'stable']


def branch_from_version(version_string):
    # Format: 31.0.1650.63, the second digit was only ever used for M4
    # no clue what it's actually intended for.
    version_regexp = r"(?P<major>\d+)\.\d+\.(?P<branch>\d+)\.(?P<minor>\d+)"
    match = re.match(version_regexp, version_string)
    # if match == None, we'll blow up, so at least provide some debugging information:
    if not match:
        print version_string
    return int(match.group('branch'))


def print_feature_diff(added_features, removed_features):
    for feature in added_features:
        print "+ %s" % feature
    for feature in removed_features:
        print "- %s" % feature


def historical_versions(os_string, channel):
    url_pattern = "http://omahaproxy.appspot.com/history?os=%s&channel=%s"
    url = url_pattern % (os_string, channel)
    releases_csv = requests.get(url).text.strip("\n")
    # Format: os,channel,version_string,date_string
    lines = releases_csv.split('\n')
    # As of June 2014, omahaproxy is now including headers:
    assert(lines[0] == 'os,channel,version,timestamp')
    # FIXME: We could replace this with more generic CSV parsing now that we have headers.
    return [line.split(',')[2] for line in lines[1:]]


def feature_file_url_for_branch(branch):
    path = features_path(branch)
    if not path:
        return None
    return BRANCH_FORMAT % (branch, path)


def feature_file_for_branch(branch):
    url = feature_file_url_for_branch(branch)
    if not url:
        return None
    return parse_features_file(requests.get(url).text)


def historical_feature_tuples(os_string, channel):
    feature_tuples = []
    version_strings = reversed(historical_versions(os_string, channel))
    seen_branches = set()

    for version in version_strings:
        branch = branch_from_version(version)
        if branch in seen_branches:
            continue
        seen_branches.add(branch)

        feature_file = feature_file_for_branch(branch)
        if not feature_file:
            continue
        feature_tuple = (version, feature_file)
        feature_tuples.append(feature_tuple)
    return feature_tuples


class FeatureAuditor(object):
    def __init__(self):
        self.last_features = []

    def add_version(self, version_name, feature_file):
        features = stable_features(feature_file)
        if self.last_features:
            added_features = list(set(features) - set(self.last_features))
            removed_features = list(set(self.last_features) - set(features))

            print "\n%s:" % version_name
            print_feature_diff(added_features, removed_features)

        self.last_features = features


def active_feature_tuples(os_string):
    feature_tuples = []
    current_releases_url = "http://omahaproxy.appspot.com/all.json"
    trains = requests.get(current_releases_url).json()
    train = next(train for train in trains if train['os'] == os_string)
    # FIXME: This is depending on the ordering of the json, we could
    # use use sorted() with true_branch, but that would put None first.
    for version in reversed(train['versions']):
        # FIXME: This is lame to exclude stable, the caller should
        # ignore it if it doesn't want it.
        if version['channel'] == 'stable':
            continue  # handled by historical_feature_tuples
        branch = version['true_branch']
        if branch:
            feature_file = feature_file_for_branch(branch)
        else:
            feature_file = parse_features_file(requests.get(TRUNK_URL).text)

        name = "%(version)s %(channel)s" % version
        feature_tuples.append((name, feature_file))
    return feature_tuples


# FIXME: This only really needs feature_files.
def stale_features(tuples):
    last_features = None
    can_be_removed = set()
    for _, feature_file in tuples:
        features = stable_features(feature_file)
        if last_features:
            can_be_removed.update(set(features))
            removed_features = list(set(last_features) - set(features))
            can_be_removed.difference_update(set(removed_features))
        last_features = features
    return sorted(can_be_removed)


def main():
    historical_tuples = historical_feature_tuples("win", "stable")
    active_tuples = active_feature_tuples("win")

    auditor = FeatureAuditor()
    for version, feature_file in historical_tuples + active_tuples:
        auditor.add_version(version, feature_file)

    print "\nConsider for removal (have been stable for at least one release):"
    for feature in stale_features(historical_tuples):
        print feature


if __name__ == "__main__":
    main()
