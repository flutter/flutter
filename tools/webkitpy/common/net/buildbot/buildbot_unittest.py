# Copyright (C) 2009 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#    * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#    * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import unittest

from webkitpy.common.net.layouttestresults import LayoutTestResults
from webkitpy.common.net.buildbot import BuildBot, Builder, Build
from webkitpy.layout_tests.models import test_results
from webkitpy.layout_tests.models import test_failures
from webkitpy.thirdparty.BeautifulSoup import BeautifulSoup


class BuilderTest(unittest.TestCase):
    def _mock_test_result(self, testname):
        return test_results.TestResult(testname, [test_failures.FailureTextMismatch()])

    def _install_fetch_build(self, failure):
        def _mock_fetch_build(build_number):
            build = Build(
                builder=self.builder,
                build_number=build_number,
                revision=build_number + 1000,
                is_green=build_number < 4
            )
            return build
        self.builder._fetch_build = _mock_fetch_build

    def setUp(self):
        self.buildbot = BuildBot()
        self.builder = Builder(u"Test Builder \u2661", self.buildbot)
        self._install_fetch_build(lambda build_number: ["test1", "test2"])

    def test_latest_layout_test_results(self):
        self.builder.fetch_layout_test_results = lambda results_url: LayoutTestResults(None)
        self.builder.accumulated_results_url = lambda: "http://dummy_url.org"
        self.assertTrue(self.builder.latest_layout_test_results())

    def test_build_caching(self):
        self.assertEqual(self.builder.build(10), self.builder.build(10))

    def test_build_and_revision_for_filename(self):
        expectations = {
            "r47483 (1)/" : (47483, 1),
            "r47483 (1).zip" : (47483, 1),
            "random junk": None,
        }
        for filename, revision_and_build in expectations.items():
            self.assertEqual(self.builder._revision_and_build_for_filename(filename), revision_and_build)

    def test_file_info_list_to_revision_to_build_list(self):
        file_info_list = [
            {"filename": "r47483 (1)/"},
            {"filename": "r47483 (1).zip"},
            {"filename": "random junk"},
        ]
        builds_and_revisions_list = [(47483, 1), (47483, 1)]
        self.assertEqual(self.builder._file_info_list_to_revision_to_build_list(file_info_list), builds_and_revisions_list)

    def test_fetch_build(self):
        buildbot = BuildBot()
        builder = Builder(u"Test Builder \u2661", buildbot)

        def mock_fetch_build_dictionary(self, build_number):
            build_dictionary = {
                "sourceStamp": {
                    "revision": None,  # revision=None means a trunk build started from the force-build button on the builder page.
                    },
                "number": int(build_number),
                # Intentionally missing the 'results' key, meaning it's a "pass" build.
            }
            return build_dictionary
        buildbot._fetch_build_dictionary = mock_fetch_build_dictionary
        self.assertIsNotNone(builder._fetch_build(1))


class BuildBotTest(unittest.TestCase):

    _example_one_box_status = '''
    <table>
    <tr>
    <td class="box"><a href="builders/Windows%20Debug%20%28Tests%29">Windows Debug (Tests)</a></td>
      <td align="center" class="LastBuild box success"><a href="builders/Windows%20Debug%20%28Tests%29/builds/3693">47380</a><br />build<br />successful</td>
      <td align="center" class="Activity building">building<br />ETA in<br />~ 14 mins<br />at 13:40</td>
    <tr>
    <td class="box"><a href="builders/SnowLeopard%20Intel%20Release">SnowLeopard Intel Release</a></td>
      <td class="LastBuild box" >no build</td>
      <td align="center" class="Activity building">building<br />< 1 min</td>
    <tr>
    <td class="box"><a href="builders/Qt%20Linux%20Release">Qt Linux Release</a></td>
      <td align="center" class="LastBuild box failure"><a href="builders/Qt%20Linux%20Release/builds/654">47383</a><br />failed<br />compile-webkit</td>
      <td align="center" class="Activity idle">idle<br />3 pending</td>
    <tr>
    <td class="box"><a href="builders/Qt%20Windows%2032-bit%20Debug">Qt Windows 32-bit Debug</a></td>
      <td align="center" class="LastBuild box failure"><a href="builders/Qt%20Windows%2032-bit%20Debug/builds/2090">60563</a><br />failed<br />failed<br />slave<br />lost</td>
      <td align="center" class="Activity building">building<br />ETA in<br />~ 5 mins<br />at 08:25</td>
    </table>
'''
    _expected_example_one_box_parsings = [
        {
            'is_green': True,
            'build_number' : 3693,
            'name': u'Windows Debug (Tests)',
            'built_revision': 47380,
            'activity': 'building',
            'pending_builds': 0,
        },
        {
            'is_green': False,
            'build_number' : None,
            'name': u'SnowLeopard Intel Release',
            'built_revision': None,
            'activity': 'building',
            'pending_builds': 0,
        },
        {
            'is_green': False,
            'build_number' : 654,
            'name': u'Qt Linux Release',
            'built_revision': 47383,
            'activity': 'idle',
            'pending_builds': 3,
        },
        {
            'is_green': True,
            'build_number' : 2090,
            'name': u'Qt Windows 32-bit Debug',
            'built_revision': 60563,
            'activity': 'building',
            'pending_builds': 0,
        },
    ]

    def test_status_parsing(self):
        buildbot = BuildBot()

        soup = BeautifulSoup(self._example_one_box_status)
        status_table = soup.find("table")
        input_rows = status_table.findAll('tr')

        for x in range(len(input_rows)):
            status_row = input_rows[x]
            expected_parsing = self._expected_example_one_box_parsings[x]

            builder = buildbot._parse_builder_status_from_row(status_row)

            # Make sure we aren't parsing more or less than we expect
            self.assertEqual(builder.keys(), expected_parsing.keys())

            for key, expected_value in expected_parsing.items():
                self.assertEqual(builder[key], expected_value, ("Builder %d parse failure for key: %s: Actual='%s' Expected='%s'" % (x, key, builder[key], expected_value)))

    def test_builder_with_name(self):
        buildbot = BuildBot()

        builder = buildbot.builder_with_name("Test Builder")
        self.assertEqual(builder.name(), "Test Builder")
        self.assertEqual(builder.url(), "http://build.webkit.org/builders/Test%20Builder")
        self.assertEqual(builder.url_encoded_name(), "Test%20Builder")
        self.assertEqual(builder.results_url(), "http://build.webkit.org/results/Test%20Builder")

        # Override _fetch_build_dictionary function to not touch the network.
        def mock_fetch_build_dictionary(self, build_number):
            build_dictionary = {
                "sourceStamp": {
                    "revision" : 2 * build_number,
                    },
                "number" : int(build_number),
                "results" : build_number % 2, # 0 means pass
            }
            return build_dictionary
        buildbot._fetch_build_dictionary = mock_fetch_build_dictionary

        build = builder.build(10)
        self.assertEqual(build.builder(), builder)
        self.assertEqual(build.url(), "http://build.webkit.org/builders/Test%20Builder/builds/10")
        self.assertEqual(build.results_url(), "http://build.webkit.org/results/Test%20Builder/r20%20%2810%29")
        self.assertEqual(build.revision(), 20)
        self.assertTrue(build.is_green())

        build = build.previous_build()
        self.assertEqual(build.builder(), builder)
        self.assertEqual(build.url(), "http://build.webkit.org/builders/Test%20Builder/builds/9")
        self.assertEqual(build.results_url(), "http://build.webkit.org/results/Test%20Builder/r18%20%289%29")
        self.assertEqual(build.revision(), 18)
        self.assertFalse(build.is_green())

        self.assertIsNone(builder.build(None))

    _example_directory_listing = '''
<h1>Directory listing for /results/SnowLeopard Intel Leaks/</h1>

<table>
        <tr class="alt">
            <th>Filename</th>
            <th>Size</th>
            <th>Content type</th>
            <th>Content encoding</th>
        </tr>
<tr class="directory ">
    <td><a href="r47483%20%281%29/"><b>r47483 (1)/</b></a></td>
    <td><b></b></td>
    <td><b>[Directory]</b></td>
    <td><b></b></td>
</tr>
<tr class="file alt">
    <td><a href="r47484%20%282%29.zip">r47484 (2).zip</a></td>
    <td>89K</td>
    <td>[application/zip]</td>
    <td></td>
</tr>
'''
    _expected_files = [
        {
            "filename" : "r47483 (1)/",
            "size" : "",
            "type" : "[Directory]",
            "encoding" : "",
        },
        {
            "filename" : "r47484 (2).zip",
            "size" : "89K",
            "type" : "[application/zip]",
            "encoding" : "",
        },
    ]

    def test_parse_build_to_revision_map(self):
        buildbot = BuildBot()
        files = buildbot._parse_twisted_directory_listing(self._example_directory_listing)
        self.assertEqual(self._expected_files, files)

    _fake_builder_page = '''
    <body>
    <div class="content">
    <h1>Some Builder</h1>
    <p>(<a href="../waterfall?show=Some Builder">view in waterfall</a>)</p>
    <div class="column">
    <h2>Recent Builds:</h2>
    <table class="info">
      <tr>
        <th>Time</th>
        <th>Revision</th>
        <th>Result</th>    <th>Build #</th>
        <th>Info</th>
      </tr>
      <tr class="alt">
        <td>Jan 10 15:49</td>
        <td><span class="revision" title="Revision 104643"><a href="http://trac.webkit.org/changeset/104643">104643</a></span></td>
        <td class="success">failure</td>    <td><a href=".../37604">#37604</a></td>
        <td class="left">Build successful</td>
      </tr>
      <tr class="">
        <td>Jan 10 15:32</td>
        <td><span class="revision" title="Revision 104636"><a href="http://trac.webkit.org/changeset/104636">104636</a></span></td>
        <td class="success">failure</td>    <td><a href=".../37603">#37603</a></td>
        <td class="left">Build successful</td>
      </tr>
      <tr class="alt">
        <td>Jan 10 15:18</td>
        <td><span class="revision" title="Revision 104635"><a href="http://trac.webkit.org/changeset/104635">104635</a></span></td>
        <td class="success">success</td>    <td><a href=".../37602">#37602</a></td>
        <td class="left">Build successful</td>
      </tr>
      <tr class="">
        <td>Jan 10 14:51</td>
        <td><span class="revision" title="Revision 104633"><a href="http://trac.webkit.org/changeset/104633">104633</a></span></td>
        <td class="failure">failure</td>    <td><a href=".../37601">#37601</a></td>
        <td class="left">Failed compile-webkit</td>
      </tr>
    </table>
    </body>'''
    _fake_builder_page_without_success = '''
    <body>
    <table>
      <tr class="alt">
        <td>Jan 10 15:49</td>
        <td><span class="revision" title="Revision 104643"><a href="http://trac.webkit.org/changeset/104643">104643</a></span></td>
        <td class="success">failure</td>
      </tr>
      <tr class="">
        <td>Jan 10 15:32</td>
        <td><span class="revision" title="Revision 104636"><a href="http://trac.webkit.org/changeset/104636">104636</a></span></td>
        <td class="success">failure</td>
      </tr>
      <tr class="alt">
        <td>Jan 10 15:18</td>
        <td><span class="revision" title="Revision 104635"><a href="http://trac.webkit.org/changeset/104635">104635</a></span></td>
        <td class="success">failure</td>
      </tr>
      <tr class="">
          <td>Jan 10 11:58</td>
          <td><span class="revision" title="Revision ??"><a href="http://trac.webkit.org/changeset/%3F%3F">??</a></span></td>
          <td class="retry">retry</td>
        </tr>
      <tr class="">
        <td>Jan 10 14:51</td>
        <td><span class="revision" title="Revision 104633"><a href="http://trac.webkit.org/changeset/104633">104633</a></span></td>
        <td class="failure">failure</td>
      </tr>
    </table>
    </body>'''

    def test_revisions_for_builder(self):
        buildbot = BuildBot()
        buildbot._fetch_builder_page = lambda builder: builder.page
        builder_with_success = Builder('Some builder', None)
        builder_with_success.page = self._fake_builder_page
        self.assertEqual(buildbot._revisions_for_builder(builder_with_success), [(104643, False), (104636, False), (104635, True), (104633, False)])

        builder_without_success = Builder('Some builder', None)
        builder_without_success.page = self._fake_builder_page_without_success
        self.assertEqual(buildbot._revisions_for_builder(builder_without_success), [(104643, False), (104636, False), (104635, False), (104633, False)])

    def test_find_green_revision(self):
        buildbot = BuildBot()
        self.assertEqual(buildbot._find_green_revision({
            'Builder 1': [(1, True), (3, True)],
            'Builder 2': [(1, True), (3, False)],
            'Builder 3': [(1, True), (3, True)],
        }), 1)
        self.assertEqual(buildbot._find_green_revision({
            'Builder 1': [(1, False), (3, True)],
            'Builder 2': [(1, True), (3, True)],
            'Builder 3': [(1, True), (3, True)],
        }), 3)
        self.assertEqual(buildbot._find_green_revision({
            'Builder 1': [(1, True), (2, True)],
            'Builder 2': [(1, False), (2, True), (3, True)],
            'Builder 3': [(1, True), (3, True)],
        }), None)
        self.assertEqual(buildbot._find_green_revision({
            'Builder 1': [(1, True), (2, True)],
            'Builder 2': [(1, True), (2, True), (3, True)],
            'Builder 3': [(1, True), (3, True)],
        }), 2)
        self.assertEqual(buildbot._find_green_revision({
            'Builder 1': [(1, False), (2, True)],
            'Builder 2': [(1, True), (3, True)],
            'Builder 3': [(1, True), (3, True)],
        }), None)
        self.assertEqual(buildbot._find_green_revision({
            'Builder 1': [(1, True), (3, True)],
            'Builder 2': [(1, False), (2, True), (3, True), (4, True)],
            'Builder 3': [(2, True), (4, True)],
        }), 3)
        self.assertEqual(buildbot._find_green_revision({
            'Builder 1': [(1, True), (3, True)],
            'Builder 2': [(1, False), (2, True), (3, True), (4, False)],
            'Builder 3': [(2, True), (4, True)],
        }), None)
        self.assertEqual(buildbot._find_green_revision({
            'Builder 1': [(1, True), (3, True)],
            'Builder 2': [(1, False), (2, True), (3, True), (4, False)],
            'Builder 3': [(2, True), (3, True), (4, True)],
        }), 3)
        self.assertEqual(buildbot._find_green_revision({
            'Builder 1': [(1, True), (2, True)],
            'Builder 2': [],
            'Builder 3': [(1, True), (2, True)],
        }), None)
        self.assertEqual(buildbot._find_green_revision({
            'Builder 1': [(1, True), (3, False), (5, True), (10, True), (12, False)],
            'Builder 2': [(1, True), (3, False), (7, True), (9, True), (12, False)],
            'Builder 3': [(1, True), (3, True), (7, True), (11, False), (12, True)],
        }), 7)

    def _fetch_build(self, build_number):
        if build_number == 5:
            return "correct build"
        return "wrong build"

    def _fetch_revision_to_build_map(self):
        return {'r5': 5, 'r2': 2, 'r3': 3}

    def test_latest_cached_build(self):
        b = Builder('builder', BuildBot())
        b._fetch_build = self._fetch_build
        b._fetch_revision_to_build_map = self._fetch_revision_to_build_map
        self.assertEqual("correct build", b.latest_cached_build())

    def results_url(self):
        return "some-url"

    def test_results_zip_url(self):
        b = Build(None, 123, 123, False)
        b.results_url = self.results_url
        self.assertEqual("some-url.zip", b.results_zip_url())
