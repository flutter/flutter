#!/usr/bin/env python3
# Copyright 2026 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Check native popup creation and parent geometry with the popup demo.

Build lib/popup_demo.dart from the multiple_windows subtree demo. Requires
sway, grim, cc, wayland-scanner, and Wayland client development headers.
"""

import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('binary', type=Path)
  parser.add_argument('--engine-dir', type=Path, required=True)
  parser.add_argument('--output', type=Path, required=True)
  args = parser.parse_args()
  args.output.mkdir(parents=True, exist_ok=True)
  output = args.output.resolve()
  fixture = Path(__file__).parent / 'fixtures' / 'wayland-scale'
  with tempfile.TemporaryDirectory(prefix='gtk4-popup-') as temp:
    directory = Path(temp)
    runtime = directory / 'runtime'
    runtime.mkdir(mode=0o700)
    env = {
        key: value
        for key, value in os.environ.items()
        if key in ['PATH', 'HOME', 'LANG', 'LC_ALL']
    }
    env.update(
        XDG_RUNTIME_DIR=str(runtime),
        WLR_BACKENDS='headless',
        WLR_RENDERER='pixman',
        WLR_LIBINPUT_NO_DEVICES='1',
        WLR_HEADLESS_OUTPUTS='1',
        GDK_BACKEND='wayland',
        GSK_RENDERER='cairo',
        GTK_A11Y='none',
        GIO_USE_VFS='local'
    )
    config = directory / 'sway.conf'
    config.write_text(
        'output HEADLESS-1 resolution 1200x900\n'
        'for_window [title="Native popup portability demo"] '
        'floating enable, border none, resize set 800 600, '
        'move position 100 100\n'
    )
    for mode, name in [('client-header', 'virtual-pointer.h'),
                       ('private-code', 'virtual-pointer.c')]:
      subprocess.run([
          'wayland-scanner', mode,
          str(fixture / 'wlr-virtual-pointer-unstable-v1.xml'),
          str(directory / name)
      ],
                     check=True)
    pointer_binary = directory / 'pointer'
    subprocess.run([
        'cc', '-I' + str(directory),
        str(fixture / 'virtual_pointer.c'),
        str(directory / 'virtual-pointer.c'), '-lwayland-client', '-o',
        str(pointer_binary)
    ],
                   check=True)
    processes = []
    with open(output / 'sway.log', 'w') as sway_log, open(output / 'app.log', 'w') as app_log:
      try:
        sway = subprocess.Popen(['sway', '--unsupported-gpu', '-c',
                                 str(config)],
                                env=env,
                                stdout=sway_log,
                                stderr=sway_log)
        processes.append(sway)
        for _ in range(100):
          sockets = list(runtime.glob('sway-ipc.*.sock'))
          displays = [p for p in runtime.glob('wayland-*') if not p.name.endswith('.lock')]
          if sockets and displays:
            break
          if sway.poll() is not None:
            raise RuntimeError('Sway failed; see sway.log')
          time.sleep(.1)
        else:
          raise RuntimeError('Timed out starting Sway')
        env.update(SWAYSOCK=str(sockets[0]), WAYLAND_DISPLAY=displays[0].name)
        app_env = env | {
            'WAYLAND_DEBUG': 'client', 'LD_LIBRARY_PATH': str(args.engine_dir.resolve())
        }
        bus_config = directory / 'bus.conf'
        bus_config.write_text(
            '<busconfig><type>session</type><listen>unix:tmpdir=/tmp</listen>'
            '<auth>EXTERNAL</auth><policy context="default">'
            '<allow send_destination="*"/><allow receive_sender="*"/>'
            '<allow own="*"/></policy></busconfig>'
        )
        app = subprocess.Popen([
            'dbus-run-session', '--config-file=' + str(bus_config), '--',
            str(args.binary.resolve())
        ],
                               env=app_env,
                               stdout=app_log,
                               stderr=app_log)
        processes.append(app)

        def parent_rect():
          tree = json.loads(subprocess.check_output(['swaymsg', '-t', 'get_tree', '-r'], env=env))

          def find(node):
            if node.get('name') == 'Native popup portability demo':
              return node['rect']
            for child in node.get('nodes', []) + node.get('floating_nodes', []):
              result = find(child)
              if result:
                return result

          return find(tree)

        for _ in range(100):
          if parent_rect():
            break
          if app.poll() is not None:
            raise RuntimeError('Demo exited; see app.log')
          time.sleep(.1)
        else:
          raise RuntimeError('Demo window did not appear')
        time.sleep(3)
        before = parent_rect()
        assert before['width'] == 800 and before['height'] == 600, before
        pointer = subprocess.Popen([str(pointer_binary)],
                                   env=env,
                                   stdin=subprocess.PIPE,
                                   stdout=subprocess.PIPE,
                                   text=True)
        processes.append(pointer)
        assert pointer.stdout.readline().strip() == 'READY'
        time.sleep(1)
        pointer.stdin.write('click 190 260 1200 900\n')
        pointer.stdin.flush()
        # Allow several full cycles of the popup's content-size animation.
        time.sleep(4)
        after = parent_rect()
        subprocess.run(['grim', str(output / 'popup.png')], env=env, check=True)
        protocol = (output / 'app.log').read_text()
        assert '.get_popup(' in protocol, 'No native Wayland popup was created'
        assert app.poll() is None, 'Demo exited while displaying its popup'
        result = {
            'before': before, 'after': after, 'native_popup': True,
            'parent_unchanged': before == after
        }
        (output / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
        assert before == after, result
        print(json.dumps(result))
      finally:
        for process in reversed(processes):
          if process.poll() is None:
            process.terminate()
            try:
              process.wait(timeout=5)
            except subprocess.TimeoutExpired:
              process.kill()
              process.wait()


if __name__ == '__main__':
  main()
