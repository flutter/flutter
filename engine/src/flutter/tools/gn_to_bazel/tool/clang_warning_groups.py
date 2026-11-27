# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Writes clang's warning groups as JSON, for compile_command_diff.py.

clang applies its warning options in order, each to every warning it
controls: -Wextra after -Wno-unused-parameter turns that warning back on,
because -Wextra controls it. To compare two command lines by what they end up
with, compile_command_diff.py needs to know which option controls which. The
list is clang's own, the "Diagnostic flags in Clang" page of its
documentation, where every flag says which others it "controls" or is a
"synonym for".

    python3 tool/clang_warning_groups.py > /tmp/clang_warning_groups.json
    python3 tool/compile_command_diff.py --warning-groups=/tmp/clang_warning_groups.json ...

reads the page of clang's main branch from clang.llvm.org; a path or another
URL as the one argument reads that instead (the page of the release the
engine's clang was cut from, when the two differ). The output is
`{"children": {group: [groups it controls]}, "synonym": {name: name}}`.
"""

import json
import re
import sys
import urllib.request

PAGE = 'https://clang.llvm.org/docs/DiagnosticsReference.html'


def parse(html):
  """The groups of the page: (children, synonym)."""
  children = {}
  synonym = {}
  for section in html.split('<section id="')[1:]:
    heading = re.search(r'<h3>-W([^<]+)<a', section)
    if not heading:
      continue
    name = heading.group(1)
    end = section.find('</section>')
    body = section[:end] if end >= 0 else section
    controlled = set()
    for kind, paragraph in re.findall(r'<p>(Also controls|Controls|Synonym for) (.*?)</p>', body,
                                      flags=re.S):
      names = [flag[2:] for flag in re.findall(r'std-ref">(-W[^<]+)</span>', paragraph)]
      if kind == 'Synonym for':
        if len(names) == 1:
          synonym[name] = names[0]
      else:
        controlled.update(names)
    children[name] = sorted(controlled)
  return children, synonym


def main(argv):
  source = argv[1] if len(argv) > 1 else PAGE
  if re.match(r'https?://', source):
    with urllib.request.urlopen(source, timeout=60) as response:
      html = response.read().decode('utf-8')
  else:
    with open(source, encoding='utf-8') as f:
      html = f.read()
  children, synonym = parse(html)
  if not children:
    print('no warning groups found in ' + source, file=sys.stderr)
    return 1
  json.dump({'children': children, 'synonym': synonym}, sys.stdout, indent=0, sort_keys=True)
  sys.stdout.write('\n')
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))
