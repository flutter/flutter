#!/usr/bin/env python3
# Copyright 2026 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import contextlib
import io
from pathlib import Path
import tempfile
import unittest
from unittest import mock

import validate_gtk4_runtime_compat as validator


class RuntimeCompatibilityTest(unittest.TestCase):

  def test_configuration_selects_explicit_sysroot(self):
    root = Path('/tmp/sysroot with spaces')
    command = validator.configure_command(root, 'host_debug_gtk4_test', True)
    self.assertIn(f'--target-sysroot={root}', command)
    self.assertNotIn('linux_x64_sysroot_variant', ' '.join(command))
    self.assertIn('--target-dir=host_debug_gtk4_test', command)
    self.assertIn('gtk4_native_accessibility_tree_compat=true', command[-1])
    self.assertIn('gtk4_runtime_api_compat=true', command[-1])

  def test_reads_multiarch_gtk_version(self):
    with tempfile.TemporaryDirectory() as directory:
      root = Path(directory)
      pc = root / 'usr/lib/x86_64-linux-gnu/pkgconfig/gtk4.pc'
      pc.parent.mkdir(parents=True)
      pc.write_text('Name: GTK\nVersion: 4.16.12\n')
      self.assertEqual(validator.gtk_version(root), (4, 16, 12))
      pc.write_text('Version: invalid\n')
      with self.assertRaisesRegex(RuntimeError, 'Unable to read GTK version'):
        validator.gtk_version(root)

  def test_rejects_direct_optional_imports(self):
    symbols = '1: 00000000 0 FUNC GLOBAL DEFAULT UND gtk_accessible_announce'
    with mock.patch.object(validator, 'dynamic_symbols', return_value=symbols):
      with self.assertRaisesRegex(RuntimeError, 'directly imports optional'):
        validator.verify_no_optional_imports(Path('/repo'), Path('/engine.so'))

  def test_rejects_gtk_dependency_from_host(self):
    output = 'libgtk-4.so.1 => /usr/lib/libgtk-4.so.1 (0x1234)'
    with mock.patch.object(validator, 'run', return_value=output):
      with self.assertRaisesRegex(RuntimeError, 'escaped selected sysroot'):
        validator.verify_runtime_closure(
            Path('/repo'), Path('/sysroot'), Path('/out/tests'), ['loader'], True
        )

  def test_host_loader_allows_host_libc_but_not_host_glib(self):
    for library, rejects in [('libc.so.6', False), ('libglib-2.0.so.0', True)]:
      with self.subTest(library=library):
        output = f'{library} => /usr/lib/{library} (0x1234)'
        with mock.patch.object(validator, 'run', return_value=output):
          if rejects:
            with self.assertRaises(RuntimeError):
              validator.verify_runtime_closure(
                  Path('/repo'), Path('/sysroot'), Path('/out/tests'), ['loader'], True
              )
          else:
            validator.verify_runtime_closure(
                Path('/repo'), Path('/sysroot'), Path('/out/tests'), ['loader'], True
            )

  def test_similarly_named_directory_is_not_inside_sysroot(self):
    output = 'libgtk-4.so.1 => /sysroot-other/libgtk-4.so.1 (0x1234)'
    with mock.patch.object(validator, 'run', return_value=output):
      with self.assertRaisesRegex(RuntimeError, 'escaped selected sysroot'):
        validator.verify_runtime_closure(
            Path('/repo'), Path('/sysroot'), Path('/out/tests'), ['loader'], True
        )

  def test_container_does_not_install_or_fetch_dependencies(self):
    with mock.patch.object(validator.shutil, 'which', return_value='/bin/podman'):
      with mock.patch.object(validator, 'run') as run:
        with tempfile.TemporaryDirectory() as output_dir:
          (Path(output_dir) / 'flutter_linux_gtk4_unittests').write_bytes(b'fixture')
          validator.run_container_test(
              Path('/repo'), Path(output_dir), 'gtk-test:local', 'podman', True
          )
    command = run.call_args.args[0]
    self.assertIn('--network=none', command)
    self.assertIn('--pull=never', command)
    self.assertNotIn('apt-get', command[-1])
    self.assertIn('FlViewGtk4AccessibilityTest.*', command[-1])
    self.assertIn('FlAccessibilitySemanticsStoreTest.*', command[-1])
    self.assertIn('GTK_A11Y=test', command[-1])
    mount = command[command.index('-v') + 1]
    self.assertNotIn(output_dir, mount)
    self.assertTrue(mount.endswith(':ro,Z'))

  def test_missing_container_image_fails_before_build(self):
    with mock.patch('sys.argv', ['validator']):
      with mock.patch.object(validator, 'run') as run:
        with contextlib.redirect_stderr(io.StringIO()):
          with self.assertRaises(SystemExit) as error:
            validator.main()
    self.assertEqual(error.exception.code, 2)
    run.assert_not_called()


if __name__ == '__main__':
  unittest.main()
