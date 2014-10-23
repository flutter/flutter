# Copyright (C) 2013 Google Inc. All rights reserved.
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

from webkitpy.tool.bot.commitannouncer import CommitAnnouncer
from webkitpy.tool.mocktool import MockTool


class CommitAnnouncerTest(unittest.TestCase):
    def test_format_commit(self):
        tool = MockTool()
        bot = CommitAnnouncer(tool, "test_password")
        self.assertEqual(
           'r456789 http://crrev.com/123456 authorABC@chromium.org committed "Commit test subject line"',
            bot._format_commit_detail("""\
1234commit1234
authorABC@chromium.org
Commit test subject line
Multiple
lines
of
description.

BUG=654321

Review URL: https://codereview.chromium.org/123456

git-svn-id: svn://svn.chromium.org/blink/trunk@456789 bbb929c8-8fbe-4397-9dbb-9b2b20218538
"""))

        self.assertEqual(
            'r456789 https://chromium.googlesource.com/chromium/blink/+/1234comm '
            'authorABC@chromium.org committed "Commit test subject line"',
            bot._format_commit_detail("""\
1234commit1234
authorABC@chromium.org
Commit test subject line
Multiple
lines
of
description.

BUG=654321

git-svn-id: svn://svn.chromium.org/blink/trunk@456789 bbb929c8-8fbe-4397-9dbb-9b2b20218538
"""))

        self.assertEqual(
            'http://crrev.com/123456 authorABC@chromium.org committed "Commit test subject line"',
            bot._format_commit_detail("""\
1234commit1234
authorABC@chromium.org
Commit test subject line
Multiple
lines
of
description.

BUG=654321

Review URL: https://codereview.chromium.org/123456
"""))

        self.assertEqual(
            'https://chromium.googlesource.com/chromium/blink/+/1234comm authorABC@chromium.org committed "Commit test subject line"',
            bot._format_commit_detail("""\
1234commit1234
authorABC@chromium.org
Commit test subject line
Multiple
lines
of
description.
"""))

        self.assertEqual(
            'r456789 http://crrev.com/123456 authorABC@chromium.org committed "Commit test subject line"',
            bot._format_commit_detail("""\
1234commit1234
authorABC@chromium.org
Commit test subject line
Multiple
lines
of
description.
Review URL: http://fake.review.url
git-svn-id: svn://svn.chromium.org/blink/trunk@000000 Fake-SVN-number

BUG=654321

Review URL: https://codereview.chromium.org/123456

git-svn-id: svn://svn.chromium.org/blink/trunk@456789 bbb929c8-8fbe-4397-9dbb-9b2b20218538
"""))

        self.assertEqual(
           'r456789 http://crrev.com/123456 authorABC@chromium.org committed "Commit test subject line" '
           '\x037TBR=reviewerDEF@chromium.org\x03',
            bot._format_commit_detail("""\
1234commit1234
authorABC@chromium.org
Commit test subject line
Multiple
lines
of
description.

BUG=654321
TBR=reviewerDEF@chromium.org

Review URL: https://codereview.chromium.org/123456

git-svn-id: svn://svn.chromium.org/blink/trunk@456789 bbb929c8-8fbe-4397-9dbb-9b2b20218538
"""))

        self.assertEqual(
           'r456789 http://crrev.com/123456 authorABC@chromium.org committed "Commit test subject line" '
           '\x037NOTRY=true\x03',
            bot._format_commit_detail("""\
1234commit1234
authorABC@chromium.org
Commit test subject line
Multiple
lines
of
description.

BUG=654321
NOTRY=true

Review URL: https://codereview.chromium.org/123456

git-svn-id: svn://svn.chromium.org/blink/trunk@456789 bbb929c8-8fbe-4397-9dbb-9b2b20218538
"""))

        self.assertEqual(
           'r456789 http://crrev.com/123456 authorABC@chromium.org committed "Commit test subject line" '
           '\x037NOTRY=true TBR=reviewerDEF@chromium.org\x03',
            bot._format_commit_detail("""\
1234commit1234
authorABC@chromium.org
Commit test subject line
Multiple
lines
of
description.

NOTRY=true
BUG=654321
TBR=reviewerDEF@chromium.org

Review URL: https://codereview.chromium.org/123456

git-svn-id: svn://svn.chromium.org/blink/trunk@456789 bbb929c8-8fbe-4397-9dbb-9b2b20218538
"""))

        self.assertEqual(
           'r456789 http://crrev.com/123456 authorABC@chromium.org committed "Commit test subject line" '
           '\x037tbr=reviewerDEF@chromium.org, reviewerGHI@chromium.org, reviewerJKL@chromium.org notry=TRUE\x03',
            bot._format_commit_detail("""\
1234commit1234
authorABC@chromium.org
Commit test subject line
Multiple
lines
of
description.

BUG=654321
tbr=reviewerDEF@chromium.org, reviewerGHI@chromium.org, reviewerJKL@chromium.org
notry=TRUE

Review URL: https://codereview.chromium.org/123456

git-svn-id: svn://svn.chromium.org/blink/trunk@456789 bbb929c8-8fbe-4397-9dbb-9b2b20218538
"""))

    def test_sanitize_string(self):
        bot = CommitAnnouncer(MockTool(), "test_password")
        self.assertEqual('normal ascii', bot._sanitize_string('normal ascii'))
        self.assertEqual('uni\\u0441ode!', bot._sanitize_string(u'uni\u0441ode!'))
