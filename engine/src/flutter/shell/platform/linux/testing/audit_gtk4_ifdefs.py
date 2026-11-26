#!/usr/bin/env python3
# Copyright 2026 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Inventory GTK conditional compilation per file without evaluating macros.

By default scan the Linux embedder. Explicit paths may be files or directories.
Use --details for branch ranges and enclosing conditions, or --json for tooling.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys

SOURCE_SUFFIXES = {'.c', '.cc', '.cpp', '.cxx', '.h', '.hh', '.hpp', '.m', '.mm'}
GTK_CONDITION = re.compile(
    r'\b(?:FLUTTER_LINUX_GTK4\w*|GTK_CHECK_VERSION|GTK_MAJOR_VERSION|GTK_MINOR_VERSION|GTK_MICRO_VERSION)\b'
)
PRESENCE_CHECK = re.compile(r'\bdefined\s*(?:\(\s*FLUTTER_LINUX_GTK4\s*\)|FLUTTER_LINUX_GTK4\b)')
DIRECTIVE = re.compile(r'^\s*#\s*(if|ifdef|ifndef|elif|else|endif)\b(.*)$')
# Mask comments and literals while retaining offsets and physical line numbers.
# This also ignores directive-looking text in multiline C++ raw strings.
NON_CODE = re.compile(
    r'(?://[^\n]*|/\*.*?\*/|(?:u8|u|U|L)?R"(?P<delimiter>[^ ()\\\t\r\n]{0,16})'
    r'\(.*?\)(?P=delimiter)"|"(?:\\.|[^"\\\n])*"|\'(?:\\.|[^\'\\\n])*\')',
    re.DOTALL,
)


def directives(source: str):
  # Join continuations before stripping // comments, as the preprocessor does.
  source = re.sub(r'\\\r?\n', '\v', source)
  source = NON_CODE.sub(lambda match: re.sub(r'[^\n\v]', ' ', match[0]), source)
  line = 1
  for logical in source.split('\n'):
    end = line + logical.count('\v')
    match = DIRECTIVE.match(logical.replace('\v', ' '))
    if match:
      yield line, end, match[1], ' '.join(match[2].split())
    line = end + 1


def audit_source(source: str) -> dict:
  stack = []
  groups = []
  directive_lines = set()
  presence_checks = []
  for line, end, kind, expression in directives(source):
    directive_lines.update(range(line, end + 1))
    condition = f'#{kind}' + (f' {expression}' if expression else '')
    relevant = bool(GTK_CONDITION.search(expression))
    if ((kind in ('ifdef', 'ifndef') and expression == 'FLUTTER_LINUX_GTK4') or
        (kind in ('if', 'elif') and PRESENCE_CHECK.search(expression))):
      presence_checks.append({'line': line, 'condition': condition})
    if kind in ('if', 'ifdef', 'ifndef'):
      group = {
          'line': line,
          'end_line': None,
          'context': [item['branches'][-1]['condition'] for item in stack],
          'branches': [],
          'gtk': relevant,
      }
      groups.append(group)
      stack.append(group)
    elif not stack:
      raise ValueError(f'line {line}: unmatched #{kind}')
    elif kind in ('elif', 'else'):
      group = stack[-1]
      if group['branches'][-1]['condition'] == '#else':
        raise ValueError(f'line {line}: #{kind} after #else')
      group['branches'][-1]['end_line'] = line - 1
      group['gtk'] |= relevant
    else:
      group = stack.pop()
      group['branches'][-1]['end_line'] = line - 1
      group['end_line'] = end
      continue
    stack[-1]['branches'].append({
        'line': line,
        'condition': condition,
        'body_line': end + 1,
        'end_line': None,
    })
  if stack:
    raise ValueError(f'line {stack[-1]["line"]}: unterminated conditional')

  blocks = []
  covered = set()
  for group in groups:
    if not group.pop('gtk'):
      continue
    blocks.append(group)
    for branch in group['branches']:
      covered.update(range(branch['body_line'], branch['end_line'] + 1))
  return {
      'blocks': blocks,
      'block_count': len(blocks),
      'branch_count': sum(len(group['branches']) for group in blocks),
      'body_lines': len(covered - directive_lines),
      'presence_checks': presence_checks,
  }


def source_files(paths: list[Path]) -> list[Path]:
  files = set()
  for path in paths:
    if not path.exists():
      raise ValueError(f'path does not exist: {path}')
    if path.is_file():
      files.add(path.resolve())
    else:
      files.update(
          file.resolve()
          for file in path.rglob('*')
          if file.is_file() and file.suffix in SOURCE_SUFFIXES
      )
  return sorted(files)


def main(argv=None) -> int:
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('paths', nargs='*', type=Path, help='Files or source directories to audit')
  parser.add_argument(
      '--details', action='store_true', help='Show all branches and enclosing conditions'
  )
  parser.add_argument('--json', action='store_true', help='Print the full inventory as JSON')
  parser.add_argument('--sort', choices=('count', 'path'), default='count')
  args = parser.parse_args(argv)
  root = Path(__file__).resolve().parent.parent
  reports = []
  errors = []
  try:
    files = source_files(args.paths or [root])
  except (OSError, ValueError) as error:
    parser.error(str(error))
  for path in files:
    name = str(path.relative_to(Path.cwd())) if path.is_relative_to(Path.cwd()) else str(path)
    try:
      report = audit_source(path.read_text(encoding='utf-8'))
      if report['block_count']:
        reports.append({'path': name, **report})
    except (OSError, ValueError) as error:
      errors.append({'path': name, 'error': str(error)})
  reports.sort(
      key=lambda report: (-report['block_count'] if args.sort == 'count' else 0, report['path'])
  )
  totals = {
      'scanned_files': len(files),
      'matched_files': len(reports),
      'blocks': sum(report['block_count'] for report in reports),
      'branches': sum(report['branch_count'] for report in reports),
      'body_lines': sum(report['body_lines'] for report in reports),
      'presence_checks': sum(len(report['presence_checks']) for report in reports),
  }
  if args.json:
    print(json.dumps({'totals': totals, 'files': reports, 'errors': errors}, indent=2))
  else:
    print('BLOCKS BRANCHES BODY_LINES FILE')
    for report in reports:
      print(
          f'{report["block_count"]:6} {report["branch_count"]:8} '
          f'{report["body_lines"]:10} {report["path"]}'
      )
      if args.details:
        for block in report['blocks']:
          context = ' > '.join(block['context']) or '(top level)'
          print(f'  lines {block["line"]}-{block["end_line"]}; context: {context}')
          for branch in block['branches']:
            body = (
                f'body {branch["body_line"]}-{branch["end_line"]}'
                if branch['body_line'] <= branch['end_line'] else 'empty body'
            )
            print(f'    {branch["line"]}: {branch["condition"]} '
                  f'({body})')
        for check in report['presence_checks']:
          print(f'  NOTE {check["line"]}: presence test: {check["condition"]}')
    print(
        f'\n{totals["blocks"]} GTK blocks in {totals["matched_files"]}/{len(files)} files; '
        f'{totals["presence_checks"]} presence tests (also match a macro defined as 0).'
    )
    for error in errors:
      print(f'{error["path"]}: {error["error"]}', file=sys.stderr)
  return 1 if errors else 0


if __name__ == '__main__':
  sys.exit(main())
