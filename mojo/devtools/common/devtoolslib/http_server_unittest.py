# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import StringIO
import gzip
import imp
import os.path
import shutil
import sys
import tempfile
import unittest
import urllib2

try:
  imp.find_module('devtoolslib')
except ImportError:
  sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from devtoolslib import http_server


class HttpServerTest(unittest.TestCase):
  """Tests for the http_server module."""

  def setUp(self):
    """Creates a tree of temporary directories and files of the form described
    below.

      parent_dir
        hello_dir
          hello_subdir
            hello_file
        other_dir
          other_file
    """
    self.parent_dir = tempfile.mkdtemp()
    self.parent_file = tempfile.NamedTemporaryFile(delete=False,
                                                   dir=self.parent_dir)
    self.hello_dir = tempfile.mkdtemp(dir=self.parent_dir)
    self.hello_subdir = tempfile.mkdtemp(dir=self.hello_dir)
    self.hello_file = tempfile.NamedTemporaryFile(delete=False,
                                                  dir=self.hello_subdir)
    self.hello_file.write('hello')
    self.hello_file.close()

    self.other_dir = tempfile.mkdtemp(dir=self.parent_dir)
    self.other_file = tempfile.NamedTemporaryFile(delete=False,
                                                  dir=self.other_dir)

  def tearDown(self):
    shutil.rmtree(self.parent_dir)

  def test_mappings(self):
    """Maps two directories and verifies that the server serves files placed
    there.
    """
    mappings = [
        ('hello/', [self.hello_dir]),
        ('other/', [self.other_dir]),
    ]
    server_address = ('http://%s:%u/' %
                      http_server.start_http_server(mappings))

    hello_relpath = os.path.relpath(self.hello_file.name, self.hello_dir)
    hello_response = urllib2.urlopen(server_address + 'hello/' +
                                     hello_relpath)
    self.assertEquals(200, hello_response.getcode())

    other_relpath = os.path.relpath(self.other_file.name, self.other_dir)
    other_response = urllib2.urlopen(server_address + 'other/' +
                                     other_relpath)
    self.assertEquals(200, other_response.getcode())

  def test_unmapped_path(self):
    """Verifies that the server returns 404 when a request for unmapped url
    prefix is made.
    """
    mappings = [
        ('hello/', [self.hello_dir]),
    ]
    server_address = ('http://%s:%u/' %
                      http_server.start_http_server(mappings))

    error_code = None
    try:
      urllib2.urlopen(server_address + 'unmapped/abc')
    except urllib2.HTTPError as error:
      error_code = error.code
    self.assertEquals(404, error_code)

  def test_multiple_paths(self):
    """Verfies mapping multiple local paths under the same url prefix."""
    mappings = [
        ('singularity/', [self.hello_dir, self.other_dir]),
    ]
    server_address = ('http://%s:%u/' %
                      http_server.start_http_server(mappings))

    hello_relpath = os.path.relpath(self.hello_file.name, self.hello_dir)
    hello_response = urllib2.urlopen(server_address + 'singularity/' +
                                     hello_relpath)
    self.assertEquals(200, hello_response.getcode())

    other_relpath = os.path.relpath(self.other_file.name, self.other_dir)
    other_response = urllib2.urlopen(server_address + 'singularity/' +
                                     other_relpath)
    self.assertEquals(200, other_response.getcode())

    # Verify that a request for a file not present under any of the mapped
    # directories results in 404.
    error_code = None
    try:
      urllib2.urlopen(server_address + 'singularity/unavailable')
    except urllib2.HTTPError as error:
      error_code = error.code
    self.assertEquals(404, error_code)

  def test_gzip(self):
    """Verifies the gzip content encoding of the files being served."""
    mappings = [
        ('hello/', [self.hello_dir]),
    ]
    server_address = ('http://%s:%u/' %
                      http_server.start_http_server(mappings))

    hello_relpath = os.path.relpath(self.hello_file.name, self.hello_dir)
    hello_response = urllib2.urlopen(server_address + 'hello/' +
                                     hello_relpath)
    self.assertEquals(200, hello_response.getcode())
    self.assertTrue('Content-Encoding' in hello_response.info())
    self.assertEquals('gzip', hello_response.info().get('Content-Encoding'))

    content = gzip.GzipFile(
        fileobj=StringIO.StringIO(hello_response.read())).read()
    self.assertEquals('hello', content)


if __name__ == "__main__":
  unittest.main()
