# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Utility module for testharness."""


# const definitions
TESTHARNESSREPORT_HEADER = 'This is a testharness.js-based test.'
TESTHARNESSREPORT_FOOTER = 'Harness: the test ran to completion.'


def is_testharness_output(content_text):
    """
    Returns whether the content_text in parameter is a testharness output.
    """

    # Leading and trailing white spaces are accepted.
    lines = content_text.strip().splitlines()
    lines = [line.strip() for line in lines]

    # A testharness output is defined as containing the header and the footer.
    found_header = False
    found_footer = False
    for line in lines:
        if line == TESTHARNESSREPORT_HEADER:
            found_header = True
        elif line == TESTHARNESSREPORT_FOOTER:
            found_footer = True

    return found_header and found_footer


def is_testharness_output_passing(content_text):
    """
    Returns whether the content_text in parameter is a passing testharness output.

    Note:
        It is expected that the |content_text| is a testharness output.
    """

    # Leading and trailing white spaces are accepted.
    lines = content_text.strip().splitlines()
    lines = [line.strip() for line in lines]

    # The check is very conservative and rejects any unexpected content in the output.
    for line in lines:
        # There should be no empty lines.
        if len(line) == 0:
            return False

        # Those lines are expected to be exactly equivalent.
        if line == TESTHARNESSREPORT_HEADER or \
           line == TESTHARNESSREPORT_FOOTER:
            continue

        # Those are expected passing output.
        if line.startswith('CONSOLE') or \
           line.startswith('PASS'):
            continue

        # Those are expected failing output.
        if line.startswith('FAIL') or \
           line.startswith('TIMEOUT') or \
           line.startswith('NOTRUN') or \
           line.startswith('Harness Error. harness_status = '):
            return False

        # Unexpected output should be considered as a failure.
        return False

    return True
