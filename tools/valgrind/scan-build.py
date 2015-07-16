#!/usr/bin/env python
# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import errno
import json
import os
import re
import sys
import urllib
import urllib2

# Where all the data lives.
ROOT_URL = "http://build.chromium.org/p/chromium.memory.fyi/builders"

# TODO(groby) - support multi-line search from the command line. Useful when
# scanning for classes of failures, see below.
SEARCH_STRING = """<p class=\"failure result\">
Failed memory test: content
</p>"""

# Location of the log cache.
CACHE_DIR = "buildlogs.tmp"

# If we don't find anything after searching |CUTOFF| logs, we're probably done.
CUTOFF = 200

def EnsurePath(path):
  """Makes sure |path| does exist, tries to create it if it doesn't."""
  try:
    os.makedirs(path)
  except OSError as exception:
    if exception.errno != errno.EEXIST:
      raise


class Cache(object):
  def __init__(self, root_dir):
    self._root_dir = os.path.abspath(root_dir)

  def _LocalName(self, name):
    """If name is a relative path, treat it as relative to cache root.
       If it is absolute and under cache root, pass it through.
       Otherwise, raise error.
    """
    if os.path.isabs(name):
      assert os.path.commonprefix([name, self._root_dir]) == self._root_dir
    else:
      name = os.path.join(self._root_dir, name)
    return name

  def _FetchLocal(self, local_name):
    local_name = self._LocalName(local_name)
    EnsurePath(os.path.dirname(local_name))
    if os.path.exists(local_name):
      f = open(local_name, 'r')
      return f.readlines();
    return None

  def _FetchRemote(self, remote_name):
    try:
      response = urllib2.urlopen(remote_name)
    except:
      print "Could not fetch", remote_name
      raise
    return response.read()

  def Update(self, local_name, remote_name):
    local_name = self._LocalName(local_name)
    EnsurePath(os.path.dirname(local_name))
    blob = self._FetchRemote(remote_name)
    f = open(local_name, "w")
    f.write(blob)
    return blob.splitlines()

  def FetchData(self, local_name, remote_name):
    result = self._FetchLocal(local_name)
    if result:
      return result
    # If we get here, the local cache does not exist yet. Fetch, and store.
    return self.Update(local_name, remote_name)


class Builder(object):
  def __init__(self, waterfall, name):
    self._name = name
    self._waterfall = waterfall

  def Name(self):
    return self._name

  def LatestBuild(self):
    return self._waterfall.GetLatestBuild(self._name)

  def GetBuildPath(self, build_num):
    return "%s/%s/builds/%d" % (
        self._waterfall._root_url, urllib.quote(self._name), build_num)

  def _FetchBuildLog(self, build_num):
    local_build_path = "builds/%s" % self._name
    local_build_file = os.path.join(local_build_path, "%d.log" % build_num)
    return self._waterfall._cache.FetchData(local_build_file,
                                            self.GetBuildPath(build_num))

  def _CheckLog(self, build_num, tester):
    log_lines = self._FetchBuildLog(build_num)
    return any(tester(line) for line in log_lines)

  def ScanLogs(self, tester):
    occurrences = []
    build = self.LatestBuild()
    no_results = 0
    while build != 0 and no_results < CUTOFF:
      if self._CheckLog(build, tester):
        occurrences.append(build)
      else:
        no_results = no_results + 1
      build = build - 1
    return occurrences


class Waterfall(object):
  def __init__(self, root_url, cache_dir):
    self._root_url = root_url
    self._builders = {}
    self._top_revision = {}
    self._cache = Cache(cache_dir)

  def Builders(self):
    return self._builders.values()

  def Update(self):
    self._cache.Update("builders", self._root_url)
    self.FetchInfo()

  def FetchInfo(self):
    if self._top_revision:
      return

    html = self._cache.FetchData("builders", self._root_url)

    """ Search for both builders and latest build number in HTML
    <td class="box"><a href="builders/<builder-name>"> identifies a builder
    <a href="builders/<builder-name>/builds/<build-num>"> is the latest build.
    """
    box_matcher = re.compile('.*a href[^>]*>([^<]*)\<')
    build_matcher = re.compile('.*a href=\"builders/(.*)/builds/([0-9]+)\".*')
    last_builder = ""
    for line in html:
      if 'a href="builders/' in line:
        if 'td class="box"' in line:
          last_builder = box_matcher.match(line).group(1)
          self._builders[last_builder] = Builder(self, last_builder)
        else:
          result = build_matcher.match(line)
          builder = result.group(1)
          assert builder == urllib.quote(last_builder)
          self._top_revision[last_builder] = int(result.group(2))

  def GetLatestBuild(self, name):
    self.FetchInfo()
    assert self._top_revision
    return self._top_revision[name]


class MultiLineChange(object):
  def __init__(self, lines):
    self._tracked_lines = lines
    self._current = 0

  def __call__(self, line):
    """ Test a single line against multi-line change.

    If it matches the currently active line, advance one line.
    If the current line is the last line, report a match.
    """
    if self._tracked_lines[self._current] in line:
      self._current = self._current + 1
      if self._current == len(self._tracked_lines):
        self._current = 0
        return True
    else:
      self._current = 0
    return False


def main(argv):
  # Create argument parser.
  parser = argparse.ArgumentParser()
  commands = parser.add_mutually_exclusive_group(required=True)
  commands.add_argument("--update", action='store_true')
  commands.add_argument("--find", metavar='search term')
  parser.add_argument("--json", action='store_true',
                      help="Output in JSON format")
  args = parser.parse_args()

  path = os.path.abspath(os.path.dirname(argv[0]))
  cache_path = os.path.join(path, CACHE_DIR)

  fyi = Waterfall(ROOT_URL, cache_path)

  if args.update:
    fyi.Update()
    for builder in fyi.Builders():
      print "Updating", builder.Name()
      builder.ScanLogs(lambda x:False)

  if args.find:
    result = []
    tester = MultiLineChange(args.find.splitlines())
    fyi.FetchInfo()

    if not args.json:
      print "SCANNING FOR ", args.find
    for builder in fyi.Builders():
      if not args.json:
        print "Scanning", builder.Name()
      occurrences = builder.ScanLogs(tester)
      if occurrences:
        min_build = min(occurrences)
        path = builder.GetBuildPath(min_build)
        if args.json:
          data = {}
          data['builder'] = builder.Name()
          data['first_affected'] = min_build
          data['last_affected'] = max(occurrences)
          data['last_build'] = builder.LatestBuild()
          data['frequency'] = ((int(builder.LatestBuild()) - int(min_build)) /
              len(occurrences))
          data['total'] = len(occurrences)
          data['first_url'] = path
          result.append(data)
        else:
          print "Earliest occurrence in build %d" % min_build
          print "Latest occurrence in build %d" % max(occurrences)
          print "Latest build: %d" % builder.LatestBuild()
          print path
          print "%d total" % len(occurrences)
    if args.json:
      json.dump(result, sys.stdout, indent=2, sort_keys=True)

if __name__ == "__main__":
  sys.exit(main(sys.argv))

