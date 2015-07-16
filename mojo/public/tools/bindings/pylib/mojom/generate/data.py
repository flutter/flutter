# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# TODO(vtl): "data" is a pretty vague name. Rename it?

import copy

import module as mojom

# This module provides a mechanism to turn mojom Modules to dictionaries and
# back again. This can be used to persist a mojom Module created progromatically
# or to read a dictionary from code or a file.
# Example:
# test_dict = {
#   'name': 'test',
#   'namespace': 'testspace',
#   'structs': [{
#     'name': 'teststruct',
#     'fields': [
#       {'name': 'testfield1', 'kind': 'i32'},
#       {'name': 'testfield2', 'kind': 'a:i32', 'ordinal': 42}]}],
#   'interfaces': [{
#     'name': 'Server',
#     'methods': [{
#       'name': 'Foo',
#       'parameters': [{
#         'name': 'foo', 'kind': 'i32'},
#         {'name': 'bar', 'kind': 'a:x:teststruct'}],
#     'ordinal': 42}]}]
# }
# test_module = data.ModuleFromData(test_dict)

# Used to create a subclass of str that supports sorting by index, to make
# pretty printing maintain the order.
def istr(index, string):
  class IndexedString(str):
    def __lt__(self, other):
      return self.__index__ < other.__index__

  rv = IndexedString(string)
  rv.__index__ = index
  return rv

def AddOptional(dictionary, key, value):
  if value is not None:
    dictionary[key] = value;

builtin_values = frozenset([
    "double.INFINITY",
    "double.NEGATIVE_INFINITY",
    "double.NAN",
    "float.INFINITY",
    "float.NEGATIVE_INFINITY",
    "float.NAN"])

def IsBuiltinValue(value):
  return value in builtin_values

def LookupKind(kinds, spec, scope):
  """Tries to find which Kind a spec refers to, given the scope in which its
  referenced. Starts checking from the narrowest scope to most general. For
  example, given a struct field like
    Foo.Bar x;
  Foo.Bar could refer to the type 'Bar' in the 'Foo' namespace, or an inner
  type 'Bar' in the struct 'Foo' in the current namespace.

  |scope| is a tuple that looks like (namespace, struct/interface), referring
  to the location where the type is referenced."""
  if spec.startswith('x:'):
    name = spec[2:]
    for i in xrange(len(scope), -1, -1):
      test_spec = 'x:'
      if i > 0:
        test_spec += '.'.join(scope[:i]) + '.'
      test_spec += name
      kind = kinds.get(test_spec)
      if kind:
        return kind

  return kinds.get(spec)

def LookupValue(values, name, scope, kind):
  """Like LookupKind, but for constant values."""
  # If the type is an enum, the value can be specified as a qualified name, in
  # which case the form EnumName.ENUM_VALUE must be used. We use the presence
  # of a '.' in the requested name to identify this. Otherwise, we prepend the
  # enum name.
  if isinstance(kind, mojom.Enum) and '.' not in name:
    name = '%s.%s' % (kind.spec.split(':', 1)[1], name)
  for i in reversed(xrange(len(scope) + 1)):
    test_spec = '.'.join(scope[:i])
    if test_spec:
      test_spec += '.'
    test_spec += name
    value = values.get(test_spec)
    if value:
      return value

  return values.get(name)

def FixupExpression(module, value, scope, kind):
  """Translates an IDENTIFIER into a built-in value or structured NamedValue
     object."""
  if isinstance(value, tuple) and value[0] == 'IDENTIFIER':
    # Allow user defined values to shadow builtins.
    result = LookupValue(module.values, value[1], scope, kind)
    if result:
      if isinstance(result, tuple):
        raise Exception('Unable to resolve expression: %r' % value[1])
      return result
    if IsBuiltinValue(value[1]):
      return mojom.BuiltinValue(value[1])
  return value

def KindToData(kind):
  return kind.spec

def KindFromData(kinds, data, scope):
  kind = LookupKind(kinds, data, scope)
  if kind:
    return kind

  if data.startswith('?'):
    kind = KindFromData(kinds, data[1:], scope).MakeNullableKind()
  elif data.startswith('a:'):
    kind = mojom.Array(KindFromData(kinds, data[2:], scope))
  elif data.startswith('a'):
    colon = data.find(':')
    length = int(data[1:colon])
    kind = mojom.Array(KindFromData(kinds, data[colon+1:], scope), length)
  elif data.startswith('r:'):
    kind = mojom.InterfaceRequest(KindFromData(kinds, data[2:], scope))
  elif data.startswith('m['):
    # Isolate the two types from their brackets.

    # It is not allowed to use map as key, so there shouldn't be nested ']'s
    # inside the key type spec.
    key_end = data.find(']')
    assert key_end != -1 and key_end < len(data) - 1
    assert data[key_end+1] == '[' and data[-1] == ']'

    first_kind = data[2:key_end]
    second_kind = data[key_end+2:-1]

    kind = mojom.Map(KindFromData(kinds, first_kind, scope),
                     KindFromData(kinds, second_kind, scope))
  else:
    kind = mojom.Kind(data)

  kinds[data] = kind
  return kind

def KindFromImport(original_kind, imported_from):
  """Used with 'import module' - clones the kind imported from the given
  module's namespace. Only used with Structs, Unions, Interfaces and Enums."""
  kind = copy.copy(original_kind)
  # |shared_definition| is used to store various properties (see
  # |AddSharedProperty()| in module.py), including |imported_from|. We don't
  # want the copy to share these with the original, so copy it if necessary.
  if hasattr(original_kind, 'shared_definition'):
    kind.shared_definition = copy.copy(original_kind.shared_definition)
  kind.imported_from = imported_from
  return kind

def ImportFromData(module, data):
  import_module = data['module']

  import_item = {}
  import_item['module_name'] = import_module.name
  import_item['namespace'] = import_module.namespace
  import_item['module'] = import_module

  # Copy the struct kinds from our imports into the current module.
  importable_kinds = (mojom.Struct, mojom.Union, mojom.Enum, mojom.Interface)
  for kind in import_module.kinds.itervalues():
    if (isinstance(kind, importable_kinds) and
        kind.imported_from is None):
      kind = KindFromImport(kind, import_item)
      module.kinds[kind.spec] = kind
  # Ditto for values.
  for value in import_module.values.itervalues():
    if value.imported_from is None:
      # Values don't have shared definitions (since they're not nullable), so no
      # need to do anything special.
      value = copy.copy(value)
      value.imported_from = import_item
      module.values[value.GetSpec()] = value

  return import_item

def StructToData(struct):
  data = {
    istr(0, 'name'): struct.name,
    istr(1, 'fields'): map(FieldToData, struct.fields),
    # TODO(yzshen): EnumToData() and ConstantToData() are missing.
    istr(2, 'enums'): [],
    istr(3, 'constants'): []
  }
  AddOptional(data, istr(4, 'attributes'), struct.attributes)
  return data

def StructFromData(module, data):
  struct = mojom.Struct(module=module)
  struct.name = data['name']
  struct.spec = 'x:' + module.namespace + '.' + struct.name
  module.kinds[struct.spec] = struct
  struct.enums = map(lambda enum:
      EnumFromData(module, enum, struct), data['enums'])
  struct.constants = map(lambda constant:
      ConstantFromData(module, constant, struct), data['constants'])
  # Stash fields data here temporarily.
  struct.fields_data = data['fields']
  struct.attributes = data.get('attributes')
  return struct

def UnionToData(union):
  data = {
    istr(0, 'name'): union.name,
    istr(1, 'fields'): map(FieldToData, union.fields)
  }
  AddOptional(data, istr(2, 'attributes'), union.attributes)
  return data

def UnionFromData(module, data):
  union = mojom.Union(module=module)
  union.name = data['name']
  union.spec = 'x:' + module.namespace + '.' + union.name
  module.kinds[union.spec] = union
  # Stash fields data here temporarily.
  union.fields_data = data['fields']
  union.attributes = data.get('attributes')
  return union

def FieldToData(field):
  data = {
    istr(0, 'name'): field.name,
    istr(1, 'kind'): KindToData(field.kind)
  }
  AddOptional(data, istr(2, 'ordinal'), field.ordinal)
  AddOptional(data, istr(3, 'default'), field.default)
  AddOptional(data, istr(4, 'attributes'), field.attributes)
  return data

def StructFieldFromData(module, data, struct):
  field = mojom.StructField()
  PopulateField(field, module, data, struct)
  return field

def UnionFieldFromData(module, data, union):
  field = mojom.UnionField()
  PopulateField(field, module, data, union)
  return field

def PopulateField(field, module, data, parent):
  field.name = data['name']
  field.kind = KindFromData(
      module.kinds, data['kind'], (module.namespace, parent.name))
  field.ordinal = data.get('ordinal')
  field.default = FixupExpression(
      module, data.get('default'), (module.namespace, parent.name), field.kind)
  field.attributes = data.get('attributes')

def ParameterToData(parameter):
  data = {
    istr(0, 'name'): parameter.name,
    istr(1, 'kind'): parameter.kind.spec
  }
  AddOptional(data, istr(2, 'ordinal'), parameter.ordinal)
  AddOptional(data, istr(3, 'default'), parameter.default)
  AddOptional(data, istr(4, 'attributes'), parameter.attributes)
  return data

def ParameterFromData(module, data, interface):
  parameter = mojom.Parameter()
  parameter.name = data['name']
  parameter.kind = KindFromData(
      module.kinds, data['kind'], (module.namespace, interface.name))
  parameter.ordinal = data.get('ordinal')
  parameter.default = data.get('default')
  parameter.attributes = data.get('attributes')
  return parameter

def MethodToData(method):
  data = {
    istr(0, 'name'):       method.name,
    istr(1, 'parameters'): map(ParameterToData, method.parameters)
  }
  if method.response_parameters is not None:
    data[istr(2, 'response_parameters')] = map(
        ParameterToData, method.response_parameters)
  AddOptional(data, istr(3, 'ordinal'), method.ordinal)
  AddOptional(data, istr(4, 'attributes'), method.attributes)
  return data

def MethodFromData(module, data, interface):
  method = mojom.Method(interface, data['name'], ordinal=data.get('ordinal'))
  method.parameters = map(lambda parameter:
      ParameterFromData(module, parameter, interface), data['parameters'])
  if data.has_key('response_parameters'):
    method.response_parameters = map(
        lambda parameter: ParameterFromData(module, parameter, interface),
                          data['response_parameters'])
  method.attributes = data.get('attributes')
  return method

def InterfaceToData(interface):
  data = {
    istr(0, 'name'):    interface.name,
    istr(1, 'methods'): map(MethodToData, interface.methods),
    # TODO(yzshen): EnumToData() and ConstantToData() are missing.
    istr(2, 'enums'): [],
    istr(3, 'constants'): []
  }
  AddOptional(data, istr(4, 'attributes'), interface.attributes)
  return data

def InterfaceFromData(module, data):
  interface = mojom.Interface(module=module)
  interface.name = data['name']
  interface.spec = 'x:' + module.namespace + '.' + interface.name
  module.kinds[interface.spec] = interface
  interface.enums = map(lambda enum:
      EnumFromData(module, enum, interface), data['enums'])
  interface.constants = map(lambda constant:
      ConstantFromData(module, constant, interface), data['constants'])
  # Stash methods data here temporarily.
  interface.methods_data = data['methods']
  interface.attributes = data.get('attributes')
  return interface

def EnumFieldFromData(module, enum, data, parent_kind):
  field = mojom.EnumField()
  field.name = data['name']
  # TODO(mpcomplete): FixupExpression should be done in the second pass,
  # so constants and enums can refer to each other.
  # TODO(mpcomplete): But then, what if constants are initialized to an enum? Or
  # vice versa?
  if parent_kind:
    field.value = FixupExpression(
        module, data.get('value'), (module.namespace, parent_kind.name), enum)
  else:
    field.value = FixupExpression(
        module, data.get('value'), (module.namespace, ), enum)
  field.attributes = data.get('attributes')
  value = mojom.EnumValue(module, enum, field)
  module.values[value.GetSpec()] = value
  return field

def EnumFromData(module, data, parent_kind):
  enum = mojom.Enum(module=module)
  enum.name = data['name']
  name = enum.name
  if parent_kind:
    name = parent_kind.name + '.' + name
  enum.spec = 'x:%s.%s' % (module.namespace, name)
  enum.parent_kind = parent_kind
  enum.fields = map(
      lambda field: EnumFieldFromData(module, enum, field, parent_kind),
      data['fields'])
  enum.attributes = data.get('attributes')

  module.kinds[enum.spec] = enum
  return enum

def ConstantFromData(module, data, parent_kind):
  constant = mojom.Constant()
  constant.name = data['name']
  if parent_kind:
    scope = (module.namespace, parent_kind.name)
  else:
    scope = (module.namespace, )
  # TODO(mpcomplete): maybe we should only support POD kinds.
  constant.kind = KindFromData(module.kinds, data['kind'], scope)
  constant.parent_kind = parent_kind
  constant.value = FixupExpression(module, data.get('value'), scope, None)

  value = mojom.ConstantValue(module, parent_kind, constant)
  module.values[value.GetSpec()] = value
  return constant

def ModuleToData(module):
  data = {
    istr(0, 'name'):       module.name,
    istr(1, 'namespace'):  module.namespace,
    # TODO(yzshen): Imports information is missing.
    istr(2, 'imports'): [],
    istr(3, 'structs'):    map(StructToData, module.structs),
    istr(4, 'unions'):     map(UnionToData, module.unions),
    istr(5, 'interfaces'): map(InterfaceToData, module.interfaces),
    # TODO(yzshen): EnumToData() and ConstantToData() are missing.
    istr(6, 'enums'): [],
    istr(7, 'constants'): []
  }
  AddOptional(data, istr(8, 'attributes'), module.attributes)
  return data

def ModuleFromData(data):
  module = mojom.Module()
  module.kinds = {}
  for kind in mojom.PRIMITIVES:
    module.kinds[kind.spec] = kind

  module.values = {}

  module.name = data['name']
  module.namespace = data['namespace']
  # Imports must come first, because they add to module.kinds which is used
  # by by the others.
  module.imports = map(
      lambda import_data: ImportFromData(module, import_data),
      data['imports'])
  module.attributes = data.get('attributes')

  # First pass collects kinds.
  module.enums = map(
      lambda enum: EnumFromData(module, enum, None), data['enums'])
  module.structs = map(
      lambda struct: StructFromData(module, struct), data['structs'])
  module.unions = map(
      lambda union: UnionFromData(module, union), data.get('unions', []))
  module.interfaces = map(
      lambda interface: InterfaceFromData(module, interface),
      data['interfaces'])
  module.constants = map(
      lambda constant: ConstantFromData(module, constant, None),
      data['constants'])

  # Second pass expands fields and methods. This allows fields and parameters
  # to refer to kinds defined anywhere in the mojom.
  for struct in module.structs:
    struct.fields = map(lambda field:
        StructFieldFromData(module, field, struct), struct.fields_data)
    del struct.fields_data
  for union in module.unions:
    union.fields = map(lambda field:
        UnionFieldFromData(module, field, union), union.fields_data)
    del union.fields_data
  for interface in module.interfaces:
    interface.methods = map(lambda method:
        MethodFromData(module, method, interface), interface.methods_data)
    del interface.methods_data

  return module

def OrderedModuleFromData(data):
  module = ModuleFromData(data)
  for interface in module.interfaces:
    next_ordinal = 0
    for method in interface.methods:
      if method.ordinal is None:
        method.ordinal = next_ordinal
      next_ordinal = method.ordinal + 1
  return module
