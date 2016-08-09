# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
from util import build_utils

def FilterProguardOutput(output):
  '''ProGuard outputs boring stuff to stdout (proguard version, jar path, etc)
  as well as interesting stuff (notes, warnings, etc). If stdout is entirely
  boring, this method suppresses the output.
  '''
  ignore_patterns = [
    'ProGuard, version ',
    'Reading program jar [',
    'Reading library jar [',
    'Preparing output jar [',
    '  Copying resources from program jar [',
  ]
  for line in output.splitlines():
    for pattern in ignore_patterns:
      if line.startswith(pattern):
        break
    else:
      # line doesn't match any of the patterns; it's probably something worth
      # printing out.
      return output
  return ''


class ProguardCmdBuilder(object):
  def __init__(self, proguard_jar):
    assert os.path.exists(proguard_jar)
    self._proguard_jar_path = proguard_jar
    self._test = None
    self._mapping = None
    self._libraries = None
    self._injars = None
    self._configs = None
    self._outjar = None

  def outjar(self, path):
    assert self._outjar is None
    self._outjar = path

  def is_test(self, enable):
    assert self._test is None
    self._test = enable

  def mapping(self, path):
    assert self._mapping is None
    assert os.path.exists(path), path
    self._mapping = path

  def libraryjars(self, paths):
    assert self._libraries is None
    for p in paths:
      assert os.path.exists(p), p
    self._libraries = paths

  def injars(self, paths):
    assert self._injars is None
    for p in paths:
      assert os.path.exists(p), p
    self._injars = paths

  def configs(self, paths):
    assert self._configs is None
    for p in paths:
      assert os.path.exists(p), p
    self._configs = paths

  def build(self):
    assert self._injars is not None
    assert self._outjar is not None
    assert self._configs is not None
    cmd = [
      'java', '-jar', self._proguard_jar_path,
      '-forceprocessing',
    ]
    if self._test:
      cmd += [
        '-dontobfuscate',
        '-dontoptimize',
        '-dontshrink',
        '-dontskipnonpubliclibraryclassmembers',
      ]

    if self._mapping:
      cmd += [
        '-applymapping', self._mapping,
      ]

    if self._libraries:
      cmd += [
        '-libraryjars', ':'.join(self._libraries),
      ]

    cmd += [
      '-injars', ':'.join(self._injars)
    ]

    for config_file in self._configs:
      cmd += ['-include', config_file]

    # The output jar must be specified after inputs.
    cmd += [
      '-outjars', self._outjar,
      '-dump', self._outjar + '.dump',
      '-printseeds', self._outjar + '.seeds',
      '-printusage', self._outjar + '.usage',
      '-printmapping', self._outjar + '.mapping',
    ]
    return cmd

  def GetInputs(self):
    inputs = [self._proguard_jar_path] + self._configs + self._injars
    if self._mapping:
      inputs.append(self._mapping)
    if self._libraries:
      inputs += self._libraries
    return inputs


  def CheckOutput(self):
    build_utils.CheckOutput(self.build(), print_stdout=True,
                            stdout_filter=FilterProguardOutput)

