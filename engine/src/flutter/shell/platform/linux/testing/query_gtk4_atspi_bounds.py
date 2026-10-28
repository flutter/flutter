#!/usr/bin/env python3
# Copyright 2026 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import json
import subprocess
import sys
import time
from collections import deque

import gi

gi.require_version('Atspi', '2.0')
from gi.repository import Atspi, GLib

if len(sys.argv) > 1 and sys.argv[1] == '--serve':
  from atspi_test_utils import accessibility_bus
  with accessibility_bus(sys.stderr):
    raise SystemExit(
        subprocess.call([
            sys.argv[2], '--gtest_filter=FlGtk4ScalingTest.ExternalWaylandScaleChanges'
        ])
    )

deadline = time.monotonic() + 3
while time.monotonic() < deadline:
  queue = deque([Atspi.get_desktop(0)])
  while queue:
    node = queue.popleft()
    try:
      if node.get_name() == 'Fractional bounds' and node.get_role() == Atspi.Role.LABEL:
        rect = node.get_component_iface().get_extents(Atspi.CoordType.WINDOW)
        print(json.dumps([rect.x, rect.y, rect.width, rect.height]))
        raise SystemExit(0)
      for index in range(node.get_child_count()):
        child = node.get_child_at_index(index)
        if child is not None:
          queue.append(child)
    except GLib.Error:
      continue
  time.sleep(0.05)
raise RuntimeError('The synthetic fractional-bounds node was not exported on AT-SPI')
