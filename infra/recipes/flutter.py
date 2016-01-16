# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

DEPS = [
  'recipe_engine/path',
  'recipe_engine/step',
  'build/git',
]

def RunSteps(api):
  api.git.checkout('https://github.com/flutter/flutter.git', recursive=True)

  checkout = api.path['checkout']
  update_packages = checkout.join('dev', 'update_packages.dart')

  api.step('update packages', ['dart', update_packages])

  flutter_cli = checkout.join('bin', 'flutter')
  flutter_package = checkout.join('packages', 'flutter')
  populate_cmd = [flutter_cli, 'cache', 'populate']
  api.step('populate flutter cache', populate_cmd, cwd=flutter_package)

  analyze_cmd = [
    flutter_cli,
    'analyze',
    '--flutter-repo',
    '--no-current-directory',
    '--no-current-package',
    '--congratulate'
  ]
  api.step('flutter analyze', analyze_cmd)


  def _pub_test(path):
    api.step('test %s' % path, ['pub', 'run', 'test', '-j1'],
      cwd=checkout.join(path))

  def _flutter_test(path):
    api.step('test %s' % path, [flutter_cli, 'test'],
      cwd=checkout.join(path))

  _pub_test('packages/cassowary')
  _flutter_test('packages/flutter')
  _pub_test('packages/flutter_tools')
  _pub_test('packages/flx')
  _pub_test('packages/newton')

  _flutter_test('examples/stocks')

def GenTests(api):
  yield api.test('basic')
