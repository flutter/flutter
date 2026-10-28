#!/usr/bin/env python3
# Copyright 2026 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Check real-engine gradient pixels across scroll and resize; requires Pillow."""

import argparse
import ctypes
import hashlib
import json
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from PIL import Image

p = argparse.ArgumentParser(
    description='Verify gradients in the real GTK4 engine before/after scroll and resize'
)
p.add_argument('binary', type=Path)
p.add_argument('--engine-dir', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
p.add_argument('--impeller', choices=['true', 'false'], default='true')
p.add_argument('--gsk-renderer', choices=['cairo', 'gl', 'vulkan'], default='cairo')
p.add_argument('--scale', type=int, choices=[1, 2], default=1)
p.add_argument('--inside-session', action='store_true', help=argparse.SUPPRESS)
a = p.parse_args()
a.output.parent.mkdir(parents=True, exist_ok=True)
if not a.inside_session:
  with tempfile.TemporaryDirectory(prefix='gradient-session-') as directory:
    config = Path(directory) / 'session.conf'
    config.write_text(
        '<busconfig><type>session</type><listen>unix:tmpdir=/tmp</listen>'
        '<auth>EXTERNAL</auth><policy context="default">'
        '<allow send_destination="*"/><allow receive_sender="*"/>'
        '<allow own="*"/></policy></busconfig>'
    )
    env = os.environ.copy()
    for key in ['GTK_MODULES', 'GTK_PATH', 'AT_SPI_BUS_ADDRESS']:
      env.pop(key, None)
    env.update(
        GTK_A11Y='none',
        GDK_BACKEND='x11',
        GDK_DEBUG='no-portals',
        GSK_RENDERER=a.gsk_renderer,
        GDK_SCALE=str(a.scale),
        GIO_USE_VFS='local'
    )
    command = [
        'xvfb-run', '-a', '-s', f'-screen 0 {1280*a.scale}x{900*a.scale}x24', 'dbus-run-session',
        f'--config-file={config}', '--', sys.executable,
        str(Path(__file__).resolve()), *sys.argv[1:], '--inside-session'
    ]
    sys.exit(subprocess.run(command, env=env, timeout=45, check=False).returncode)


def wait(predicate, description):
  deadline = time.monotonic() + 25
  while time.monotonic() < deadline:
    if app.poll() is not None:
      raise RuntimeError('App exited ' + str(app.returncode))
    result = predicate()
    if result:
      return result
    time.sleep(.1)
  raise RuntimeError('Timed out: ' + description)


def check(meta):
  image = Image.frombytes('RGBA', (meta['width'], meta['height']), Path(meta['path']).read_bytes())
  cases = []
  offset = int(meta.get('scroll_offset', 0))

  def sample(label, x, y, expected):
    y -= offset
    if y < 0:
      return
    observed = image.getpixel((x, y))
    error = max(abs(observed[i] - expected[i]) for i in range(4))
    cases.append(
        dict(
            case=label,
            point=[x, y],
            expected=[round(v, 2) for v in expected],
            observed=observed,
            error=round(error, 2),
            passed=error <= 4
        )
    )

  for fraction in [.1, .25, .5, .75, .9]:
    x = 700 + int(400 * fraction)
    t = (x + .5 - 700) / 400
    sample('horizontal-' + str(fraction), x, 100, [255 * (1 - t), 0, 255 * t, 255])
    y = 20 + int(200 * fraction)
    t = (y + .5 - 20) / 200
    sample('vertical-' + str(fraction), 200, y, [255 * (1 - t), 0, 255 * t, 255])
    x = 20 + int(1100 * fraction)
    y = 330
    t = ((x + .5 - 20) * 1100 + (y + .5 - 250) * 160) / (1100**2 + 160**2)
    alpha = (128 / 255) * (1 - t) + t
    bg = 32 * (1 - alpha)
    sample(
        'translucent-diagonal-' + str(fraction), x, y,
        [bg, 255 * (1 - t) * alpha + bg, 255 * t * alpha + bg, 255]
    )
  for distance in [100, 200, 280]:
    t = (distance + .5) / 400
    sample('radial-' + str(distance), 320 + distance, 520, [255 * (1 - t), 0, 255 * t, 255])
  sample('rounded-outside', 21, 251, [32, 32, 32, 255])
  sample('background', 650, 100, [32, 32, 32, 255])
  return dict(
      width=meta['width'],
      height=meta['height'],
      index=meta['index'],
      scroll_offset=offset,
      samples=cases,
      passed=all(c['passed'] for c in cases)
  )


def resize():
  x = ctypes.CDLL('libX11.so.6')
  ptr = ctypes.c_void_p
  ulong = ctypes.c_ulong
  uint = ctypes.c_uint
  x.XOpenDisplay.restype = ptr
  x.XDefaultRootWindow.argtypes = [ptr]
  x.XDefaultRootWindow.restype = ulong
  x.XQueryTree.argtypes = [
      ptr, ulong,
      ctypes.POINTER(ulong),
      ctypes.POINTER(ulong),
      ctypes.POINTER(ctypes.POINTER(ulong)),
      ctypes.POINTER(uint)
  ]
  x.XGetGeometry.argtypes = [
      ptr, ulong,
      ctypes.POINTER(ulong),
      ctypes.POINTER(ctypes.c_int),
      ctypes.POINTER(ctypes.c_int),
      ctypes.POINTER(uint),
      ctypes.POINTER(uint),
      ctypes.POINTER(uint),
      ctypes.POINTER(uint)
  ]
  x.XResizeWindow.argtypes = [ptr, ulong, uint, uint]
  x.XFlush.argtypes = [ptr]
  x.XCloseDisplay.argtypes = [ptr]
  x.XFree.argtypes = [ptr]
  d = x.XOpenDisplay(None)
  root = x.XDefaultRootWindow(d)
  r = ulong()
  parent = ulong()
  children = ctypes.POINTER(ulong)()
  count = uint()
  x.XQueryTree(
      d, root, ctypes.byref(r), ctypes.byref(parent), ctypes.byref(children), ctypes.byref(count)
  )
  found = False
  for i in range(count.value):
    px = ctypes.c_int()
    py = ctypes.c_int()
    w = uint()
    h = uint()
    b = uint()
    depth = uint()
    x.XGetGeometry(
        d, children[i], ctypes.byref(r), ctypes.byref(px), ctypes.byref(py), ctypes.byref(w),
        ctypes.byref(h), ctypes.byref(b), ctypes.byref(depth)
    )
    if w.value > 1000 and h.value > 500:
      x.XResizeWindow(
          d, children[i], 1180 * int(os.environ.get('GDK_SCALE', '1')),
          680 * int(os.environ.get('GDK_SCALE', '1'))
      )
      found = True
      break
  x.XFlush(d)
  x.XFree(children)
  x.XCloseDisplay(d)
  if not found:
    raise RuntimeError('No fixture window found for resize')


with tempfile.TemporaryDirectory(prefix='gradient-pixels-') as directory:
  env = os.environ.copy()
  env.update(
      GRADIENT_PROBE_OUTPUT=directory,
      LD_LIBRARY_PATH=str(a.engine_dir.resolve()),
      FLUTTER_ENGINE_SWITCHES='1',
      FLUTTER_ENGINE_SWITCH_1='enable-impeller=' + a.impeller
  )
  with open(str(a.output) + '.log', 'w') as log:
    app = subprocess.Popen([str(a.binary.resolve())], env=env, stdout=log, stderr=subprocess.STDOUT)
    try:
      path = Path(directory) / 'latest.json'

      def latest():
        try:
          return json.loads(path.read_text())
        except (FileNotFoundError, json.JSONDecodeError):
          return None

      first = wait(latest, 'initial readback')
      before = check(first)
      resize()
      second = wait(
          lambda: (r if (r := latest()) and r['width'] != first['width'] else None),
          'resized readback'
      )
      after = check(second)
      if second.get('scroll_offset') != 40:
        raise RuntimeError('Scroll transition not captured')
      maps = sorted({
          l.split()[-1]
          for l in Path(f'/proc/{app.pid}/maps').read_text().splitlines()
          if 'libflutter_linux_gtk4.so' in l
      })
      if len(maps) != 1:
        raise RuntimeError(f'Expected one loaded GTK4 engine library, got {maps}')
      expected_engine = a.engine_dir / 'libflutter_linux_gtk4.so'
      if hashlib.sha256(Path(maps[0]).read_bytes()
                       ).digest() != hashlib.sha256(expected_engine.read_bytes()).digest():
        raise RuntimeError('Loaded engine does not match the requested engine directory')
      report = dict(
          before=before,
          after=after,
          impeller=a.impeller,
          engine_library=maps,
          engine_sha256=[hashlib.sha256(Path(p).read_bytes()).hexdigest() for p in maps],
          passed=before['passed'] and after['passed'],
          scope='real GTK4 engine; widget RepaintBoundary GPU image readback; X11 resize'
      )
      log.flush()
      lines = Path(str(a.output) + '.log').read_text().splitlines()
      report.update(
          gsk_requested=a.gsk_renderer,
          scale=a.scale,
          gsk_observed=next(
              (line.split(' ', 1)[1] for line in lines if line.startswith('GRADIENT_GSK ')), None
          ),
          gtk_runtime=next(
              (line.split(' ', 1)[1] for line in lines if line.startswith('GRADIENT_GTK ')), None
          )
      )
      uses_impeller = any('Using the Impeller rendering backend' in line for line in lines)
      if uses_impeller != (a.impeller == 'true'):
        raise RuntimeError('Startup log does not match the requested engine renderer')
      a.output.write_text(json.dumps(report, indent=2) + '\n')
      print(
          json.dumps({
              'passed': report['passed'],
              'failed_samples': sum(not c['passed'] for r in [before, after] for c in r['samples'])
          })
      )
      if not report['passed']:
        raise SystemExit(1)
    finally:
      app.terminate()
      app.wait(timeout=5)
