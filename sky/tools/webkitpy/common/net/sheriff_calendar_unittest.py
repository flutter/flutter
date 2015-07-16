# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This is based on code from:
# https://chromium.googlesource.com/chromium/tools/build/+/master/scripts/tools/blink_roller/auto_roll_test.py
# Ideally we should share code between these.


from webkitpy.common.system.outputcapture import OutputCaptureTestCaseBase
import sheriff_calendar as calendar


class SheriffCalendarTest(OutputCaptureTestCaseBase):
    def test_complete_email(self):
        expected_emails = ['foo@chromium.org', 'bar@google.com', 'baz@chromium.org']
        names = ['foo', 'bar@google.com', 'baz']
        self.assertEqual(map(calendar._complete_email, names), expected_emails)

    def test_emails(self):
        expected_emails = ['foo@bar.com', 'baz@baz.com']
        calendar._emails_from_url = lambda urls: expected_emails
        self.assertEqual(calendar.current_gardener_emails(), expected_emails)

    def _assert_parse(self, js_string, expected_emails):
        self.assertEqual(calendar._names_from_sheriff_js(js_string), expected_emails)

    def test_names_from_sheriff_js(self):
        self._assert_parse('document.write(\'none (channel is sheriff)\')', [])
        self._assert_parse('document.write(\'foo, bar\')', ['foo', 'bar'])

    def test_email_regexp(self):
        self.assertTrue(calendar._email_is_valid('somebody@example.com'))
        self.assertTrue(calendar._email_is_valid('somebody@example.domain.com'))
        self.assertTrue(calendar._email_is_valid('somebody@example-domain.com'))
        self.assertTrue(calendar._email_is_valid('some.body@example.com'))
        self.assertTrue(calendar._email_is_valid('some_body@example.com'))
        self.assertTrue(calendar._email_is_valid('some+body@example.com'))
        self.assertTrue(calendar._email_is_valid('some+body@com'))
        self.assertTrue(calendar._email_is_valid('some/body@example.com'))
        # These are valid according to the standard, but not supported here.
        self.assertFalse(calendar._email_is_valid('some~body@example.com'))
        self.assertFalse(calendar._email_is_valid('some!body@example.com'))
        self.assertFalse(calendar._email_is_valid('some?body@example.com'))
        self.assertFalse(calendar._email_is_valid('some" "body@example.com'))
        self.assertFalse(calendar._email_is_valid('"{somebody}"@example.com'))
        # Bogus.
        self.assertFalse(calendar._email_is_valid('rm -rf /#@example.com'))
        self.assertFalse(calendar._email_is_valid('some body@example.com'))
        self.assertFalse(calendar._email_is_valid('[some body]@example.com'))

    def test_filter_emails(self):
        input_emails = ['foo@bar.com', 'baz@baz.com', 'bogus email @ !!!']
        expected_emails = ['foo@bar.com', 'baz@baz.com']
        self.assertEquals(calendar._filter_emails(input_emails), expected_emails)
        self.assertStdout('WARNING: Not including bogus email @ !!! (invalid email address)\n')
