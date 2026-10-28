# Copyright 2026 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Tests for the AT-SPI comparison report, without a GUI or accessibility bus."""

import unittest

from run_atspi_parity_test import differences, normalized_action


class AtspiParityReportTest(unittest.TestCase):

  def test_backend_action_names_match(self):
    for atk, gtk in [('Tap', 'flutter.tap'), ('ScrollDown', 'flutter.scroll-down'),
                     ('MoveCursorForwardByWord', 'flutter.move-cursor-forward-by-word')]:
      with self.subTest(atk=atk):
        self.assertEqual(normalized_action(atk), normalized_action(gtk))

  def test_identical_snapshots_have_no_differences(self):
    self.assertEqual(
        differences({'text': {'selections': [[1, 2]]}}, {'text': {'selections': [[1, 2]]}}), []
    )

  def test_missing_interface_is_different_from_null(self):
    report = differences({}, {'text': None})
    self.assertEqual(report[0]['path'], '/text')
    self.assertEqual(report[0]['missing'], 'gtk3')

  def test_nested_state_and_selection_differences_are_preserved(self):
    report = differences({'Editor': {'selection': [1, 2], 'focused': False}},
                         {'Editor': {'selection': [1, 3], 'focused': True}})
    self.assertEqual([entry['path'] for entry in report], ['/Editor/focused', '/Editor/selection'])
    self.assertEqual(report[1]['gtk3'], [1, 2])
    self.assertEqual(report[1]['gtk4'], [1, 3])


if __name__ == '__main__':
  unittest.main()
