#!/usr/bin/env python3
# Copyright 2026 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Run the GTK4 native action fixture through an isolated AT-SPI client.

Usage: python3 run_gtk4_atspi_action_test.py /path/to/flutter_linux_gtk4_unittests

Requires GTK 4.10+, PyGObject with Atspi introspection, Xvfb, dbus-run-session,
and the AT-SPI bus launcher/registry. The binary must enable native GTK4 a11y.
"""

import argparse
import contextlib
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time


def service_path(name):
  found = shutil.which(name)
  if found:
    return found
  for directory in ('/usr/libexec', '/usr/lib/at-spi2-core'):
    candidate = Path(directory) / name
    if candidate.is_file() and os.access(candidate, os.X_OK):
      return str(candidate)
  raise RuntimeError(f'Missing AT-SPI service: {name}')


@contextlib.contextmanager
def process(command, output):
  child = subprocess.Popen(command, stdout=output, stderr=subprocess.STDOUT)
  try:
    yield child
  finally:
    if child.poll() is None:
      child.terminate()
    try:
      child.wait(timeout=5)
    except subprocess.TimeoutExpired:
      child.kill()
      child.wait()


def wait_until(predicate, description, seconds=10):
  deadline = time.monotonic() + seconds
  while time.monotonic() < deadline:
    result = predicate()
    if result:
      return result
    time.sleep(0.05)
  raise RuntimeError(f'Timed out waiting for {description}')


def run_fixture(binary, output, check_focus=False):
  import gi
  gi.require_version('Atspi', '2.0')
  from gi.repository import Atspi, Gio, GLib

  session = Gio.bus_get_sync(Gio.BusType.SESSION, None)

  def owns(connection, name):
    return connection.call_sync(
        'org.freedesktop.DBus', '/org/freedesktop/DBus', 'org.freedesktop.DBus', 'NameHasOwner',
        GLib.Variant('(s)', (name,)), GLib.VariantType.new('(b)'), Gio.DBusCallFlags.NONE, 1000,
        None
    ).unpack()[0]

  # Start services explicitly: a private session need not have a systemd user
  # manager to satisfy the host's D-Bus activation configuration.
  with process([service_path('at-spi-bus-launcher')], output):
    wait_until(lambda: owns(session, 'org.a11y.Bus'), 'accessibility bus')
    address = session.call_sync(
        'org.a11y.Bus', '/org/a11y/bus', 'org.a11y.Bus', 'GetAddress', None,
        GLib.VariantType.new('(s)'), Gio.DBusCallFlags.NONE, 5000, None
    ).unpack()[0]
    bus = Gio.DBusConnection.new_for_address_sync(
        address, Gio.DBusConnectionFlags.AUTHENTICATION_CLIENT
        | Gio.DBusConnectionFlags.MESSAGE_BUS_CONNECTION, None, None
    )
    with process([service_path('at-spi2-registryd')], output):
      wait_until(lambda: owns(bus, 'org.a11y.atspi.Registry'), 'AT-SPI registry')
      Atspi.set_timeout(2000, 5000)
      command = [binary, '--gtest_filter=FlViewGtk4AccessibilityTest.ExternalAtspiActivation']
      with process(command, output) as fixture:

        def find_fixture():
          if fixture.poll() is not None:
            raise RuntimeError('Engine fixture exited before activation')
          desktop = Atspi.get_desktop(0)
          for index in range(desktop.get_child_count()):
            app = desktop.get_child_at_index(index)
            if app and app.get_process_id() == fixture.pid:
              pending = [app]
              # Bound traversal even if a broken exporter returns cycles.
              for _ in range(100):
                if not pending:
                  break
                node = pending.pop()
                if node.get_name() == 'Flutter AT-SPI activation fixture':
                  return node
                pending.extend(
                    filter(
                        None, (node.get_child_at_index(i) for i in range(node.get_child_count()))
                    )
                )
          return None

        node = wait_until(find_fixture, 'Flutter native accessible node')
        action = node.get_action_iface()
        if action is None:
          raise RuntimeError('Native node does not export AT-SPI Action')
        names = [action.get_action_name(i) for i in range(action.get_n_actions())]
        if names != ['flutter.tap']:
          raise RuntimeError(f'Unexpected native actions: {names}')
        if check_focus:
          focus_events = []

          def on_focus(event, *_):
            if (event.source.get_process_id() == fixture.pid and
                event.source.get_name() == 'Flutter AT-SPI activation fixture'):
              focus_events.append(bool(event.detail1))

          listener = Atspi.EventListener.new(on_focus, None)
          listener.register('object:state-changed:focused')
          try:
            for expected in (True, False):
              if not action.do_action(0):
                raise RuntimeError('AT-SPI rejected focus-transition trigger')

              def received_focus():
                context = GLib.MainContext.default()
                while context.pending():
                  context.iteration(False)
                return focus_events and focus_events[-1] == expected

              wait_until(received_focus, f'focused={expected} notification', seconds=5)
              node.clear_cache()
              if node.get_state_set().contains(Atspi.StateType.FOCUSED) != expected:
                raise RuntimeError('Focus event disagrees with exported state')
            if focus_events != [True, False]:
              raise RuntimeError(f'Unexpected focus notifications: {focus_events}')
          finally:
            listener.deregister('object:state-changed:focused')
        if not action.do_action(0):
          raise RuntimeError('AT-SPI rejected flutter.tap')
        if fixture.wait(timeout=10) != 0:
          raise RuntimeError('Engine did not receive the expected semantics action')
        print('PASS: AT-SPI flutter.tap reached the Flutter embedder')
        if check_focus:
          print('PASS: AT-SPI observed focus gain and loss without duplicate events')


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('binary', type=lambda value: str(Path(value).resolve()))
  parser.add_argument('--check-focus', action='store_true', help='Verify focus events (GTK 4.18+)')
  parser.add_argument('--isolated-session', action='store_true', help=argparse.SUPPRESS)
  args = parser.parse_args()
  if not Path(args.binary).is_file():
    parser.error(f'Unit test binary not found: {args.binary}')
  if not args.isolated_session:
    environment = os.environ.copy()
    for key in ('GTK_MODULES', 'GTK_PATH', 'AT_SPI_BUS_ADDRESS'):
      environment.pop(key, None)
    environment.update(
        GTK_A11Y='atspi',
        GDK_BACKEND='x11',
        GDK_DISABLE='gl,vulkan',
        GSK_RENDERER='cairo',
        GIO_USE_VFS='local',
        FLUTTER_TEST_ATSPI_ACTION='1',
        FLUTTER_TEST_ATSPI_FOCUS='1' if args.check_focus else '0'
    )
    return subprocess.run([
        'xvfb-run', '-a', 'dbus-run-session', '--', sys.executable,
        str(Path(__file__).resolve()), '--isolated-session', args.binary,
        *(['--check-focus'] if args.check_focus else [])
    ],
                          env=environment,
                          timeout=45,
                          check=False).returncode
  with tempfile.TemporaryFile(mode='w+') as output:
    try:
      run_fixture(args.binary, output, args.check_focus)
    finally:
      output.seek(0)
      print(output.read(), end='')
  return 0


if __name__ == '__main__':
  try:
    sys.exit(main())
  except (RuntimeError, OSError, subprocess.TimeoutExpired) as error:
    print(f'FAIL: {error}', file=sys.stderr)
    sys.exit(1)
