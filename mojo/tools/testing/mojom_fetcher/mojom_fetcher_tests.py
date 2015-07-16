#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import io
import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "..", "..", "..", "public", "tools",
                                "mojom_fetcher"))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "..", "..", "..", "public", "tools",
                                "mojom_fetcher", "pylib"))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "..", "..", "..", "public", "tools",
                                "bindings", "pylib"))

from mojom_fetcher import UrlRewriter, UrlRewriterException, MojomFetcher

# Fake repository for testing
from fakes import FakeRepository


class TestUrlRewriter(unittest.TestCase):
  def test_no_transitive(self):
    rules = {"foo.com": "bar.com/foo", "bar.com": "baz.com"}
    try:
      UrlRewriter(rules)
      self.fail()
    except UrlRewriterException:
      # This is expected
      pass

  def test_rewrite(self):
    rules = {"foo.com": "bar.com/foo", "baz.com": "bar.com/baz"}
    rewriter = UrlRewriter(rules)
    self.assertEquals("bar.com/foo/foo_file",
                      rewriter.rewrite("foo.com/foo_file"))
    self.assertEquals("bar.com/baz/foo_file",
                      rewriter.rewrite("baz.com/foo_file"))
    self.assertEquals("example.com/file",
                      rewriter.rewrite("example.com/file"))


class FakeRequest(object):
  def __init__(self, content, ok):
    self.content = content
    self.ok = ok


class FakeMojomFetcher(MojomFetcher):
  data = """module test;
interface Fiz {};"""

  def __init__(self, repository, rewriter):
    self.count = 1
    self.opened_files = {}
    self.downloaded_urls = []
    MojomFetcher.__init__(self, repository, rewriter)

  def _requests_get(self, url):
    self.downloaded_urls.append(url)
    return FakeRequest(self.data, True)

  def _os_makedirs(self, _):
    return

  def _open(self, f, _):
    fake_file = io.BytesIO()
    self.opened_files[f] = fake_file
    if "services.fiz.org/foo/bar.mojom" in f:
      self._repository.all_files_available = True
    return fake_file


class TestMojomFetcher(unittest.TestCase):
  def setUp(self):
    self.rules = {"foo.com": "bar.com/foo", "baz.com": "bar.com/baz"}
    self.rewriter = UrlRewriter(self.rules)
    self.repository = FakeRepository("/path/to/repo", "third_party/external")
    self.fetcher = FakeMojomFetcher(self.repository, self.rewriter)

  def test_get(self):
    self.fetcher.get("foo.com/bar.mojom")
    self.assertEquals(["https://bar.com/foo/bar.mojom",
                       "https://services.fiz.org/foo/bar.mojom"],
                      self.fetcher.downloaded_urls)

  def test_update(self):
    self.fetcher.update()
    self.assertEquals(["https://services.domokit.org/foo/fiz.mojom",
                       "https://services.fiz.org/foo/bar.mojom"],
                      self.fetcher.downloaded_urls)

  def test_discover(self):
    self.fetcher.update()
    self.assertEquals(["https://services.domokit.org/foo/fiz.mojom",
                       "https://services.fiz.org/foo/bar.mojom"],
                      self.fetcher.downloaded_urls)

if __name__ == '__main__':
  loader = unittest.defaultTestLoader
  runner = unittest.TextTestRunner()
  directory = os.path.dirname(os.path.abspath(__file__))
  suite = loader.discover(directory, '*_tests.py')
  runner.run(suite)
