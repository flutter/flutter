# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import unittest

import module as mojom
import generator

class TestGenerator(unittest.TestCase):

  def testGetUnionsAddsOrdinals(self):
    module = mojom.Module()
    union = module.AddUnion('a')
    union.AddField('a', mojom.BOOL)
    union.AddField('b', mojom.BOOL)
    union.AddField('c', mojom.BOOL, ordinal=10)
    union.AddField('d', mojom.BOOL)

    gen = generator.Generator(module)
    union = gen.GetUnions()[0]
    ordinals = [field.ordinal for field in union.fields]

    self.assertEquals([0, 1, 10, 11], ordinals)
