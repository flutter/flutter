#!/usr/bin/env python3
# Copyright 2026 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import contextlib
import io
import json
from pathlib import Path
import tempfile
import unittest

import audit_gtk4_ifdefs as audit


class AuditGtk4IfdefsTest(unittest.TestCase):

  def test_nested_blocks_and_else_ranges_do_not_double_count_lines(self):
    report = audit.audit_source(
        '#if OTHER\n#if FLUTTER_LINUX_GTK4\na();\n#if GTK_CHECK_VERSION(4, 14, 0)\n'
        'b();\n#endif\n#else\nc();\n#endif\n#endif\n'
    )
    self.assertEqual(report['block_count'], 2)
    self.assertEqual(report['branch_count'], 3)
    self.assertEqual(report['body_lines'], 3)
    outer, inner = report['blocks']
    self.assertEqual((outer['line'], outer['end_line']), (2, 9))
    self.assertEqual(outer['context'], ['#if OTHER'])
    self.assertEqual(outer['branches'][1]['condition'], '#else')
    self.assertEqual(inner['context'], ['#if OTHER', '#if FLUTTER_LINUX_GTK4'])

  def test_gtk_elif_includes_all_sibling_branches(self):
    report = audit.audit_source(
        '#if OTHER\na();\n#elif GTK_MAJOR_VERSION >= 4\nb();\n#else\nc();\n#endif\n'
    )
    self.assertEqual(report['block_count'], 1)
    self.assertEqual(report['branch_count'], 3)
    self.assertEqual(report['body_lines'], 3)

  def test_ignores_comments_literals_and_header_guards(self):
    report = audit.audit_source(
        '#ifndef FLUTTER_SHELL_FL_GTK4_H_\n#define FLUTTER_SHELL_FL_GTK4_H_\n'
        '/*\n#if FLUTTER_LINUX_GTK4\n#endif\n*/\n'
        'const char* text = R"code(\n#if FLUTTER_LINUX_GTK4\n#endif\n)code";\n'
        '// #if FLUTTER_LINUX_GTK4\n'
        '#if OTHER // FLUTTER_LINUX_GTK4\n#endif\n#endif\n'
    )
    self.assertEqual(report['block_count'], 0)

  def test_continuations_keep_physical_line_numbers(self):
    report = audit.audit_source('#if OTHER && \\\n  defined(FLUTTER_LINUX_GTK4)\ncall();\n#endif\n')
    branch = report['blocks'][0]['branches'][0]
    self.assertEqual(branch['body_line'], 3)
    self.assertEqual(branch['end_line'], 3)
    self.assertEqual(report['body_lines'], 1)
    self.assertEqual(len(report['presence_checks']), 1)

  def test_cpp_digit_separators_do_not_hide_following_directives(self):
    report = audit.audit_source(
        "int first = 1'000;\n#if FLUTTER_LINUX_GTK4\ncall();\n#endif\nint second = 2'000;\n"
    )
    self.assertEqual(report['block_count'], 1)
    self.assertEqual(report['blocks'][0]['line'], 2)

  def test_spliced_line_comment_does_not_create_directive(self):
    report = audit.audit_source('// comment \\\n#if FLUTTER_LINUX_GTK4\n')
    self.assertEqual(report['block_count'], 0)

  def test_presence_checks_distinguish_numeric_and_optional_macros(self):
    report = audit.audit_source(
        '#ifdef FLUTTER_LINUX_GTK4\n#endif\n'
        '#if !defined FLUTTER_LINUX_GTK4\n#endif\n'
        '#if FLUTTER_LINUX_GTK4\n#endif\n'
        '#if defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT)\n#endif\n'
    )
    self.assertEqual(report['block_count'], 4)
    self.assertEqual([item['line'] for item in report['presence_checks']], [1, 3])

  def test_malformed_conditionals_are_reported(self):
    for source in ('#endif\n', '#if FLUTTER_LINUX_GTK4\n', '#if X\n#else\n#elif Y\n'):
      with self.subTest(source=source), self.assertRaises(ValueError):
        audit.audit_source(source)

  def test_json_cli_deduplicates_files_and_returns_errors(self):
    with tempfile.TemporaryDirectory() as directory:
      root = Path(directory)
      valid = root / 'widget.cc'
      valid.write_text('#if FLUTTER_LINUX_GTK4\nwidget();\n#endif\n')
      (root / 'ignored.txt').write_text('#if FLUTTER_LINUX_GTK4\n')
      output = io.StringIO()
      with contextlib.redirect_stdout(output):
        result = audit.main([str(root), str(valid), '--json'])
      self.assertEqual(result, 0)
      report = json.loads(output.getvalue())
      self.assertEqual(report['totals']['scanned_files'], 1)
      self.assertEqual(report['totals']['blocks'], 1)
      valid.write_text('#if FLUTTER_LINUX_GTK4\n')
      output = io.StringIO()
      with contextlib.redirect_stdout(output):
        result = audit.main([str(valid), '--json'])
      self.assertEqual(result, 1)
      self.assertIn('unterminated', json.loads(output.getvalue())['errors'][0]['error'])

  def test_details_include_else_and_presence_notes(self):
    with tempfile.TemporaryDirectory() as directory:
      path = Path(directory) / 'widget.h'
      path.write_text('#ifdef FLUTTER_LINUX_GTK4\na();\n#else\nb();\n#endif\n')
      output = io.StringIO()
      with contextlib.redirect_stdout(output):
        self.assertEqual(audit.main([str(path), '--details']), 0)
      self.assertIn('lines 1-5', output.getvalue())
      self.assertIn('3: #else', output.getvalue())
      self.assertIn('presence test', output.getvalue())


if __name__ == '__main__':
  unittest.main()
