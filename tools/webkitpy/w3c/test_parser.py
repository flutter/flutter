#!/usr/bin/env python

# Copyright (C) 2013 Adobe Systems Incorporated. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above
#    copyright notice, this list of conditions and the following
#    disclaimer.
# 2. Redistributions in binary form must reproduce the above
#    copyright notice, this list of conditions and the following
#    disclaimer in the documentation and/or other materials
#    provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
# OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
# THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

import logging
import re

from webkitpy.common.host import Host
from webkitpy.thirdparty.BeautifulSoup import BeautifulSoup as Parser


_log = logging.getLogger(__name__)


class TestParser(object):

    def __init__(self, options, filename):
        self.options = options
        self.filename = filename
        self.host = Host()
        self.filesystem = self.host.filesystem

        self.test_doc = None
        self.ref_doc = None
        self.load_file(filename)

    def load_file(self, filename):
        if self.filesystem.isfile(filename):
            try:
                self.test_doc = Parser(self.filesystem.read_binary_file(filename))
            except:
                # FIXME: Figure out what to do if we can't parse the file.
                _log.error("Failed to parse %s", filename)
                self.test_doc is None
        else:
            if self.filesystem.isdir(filename):
                # FIXME: Figure out what is triggering this and what to do about it.
                _log.error("Trying to load %s, which is a directory", filename)
            self.test_doc = None
        self.ref_doc = None

    def analyze_test(self, test_contents=None, ref_contents=None):
        """ Analyzes a file to determine if it's a test, what type of test, and what reference or support files it requires. Returns all of the test info """

        test_info = None

        if test_contents is None and self.test_doc is None:
            return test_info

        if test_contents is not None:
            self.test_doc = Parser(test_contents)

        if ref_contents is not None:
            self.ref_doc = Parser(ref_contents)

        # First check if it's a reftest

        matches = self.reference_links_of_type('match') + self.reference_links_of_type('mismatch')
        if matches:
            if len(matches) > 1:
                # FIXME: Is this actually true? We should fix this.
                _log.warning('Multiple references are not supported. Importing the first ref defined in %s',
                             self.filesystem.basename(self.filename))

            try:
                ref_file = self.filesystem.join(self.filesystem.dirname(self.filename), matches[0]['href'])
            except KeyError as e:
                # FIXME: Figure out what to do w/ invalid test files.
                _log.error('%s has a reference link but is missing the "href"', self.filesystem)
                return None

            if self.ref_doc is None:
                self.ref_doc = self.load_file(ref_file)

            test_info = {'test': self.filename, 'reference': ref_file}

            # If the ref file path is relative, we need to check it for
            # relative paths also because when it lands in WebKit, it will be
            # moved down into the test dir.
            #
            # Note: The test files themselves are not checked for support files
            # outside their directories as the convention in the CSSWG is to
            # put all support files in the same dir or subdir as the test.
            #
            # All non-test files in the test's directory tree are normally
            # copied as part of the import as they are assumed to be required
            # support files.
            #
            # *But*, there is exactly one case in the entire css2.1 suite where
            # a test depends on a file that lives in a different directory,
            # which depends on another file that lives outside of its
            # directory. This code covers that case :)
            if matches[0]['href'].startswith('..'):
                support_files = self.support_files(self.ref_doc)
                test_info['refsupport'] = support_files

        elif self.is_jstest():
            test_info = {'test': self.filename, 'jstest': True}
        elif self.options['all'] is True and not('-ref' in self.filename) and not('reference' in self.filename):
            test_info = {'test': self.filename}

        return test_info

    def reference_links_of_type(self, reftest_type):
        return self.test_doc.findAll(rel=reftest_type)

    def is_jstest(self):
        """Returns whether the file appears to be a jstest, by searching for usage of W3C-style testharness paths."""
        return bool(self.test_doc.find(src=re.compile('[\'\"/]?/resources/testharness')))

    def support_files(self, doc):
        """ Searches the file for all paths specified in url()'s, href or src attributes."""
        support_files = []

        if doc is None:
            return support_files

        elements_with_src_attributes = doc.findAll(src=re.compile('.*'))
        elements_with_href_attributes = doc.findAll(href=re.compile('.*'))

        url_pattern = re.compile('url\(.*\)')
        urls = []
        for url in doc.findAll(text=url_pattern):
            url = re.search(url_pattern, url)
            url = re.sub('url\([\'\"]?', '', url.group(0))
            url = re.sub('[\'\"]?\)', '', url)
            urls.append(url)

        src_paths = [src_tag['src'] for src_tag in elements_with_src_attributes]
        href_paths = [href_tag['href'] for href_tag in elements_with_href_attributes]

        paths = src_paths + href_paths + urls
        for path in paths:
            if not(path.startswith('http:')) and not(path.startswith('mailto:')):
                support_files.append(path)

        return support_files
