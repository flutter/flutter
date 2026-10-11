#!/usr/bin/env python3
# Copyright 2026 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Compare identical Flutter semantics exported by GTK3 and GTK4 over AT-SPI.

Requires both Linux unit-test binaries, GTK4 native accessibility (4.14+ for
text comparisons), PyGObject/Atspi, Xvfb and the AT-SPI services. Differences
are reported in JSON; --strict also fails when any differences remain.
"""

import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

from atspi_test_utils import accessibility_bus, process, wait_until


def normalized_action(name):
  return name.removeprefix('flutter.').replace('-', '').lower()


def differences(left, right, path=''):
  if isinstance(left, dict) and isinstance(right, dict):
    result = []
    for key in sorted(left.keys() | right.keys()):
      if key not in left or key not in right:
        result.append({
            'path': f'{path}/{key}', 'gtk3': left.get(key), 'gtk4': right.get(key),
            'missing': 'gtk3' if key not in left else 'gtk4'
        })
      else:
        result.extend(differences(left[key], right[key], f'{path}/{key}'))
    return result
  return [] if left == right else [{'path': path, 'gtk3': left, 'gtk4': right}]


def find_root(Atspi, fixture):
  if fixture.poll() is not None:
    raise RuntimeError('Parity fixture exited before its tree was exported')
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
      if node.get_name() == 'Parity root':
        return node
      pending.extend(
          child for i in range(node.get_child_count())
          if (child := node.get_child_at_index(i)) is not None
      )
  return None


def descendants(root):
  pending = [root]
  nodes = {}
  for _ in range(100):
    if not pending:
      return nodes
    node = pending.pop()
    name = node.get_name()
    if name in nodes:
      raise RuntimeError(f'Duplicate name or cycle in fixture tree: {name}')
    nodes[name] = node
    pending.extend(
        child for i in range(node.get_child_count())
        if (child := node.get_child_at_index(i)) is not None
    )
  raise RuntimeError('Parity tree exceeded traversal limit')


def snapshot(Atspi, nodes):
  result = {}
  for name, node in sorted(nodes.items()):
    node.clear_cache()
    states = node.get_state_set()
    if states.contains(Atspi.StateType.DEFUNCT):
      raise RuntimeError(f'Fixture contains a defunct node: {name}')
    record = {
        'role': node.get_role_name(),
        'interfaces': sorted(node.get_interfaces()),
        'states': sorted(state.value_nick for state in states.get_states()),
        'children': [node.get_child_at_index(i).get_name() for i in range(node.get_child_count())],
        'actions': [],
    }
    action = node.get_action_iface()
    if action is not None:
      record['actions'] = sorted(
          normalized_action(action.get_action_name(i)) for i in range(action.get_n_actions())
      )
    text = node.get_text_iface()
    if text is not None:
      contents = Atspi.Text.get_text(text, 0, -1)
      record['text'] = {
          'count':
              text.get_character_count(),
          'caret':
              text.get_caret_offset(),
          'selections': [[selection.start_offset, selection.end_offset]
                         for i in range(text.get_n_selections())
                         if (selection := Atspi.Text.get_selection(text, i)) is not None],
      }
      if name == 'Password':
        # Record disclosure as a boolean, never include protected text in logs.
        record['text']['exposes_fixture_secret'] = contents == 'fixture-private-value'
      else:
        record['text']['contents'] = contents
    result[name] = record
  return result


def invoke(node, expected):
  action = node.get_action_iface()
  if action is None:
    raise RuntimeError(f'{node.get_name()} has no Action interface')
  for index in range(action.get_n_actions()):
    if normalized_action(action.get_action_name(index)) == expected:
      if action.do_action(index):
        return
      break
  raise RuntimeError(f'{node.get_name()} rejected {expected}')


def run_backend(Atspi, binary, output):
  command = [binary, '--gtest_filter=FlAccessibilityParityTest.ExternalAtspiParity']
  with process(command, output) as fixture:
    root = wait_until(lambda: find_root(Atspi, fixture), 'parity root')
    nodes = descendants(root)
    expected = {
        'Parity root', 'Activate', 'Checked', 'Editor', 'Password', 'Slider', 'Scroll region',
        'Nested group', 'Finish comparison', 'Unicode'
    }
    if nodes.keys() != expected:
      raise RuntimeError(f'Incomplete parity tree: {sorted(nodes)}')
    before = snapshot(Atspi, nodes)
    if 'checked' not in before['Checked']['states']:
      raise RuntimeError('Initial checkbox does not expose checked state')
    if before['Editor'].get('text', {}).get('contents') != 'Hello world':
      raise RuntimeError('Editor contents were not exported')
    invoke(nodes['Activate'], 'tap')

    def unchecked():
      nodes['Checked'].clear_cache()
      return not nodes['Checked'].get_state_set().contains(Atspi.StateType.CHECKED)

    wait_until(unchecked, 'partial checkbox update')
    invoke(nodes['Slider'], 'increase')
    invoke(nodes['Scroll region'], 'scrolldown')
    after = snapshot(Atspi, nodes)
    invoke(nodes['Finish comparison'], 'tap')
    if fixture.wait(timeout=10) != 0:
      raise RuntimeError('Fixture did not receive exactly the expected actions')
    return {'before': before, 'after': after}


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('--gtk3', required=True, type=lambda value: str(Path(value).resolve()))
  parser.add_argument('--gtk4', required=True, type=lambda value: str(Path(value).resolve()))
  parser.add_argument('--output', type=Path, help='Write comparison JSON to this path')
  parser.add_argument('--strict', action='store_true', help='Fail on any remaining difference')
  parser.add_argument('--isolated-session', action='store_true', help=argparse.SUPPRESS)
  args = parser.parse_args()
  for binary in (args.gtk3, args.gtk4):
    if not Path(binary).is_file():
      parser.error(f'Unit test binary not found: {binary}')
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
        NO_AT_BRIDGE='0',
        FLUTTER_TEST_ATSPI_PARITY='1',
        LC_ALL='C.UTF-8'
    )
    command = [
        'xvfb-run', '-a', 'dbus-run-session', '--', sys.executable,
        str(Path(__file__).resolve()), '--isolated-session', '--gtk3', args.gtk3, '--gtk4',
        args.gtk4
    ]
    if args.output:
      command.extend(['--output', str(args.output.resolve())])
    if args.strict:
      command.append('--strict')
    return subprocess.run(command, env=environment, timeout=60, check=False).returncode
  with tempfile.TemporaryFile(mode='w+') as output:
    try:
      with accessibility_bus(output) as Atspi:
        gtk3 = run_backend(Atspi, args.gtk3, output)
        gtk4 = run_backend(Atspi, args.gtk4, output)
      output.seek(0)
      runtimes = [
          json.loads(line.removeprefix('PARITY_RUNTIME '))
          for line in output
          if line.startswith('PARITY_RUNTIME ')
      ]
      if len(runtimes) != 2:
        raise RuntimeError('Fixtures did not identify their loaded GTK/GLib versions')
      report = {
          'environment': {'gtk3': runtimes[0], 'gtk4': runtimes[1], 'display': 'x11'}, 'gtk3': gtk3,
          'gtk4': gtk4, 'differences': differences(gtk3, gtk4)
      }
      encoded = json.dumps(report, indent=2, ensure_ascii=True) + '\n'
      if args.output:
        args.output.write_text(encoded)
        print(
            f'PASS: common action and partial-update checks; {len(report["differences"])} differences'
        )
        print(f'Report: {args.output}')
      else:
        print(encoded, end='')
      return 1 if args.strict and report['differences'] else 0
    except Exception:
      output.seek(0)
      print(output.read(), file=sys.stderr, end='')
      raise


if __name__ == '__main__':
  try:
    sys.exit(main())
  except (RuntimeError, OSError, subprocess.TimeoutExpired) as error:
    print(f'FAIL: {error}', file=sys.stderr)
    sys.exit(1)
