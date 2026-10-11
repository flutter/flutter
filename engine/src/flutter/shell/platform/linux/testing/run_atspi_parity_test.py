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
import hashlib
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


def protected_value_checks(Atspi, node, secret):
  """Query exported value surfaces; retain only disclosure booleans."""
  node.clear_cache()
  surfaces = {
      'name': node.get_name(),
      'description': node.get_description(),
      'attributes': node.get_attributes(),
  }
  text = node.get_text_iface()
  text_record = None
  if text is not None:
    surfaces['text'] = Atspi.Text.get_text(text, 0, -1)
    text_record = {
        'count':
            text.get_character_count(),
        'caret':
            text.get_caret_offset(),
        'masked':
            set(surfaces['text']) <= {'*'},
        'selections': [[selection.start_offset, selection.end_offset]
                       for i in range(text.get_n_selections())
                       if (selection := Atspi.Text.get_selection(text, i)) is not None],
    }
    surfaces['text_default_attributes'] = text.get_default_attributes()
    if text.get_character_count() > 0:
      surfaces['text_attributes'] = text.get_text_attributes(0)
    for index in range(text.get_n_selections()):
      selection = Atspi.Text.get_selection(text, index)
      if selection is not None:
        surfaces[f'selected_text_{index}'] = Atspi.Text.get_text(
            text, selection.start_offset, selection.end_offset
        )
  value = node.get_value_iface()
  if value is not None:
    surfaces['value_text'] = value.get_text()
  action = node.get_action_iface()
  actions = [] if action is None else [
      normalized_action(action.get_action_name(i)) for i in range(action.get_n_actions())
  ]
  return {
      'disclosure': {name: secret in str(value) for name, value in surfaces.items()},
      'copy_advertised': 'copy' in actions,
      'cut_advertised': 'cut' in actions,
      'paste_advertised': 'paste' in actions,
      'role': node.get_role_name(),
      'text': text_record,
  }


def require_protected(checks):
  if any(checks['disclosure'].values()) or checks['copy_advertised'] or checks['cut_advertised']:
    raise RuntimeError('GTK4 exposed a protected value or advertised copy/cut')
  if not checks['paste_advertised']:
    raise RuntimeError('GTK4 lost the permitted paste action on protected input')
  if checks['text'] is None or not checks['text']['masked']:
    raise RuntimeError('GTK4 did not expose masked protected Text')


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


def run_backend(Atspi, binary, output, require_password_privacy=False):
  from gi.repository import GLib
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
    password = protected_value_checks(Atspi, nodes['Password'], 'fixture-private-value')
    if require_password_privacy:
      require_protected(password)
    # No node in this fixture has selected or expanded semantics, including
    # explicit false. Their absence must not advertise these capabilities.
    for name, record in before.items():
      if {'selectable', 'expandable'} & set(record['states']):
        raise RuntimeError(f'{name} advertises absent selection/expansion semantics')
    if 'checked' not in before['Checked']['states']:
      raise RuntimeError('Initial checkbox does not expose checked state')
    if before['Editor'].get('text', {}).get('contents') != 'Hello world':
      raise RuntimeError('Editor contents were not exported')
    invoke(nodes['Activate'], 'tap')

    def unchecked():
      nodes['Checked'].clear_cache()
      return not nodes['Checked'].get_state_set().contains(Atspi.StateType.CHECKED)

    wait_until(unchecked, 'partial checkbox update')
    text_events = []

    def on_protected_text(event, unused):
      if event.source == nodes['Editor']:
        # Event payloads may contain removed text. Never persist those strings.
        payload = str(event.any_data)
        text_events.append({
            'type': event.type,
            'start': event.detail1,
            'length': event.detail2,
            'exposes_value': 'Hello world' in payload,
            'payload_redacted': set(payload) <= {'*'},
            'payload_length': len(payload),
        })

    listener = Atspi.EventListener.new(on_protected_text, None)
    listener.register('object:text-changed')
    try:
      invoke(nodes['Slider'], 'increase')
      if require_password_privacy:

        def editor_protected():
          context = GLib.MainContext.default()
          while context.pending():
            context.iteration(False)
          checks = protected_value_checks(Atspi, nodes['Editor'], 'Hello world')
          if (len(text_events) < 2 or any(checks['disclosure'].values()) or
              checks['copy_advertised'] or checks['cut_advertised']):
            return None
          return checks

        protected_editor = wait_until(editor_protected, 'existing editor becomes protected')
        require_protected(protected_editor)
        if any(event['exposes_value'] or not event['payload_redacted'] for event in text_events):
          raise RuntimeError('GTK4 disclosed protected contents in a text-change event')
        if [(event['type'], event['start'], event['length'], event['payload_length'])
            for event in text_events] != [('object:text-changed:delete', 0, 11, 11),
                                          ('object:text-changed:insert', 0, 11, 11)]:
          raise RuntimeError('GTK4 did not preserve the protected deletion notification range')
      else:
        # GTK3 is a baseline, not the privacy oracle for synthetic clear input.
        protected_editor = protected_value_checks(Atspi, nodes['Editor'], 'Hello world')
    finally:
      listener.deregister('object:text-changed')
    protected_unicode = protected_value_checks(Atspi, nodes['Unicode'], 'A\U0001f600 caf\u00e9')
    protected_selection_supported = False
    if require_password_privacy:
      require_protected(protected_unicode)
      if protected_editor['text'] != {'count': 11, 'caret': 5, 'masked': True, 'selections':
          [[2, 5]]} or protected_unicode['text'] != {'count': 7, 'caret': 2, 'masked': True,
                                                     'selections': [[1, 2]]}:
        raise RuntimeError('GTK4 lost protected length/caret/selection or Unicode offsets')
      # Custom nodes need not expose toolkit metadata. Use the loaded runtime
      # printed by this fixture, without seeking its shared output descriptor.
      runtime_lines = os.pread(output.fileno(),
                               os.fstat(output.fileno()).st_size, 0).decode().splitlines()
      runtimes = [
          json.loads(line.removeprefix('PARITY_RUNTIME '))
          for line in runtime_lines
          if line.startswith('PARITY_RUNTIME ')
      ]
      if not runtimes:
        raise RuntimeError('Fixture did not identify its runtime for protected selection')
      version = tuple(int(part) for part in runtimes[-1]['gtk'].split('.')[:2])
      protected_selection_supported = version >= (4, 22)
      if protected_selection_supported:
        text = nodes['Unicode'].get_text_iface()
        if not Atspi.Text.set_selection(text, 0, 1, 2):
          raise RuntimeError('GTK4 rejected protected Unicode selection')
    invoke(nodes['Scroll region'], 'scrolldown')

    def editor_restored():
      nodes['Editor'].clear_cache()
      text = nodes['Editor'].get_text_iface()
      return text is not None and Atspi.Text.get_text(text, 0, -1) == 'Hello world'

    wait_until(editor_restored, 'editor readable again')
    after = snapshot(Atspi, nodes)
    invoke(nodes['Finish comparison'], 'tap')
    if fixture.wait(timeout=10) != 0:
      raise RuntimeError('Fixture did not receive exactly the expected actions')
    return {
        'before': before,
        'after': after,
        'password_checks': {
            'initial': password,
            'existing_editor_protected': protected_editor,
            'unicode_protected': protected_unicode,
            'unicode_selection_supported': protected_selection_supported,
            'protection_text_events': text_events,
            'editor_restored': True,
        },
        'action_checks': {'correct_view_and_node': True, 'exactly_once': True},
    }


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
        gtk4 = run_backend(Atspi, args.gtk4, output, require_password_privacy=True)
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
      # Identify the tested artifacts even when the checkout has local edits.
      source = Path(__file__).resolve().parent.parent
      files = {
          'gtk3_binary': Path(args.gtk3),
          'gtk4_binary': Path(args.gtk4),
          'collector': Path(__file__),
          'fixture': source / 'fl_accessibility_parity_test.cc',
          'gtk4_adapter': source / 'fl_view_gtk4_accessibility.cc',
      }
      report['environment']['sha256'] = {
          name: hashlib.sha256(path.read_bytes()).hexdigest() for name, path in files.items()
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
