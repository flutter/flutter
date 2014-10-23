# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import re
import urllib2

# This is based on code from:
# https://chromium.googlesource.com/chromium/tools/build/+/master/scripts/tools/blink_roller/auto_roll.py
# Ideally we should share code between these.

# FIXME: This probably belongs in config.py?
BLINK_SHERIFF_URL = (
    'http://build.chromium.org/p/chromium.webkit/sheriff_webkit.js')


# Does not support unicode or special characters.
VALID_EMAIL_REGEXP = re.compile(r'^[A-Za-z0-9\.&\'\+-/=_]+@[A-Za-z0-9\.-]+$')


def _complete_email(name):
    """If the name does not include '@', append '@chromium.org'."""
    if '@' not in name:
        return name + '@chromium.org'
    return name


def _names_from_sheriff_js(sheriff_js):
    match = re.match(r'document.write\(\'(.*)\'\)', sheriff_js)
    emails_string = match.group(1)
    # Detect 'none (channel is sheriff)' text and ignore it.
    if 'channel is sheriff' in emails_string.lower():
        return []
    return map(str.strip, emails_string.split(','))


def _email_is_valid(email):
    """Determines whether the given email address is valid."""
    return VALID_EMAIL_REGEXP.match(email) is not None


def _filter_emails(emails):
    """Returns the given list with any invalid email addresses removed."""
    rv = []
    for email in emails:
        if _email_is_valid(email):
            rv.append(email)
        else:
            print 'WARNING: Not including %s (invalid email address)' % email
    return rv


def _emails_from_url(sheriff_url):
    sheriff_js = urllib2.urlopen(sheriff_url).read()
    return map(_complete_email, _names_from_sheriff_js(sheriff_js))


def current_gardener_emails():
    return _emails_from_url(BLINK_SHERIFF_URL)
