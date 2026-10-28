#!/usr/bin/env python3
# Copyright 2026 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Check independent reading/hit order; currently fails on GTK's generic lookup."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

from atspi_test_utils import accessibility_bus, process, wait_until


def probe(binary, output):
  with accessibility_bus(output) as Atspi:
    with process([str(binary), '--gtest_filter=FlViewGtk4AccessibilityTest.ExternalAtspiGeometry'],
                 output) as fixture:

      def named(name):
        if fixture.poll() is not None:
          raise RuntimeError('Overlap fixture exited before verification')
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

      root = wait_until(lambda: named('Geometry root'), 'root')
      group = wait_until(lambda: named('Geometry group'), 'group')
      front = wait_until(lambda: named('Geometry button'), 'first button')
      back = wait_until(lambda: named('Overlapping geometry button'), 'second button')
      libraries = sorted({
          line.split()[-1]
          for line in Path(f'/proc/{fixture.pid}/maps').read_text().splitlines()
          if '/libgtk-4.so.' in line
      })
      if len(libraries) != 1:
        raise RuntimeError(f'Unexpected GTK library mapping: {libraries}')

      def snapshot(expected):
        group.clear_cache()
        children = [group.get_child_at_index(i) for i in range(group.get_child_count())]
        if children != [front, back]:
          raise RuntimeError('Native reading order changed or lost a button')
        rect = front.get_component_iface().get_extents(Atspi.CoordType.WINDOW)
        point = [rect.x + rect.width // 2, rect.y + rect.height // 2]
        checks = []
        for target in (root, group):
          observed = target.get_component_iface().get_accessible_at_point(
              *point, Atspi.CoordType.WINDOW
          )
          checks.append({
              'target': target.get_name(), 'point': point, 'expected': expected.get_name(),
              'observed': observed.get_name() if observed else None, 'passed': observed == expected
          })
        return {'reading_order': [child.get_name() for child in children], 'hit_checks': checks}

      def tap():
        actions = front.get_action_iface()
        if (actions.get_n_actions() != 1 or actions.get_action_name(0) != 'flutter.tap' or
            not actions.do_action(0)):
          raise RuntimeError('Overlap fixture tap was rejected')

      before = snapshot(front)
      tap()
      wait_until(
          lambda: root.get_component_iface().get_extents(Atspi.CoordType.PARENT).x == 52,
          'partial ancestor and hit-order update'
      )
      after = snapshot(back)
      if front != named('Geometry button') or back != named('Overlapping geometry button'):
        raise RuntimeError('Hit-order update replaced native buttons')
      tap()
      if fixture.wait(timeout=10) != 0:
        raise RuntimeError('Fixture did not receive exactly two native taps')
      return {
          'before':
              before, 'after':
                  after, 'retained_identity':
                      True, 'native_tap_dispatches':
                          2, 'server_library':
                              libraries[0], 'server_library_sha256':
                                  hashlib.sha256(Path(libraries[0]).read_bytes()).hexdigest(),
          'passed':
              all(check['passed'] for phase in (before, after) for check in phase['hit_checks'])
      }


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('binary', type=Path)
  parser.add_argument('--output', type=Path, required=True)
  parser.add_argument('--inside-session', action='store_true', help=argparse.SUPPRESS)
  args = parser.parse_args()
  if not args.inside_session:
    with tempfile.TemporaryDirectory(prefix='gtk4-overlap-') as directory:
      config = Path(directory) / 'session.conf'
      config.write_text(
          '''<busconfig><type>session</type><listen>unix:tmpdir=/tmp</listen>
<auth>EXTERNAL</auth><policy context="default"><allow send_destination="*"/>
<allow receive_sender="*"/><allow own="*"/></policy></busconfig>'''
      )
      env = os.environ.copy()
      for key in ('GTK_MODULES', 'GTK_PATH', 'AT_SPI_BUS_ADDRESS'):
        env.pop(key, None)
      env.update(
          FLUTTER_TEST_ATSPI_GEOMETRY='1',
          FLUTTER_TEST_ATSPI_OVERLAP='1',
          GTK_A11Y='atspi',
          GDK_BACKEND='x11',
          GDK_SCALE='1',
          GSK_RENDERER='cairo',
          GDK_DISABLE='gl,vulkan',
          GDK_DEBUG='no-portals',
          GIO_USE_VFS='local'
      )
      return subprocess.run([
          'xvfb-run', '-a', 'dbus-run-session', f'--config-file={config}', '--', sys.executable,
          __file__,
          str(args.binary.resolve()), '--output',
          str(args.output.resolve()), '--inside-session'
      ],
                            env=env,
                            timeout=30,
                            check=False).returncode
  with tempfile.TemporaryFile(mode='w+') as output:
    try:
      report = probe(args.binary, output)
    except Exception:
      output.seek(0)
      print(output.read(), file=sys.stderr)
      raise
  report.update(
      binary_sha256=hashlib.sha256(args.binary.read_bytes()).hexdigest(),
      scope='mock engine, real GTK/AT-SPI; private X11 at scale 1'
  )
  args.output.write_text(json.dumps(report, indent=2) + '\n')
  print(f'{"PASS" if report["passed"] else "FAIL"}: independent native hit order; {args.output}')
  return 0 if report['passed'] else 1


if __name__ == '__main__':
  sys.exit(main())
