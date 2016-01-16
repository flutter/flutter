#!/usr/bin/env python

# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Bootstrap script to clone and forward to the recipe engine tool."""

import ast
import logging
import os
import random
import re
import subprocess
import sys
import time
import traceback

BOOTSTRAP_VERSION = 1
# The root of the repository relative to the directory of this file.
REPO_ROOT = os.path.join(os.pardir)
# The path of the recipes.cfg file relative to the root of the repository.
RECIPES_CFG = os.path.join('infra', 'config', 'recipes.cfg')


def parse_protobuf(fh):
  """Parse the protobuf text format just well enough to understand recipes.cfg.

  We don't use the protobuf library because we want to be as self-contained
  as possible in this bootstrap, so it can be simply vendored into a client
  repo.

  We assume all fields are repeated since we don't have a proto spec to work
  with.

  Args:
    fh: a filehandle containing the text format protobuf.
  Returns:
    A recursive dictionary of lists.
  """
  def parse_atom(text):
    if text == 'true': return True
    if text == 'false': return False
    return ast.literal_eval(text)

  ret = {}
  for line in fh:
    line = line.strip()
    m = re.match(r'(\w+)\s*:\s*(.*)', line)
    if m:
      ret.setdefault(m.group(1), []).append(parse_atom(m.group(2)))
      continue

    m = re.match(r'(\w+)\s*{', line)
    if m:
      subparse = parse_protobuf(fh)
      ret.setdefault(m.group(1), []).append(subparse)
      continue

    if line == '}': return ret
    if line == '': continue

    raise Exception('Could not understand line: <%s>' % line)

  return ret


def get_unique(things):
  if len(things) == 1:
    return things[0]
  elif len(things) == 0:
    raise ValueError("Expected to get one thing, but dinna get none.")
  else:
    logging.warn('Expected to get one thing, but got a bunch: %s\n%s' %
                 (things, traceback.format_stack()))
    return things[0]


def main():
  if sys.platform.startswith(('win', 'cygwin')):
    git = 'git.bat'
  else:
    git = 'git'

  # Find the repository and config file to operate on.
  repo_root = os.path.abspath(
      os.path.join(os.path.dirname(__file__), REPO_ROOT))
  recipes_cfg_path = os.path.join(repo_root, RECIPES_CFG)

  with open(recipes_cfg_path, 'rU') as fh:
    protobuf = parse_protobuf(fh)

  engine_buf = get_unique([
      b for b in protobuf['deps'] if b.get('project_id') == ['recipe_engine'] ])
  engine_url = get_unique(engine_buf['url'])
  engine_revision = get_unique(engine_buf['revision'])
  engine_subpath = (get_unique(engine_buf.get('path_override', ['']))
                    .replace('/', os.path.sep))

  recipes_path = os.path.join(repo_root,
      get_unique(protobuf['recipes_path']).replace('/', os.path.sep))
  deps_path = os.path.join(recipes_path, '.recipe_deps')
  engine_path = os.path.join(deps_path, 'recipe_engine')

  # Ensure that we have the recipe engine cloned.
  def ensure_engine():
    if not os.path.exists(deps_path):
      os.makedirs(deps_path)
    if not os.path.exists(engine_path):
      subprocess.check_call([git, 'clone', engine_url, engine_path])

    needs_fetch = subprocess.call(
        [git, 'rev-parse', '--verify', '%s^{commit}' % engine_revision],
        cwd=engine_path, stdout=open(os.devnull, 'w'))
    if needs_fetch:
      subprocess.check_call([git, 'fetch'], cwd=engine_path)
    subprocess.check_call(
        [git, 'checkout', '--quiet', engine_revision], cwd=engine_path)

  try:
    ensure_engine()
  except subprocess.CalledProcessError as e:
    if e.returncode == 128:  # Thrown when git gets a lock error.
      time.sleep(random.uniform(2,5))
      ensure_engine()
    else:
      raise

  args = ['--package', recipes_cfg_path,
          '--bootstrap-script', __file__] + sys.argv[1:]
  return subprocess.call([
      sys.executable, '-u',
      os.path.join(engine_path, engine_subpath, 'recipes.py')] + args)

if __name__ == '__main__':
  sys.exit(main())
