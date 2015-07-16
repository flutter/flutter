# Copyright (c) 2010, Google Inc. All rights reserved.
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

import re


def view_source_url(local_path):
    return "http://trac.webkit.org/browser/trunk/%s" % local_path


def view_revision_url(revision_number):
    return "http://trac.webkit.org/changeset/%s" % revision_number


def chromium_results_url_base():
    return 'https://storage.googleapis.com/chromium-layout-test-archives'


def chromium_results_url_base_for_builder(builder_name):
    return '%s/%s' % (chromium_results_url_base(), re.sub('[ .()]', '_', builder_name))


def chromium_results_zip_url(builder_name):
    return chromium_results_url_base_for_builder(builder_name) + '/results/layout-test-results.zip'


def chromium_accumulated_results_url_base_for_builder(builder_name):
    return chromium_results_url_base_for_builder(builder_name) + "/results/layout-test-results"


chromium_lkgr_url = "http://chromium-status.appspot.com/lkgr"
contribution_guidelines = "http://webkit.org/coding/contributing.html"

bug_server_domain = "webkit.org"
bug_server_host = "bugs." + bug_server_domain
_bug_server_regex = "https?://%s/" % re.sub('\.', '\\.', bug_server_host)
bug_server_url = "https://%s/" % bug_server_host
bug_url_long = _bug_server_regex + r"show_bug\.cgi\?id=(?P<bug_id>\d+)(&ctype=xml|&excludefield=attachmentdata)*"
bug_url_short = r"https?\://%s/b/(?P<bug_id>\d+)" % bug_server_domain

attachment_url = _bug_server_regex + r"attachment\.cgi\?id=(?P<attachment_id>\d+)(&action=(?P<action>\w+))?"
direct_attachment_url = r"https?://bug-(?P<bug_id>\d+)-attachments.%s/attachment\.cgi\?id=(?P<attachment_id>\d+)" % bug_server_domain

buildbot_url = "http://build.webkit.org"
chromium_buildbot_url = "http://build.chromium.org/p/chromium.webkit"

chromium_webkit_sheriff_url = "http://build.chromium.org/p/chromium.webkit/sheriff_webkit.js"

omahaproxy_url = "http://omahaproxy.appspot.com/"

def parse_bug_id(string):
    if not string:
        return None
    match = re.search(bug_url_short, string)
    if match:
        return int(match.group('bug_id'))
    match = re.search(bug_url_long, string)
    if match:
        return int(match.group('bug_id'))
    return None


def parse_attachment_id(string):
    if not string:
        return None
    match = re.search(attachment_url, string)
    if match:
        return int(match.group('attachment_id'))
    match = re.search(direct_attachment_url, string)
    if match:
        return int(match.group('attachment_id'))
    return None
