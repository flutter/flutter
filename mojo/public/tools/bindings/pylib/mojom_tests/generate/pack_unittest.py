# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import imp
import os.path
import sys
import unittest


def _GetDirAbove(dirname):
  """Returns the directory "above" this file containing |dirname| (which must
  also be "above" this file)."""
  path = os.path.abspath(__file__)
  while True:
    path, tail = os.path.split(path)
    assert tail
    if tail == dirname:
      return path


try:
  imp.find_module("mojom")
except ImportError:
  sys.path.append(os.path.join(_GetDirAbove("pylib"), "pylib"))
from mojom.generate import pack
from mojom.generate import module as mojom


# TODO(yzshen): Move tests in pack_tests.py here.
class PackTest(unittest.TestCase):
  def _CheckPackSequence(self, kinds, fields, offsets):
    """Checks the pack order and offsets of a sequence of mojom.Kinds.

    Args:
      kinds: A sequence of mojom.Kinds that specify the fields that are to be
      created.
      fields: The expected order of the resulting fields, with the integer "1"
      first.
      offsets: The expected order of offsets, with the integer "0" first.
    """
    struct = mojom.Struct('test')
    index = 1
    for kind in kinds:
      struct.AddField('%d' % index, kind)
      index += 1
    ps = pack.PackedStruct(struct)
    num_fields = len(ps.packed_fields)
    self.assertEquals(len(kinds), num_fields)
    for i in xrange(num_fields):
      self.assertEquals('%d' % fields[i], ps.packed_fields[i].field.name)
      self.assertEquals(offsets[i], ps.packed_fields[i].offset)

  def testMinVersion(self):
    """Tests that |min_version| is properly set for packed fields."""
    struct = mojom.Struct('test')
    struct.AddField('field_2', mojom.BOOL, 2)
    struct.AddField('field_0', mojom.INT32, 0)
    struct.AddField('field_1', mojom.INT64, 1)
    ps = pack.PackedStruct(struct)

    self.assertEquals('field_0', ps.packed_fields[0].field.name)
    self.assertEquals('field_2', ps.packed_fields[1].field.name)
    self.assertEquals('field_1', ps.packed_fields[2].field.name)

    self.assertEquals(0, ps.packed_fields[0].min_version)
    self.assertEquals(0, ps.packed_fields[1].min_version)
    self.assertEquals(0, ps.packed_fields[2].min_version)

    struct.fields[0].attributes = {'MinVersion': 1}
    ps = pack.PackedStruct(struct)

    self.assertEquals(0, ps.packed_fields[0].min_version)
    self.assertEquals(1, ps.packed_fields[1].min_version)
    self.assertEquals(0, ps.packed_fields[2].min_version)

  def testGetVersionInfoEmptyStruct(self):
    """Tests that pack.GetVersionInfo() never returns an empty list, even for
    empty structs.
    """
    struct = mojom.Struct('test')
    ps = pack.PackedStruct(struct)

    versions = pack.GetVersionInfo(ps)
    self.assertEquals(1, len(versions))
    self.assertEquals(0, versions[0].version)
    self.assertEquals(0, versions[0].num_fields)
    self.assertEquals(8, versions[0].num_bytes)

  def testGetVersionInfoComplexOrder(self):
    """Tests pack.GetVersionInfo() using a struct whose definition order,
    ordinal order and pack order for fields are all different.
    """
    struct = mojom.Struct('test')
    struct.AddField('field_3', mojom.BOOL, ordinal=3,
                    attributes={'MinVersion': 3})
    struct.AddField('field_0', mojom.INT32, ordinal=0)
    struct.AddField('field_1', mojom.INT64, ordinal=1,
                    attributes={'MinVersion': 2})
    struct.AddField('field_2', mojom.INT64, ordinal=2,
                    attributes={'MinVersion': 3})
    ps = pack.PackedStruct(struct)

    versions = pack.GetVersionInfo(ps)
    self.assertEquals(3, len(versions))

    self.assertEquals(0, versions[0].version)
    self.assertEquals(1, versions[0].num_fields)
    self.assertEquals(16, versions[0].num_bytes)

    self.assertEquals(2, versions[1].version)
    self.assertEquals(2, versions[1].num_fields)
    self.assertEquals(24, versions[1].num_bytes)

    self.assertEquals(3, versions[2].version)
    self.assertEquals(4, versions[2].num_fields)
    self.assertEquals(32, versions[2].num_bytes)

  def testInterfaceAlignment(self):
    """Tests that interfaces are aligned on 4-byte boundaries, although the size
    of an interface is 8 bytes.
    """
    kinds = (mojom.INT32, mojom.Interface('test_interface'))
    fields = (1, 2)
    offsets = (0, 4)
    self._CheckPackSequence(kinds, fields, offsets)
