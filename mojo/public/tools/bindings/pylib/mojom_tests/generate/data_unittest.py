# Copyright 2014 The Chromium Authors. All rights reserved.
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
from mojom.generate import data
from mojom.generate import module as mojom


class DataTest(unittest.TestCase):

  def testStructDataConversion(self):
    """Tests that a struct can be converted from data."""
    module = mojom.Module('test_module', 'test_namespace')
    struct_data = {
        'name': 'SomeStruct',
        'enums': [],
        'constants': [],
        'fields': [
            {'name': 'field1', 'kind': 'i32'},
            {'name': 'field2', 'kind': 'i32', 'ordinal': 10},
            {'name': 'field3', 'kind': 'i32', 'default': 15}]}

    struct = data.StructFromData(module, struct_data)
    struct.fields = map(lambda field:
        data.StructFieldFromData(module, field, struct), struct.fields_data)
    self.assertEquals(struct_data, data.StructToData(struct))

  def testUnionDataConversion(self):
    """Tests that a union can be converted from data."""
    module = mojom.Module('test_module', 'test_namespace')
    union_data = {
        'name': 'SomeUnion',
        'fields': [
            {'name': 'field1', 'kind': 'i32'},
            {'name': 'field2', 'kind': 'i32', 'ordinal': 10}]}

    union = data.UnionFromData(module, union_data)
    union.fields = map(lambda field:
        data.UnionFieldFromData(module, field, union), union.fields_data)
    self.assertEquals(union_data, data.UnionToData(union))

  def testImportFromDataNoMissingImports(self):
    """Tests that unions, structs, interfaces and enums are imported."""
    module = mojom.Module('test_module', 'test_namespace')
    imported_module = mojom.Module('import_module', 'import_namespace')
    #TODO(azani): Init values in module.py.
    #TODO(azani): Test that values are imported.
    imported_module.values = {}
    imported_data = {'module' : imported_module}


    struct = mojom.Struct('TestStruct', module=module)
    imported_module.kinds[struct.spec] = struct

    union = mojom.Union('TestUnion', module=module)
    imported_module.kinds[union.spec] = union

    interface = mojom.Interface('TestInterface', module=module)
    imported_module.kinds[interface.spec] = interface

    enum = mojom.Enum('TestEnum', module=module)
    imported_module.kinds[enum.spec] = enum

    data.ImportFromData(module, imported_data)

    # Test that the kind was imported.
    self.assertIn(struct.spec, module.kinds)
    self.assertEquals(struct.name, module.kinds[struct.spec].name)

    self.assertIn(union.spec, module.kinds)
    self.assertEquals(union.name, module.kinds[union.spec].name)

    self.assertIn(interface.spec, module.kinds)
    self.assertEquals(interface.name, module.kinds[interface.spec].name)

    self.assertIn(enum.spec, module.kinds)
    self.assertEquals(enum.name, module.kinds[enum.spec].name)

    # Test that the imported kind is a copy and not the original.
    self.assertIsNot(struct, module.kinds[struct.spec])
    self.assertIsNot(union, module.kinds[union.spec])
    self.assertIsNot(interface, module.kinds[interface.spec])
    self.assertIsNot(enum, module.kinds[enum.spec])

  def testImportFromDataNoExtraneousImports(self):
    """Tests that arrays, maps and interface requests are not imported."""
    module = mojom.Module('test_module', 'test_namespace')
    imported_module = mojom.Module('import_module', 'import_namespace')
    #TODO(azani): Init values in module.py.
    imported_module.values = {}
    imported_data = {'module' : imported_module}

    array = mojom.Array(mojom.INT16, length=20)
    imported_module.kinds[array.spec] = array

    map_kind = mojom.Map(mojom.INT16, mojom.INT16)
    imported_module.kinds[map_kind.spec] = map_kind

    interface = mojom.Interface('TestInterface', module=module)
    imported_module.kinds[interface.spec] = interface

    interface_req = mojom.InterfaceRequest(interface)
    imported_module.kinds[interface_req.spec] = interface_req

    data.ImportFromData(module, imported_data)

    self.assertNotIn(array.spec, module.kinds)
    self.assertNotIn(map_kind.spec, module.kinds)
    self.assertNotIn(interface_req.spec, module.kinds)

  def testNonInterfaceAsInterfaceRequest(self):
    """Tests that a non-interface cannot be used for interface requests."""
    module = mojom.Module('test_module', 'test_namespace')
    interface = mojom.Interface('TestInterface', module=module)
    method_dict = {
        'name': 'Foo',
        'parameters': [{'name': 'foo', 'kind': 'r:i32'}],
    }
    with self.assertRaises(Exception) as e:
      data.MethodFromData(module, method_dict, interface)
    self.assertEquals(e.exception.__str__(),
                      'Interface request requires \'i32\' to be an interface.')
