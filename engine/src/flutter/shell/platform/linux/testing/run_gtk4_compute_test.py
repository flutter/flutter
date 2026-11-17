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
  parser.add_argument('--flutter-renderer', choices=['opengl', 'vulkan'], default='opengl')
  parser.add_argument('--dispatch', action='store_true', help='Require compute-to-render pixels')
  parser.add_argument(
      '--gtk-snapshot',
      action='store_true',
      help='Require a GTK widget snapshot from the compute_snapshot.h runner helper'
  )
  parser.add_argument('--display-backend', choices=['x11', 'wayland'], default='x11')
  parser.add_argument(
      '--vulkan-presentation',
      choices=['dmabuf', 'readback'],
      help='Require the observed Vulkan presentation path'
  )
  parser.add_argument(
      '--pixel-buffer-texture',
      action='store_true',
      help='Verify a native RGBA plugin texture after compute dispatch'
  )
  args = parser.parse_args()
  if args.pixel_buffer_texture and not (args.dispatch and args.gtk_snapshot):
    parser.error('--pixel-buffer-texture requires --dispatch and --gtk-snapshot')
  if args.vulkan_presentation and args.flutter_renderer != 'vulkan':
    parser.error('--vulkan-presentation requires --flutter-renderer vulkan')
  binary = args.binary.resolve(strict=True)
  expected_engine = (args.engine_dir / 'libflutter_linux_gtk4.so').resolve(strict=True)
  args.output = args.output.resolve()
  args.output.parent.mkdir(parents=True, exist_ok=True)
  report = {
      'gsk_renderer_requested': args.gsk_renderer,
      'flutter_renderer_requested': args.flutter_renderer,
      'display_backend_requested': args.display_backend, 'passed': False
  }
  log_path = args.output.with_suffix('.log')
  snapshot_path = args.output.with_suffix('.png')
  if args.gtk_snapshot:
    snapshot_path.unlink(missing_ok=True)
  with tempfile.TemporaryDirectory(prefix='gtk4-compute-') as directory:
    result_path = Path(directory) / 'capabilities.json'
    quit_path = Path(directory) / 'quit'
    env = os.environ.copy()
    for key in ['GTK_MODULES', 'GTK_PATH', 'AT_SPI_BUS_ADDRESS']:
      env.pop(key, None)
    env.update(
        COMPUTE_PROBE_OUTPUT=str(result_path),
        GTK_A11Y='none',
        GDK_DEBUG=','.join(filter(None, [env.get('GDK_DEBUG'), 'no-portals'])),
        GIO_USE_VFS='local',
        FLUTTER_LINUX_GTK_DEBUG='1',
        GDK_BACKEND=args.display_backend,
        GSK_RENDERER=args.gsk_renderer,
        FLUTTER_LINUX_RENDERER=args.flutter_renderer,
        FLUTTER_ENGINE_SWITCHES='2',
        FLUTTER_ENGINE_SWITCH_1='enable-impeller=true',
        FLUTTER_ENGINE_SWITCH_2='enable-flutter-gpu=true'
    )
    if args.gtk_snapshot:
      env['COMPUTE_PROBE_SNAPSHOT'] = str(snapshot_path)
      env['COMPUTE_PROBE_QUIT'] = str(quit_path)
    try:
      with log_path.open('w') as log:
        command = ['dbus-run-session', '--', str(binary)]
        if args.pixel_buffer_texture:
          command.append('--pixel-buffer-texture')
        if args.display_backend == 'x11':
          command = ['xvfb-run', '-a', *command]
        app = subprocess.Popen(
            command, env=env, stdout=log, stderr=subprocess.STDOUT, start_new_session=True
        )
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
          report['vulkan_device_diagnostics'] = [
              line for line in startup.splitlines() if 'event=vulkan-device' in line
          ]
          report['impeller_vulkan_observed'] = 'Impeller rendering backend (Vulkan' in startup
          report['passed'] = (
              'error' not in report and report['gtk4_loaded'] and report['engine_matches'] and
              report['impeller_gles_observed'] and not probe['supports_compute'] and
              probe['create_compute_pass_rejected'] and probe['max_workgroup_invocations'] == 0 and
              probe['max_shared_memory_bytes'] == 0 and probe['max_workgroup_size'] == [0, 0, 0] and
              probe['max_workgroup_count'] == [0, 0, 0]
          )
          if args.flutter_renderer == 'vulkan':
            report['passed'] = (
                'error' not in report and report['gtk4_loaded'] and report['engine_matches'] and
                report['impeller_vulkan_observed'] and probe['supports_compute'] and
                not probe['create_compute_pass_rejected'] and
                probe['max_workgroup_invocations'] > 0 and
                all(value > 0 for value in probe['max_workgroup_size']) and
                all(value > 0 for value in probe['max_workgroup_count'])
            )
          if args.dispatch:
            report['passed'] = (
                report['passed'] and probe.get('dispatch_tested') is True and
                probe.get('compute_pixels_passed') is True
            )
          if args.gtk_snapshot:
            while not snapshot_path.exists():
              if app.poll() is not None or time.monotonic() > deadline:
                raise RuntimeError('GTK snapshot missing')
              time.sleep(.1)
            from PIL import Image
            # PNG encoding finishes before the runner callback returns.
            while True:
              try:
                with Image.open(snapshot_path) as image:
                  image = image.convert('RGBA')
                  w, h = image.size
                  samples = [
                      image.getpixel((int(w * x), int(h * y)))
                      for x, y in [(.1, .1), (.9, .1), (.1, .9), (.9, .9), (.5, .5)]
                  ]
                break
              except OSError:
                if time.monotonic() > deadline:
                  raise
                time.sleep(.05)
            renderer_lines = [
                line.partition('COMPUTE_GTK_RENDERER ')[2]
                for line in log_path.read_text().splitlines()
                if line.startswith('COMPUTE_GTK_RENDERER ')
            ]
            capture_lines = [
                line.partition('COMPUTE_GTK_CAPTURE_RENDERER ')[2]
                for line in log_path.read_text().splitlines()
                if line.startswith('COMPUTE_GTK_CAPTURE_RENDERER ')
            ]
            report['gtk_capture_method'] = 'surfaceless-renderer'
            report['gsk_capture_renderer'] = capture_lines[-1] if capture_lines else None
            report['gsk_renderer_observed'] = renderer_lines[-1] if renderer_lines else None
            report['passed'] = report['passed'] and bool(capture_lines) and (
                report['gsk_capture_renderer'] == report['gsk_renderer_observed']
            )
            expected_class = {'gl': 'gl', 'vulkan': 'vulkan', 'cairo': 'cairo'}[args.gsk_renderer]
            report['passed'] = report['passed'] and bool(renderer_lines) and (
                expected_class in renderer_lines[-1].lower()
            )
            report['gtk_pixels_rgba'] = samples
            report['gtk_snapshot'] = str(snapshot_path)
            expected_samples = [(0, 255, 0, 255)] * 5
            if args.pixel_buffer_texture:
              expected_samples = [(255, 0, 0, 255), (0, 255, 0, 255), (0, 0, 255, 255),
                                  (255, 255, 255, 255), (255, 255, 255, 255)]
              report['passed'
                    ] = report['passed'] and probe.get('pixel_buffer_texture_tested') is True
            report['passed'] = report['passed'] and samples == expected_samples
            quit_path.touch()
            report['clean_exit'] = app.wait(timeout=10) == 0
            report['passed'] = report['passed'] and report['clean_exit']
          presentation_lines = [
              line for line in log_path.read_text().splitlines()
              if 'event=vulkan-presentation ' in line
          ]
          report['vulkan_presentation_diagnostics'] = presentation_lines
          if args.vulkan_presentation:
            report['passed'] = report['passed'] and bool(presentation_lines) and (
                f'path={args.vulkan_presentation} ' in presentation_lines[-1]
            )
        finally:
          if app.poll() is None:
            os.killpg(app.pid, signal.SIGTERM)
          app.wait(timeout=10)
    except Exception as error:
      report['passed'] = False
      report['driver_error'] = str(error)
  args.output.write_text(json.dumps(report, indent=2) + '\n')
  print(json.dumps(report, indent=2))
  return 0 if report['passed'] else 1


if __name__ == '__main__':
  raise SystemExit(main())
