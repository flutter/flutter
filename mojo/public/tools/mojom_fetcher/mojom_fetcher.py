#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Tool to manage external mojom interfaces."""

import argparse
import errno
import logging
import os
import sys
import urllib2

# Local library
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "pylib"))
# Bindings library
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "..", "bindings", "pylib"))
# Requests library
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "..", "..", "..", "..", "third_party",
                                "requests", "src"))

import requests

from fetcher.repository import Repository
from fetcher.dependency import Dependency
from mojom.parse.parser import Parse, ParseError


class UrlRewriterException(Exception):
  """Exception when processing URL rewrite rules."""
  pass

class UrlRewriter(object):
  """UrlRewriter rewrites URLs according to the provided mappings.

  Note that mappings are not followed transitively. If mappings contains
  {"a": "b", "b": "c"}, then UrlRewriter.rewrite("a") will return "b", not "c".
  """

  def __init__(self, mappings):
    self._mappings = mappings
    for target in self._mappings.values():
      for source in self._mappings.keys():
        if source in target or target in source:
          raise UrlRewriterException(
              "%s and %s share a common subpath" % (source, target))

  def rewrite(self, path):
    for origin, destination in self._mappings.items():
      if path.startswith(origin):
        return destination + path[len(origin):]
    return path


class MojomFetcher(object):
  def __init__(self, repository, url_rewriter):
    self._repository = repository
    self._url_rewriter = url_rewriter

  def _requests_get(self, url):
    return requests.get(url, verify=True)

  def _os_makedirs(self, dirs):
    try:
      os.makedirs(dirs)
    except OSError as e:
      # The directory may already exist, we don't care.
      if e.errno != errno.EEXIST:
        raise

  def _open(self, f, mode="r"):
    return open(f, mode)

  def _download_dependencies(self, dependencies):
    """Takes the list of mojom dependencies and download the external ones.
    Returns the number of successfully downloaded dependencies."""

    downloaded = 0
    for dep in dependencies:
      if self._maybe_download_dep(dep):
        downloaded += 1
    return downloaded

  def _maybe_download_dep(self, dep):
    if not dep.maybe_is_a_url():
      return False

    for candidate in dep.generate_candidate_urls():
      url = self._url_rewriter.rewrite(candidate)
      response = self._requests_get("https://" + url)
      if not response.ok:
        # If we get an error, it just mean that this candidate URL is not
        # correct. We must try the other ones before giving up.
        logging.debug("Error while downloading %s (%s)", candidate, url)
        continue
      # This is an external dependency
      directory = os.path.dirname(candidate)
      full_directory = os.path.join(self._repository.get_external_directory(),
                                    directory)
      try:
        self._os_makedirs(full_directory)
      except OSError as e:
        # The directory may already exist, we don't care.
        if e.errno != errno.EEXIST:
          raise
      with self._open(os.path.join(self._repository.get_external_directory(),
                             candidate), "w") as f:
        data = response.content
        try:
          Parse(data, candidate)
        except ParseError:
          logging.warn("File at %s is not a mojom", url)
          break
        f.write(data)
      return True
    return False

  def discover(self):
    """Discover missing .mojom dependencies and download them."""
    while True:
      missing_deps = self._repository.get_missing_dependencies()
      downloaded = self._download_dependencies(missing_deps)
      if downloaded == 0:
        return 0

  def get(self, dep):
    dependency = Dependency(self._repository, ".", dep)
    downloaded = self._download_dependencies([dependency])
    if downloaded != 0:
      return self.discover()
    else:
      return -1

  def update(self):
    dependencies = [Dependency(self._repository, ".", f)
                    for f in self._repository.get_external_urls()]
    # TODO(etiennej): We may want to suggest to the user to delete
    # un-downloadable dependencies.
    downloaded = self._download_dependencies(dependencies)
    if downloaded != 0:
      return self.discover()
    else:
      return -1

def _main(args):
  if args.prefix_rewrite:
    rewrite_rules = dict([x.split(':', 1) for x in args.prefix_rewrite])
  else:
    rewrite_rules = {}
  rewriter = UrlRewriter(rewrite_rules)
  repository_path = os.path.abspath(args.repository_path)
  repository = Repository(repository_path, args.external_dir)
  fetcher = MojomFetcher(repository, rewriter)
  if args.action == 'discover':
    return fetcher.discover()
  elif args.action == 'get':
    return fetcher.get(args.url)
  elif args.action == 'update':
    return fetcher.update()
  else:
    logging.error("No matching action %s", args.action[0])
    return -1

def main():
  logging.basicConfig(level=logging.ERROR)
  parser = argparse.ArgumentParser(description='Download mojom dependencies.')
  parser.add_argument('--repository-path', type=str, action='store',
                      default='.', help='The path to the client repository.')
  parser.add_argument('--external-dir', type=str, action='store',
                      default='external',
                      help='Directory for external interfaces')
  parser.add_argument('--prefix-rewrite', type=str, action='append',
                      help='If present, "origin:destination" pairs. "origin" '
                      'prefixes will be rewritten as "destination". May be '
                      'used several times. Rewrites are not transitive.')

  subparsers = parser.add_subparsers(dest='action', help='action')
  parser_get = subparsers.add_parser(
      'get', help='Get the specified URL and all its transitive dependencies')
  parser_get.add_argument('url', type=str, nargs=1,
                      help='URL to download for get action')
  subparsers.add_parser(
      'discover',
      help='Recursively discover and download new external dependencies')
  subparsers.add_parser('update', help='Update all external dependencies')

  args = parser.parse_args()
  return _main(args)


if __name__ == '__main__':
  sys.exit(main())
