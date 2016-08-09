# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Unittests for SurfaceStatsCollector."""
# pylint: disable=W0212

import unittest

from pylib.perf.surface_stats_collector import SurfaceStatsCollector


class TestSurfaceStatsCollector(unittest.TestCase):
  @staticmethod
  def _CreateUniformTimestamps(base, num, delta):
    return [base + i * delta for i in range(1, num + 1)]

  @staticmethod
  def _CreateDictionaryFromResults(results):
    dictionary = {}
    for result in results:
      dictionary[result.name] = result
    return dictionary

  def setUp(self):
    self.refresh_period = 0.1

  def testOneFrameDelta(self):
    timestamps = self._CreateUniformTimestamps(0, 10, self.refresh_period)
    results = self._CreateDictionaryFromResults(
                  SurfaceStatsCollector._CalculateResults(
                      self.refresh_period, timestamps, ''))

    self.assertEquals(results['avg_surface_fps'].value,
                      int(round(1 / self.refresh_period)))
    self.assertEquals(results['jank_count'].value, 0)
    self.assertEquals(results['max_frame_delay'].value, 1)
    self.assertEquals(len(results['frame_lengths'].value), len(timestamps) - 1)

  def testAllFramesTooShort(self):
    timestamps = self._CreateUniformTimestamps(0, 10, self.refresh_period / 100)
    self.assertRaises(Exception,
                      SurfaceStatsCollector._CalculateResults,
                      [self.refresh_period, timestamps, ''])

  def testSomeFramesTooShort(self):
    timestamps = self._CreateUniformTimestamps(0, 5, self.refresh_period)
    # The following timestamps should be skipped.
    timestamps += self._CreateUniformTimestamps(timestamps[4],
                                                5,
                                                self.refresh_period / 100)
    timestamps += self._CreateUniformTimestamps(timestamps[4],
                                                5,
                                                self.refresh_period)

    results = self._CreateDictionaryFromResults(
                  SurfaceStatsCollector._CalculateResults(
                      self.refresh_period, timestamps, ''))

    self.assertEquals(len(results['frame_lengths'].value), 9)


if __name__ == '__main__':
  unittest.main()
