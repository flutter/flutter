# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import threading

class TestCollection(object):
  """A threadsafe collection of tests.

  Args:
    tests: List of tests to put in the collection.
  """

  def __init__(self, tests=None):
    if not tests:
      tests = []
    self._lock = threading.Lock()
    self._tests = []
    self._tests_in_progress = 0
    # Used to signal that an item is available or all items have been handled.
    self._item_available_or_all_done = threading.Event()
    for t in tests:
      self.add(t)

  def _pop(self):
    """Pop a test from the collection.

    Waits until a test is available or all tests have been handled.

    Returns:
      A test or None if all tests have been handled.
    """
    while True:
      # Wait for a test to be available or all tests to have been handled.
      self._item_available_or_all_done.wait()
      with self._lock:
        # Check which of the two conditions triggered the signal.
        if self._tests_in_progress == 0:
          return None
        try:
          return self._tests.pop(0)
        except IndexError:
          # Another thread beat us to the available test, wait again.
          self._item_available_or_all_done.clear()

  def add(self, test):
    """Add a test to the collection.

    Args:
      test: A test to add.
    """
    with self._lock:
      self._tests.append(test)
      self._item_available_or_all_done.set()
      self._tests_in_progress += 1

  def test_completed(self):
    """Indicate that a test has been fully handled."""
    with self._lock:
      self._tests_in_progress -= 1
      if self._tests_in_progress == 0:
        # All tests have been handled, signal all waiting threads.
        self._item_available_or_all_done.set()

  def __iter__(self):
    """Iterate through tests in the collection until all have been handled."""
    while True:
      r = self._pop()
      if r is None:
        break
      yield r

  def __len__(self):
    """Return the number of tests currently in the collection."""
    return len(self._tests)

  def test_names(self):
    """Return a list of the names of the tests currently in the collection."""
    with self._lock:
      return list(t.test for t in self._tests)
