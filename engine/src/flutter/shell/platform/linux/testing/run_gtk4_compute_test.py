#!/usr/bin/env python3
# Copyright 2026 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Check Flutter GPU's compute capability gate in a real GTK4 app."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import tempfile
import time


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('binary', type=Path)
  parser.add_argument('--engine-dir', type=Path, required=True)
  parser.add_argument('--output', type=Path, required=True)
  parser.add_argument('--gsk-renderer', choices=['gl', 'vulkan', 'cairo'], default='gl')
  args = parser.parse_args()
  binary = args.binary.resolve(strict=True)
  expected_engine = (args.engine_dir / 'libflutter_linux_gtk4.so').resolve(strict=True)
  args.output = args.output.resolve()
  args.output.parent.mkdir(parents=True, exist_ok=True)
  report = {'gsk_renderer_requested': args.gsk_renderer, 'passed': False}
  log_path = args.output.with_suffix('.log')
  with tempfile.TemporaryDirectory(prefix='gtk4-compute-') as directory:
    result_path = Path(directory) / 'capabilities.json'
    env = os.environ.copy()
    for key in ['GTK_MODULES', 'GTK_PATH', 'AT_SPI_BUS_ADDRESS']:
      env.pop(key, None)
    env.update(
        COMPUTE_PROBE_OUTPUT=str(result_path),
        GTK_A11Y='none',
        GDK_BACKEND='x11',
        GSK_RENDERER=args.gsk_renderer,
        FLUTTER_ENGINE_SWITCHES='2',
        FLUTTER_ENGINE_SWITCH_1='enable-impeller=true',
        FLUTTER_ENGINE_SWITCH_2='enable-flutter-gpu=true'
    )
    try:
      with log_path.open('w') as log:
        app = subprocess.Popen(['xvfb-run', '-a', 'dbus-run-session', '--',
                                str(binary)],
                               env=env,
                               stdout=log,
                               stderr=subprocess.STDOUT,
                               start_new_session=True)
        try:
          deadline = time.monotonic() + 45
          while not result_path.exists():
            if app.poll() is not None:
              raise RuntimeError(f'App exited with {app.returncode}; see {log_path}')
            if time.monotonic() > deadline:
              raise RuntimeError(f'Timed out waiting for capability report; see {log_path}')
            time.sleep(.1)
          # The writer may have created the file before finishing the JSON.
          while True:
            try:
              probe = json.loads(result_path.read_text())
              break
            except json.JSONDecodeError:
              if time.monotonic() > deadline:
                raise
              time.sleep(.05)
          report.update(probe)
          maps = Path(f'/proc/{probe["pid"]}/maps').read_text()
          engines = {
              line.split()[-1]
              for line in maps.splitlines()
              if 'libflutter_linux_gtk' in line and '.so' in line
          }
          report['gtk4_loaded'] = 'libgtk-4.so' in maps
          report['loaded_engines'] = sorted(engines)
          expected_hash = hashlib.sha256(expected_engine.read_bytes()).hexdigest()
          report['engine_sha256'] = expected_hash
          report['engine_matches'] = bool(engines) and all(
              hashlib.sha256(Path(path).read_bytes()).hexdigest() == expected_hash
              for path in engines
          )
          startup = log_path.read_text()
          report['impeller_gles_observed'] = 'Impeller rendering backend (OpenGLES' in startup
          report['passed'] = (
              'error' not in report and report['gtk4_loaded'] and report['engine_matches'] and
              report['impeller_gles_observed'] and not probe['supports_compute'] and
              probe['create_compute_pass_rejected'] and probe['max_workgroup_invocations'] == 0 and
              probe['max_shared_memory_bytes'] == 0 and probe['max_workgroup_size'] == [0, 0, 0] and
              probe['max_workgroup_count'] == [0, 0, 0]
          )
        finally:
          if app.poll() is None:
            os.killpg(app.pid, signal.SIGTERM)
          app.wait(timeout=10)
    except Exception as error:
      report['driver_error'] = str(error)
  args.output.write_text(json.dumps(report, indent=2) + '\n')
  print(json.dumps(report, indent=2))
  return 0 if report['passed'] else 1


if __name__ == '__main__':
  raise SystemExit(main())
