#!/usr/bin/env python3
# Copyright 2026 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import hashlib
import json
import os
import pathlib
import signal
import subprocess
import tempfile
import time

parser = argparse.ArgumentParser(
    description='Real-engine fractional Wayland DPR and gradient pixels'
)
parser.add_argument('binary', type=pathlib.Path)
parser.add_argument('--engine-dir', type=pathlib.Path, required=True)
parser.add_argument(
    '--output', type=pathlib.Path, default=pathlib.Path('/tmp/gtk4-wayland-render-scale.json')
)
parser.add_argument('--impeller', choices=('true', 'false'), default='true')
parser.add_argument('--gsk-renderer', choices=('cairo', 'gl', 'vulkan'), default='cairo')
args = parser.parse_args()
args.binary = args.binary.resolve()
args.engine_dir = args.engine_dir.resolve()
args.output = args.output.resolve()
args.output.parent.mkdir(parents=True, exist_ok=True)
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
      GTK_A11Y='test',
      GSK_RENDERER=args.gsk_renderer,
      GDK_DEBUG='no-portals',
      GIO_USE_VFS='local',
      FLUTTER_LINUX_RENDERER='software',
      FLUTTER_TEST_WAYLAND_SCALE='1'
  )
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
    env.pop('FLUTTER_TEST_WAYLAND_SCALE', None)
    env.pop('FLUTTER_LINUX_RENDERER', None)
    captures = d / 'captures'
    captures.mkdir()
    env['GRADIENT_PROBE_OUTPUT'] = str(captures)
    env['FLUTTER_ENGINE_SWITCHES'] = '1'
    env['FLUTTER_ENGINE_SWITCH_1'] = 'enable-impeller=' + args.impeller
    env['LD_LIBRARY_PATH'] = str(args.engine_dir)
    env['GRADIENT_PROBE_PHYSICAL'] = '1'
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
    bus = d / 'bus.conf'
    bus.write_text(
        '<busconfig><type>session</type><listen>unix:tmpdir=/tmp</listen><auth>EXTERNAL</auth><policy context="default"><allow send_destination="*"/><allow receive_sender="*"/><allow own="*"/></policy></busconfig>'
    )
    app_log = open(str(args.output) + '.log', 'w')
    probe = subprocess.Popen([
        'dbus-run-session', '--config-file=' + str(bus), '--',
        str(args.binary)
    ],
                             env=env,
                             stdout=app_log,
                             stderr=app_log,
                             start_new_session=True)
    from PIL import Image
    results = []
    previous_index = -1
    first_display_id = None
    second_display_id = None
    for phase, scale in enumerate([1, 1.25, 1.5, 1.75, 1.5, 1, 2, 1, 1.5, 1.5, 1.5, 1.5]):
      logical_width = 997 if phase == 8 else 991 if phase >= 9 else 1001
      logical_height = 599 if phase == 8 else 587 if phase >= 9 else 603
      expected = (int(logical_width * scale + .5), int(logical_height * scale + .5))
      deadline = time.monotonic() + 15
      while time.monotonic() < deadline:
        try:
          data = json.loads((captures / 'latest.json').read_text())
          if data['dpr'] == scale and data['index'] > previous_index and (
              data['physical_width'], data['physical_height']) == expected and (
                  phase != 10 or data['display_id']
                  == second_display_id) and (phase != 11 or data['display_id'] == first_display_id):
            break
        except (FileNotFoundError, json.JSONDecodeError):
          pass
        if probe.poll() is not None:
          raise RuntimeError('app exited')
        time.sleep(.05)
      else:
        raise RuntimeError(f'missing rendered scale {scale}')
      previous_index = data['index']
      if phase == 0:
        first_display_id = data['display_id']
      if phase == 6:
        second_display_id = data['display_id']
        assert first_display_id != second_display_id
      if phase == 10:
        assert data['display_id'] == second_display_id
      if phase == 11:
        assert data['display_id'] == first_display_id
      assert (data['physical_width'], data['physical_height']) == expected, data
      assert abs(data['width'] - expected[0]) <= 1 and abs(data['height'] - expected[1]) <= 1, data
      im = Image.frombytes(
          'RGBA', (data['width'], data['height']),
          pathlib.Path(data['path']).read_bytes()
      )
      samples = []
      for x, y, axis in [(120, 120, 'vertical'), (900, 120, 'horizontal')]:
        px = int(x * scale)
        py = int((y - data['scroll_offset']) * scale)
        actual = im.getpixel((px, py))
        t = (((py + .5) / scale + data['scroll_offset'] - 20) / 200 if axis == 'vertical' else
             ((px + .5) / scale - 700) / 400)
        target = (round(255 * (1 - t)), 0, round(255 * t), 255)
        error = max(abs(a - b) for a, b in zip(actual, target))
        assert error <= 4, (scale, axis, actual, target)
        samples.append({'axis': axis, 'actual': actual, 'expected': target, 'error': error})
      results.append({
          'phase': phase, 'scale': scale, 'width': data['width'], 'height': data['height'],
          'physical_size': expected, 'display_id': data['display_id'],
          'display_dpr': data['display_dpr'],
          'display_size': [data['display_width'], data['display_height']], 'samples': samples
      })
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
    assert len(results) == 12
    # Verify that the requested engine was actually mapped by the app process.
    mapped = set()
    for process in pathlib.Path('/proc').iterdir():
      if not process.name.isdigit():
        continue
      try:
        if os.getpgid(int(process.name)) != probe.pid:
          continue
        for line in (process / 'maps').read_text().splitlines():
          if 'libflutter_linux_gtk4.so' in line:
            mapped.add(line.split()[-1])
      except (OSError, PermissionError):
        continue
    assert len(mapped) == 1, mapped
    engine_sha = hashlib.sha256(pathlib.Path(next(iter(mapped))).read_bytes()).hexdigest()
    assert engine_sha == hashlib.sha256((args.engine_dir / 'libflutter_linux_gtk4.so').read_bytes()
                                       ).hexdigest()
    app_log.flush()
    startup = pathlib.Path(str(args.output) + '.log').read_text()
    assert ('Using the Impeller rendering backend' in startup) == (args.impeller == 'true')
    report = {
        'passed':
            True, 'engine_sha256':
                engine_sha, 'impeller':
                    args.impeller, 'gsk_requested':
                        args.gsk_renderer, 'gsk_observed':
                            next((
                                line.split(' ', 1)[1]
                                for line in startup.splitlines()
                                if line.startswith('GRADIENT_GSK ')
                            ), None), 'results':
                                results
    }
    args.output.write_text(json.dumps(report, indent=2) + '\n')
    print(f'PASS: {args.output}')
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
