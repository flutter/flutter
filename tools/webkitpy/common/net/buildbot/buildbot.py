# Copyright (c) 2009, Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
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

import json
import operator
import re
import urllib
import urllib2

import webkitpy.common.config.urls as config_urls
from webkitpy.common.memoized import memoized
from webkitpy.common.net.layouttestresults import LayoutTestResults
from webkitpy.common.net.networktransaction import NetworkTransaction
from webkitpy.common.system.logutils import get_logger
from webkitpy.thirdparty.BeautifulSoup import BeautifulSoup


_log = get_logger(__file__)


class Builder(object):
    def __init__(self, name, buildbot):
        self._name = name
        self._buildbot = buildbot
        self._builds_cache = {}
        self._revision_to_build_number = None

    def name(self):
        return self._name

    def results_url(self):
        return "%s/results/%s" % (self._buildbot.buildbot_url, self.url_encoded_name())

    # In addition to per-build results, the build.chromium.org builders also
    # keep a directory that accumulates test results over many runs.
    def accumulated_results_url(self):
        return None

    def latest_layout_test_results_url(self):
        return self.accumulated_results_url() or self.latest_cached_build().results_url();

    @memoized
    def latest_layout_test_results(self):
        return self.fetch_layout_test_results(self.latest_layout_test_results_url())

    def _fetch_file_from_results(self, results_url, file_name):
        # It seems this can return None if the url redirects and then returns 404.
        result = urllib2.urlopen("%s/%s" % (results_url, file_name))
        if not result:
            return None
        # urlopen returns a file-like object which sometimes works fine with str()
        # but sometimes is a addinfourl object.  In either case calling read() is correct.
        return result.read()

    def fetch_layout_test_results(self, results_url):
        # FIXME: This should cache that the result was a 404 and stop hitting the network.
        results_file = NetworkTransaction(convert_404_to_None=True).run(lambda: self._fetch_file_from_results(results_url, "failing_results.json"))
        return LayoutTestResults.results_from_string(results_file)

    def url_encoded_name(self):
        return urllib.quote(self._name)

    def url(self):
        return "%s/builders/%s" % (self._buildbot.buildbot_url, self.url_encoded_name())

    # This provides a single place to mock
    def _fetch_build(self, build_number):
        build_dictionary = self._buildbot._fetch_build_dictionary(self, build_number)
        if not build_dictionary:
            return None
        revision_string = build_dictionary['sourceStamp']['revision']
        return Build(self,
            build_number=int(build_dictionary['number']),
            # 'revision' may be None if a trunk build was started by the force-build button on the web page.
            revision=(int(revision_string) if revision_string else None),
            # Buildbot uses any nubmer other than 0 to mean fail.  Since we fetch with
            # filter=1, passing builds may contain no 'results' value.
            is_green=(not build_dictionary.get('results')),
        )

    def build(self, build_number):
        if not build_number:
            return None
        cached_build = self._builds_cache.get(build_number)
        if cached_build:
            return cached_build

        build = self._fetch_build(build_number)
        self._builds_cache[build_number] = build
        return build

    def latest_cached_build(self):
        revision_build_pairs = self.revision_build_pairs_with_results()
        revision_build_pairs.sort(key=lambda i: i[1])
        latest_build_number = revision_build_pairs[-1][1]
        return self.build(latest_build_number)

    file_name_regexp = re.compile(r"r(?P<revision>\d+) \((?P<build_number>\d+)\)")
    def _revision_and_build_for_filename(self, filename):
        # Example: "r47483 (1)/" or "r47483 (1).zip"
        match = self.file_name_regexp.match(filename)
        if not match:
            return None
        return (int(match.group("revision")), int(match.group("build_number")))

    def _fetch_revision_to_build_map(self):
        # All _fetch requests go through _buildbot for easier mocking
        # FIXME: This should use NetworkTransaction's 404 handling instead.
        try:
            # FIXME: This method is horribly slow due to the huge network load.
            # FIXME: This is a poor way to do revision -> build mapping.
            # Better would be to ask buildbot through some sort of API.
            print "Loading revision/build list from %s." % self.results_url()
            print "This may take a while..."
            result_files = self._buildbot._fetch_twisted_directory_listing(self.results_url())
        except urllib2.HTTPError, error:
            if error.code != 404:
                raise
            _log.debug("Revision/build list failed to load.")
            result_files = []
        return dict(self._file_info_list_to_revision_to_build_list(result_files))

    def _file_info_list_to_revision_to_build_list(self, file_info_list):
        # This assumes there was only one build per revision, which is false but we don't care for now.
        revisions_and_builds = []
        for file_info in file_info_list:
            revision_and_build = self._revision_and_build_for_filename(file_info["filename"])
            if revision_and_build:
                revisions_and_builds.append(revision_and_build)
        return revisions_and_builds

    def _revision_to_build_map(self):
        if not self._revision_to_build_number:
            self._revision_to_build_number = self._fetch_revision_to_build_map()
        return self._revision_to_build_number

    def revision_build_pairs_with_results(self):
        return self._revision_to_build_map().items()

    # This assumes there can be only one build per revision, which is false, but we don't care for now.
    def build_for_revision(self, revision, allow_failed_lookups=False):
        # NOTE: This lookup will fail if that exact revision was never built.
        build_number = self._revision_to_build_map().get(int(revision))
        if not build_number:
            return None
        build = self.build(build_number)
        if not build and allow_failed_lookups:
            # Builds for old revisions with fail to lookup via buildbot's json api.
            build = Build(self,
                build_number=build_number,
                revision=revision,
                is_green=False,
            )
        return build


class Build(object):
    def __init__(self, builder, build_number, revision, is_green):
        self._builder = builder
        self._number = build_number
        self._revision = revision
        self._is_green = is_green

    @staticmethod
    def build_url(builder, build_number):
        return "%s/builds/%s" % (builder.url(), build_number)

    def url(self):
        return self.build_url(self.builder(), self._number)

    def results_url(self):
        results_directory = "r%s (%s)" % (self.revision(), self._number)
        return "%s/%s" % (self._builder.results_url(), urllib.quote(results_directory))

    def results_zip_url(self):
        return "%s.zip" % self.results_url()

    def builder(self):
        return self._builder

    def revision(self):
        return self._revision

    def is_green(self):
        return self._is_green

    def previous_build(self):
        # previous_build() allows callers to avoid assuming build numbers are sequential.
        # They may not be sequential across all master changes, or when non-trunk builds are made.
        return self._builder.build(self._number - 1)


class BuildBot(object):
    _builder_factory = Builder
    _default_url = config_urls.buildbot_url

    def __init__(self, url=None):
        self.buildbot_url = url if url else self._default_url
        self._builder_by_name = {}

    def _parse_last_build_cell(self, builder, cell):
        status_link = cell.find('a')
        if status_link:
            # Will be either a revision number or a build number
            revision_string = status_link.string
            # If revision_string has non-digits assume it's not a revision number.
            builder['built_revision'] = int(revision_string) \
                                        if not re.match('\D', revision_string) \
                                        else None

            # FIXME: We treat slave lost as green even though it is not to
            # work around the Qts bot being on a broken internet connection.
            # The real fix is https://bugs.webkit.org/show_bug.cgi?id=37099
            builder['is_green'] = not re.search('fail', cell.renderContents()) or \
                                  not not re.search('lost', cell.renderContents())

            status_link_regexp = r"builders/(?P<builder_name>.*)/builds/(?P<build_number>\d+)"
            link_match = re.match(status_link_regexp, status_link['href'])
            builder['build_number'] = int(link_match.group("build_number"))
        else:
            # We failed to find a link in the first cell, just give up.  This
            # can happen if a builder is just-added, the first cell will just
            # be "no build"
            # Other parts of the code depend on is_green being present.
            builder['is_green'] = False
            builder['built_revision'] = None
            builder['build_number'] = None

    def _parse_current_build_cell(self, builder, cell):
        activity_lines = cell.renderContents().split("<br />")
        builder["activity"] = activity_lines[0] # normally "building" or "idle"
        # The middle lines document how long left for any current builds.
        match = re.match("(?P<pending_builds>\d) pending", activity_lines[-1])
        builder["pending_builds"] = int(match.group("pending_builds")) if match else 0

    def _parse_builder_status_from_row(self, status_row):
        status_cells = status_row.findAll('td')
        builder = {}

        # First cell is the name
        name_link = status_cells[0].find('a')
        builder["name"] = unicode(name_link.string)

        self._parse_last_build_cell(builder, status_cells[1])
        self._parse_current_build_cell(builder, status_cells[2])
        return builder

    def _matches_regexps(self, builder_name, name_regexps):
        for name_regexp in name_regexps:
            if re.match(name_regexp, builder_name):
                return True
        return False

    # FIXME: This method needs to die, but is used by a unit test at the moment.
    def _builder_statuses_with_names_matching_regexps(self, builder_statuses, name_regexps):
        return [builder for builder in builder_statuses if self._matches_regexps(builder["name"], name_regexps)]

    # FIXME: These _fetch methods should move to a networking class.
    def _fetch_build_dictionary(self, builder, build_number):
        # Note: filter=1 will remove None and {} and '', which cuts noise but can
        # cause keys to be missing which you might otherwise expect.
        # FIXME: The bot sends a *huge* amount of data for each request, we should
        # find a way to reduce the response size further.
        json_url = "%s/json/builders/%s/builds/%s?filter=1" % (self.buildbot_url, urllib.quote(builder.name()), build_number)
        try:
            return json.load(urllib2.urlopen(json_url))
        except urllib2.URLError, err:
            build_url = Build.build_url(builder, build_number)
            _log.error("Error fetching data for %s build %s (%s, json: %s): %s" % (builder.name(), build_number, build_url, json_url, err))
            return None
        except ValueError, err:
            build_url = Build.build_url(builder, build_number)
            _log.error("Error decoding json data from %s: %s" % (build_url, err))
            return None

    def _fetch_one_box_per_builder(self):
        build_status_url = "%s/one_box_per_builder" % self.buildbot_url
        return urllib2.urlopen(build_status_url)

    def _file_cell_text(self, file_cell):
        """Traverses down through firstChild elements until one containing a string is found, then returns that string"""
        element = file_cell
        while element.string is None and element.contents:
            element = element.contents[0]
        return element.string

    def _parse_twisted_file_row(self, file_row):
        string_or_empty = lambda string: unicode(string) if string else u""
        file_cells = file_row.findAll('td')
        return {
            "filename": string_or_empty(self._file_cell_text(file_cells[0])),
            "size": string_or_empty(self._file_cell_text(file_cells[1])),
            "type": string_or_empty(self._file_cell_text(file_cells[2])),
            "encoding": string_or_empty(self._file_cell_text(file_cells[3])),
        }

    def _parse_twisted_directory_listing(self, page):
        soup = BeautifulSoup(page)
        # HACK: Match only table rows with a class to ignore twisted header/footer rows.
        file_rows = soup.find('table').findAll('tr', {'class': re.compile(r'\b(?:directory|file)\b')})
        return [self._parse_twisted_file_row(file_row) for file_row in file_rows]

    # FIXME: There should be a better way to get this information directly from twisted.
    def _fetch_twisted_directory_listing(self, url):
        return self._parse_twisted_directory_listing(urllib2.urlopen(url))

    def builders(self):
        return [self.builder_with_name(status["name"]) for status in self.builder_statuses()]

    # This method pulls from /one_box_per_builder as an efficient way to get information about
    def builder_statuses(self):
        soup = BeautifulSoup(self._fetch_one_box_per_builder())
        return [self._parse_builder_status_from_row(status_row) for status_row in soup.find('table').findAll('tr')]

    def builder_with_name(self, name):
        builder = self._builder_by_name.get(name)
        if not builder:
            builder = self._builder_factory(name, self)
            self._builder_by_name[name] = builder
        return builder

    # This makes fewer requests than calling Builder.latest_build would.  It grabs all builder
    # statuses in one request using self.builder_statuses (fetching /one_box_per_builder instead of builder pages).
    def _latest_builds_from_builders(self):
        builder_statuses = self.builder_statuses()
        return [self.builder_with_name(status["name"]).build(status["build_number"]) for status in builder_statuses]

    def _build_at_or_before_revision(self, build, revision):
        while build:
            if build.revision() <= revision:
                return build
            build = build.previous_build()

    def _fetch_builder_page(self, builder):
        builder_page_url = "%s/builders/%s?numbuilds=100" % (self.buildbot_url, urllib2.quote(builder.name()))
        return urllib2.urlopen(builder_page_url)

    def _revisions_for_builder(self, builder):
        soup = BeautifulSoup(self._fetch_builder_page(builder))
        revisions = []
        for status_row in soup.find('table').findAll('tr'):
            revision_anchor = status_row.find('a')
            table_cells = status_row.findAll('td')
            if not table_cells or len(table_cells) < 3 or not table_cells[2].string:
                continue
            if revision_anchor and revision_anchor.string and re.match(r'^\d+$', revision_anchor.string):
                revisions.append((int(revision_anchor.string), 'success' in table_cells[2].string))
        return revisions

    def _find_green_revision(self, builder_revisions):
        revision_statuses = {}
        for builder in builder_revisions:
            for revision, succeeded in builder_revisions[builder]:
                revision_statuses.setdefault(revision, set())
                if succeeded and revision_statuses[revision] != None:
                    revision_statuses[revision].add(builder)
                else:
                    revision_statuses[revision] = None

        # In descending order, look for a revision X with successful builds
        # Once we found X, check if remaining builders succeeded in the neighborhood of X.
        revisions_in_order = sorted(revision_statuses.keys(), reverse=True)
        for i, revision in enumerate(revisions_in_order):
            if not revision_statuses[revision]:
                continue

            builders_succeeded_in_future = set()
            for future_revision in sorted(revisions_in_order[:i + 1]):
                if not revision_statuses[future_revision]:
                    break
                builders_succeeded_in_future = builders_succeeded_in_future.union(revision_statuses[future_revision])

            builders_succeeded_in_past = set()
            for past_revision in revisions_in_order[i:]:
                if not revision_statuses[past_revision]:
                    break
                builders_succeeded_in_past = builders_succeeded_in_past.union(revision_statuses[past_revision])

            if len(builders_succeeded_in_future) == len(builder_revisions) and len(builders_succeeded_in_past) == len(builder_revisions):
                return revision
        return None
