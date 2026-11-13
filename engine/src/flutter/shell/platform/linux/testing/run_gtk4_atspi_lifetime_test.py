#!/usr/bin/env python3
# Copyright 2026 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Retain native objects across reparenting and destruction of a second view."""

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
    from gi.repository import GLib
    with process([str(binary), '--gtest_filter=FlViewGtk4AccessibilityTest.ExternalAtspiLifetime'],
                 output) as fixture:

      def named(name):
        if fixture.poll() is not None:
          raise RuntimeError('Lifetime fixture exited before verification')
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
            node.clear_cache()
            if node.get_name() == name:
              return node
            pending.extend(
                child for i in range(node.get_child_count())
                if (child := node.get_child_at_index(i)) is not None
            )
        return None

      root = wait_until(lambda: named('Lifetime root'), 'target view')
      parent = wait_until(lambda: named('Lifetime old parent'), 'old parent')
      child = wait_until(lambda: named('Lifetime child'), 'retained child')
      controller = wait_until(lambda: named('Lifetime controller'), 'control view')
      # Query states and geometry to exercise realized native contexts and caches.
      child.get_state_set()
      child.get_component_iface().get_extents(Atspi.CoordType.WINDOW)
      old_actions = child.get_action_iface()
      events = []

      def on_event(event, *_):
        if event.source in (root, parent, child, controller):
          events.append({'type': event.type, 'detail1': event.detail1})

      listener = Atspi.EventListener.new(on_event, None)
      event_types = ['object:children-changed', 'object:state-changed', 'object:text-changed']
      for event_type in event_types:
        listener.register(event_type)
      libraries = sorted({
          line.split()[-1]
          for line in Path(f'/proc/{fixture.pid}/maps').read_text().splitlines()
          if '/libgtk-4.so.' in line
      })

      def tap(node):
        actions = node.get_action_iface()
        if actions is None or not actions.do_action(0):
          raise RuntimeError('Native lifetime control action rejected')

      def drain():
        context = GLib.MainContext.default()
        while context.pending():
          context.iteration(False)

      try:
        tap(controller)

        def moved():
          drain()
          child.clear_cache()
          root.clear_cache()
          return child.get_parent() == root and root.get_child_count() == 1

        wait_until(moved, 'root-only reparenting')
        if named('Lifetime child') != child or named('Lifetime old parent') is not None:
          raise RuntimeError('Reparenting replaced the child or retained the removed parent')
        # The retained, moved object still dispatches to its original view/id.
        tap(child)
        tap(controller)
        wait_until(lambda: named('Lifetime destroyed'), 'target window/view disposal')
        drain()
        if named('Lifetime child') is not None or named('Lifetime root') is not None:
          raise RuntimeError('Destroyed view remains in native traversal')
        stale = []
        for name, node in [('root', root), ('old_parent', parent), ('child', child)]:
          node.clear_cache()
          try:
            state = node.get_state_set()
            defunct = state is not None and state.contains(Atspi.StateType.DEFUNCT)
            parent_query = node.get_parent()
            children = node.get_child_count()
            stale.append({
                'node': name, 'defunct': defunct, 'has_parent': parent_query is not None,
                'children': children
            })
            if not defunct or parent_query is not None or children > 0:
              raise RuntimeError(f'Unsafe detached native object: {stale[-1]}')
          except GLib.Error as error:
            # Unregistered native objects may reject queries rather than export
            # an empty defunct object. The live controller must remain usable.
            message = str(error)
            if not any(
                reason in message
                for reason in ('does not exist', 'no longer exists', 'defunct', 'UnknownObject')):
              raise
            stale.append({'node': name, 'query_error': message})
        try:
          old_actions.do_action(0)
        except GLib.Error:
          pass
        drain()
        if not any(event['type'] == 'object:state-changed:defunct' for event in events):
          raise RuntimeError('Listener did not receive a retained-object defunct event')
        # The fixture checks that the stale action dispatched no target call.
        tap(controller)
        if fixture.wait(timeout=10) != 0:
          raise RuntimeError('Lifetime fixture routing/teardown assertions failed')
        return {
            'reparented_identity': True, 'target_view_destroyed': True, 'retained_queries': stale,
            'stale_action_no_dispatch': True, 'controller_taps': 3, 'moved_child_taps': 1,
            'event_listener_active_during_transitions': True, 'events': events,
            'gtk_libraries': libraries, 'gtk_library_sha256': [
                hashlib.sha256(Path(path).read_bytes()).hexdigest() for path in libraries
            ], 'passed': True
        }
      finally:
        for event_type in event_types:
          listener.deregister(event_type)


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('binary', type=Path)
  parser.add_argument('--output', type=Path, required=True)
  parser.add_argument('--inside-session', action='store_true', help=argparse.SUPPRESS)
  args = parser.parse_args()
  if not args.inside_session:
    with tempfile.TemporaryDirectory(prefix='gtk4-lifetime-') as directory:
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
          FLUTTER_TEST_ATSPI_LIFETIME='1',
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
                            timeout=40,
                            check=False).returncode
  with tempfile.TemporaryFile(mode='w+') as output:
    try:
      report = probe(args.binary, output)
    except Exception:
      output.seek(0)
      print(output.read(), file=sys.stderr)
      raise
  report['binary_sha256'] = hashlib.sha256(args.binary.read_bytes()).hexdigest()
  args.output.write_text(json.dumps(report, indent=2) + '\n')
  print(f'PASS: native reparenting and retained references after view destruction; {args.output}')
  return 0


if __name__ == '__main__':
  sys.exit(main())
