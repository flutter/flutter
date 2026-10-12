#!/usr/bin/env python3
# Copyright 2026 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Verify nested GTK4 accessibility coordinates through real AT-SPI."""

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import subprocess
import sys
import tempfile

from atspi_test_utils import accessibility_bus, process, wait_until


def run_fixture(binary, output, scale):
  with accessibility_bus(output) as Atspi:
    with process([binary, '--gtest_filter=FlViewGtk4AccessibilityTest.ExternalAtspiGeometry'],
                 output) as fixture:

      def named(name):
        if fixture.poll() is not None:
          raise RuntimeError('Geometry fixture exited before verification')
        desktop = Atspi.get_desktop(0)
        for index in range(desktop.get_child_count()):
          app = desktop.get_child_at_index(index)
          if app is None or app.get_process_id() != fixture.pid:
            continue
          pending = [app]
          for _ in range(100):
            if not pending:
              break
            node = pending.pop()
            if node.get_name() == name:
              return node
            pending.extend(
                child for i in range(node.get_child_count())
                if (child := node.get_child_at_index(i)) is not None
            )
        return None

      root = wait_until(lambda: named('Geometry root'), 'geometry root')
      group = wait_until(lambda: named('Geometry group'), 'geometry group')
      button = wait_until(lambda: named('Geometry button'), 'geometry button')
      surface = root.get_parent()

      def rectangle(node, coordinates):
        rect = node.get_component_iface().get_extents(coordinates)
        return [rect.x, rect.y, rect.width, rect.height]

      # Physical view bounds are independently derived from the fixture's
      # composed transforms. GTK coordinates are logical and parent-relative.
      def logical(bounds):
        x, y, width, height = bounds
        left, top = math.floor(x / scale), math.floor(y / scale)
        return [
            left, top,
            math.ceil((x + width) / scale) - left,
            math.ceil((y + height) / scale) - top
        ]

      def snapshot(dx, dy):
        physical = [[40 + dx, 54 + dy, 600, 400], [76 + dx, 70 + dy, 200, 160],
                    [93 + dx, 95 + dy, 40, 20]]
        bounds = [logical(b) for b in physical]
        surface_bounds = rectangle(surface, Atspi.CoordType.WINDOW)
        if surface_bounds[:2] != [37, 29]:
          raise RuntimeError(f'Nested GTK host offset is wrong: {surface_bounds}')
        records = []
        for index, node in enumerate((root, group, button)):
          view = bounds[index]
          origin = bounds[index - 1][:2] if index else [0, 0]
          parent_expected = [view[0] - origin[0], view[1] - origin[1], *view[2:]]
          window_expected = [surface_bounds[0] + view[0], surface_bounds[1] + view[1], *view[2:]]
          parent = rectangle(node, Atspi.CoordType.PARENT)
          window = rectangle(node, Atspi.CoordType.WINDOW)
          if parent != parent_expected or window != window_expected:
            raise RuntimeError(
                f'{node.get_name()}: parent={parent}, expected={parent_expected}; '
                f'window={window}, expected={window_expected}; scale={scale}'
            )
          records.append({'name': node.get_name(), 'parent': parent, 'window': window})
        return {'surface_window': surface_bounds, 'nodes': records}

      before = snapshot(0, 0)
      actions = button.get_action_iface()
      names = [actions.get_action_name(i) for i in range(actions.get_n_actions())]
      if names != ['flutter.tap'] or not actions.do_action(0):
        raise RuntimeError('Geometry update action was rejected')

      def moved():
        # Queries must observe the root-only update on the same native objects.
        return rectangle(root, Atspi.CoordType.PARENT)[0] == math.floor(52 / scale)

      wait_until(moved, 'root-only geometry update')
      after = snapshot(12, 8)
      if button != named('Geometry button') or group != named('Geometry group'):
        raise RuntimeError('Geometry update replaced retained native objects')
      if not actions.do_action(0):
        raise RuntimeError('Geometry fixture finish action was rejected')
      fixture.wait(timeout=10)
      if fixture.returncode != 0:
        raise RuntimeError(f'Geometry fixture failed: {fixture.returncode}')
      output.seek(0)
      log = output.read()
      if f'GEOMETRY_SCALE {scale}\n' not in log:
        raise RuntimeError('Fixture GTK scale does not match the requested scale')
      runtime = json.loads(
          next(
              line.removeprefix('GEOMETRY_RUNTIME ')
              for line in log.splitlines()
              if line.startswith('GEOMETRY_RUNTIME ')
          )
      )
      return {
          'scale': scale, 'runtime': runtime, 'before': before, 'after': after,
          'retained_identity': True, 'native_tap_dispatches': 2, 'passed': True
      }


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('binary', type=Path)
  parser.add_argument('--output', type=Path)
  parser.add_argument('--inside-session', action='store_true', help=argparse.SUPPRESS)
  parser.add_argument('--scale', type=int, choices=(1, 2), default=1, help=argparse.SUPPRESS)
  args = parser.parse_args()
  binary = args.binary.resolve()
  if args.inside_session:
    with tempfile.TemporaryFile(mode='w+') as output:
      try:
        report = run_fixture(str(binary), output, args.scale)
      except Exception:
        output.seek(0)
        print(output.read(), file=sys.stderr)
        raise
  else:
    results = []
    with tempfile.TemporaryDirectory(prefix='gtk4-atspi-geometry-') as directory:
      config = Path(directory) / 'session.conf'
      # Prevent unrelated desktop portals from autoactivating in the test bus.
      # The accessibility_bus helper starts the required AT-SPI services.
      config.write_text(
          '''<busconfig><type>session</type><listen>unix:tmpdir=/tmp</listen>
<auth>EXTERNAL</auth><policy context="default"><allow send_destination="*"/>
<allow receive_sender="*"/><allow own="*"/></policy></busconfig>'''
      )
      for scale in (1, 2):
        result = Path(directory) / f'scale-{scale}.json'
        environment = os.environ.copy()
        for key in ('GTK_MODULES', 'GTK_PATH', 'AT_SPI_BUS_ADDRESS'):
          environment.pop(key, None)
        environment.update(
            FLUTTER_TEST_ATSPI_GEOMETRY='1',
            GTK_A11Y='atspi',
            GDK_BACKEND='x11',
            GDK_SCALE=str(scale),
            GSK_RENDERER='cairo',
            GDK_DISABLE='gl,vulkan',
            GDK_DEBUG='no-portals',
            GIO_USE_VFS='local'
        )
        subprocess.run([
            'xvfb-run', '-a', 'dbus-run-session', f'--config-file={config}', '--', sys.executable,
            __file__,
            str(binary), '--inside-session', '--scale',
            str(scale), '--output',
            str(result)
        ],
                       env=environment,
                       check=True)
        results.append(json.loads(result.read_text()))
    report = {
        'binary_sha256': hashlib.sha256(binary.read_bytes()).hexdigest(),
        'display': 'private X11/Xvfb', 'scope': 'mock engine, real GTK and AT-SPI',
        'scales': results, 'passed': True
    }
  if args.output:
    args.output.write_text(json.dumps(report, indent=2) + '\n')
  print(json.dumps(report, indent=2))


if __name__ == '__main__':
  main()
