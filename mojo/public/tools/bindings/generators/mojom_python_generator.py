# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Generates Python source files from a mojom.Module."""

import re

import mojom.generate.constant_resolver as resolver
import mojom.generate.generator as generator
import mojom.generate.data as data
import mojom.generate.module as mojom
from mojom.generate.template_expander import UseJinja

_kind_to_type = {
  mojom.BOOL:                  '_descriptor.TYPE_BOOL',
  mojom.INT8:                  '_descriptor.TYPE_INT8',
  mojom.UINT8:                 '_descriptor.TYPE_UINT8',
  mojom.INT16:                 '_descriptor.TYPE_INT16',
  mojom.UINT16:                '_descriptor.TYPE_UINT16',
  mojom.INT32:                 '_descriptor.TYPE_INT32',
  mojom.UINT32:                '_descriptor.TYPE_UINT32',
  mojom.INT64:                 '_descriptor.TYPE_INT64',
  mojom.UINT64:                '_descriptor.TYPE_UINT64',
  mojom.FLOAT:                 '_descriptor.TYPE_FLOAT',
  mojom.DOUBLE:                '_descriptor.TYPE_DOUBLE',
  mojom.STRING:                '_descriptor.TYPE_STRING',
  mojom.NULLABLE_STRING:       '_descriptor.TYPE_NULLABLE_STRING',
  mojom.HANDLE:                '_descriptor.TYPE_HANDLE',
  mojom.DCPIPE:                '_descriptor.TYPE_HANDLE',
  mojom.DPPIPE:                '_descriptor.TYPE_HANDLE',
  mojom.MSGPIPE:               '_descriptor.TYPE_HANDLE',
  mojom.SHAREDBUFFER:          '_descriptor.TYPE_HANDLE',
  mojom.NULLABLE_HANDLE:       '_descriptor.TYPE_NULLABLE_HANDLE',
  mojom.NULLABLE_DCPIPE:       '_descriptor.TYPE_NULLABLE_HANDLE',
  mojom.NULLABLE_DPPIPE:       '_descriptor.TYPE_NULLABLE_HANDLE',
  mojom.NULLABLE_MSGPIPE:      '_descriptor.TYPE_NULLABLE_HANDLE',
  mojom.NULLABLE_SHAREDBUFFER: '_descriptor.TYPE_NULLABLE_HANDLE',
}

# int64 integers are not handled by array.array. int64/uint64 array are
# supported but storage is not optimized (ie. they are plain python list, not
# array.array)
_kind_to_typecode_for_native_array = {
  mojom.INT8:   'b',
  mojom.UINT8:  'B',
  mojom.INT16:  'h',
  mojom.UINT16: 'H',
  mojom.INT32:  'i',
  mojom.UINT32: 'I',
  mojom.FLOAT:  'f',
  mojom.DOUBLE: 'd',
}


def NameToComponent(name):
  # insert '_' between anything and a Title name (e.g, HTTPEntry2FooBar ->
  # HTTP_Entry2_FooBar)
  name = re.sub('([^_])([A-Z][^A-Z_]+)', r'\1_\2', name)
  # insert '_' between non upper and start of upper blocks (e.g.,
  # HTTP_Entry2_FooBar -> HTTP_Entry2_Foo_Bar)
  name = re.sub('([^A-Z_])([A-Z])', r'\1_\2', name)
  return [x.lower() for x in name.split('_')]

def UpperCamelCase(name):
  return ''.join([x.capitalize() for x in NameToComponent(name)])

def CamelCase(name):
  uccc = UpperCamelCase(name)
  return uccc[0].lower() + uccc[1:]

def ConstantStyle(name):
  components = NameToComponent(name)
  if components[0] == 'k':
    components = components[1:]
  return '_'.join([x.upper() for x in components])

def FieldStyle(name):
  components = NameToComponent(name)
  return '_'.join([x.lower() for x in components])

def GetNameForElement(element):
  if (mojom.IsEnumKind(element) or mojom.IsInterfaceKind(element) or
      mojom.IsStructKind(element) or mojom.IsUnionKind(element) or
      isinstance(element, mojom.Method)):
    return UpperCamelCase(element.name)
  if isinstance(element, mojom.EnumValue):
    return (GetNameForElement(element.enum) + '.' +
            ConstantStyle(element.name))
  if isinstance(element, (mojom.NamedValue,
                          mojom.Constant)):
    return ConstantStyle(element.name)
  if isinstance(element, mojom.Field):
    return FieldStyle(element.name)
  raise Exception('Unexpected element: %s' % element)

def ExpressionToText(token):
  if isinstance(token, (mojom.EnumValue, mojom.NamedValue)):
    return str(token.resolved_value)

  if isinstance(token, mojom.BuiltinValue):
    if token.value == 'double.INFINITY' or token.value == 'float.INFINITY':
      return 'float(\'inf\')';
    if (token.value == 'double.NEGATIVE_INFINITY' or
        token.value == 'float.NEGATIVE_INFINITY'):
      return 'float(\'-inf\')'
    if token.value == 'double.NAN' or token.value == 'float.NAN':
      return 'float(\'nan\')';

  if token in ['true', 'false']:
    return str(token == 'true')

  return token

def GetFullyQualifiedName(kind):
  name = []
  if kind.imported_from:
    name.append(kind.imported_from['python_module'])
  name.append(GetNameForElement(kind))
  return '.'.join(name)

def GetFieldType(kind, field=None):
  if mojom.IsArrayKind(kind):
    arguments = []
    if kind.kind in _kind_to_typecode_for_native_array:
      arguments.append('%r' % _kind_to_typecode_for_native_array[kind.kind])
    elif kind.kind != mojom.BOOL:
      arguments.append(GetFieldType(kind.kind))
    if mojom.IsNullableKind(kind):
      arguments.append('nullable=True')
    if kind.length is not None:
      arguments.append('length=%d' % kind.length)
    array_type = 'GenericArrayType'
    if kind.kind == mojom.BOOL:
      array_type = 'BooleanArrayType'
    elif kind.kind in _kind_to_typecode_for_native_array:
      array_type = 'NativeArrayType'
    return '_descriptor.%s(%s)' % (array_type, ', '.join(arguments))

  if mojom.IsMapKind(kind):
    arguments = [
      GetFieldType(kind.key_kind),
      GetFieldType(kind.value_kind),
    ]
    if mojom.IsNullableKind(kind):
      arguments.append('nullable=True')
    return '_descriptor.MapType(%s)' % ', '.join(arguments)

  if mojom.IsUnionKind(kind):
    arguments = [ 'lambda: %s' % GetFullyQualifiedName(kind) ]
    if mojom.IsNullableKind(kind):
      arguments.append('nullable=True')
    return '_descriptor.UnionType(%s)' % ', '.join(arguments)

  if mojom.IsStructKind(kind):
    arguments = [ 'lambda: %s' % GetFullyQualifiedName(kind) ]
    if mojom.IsNullableKind(kind):
      arguments.append('nullable=True')
    return '_descriptor.StructType(%s)' % ', '.join(arguments)

  if mojom.IsEnumKind(kind):
    return GetFieldType(mojom.INT32)

  if mojom.IsInterfaceKind(kind):
    arguments = [ 'lambda: %s' % GetFullyQualifiedName(kind) ]
    if mojom.IsNullableKind(kind):
      arguments.append('nullable=True')
    return '_descriptor.InterfaceType(%s)' % ', '.join(arguments)

  if mojom.IsInterfaceRequestKind(kind):
    arguments = []
    if mojom.IsNullableKind(kind):
      arguments.append('nullable=True')
    return '_descriptor.InterfaceRequestType(%s)' % ', '.join(arguments)

  return _kind_to_type[kind]

def GetFieldDescriptor(field, index, min_version):
  class_name = 'SingleFieldGroup'
  if field.kind == mojom.BOOL:
    class_name = 'FieldDescriptor'
  arguments = [ '%r' % GetNameForElement(field) ]
  arguments.append(GetFieldType(field.kind, field))
  arguments.append(str(index))
  arguments.append(str(min_version))
  if field.default:
    if mojom.IsStructKind(field.kind):
      arguments.append('default_value=True')
    else:
      arguments.append('default_value=%s' % ExpressionToText(field.default))
  return '_descriptor.%s(%s)' % (class_name, ', '.join(arguments))

def GetStructFieldDescriptor(packed_field):
  return GetFieldDescriptor(
      packed_field.field, packed_field.index, packed_field.min_version)

def GetUnionFieldDescriptor(field):
  return GetFieldDescriptor(field, field.ordinal, 0)

def GetFieldGroup(byte):
  if byte.packed_fields[0].field.kind == mojom.BOOL:
    descriptors = map(GetStructFieldDescriptor, byte.packed_fields)
    return '_descriptor.BooleanGroup([%s])' % ', '.join(descriptors)
  assert len(byte.packed_fields) == 1
  return GetStructFieldDescriptor(byte.packed_fields[0])

def MojomToPythonImport(mojom):
  return mojom.replace('.mojom', '_mojom')

class Generator(generator.Generator):

  python_filters = {
    'expression_to_text': ExpressionToText,
    'field_group': GetFieldGroup,
    'union_field_descriptor': GetUnionFieldDescriptor,
    'fully_qualified_name': GetFullyQualifiedName,
    'name': GetNameForElement,
  }

  @UseJinja('python_templates/module.py.tmpl', filters=python_filters)
  def GeneratePythonModule(self):
    return {
      'enums': self.module.enums,
      'imports': self.GetImports(),
      'interfaces': self.GetInterfaces(),
      'module': resolver.ResolveConstants(self.module, ExpressionToText),
      'namespace': self.module.namespace,
      'structs': self.GetStructs(),
      'unions': self.GetUnions(),
    }

  def GenerateFiles(self, args):
    import_path = MojomToPythonImport(self.module.name)
    self.Write(self.GeneratePythonModule(),
               self.MatchMojomFilePath('%s.py' % import_path))

  def GetImports(self):
    for each in self.module.imports:
      each['python_module'] = MojomToPythonImport(each['module_name'])
    return self.module.imports

  def GetJinjaParameters(self):
    return {
      'lstrip_blocks': True,
      'trim_blocks': True,
    }
