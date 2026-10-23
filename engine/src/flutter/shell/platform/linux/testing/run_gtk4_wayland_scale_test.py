#!/usr/bin/env python3
# Copyright 2026 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import hashlib
import math
import os
import subprocess
import tempfile
import pathlib
import time
import json
import sys
import threading
import queue
import signal

parser = argparse.ArgumentParser(
    description='GTK4 fractional scaling in a private two-output Wayland compositor'
)
parser.add_argument('binary', type=pathlib.Path)
parser.add_argument('--sized-to-content', action='store_true')
parser.add_argument(
    '--atspi', action='store_true', help='Also query bounds through a private AT-SPI bus'
)
parser.add_argument(
    '--output', type=pathlib.Path, default=pathlib.Path('/tmp/gtk4-wayland-scale.json')
)
args = parser.parse_args()
args.binary = args.binary.resolve()
args.output = args.output.resolve()
args.output.parent.mkdir(parents=True, exist_ok=True)
fixture = pathlib.Path(__file__).resolve().parent / 'fixtures' / 'wayland-scale'
report = {
    'passed': False, 'binary_sha256': hashlib.sha256(args.binary.read_bytes()).hexdigest(),
    'mode': 'native'
}
with tempfile.TemporaryDirectory(prefix='gtk4-fractional-') as temp:
  d = pathlib.Path(temp)
  runtime = d / 'runtime'
  runtime.mkdir(mode=0o700)
  env = {k: v for k, v in os.environ.items() if k in ['PATH', 'HOME', 'LANG', 'LC_ALL']}
  env.update(
      XDG_RUNTIME_DIR=str(runtime),
      WLR_BACKENDS='headless',
      WLR_RENDERER='pixman',
      WLR_LIBINPUT_NO_DEVICES='1',
      WLR_HEADLESS_OUTPUTS='2',
      GDK_BACKEND='wayland',
      GTK_A11Y='atspi' if args.atspi else 'test',
      GSK_RENDERER='cairo',
      GDK_DEBUG='no-portals',
      GIO_USE_VFS='local',
      FLUTTER_LINUX_RENDERER='software',
      FLUTTER_TEST_WAYLAND_SCALE='1'
  )
  if args.sized_to_content:
    env['FLUTTER_TEST_WAYLAND_CONTENT_SIZE'] = '1'
  config = d / 'sway.conf'
  config.write_text(
      'output HEADLESS-1 resolution 2400x1800 scale 1\noutput HEADLESS-1 position 0 0\noutput HEADLESS-2 resolution 2400x1800 scale 2\noutput HEADLESS-2 position 2400 0\nfor_window [title="Flutter fractional scale probe"] floating enable, border none, resize set 1001 603, move position 50 50\n'
  )
  log = open(str(args.output) + '.sway.log', 'w')
  sway = subprocess.Popen(['sway', '--unsupported-gpu', '-c',
                           str(config)],
                          env=env,
                          stdout=log,
                          stderr=log)
  probe = None
  pointer = None
  try:
    for _ in range(100):
      sockets = list(runtime.glob('sway-ipc.*.sock'))
      displays = list(runtime.glob('wayland-*'))
      displays = [x for x in displays if not x.name.endswith('.lock')]
      if sockets and displays:
        break
      if sway.poll() is not None:
        raise RuntimeError('sway failed')
      time.sleep(.1)
    else:
      raise RuntimeError('sway timeout')
    env['SWAYSOCK'] = str(sockets[0])
    env['WAYLAND_DISPLAY'] = displays[0].name

    def command(cmd):
      result = subprocess.run(['swaymsg', '-s', env['SWAYSOCK'], cmd],
                              env=env,
                              text=True,
                              capture_output=True,
                              check=True)
      if not all(x['success'] for x in json.loads(result.stdout)):
        raise RuntimeError(result.stdout)

    command('focus output HEADLESS-1')
    for mode, generated in [('client-header', 'virtual-pointer.h'),
                            ('private-code', 'virtual-pointer.c')]:
      subprocess.run([
          'wayland-scanner', mode,
          str(fixture / 'wlr-virtual-pointer-unstable-v1.xml'),
          str(d / generated)
      ],
                     check=True,
                     capture_output=True)
    subprocess.run([
        'cc', '-I' + str(d),
        str(fixture / 'virtual_pointer.c'),
        str(d / 'virtual-pointer.c'), '-lwayland-client', '-o',
        str(d / 'scale-pointer')
    ],
                   check=True,
                   capture_output=True)
    pointer = subprocess.Popen([str(d / 'scale-pointer')],
                               env=env,
                               stdin=subprocess.PIPE,
                               stdout=subprocess.PIPE,
                               text=True)
    assert pointer.stdout.readline().strip() == 'READY'
    command('input type:pointer map_to_output *')
    bus = d / 'bus.conf'
    bus.write_text(
        f'<busconfig><type>session</type><listen>unix:tmpdir=/tmp</listen><auth>EXTERNAL</auth><policy context="default"><allow send_destination="*"/><allow receive_sender="*"/><allow own="*"/></policy></busconfig>'
    )
    fixture_command = [
        str(args.binary), '--gtest_filter=FlGtk4ScalingTest.ExternalWaylandScaleChanges'
    ]
    if args.atspi:
      fixture_command = [
          '/usr/bin/python3',
          str(pathlib.Path(__file__).with_name('query_gtk4_atspi_bounds.py')), '--serve',
          str(args.binary)
      ]
    probe = subprocess.Popen([
        'dbus-run-session', '--config-file=' + str(bus), '--', *fixture_command
    ],
                             env=env,
                             text=True,
                             stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT,
                             bufsize=1,
                             start_new_session=True)
    lines = queue.Queue()

    def read_lines():
      for line in probe.stdout:
        lines.put(line)
      lines.put(None)

    threading.Thread(target=read_lines, daemon=True).start()
    phases = []
    display_phases = []
    atspi_phases = []
    deadline = time.monotonic() + 100
    with open(str(args.output) + '.log', 'w') as output:
      while time.monotonic() < deadline:
        try:
          line = lines.get(timeout=1)
        except queue.Empty:
          continue
        if line is None:
          break
        output.write(line)
        output.flush()
        if line.startswith('SCALE_PHASE'):
          parts = line.split()
          phase = int(parts[1])
          phases.append(parts[1:])
          if args.atspi:
            client_env = dict(env)
            for process in pathlib.Path('/proc').iterdir():
              if not process.name.isdigit():
                continue
              try:
                if os.getpgid(int(process.name)
                             ) != probe.pid or (process / 'exe').resolve() != args.binary:
                  continue
                entries = (process / 'environ').read_bytes().split(b'\0')
                address = next(
                    entry.split(b'=', 1)[1].decode()
                    for entry in entries
                    if entry.startswith(b'DBUS_SESSION_BUS_ADDRESS=')
                )
                client_env['DBUS_SESSION_BUS_ADDRESS'] = address
                break
              except OSError:
                continue
            assert 'DBUS_SESSION_BUS_ADDRESS' in client_env
            client = subprocess.run([
                '/usr/bin/python3',
                str(pathlib.Path(__file__).with_name('query_gtk4_atspi_bounds.py'))
            ],
                                    env=client_env,
                                    text=True,
                                    capture_output=True,
                                    check=False,
                                    timeout=4)
            if client.returncode:
              raise RuntimeError(client.stderr + client.stdout)
            actual = json.loads(client.stdout)
            scale = float(parts[2])
            expected = [
                math.floor(125 / scale),
                math.floor(75 / scale),
                math.ceil(375 / scale) - math.floor(125 / scale),
                math.ceil(225 / scale) - math.floor(75 / scale)
            ]
            assert actual == expected, (phase, actual, expected)
            atspi_phases.append({'phase': phase, 'bounds': actual})
          tree = json.loads(
              subprocess.check_output(['swaymsg', '-s', env['SWAYSOCK'], '-t', 'get_tree'],
                                      env=env,
                                      text=True)
          )

          def find(node):
            if node.get('name') == 'Flutter fractional scale probe':
              return node
            for child in node.get('nodes', []) + node.get('floating_nodes', []):
              found = find(child)
              if found:
                return found

          rect = find(tree)['rect']
          output.write('RECT ' + json.dumps(rect) + '\n')
          output.flush()
          command(f"seat seat0 cursor set {rect['x']+100} {rect['y']+80}")
          outputs = json.loads(
              subprocess.check_output(['swaymsg', '-s', env['SWAYSOCK'], '-t', 'get_outputs'],
                                      env=env,
                                      text=True)
          )
          extent_x = max(o['rect']['x'] + o['rect']['width'] for o in outputs)
          extent_y = max(o['rect']['y'] + o['rect']['height'] for o in outputs)
          pointer.stdin.write(
              f"click {rect['x']+100} {rect['y']+80} {extent_x} {extent_y}\nscroll\n"
          )
          pointer.stdin.flush()
        elif line.startswith('DISPLAY_PHASE'):
          display_phases.append(line.split()[1:])
        elif line.startswith('POINTER_PHASE'):
          phase = int(line.split()[1])
          if phase < 5:
            command('output HEADLESS-1 scale ' + str([1.25, 1.5, 1.75, 1.5, 1][phase]))
          elif phase == 5:
            command('[title="Flutter fractional scale probe"] move container to output HEADLESS-2')
            command('[title="Flutter fractional scale probe"] move position 50 50')
          elif phase == 6:
            command('[title="Flutter fractional scale probe"] move container to output HEADLESS-1')
            command('[title="Flutter fractional scale probe"] move position 50 50')
          elif phase == 7:
            command('[title="Flutter fractional scale probe"] resize set 997 599')
            command('output HEADLESS-1 scale 1.5')
          elif phase == 8:
            command('[title="Flutter fractional scale probe"] resize set 991 587')
          elif phase == 9:
            command('output HEADLESS-2 scale 1.5')
            command('[title="Flutter fractional scale probe"] move container to output HEADLESS-2')
            command('[title="Flutter fractional scale probe"] move position 50 50')
          elif phase == 10:
            command('[title="Flutter fractional scale probe"] move container to output HEADLESS-1')
            command('[title="Flutter fractional scale probe"] move position 50 50')
      probe.wait(timeout=5)
    report.update(
        exit_code=probe.returncode,
        phases=phases,
        display_phases=display_phases,
        atspi_phases=atspi_phases,
        passed=probe.returncode == 0 and len(phases) == 12
    )
    args.output.write_text(json.dumps(report, indent=2) + '\n')
    print(f"{'PASS' if report['passed'] else 'FAIL'}: {args.output}")
    sys.exit(0 if report['passed'] else 1)
  finally:
    if probe and probe.poll() is None:
      os.killpg(probe.pid, signal.SIGTERM)
      probe.wait(timeout=5)
    if pointer:
      pointer.stdin.close()
      pointer.wait(timeout=5)
    sway.terminate()
    sway.wait(timeout=5)
    log.close()
