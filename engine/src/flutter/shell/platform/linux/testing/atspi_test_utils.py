# Copyright 2026 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Process and private accessibility-bus support for Linux integration tests."""

import contextlib
import os
from pathlib import Path
import shutil
import subprocess
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


@contextlib.contextmanager
def accessibility_bus(output):
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

  # Private sessions need not have systemd user-service activation available.
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
      yield Atspi
