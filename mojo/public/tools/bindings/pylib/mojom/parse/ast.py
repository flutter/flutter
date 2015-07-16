# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Node classes for the AST for a Mojo IDL file."""

# Note: For convenience of testing, you probably want to define __eq__() methods
# for all node types; it's okay to be slightly lax (e.g., not compare filename
# and lineno). You may also define __repr__() to help with analyzing test
# failures, especially for more complex types.


class NodeBase(object):
  """Base class for nodes in the AST."""

  def __init__(self, filename=None, lineno=None):
    self.filename = filename
    self.lineno = lineno

  def __eq__(self, other):
    return type(self) == type(other)

  # Make != the inverse of ==. (Subclasses shouldn't have to override this.)
  def __ne__(self, other):
    return not self == other


# TODO(vtl): Some of this is complicated enough that it should be tested.
class NodeListBase(NodeBase):
  """Represents a list of other nodes, all having the same type. (This is meant
  to be subclassed, with subclasses defining _list_item_type to be the class (or
  classes, in a tuple) of the members of the list.)"""

  def __init__(self, item_or_items=None, **kwargs):
    super(NodeListBase, self).__init__(**kwargs)
    self.items = []
    if item_or_items is None:
      pass
    elif isinstance(item_or_items, list):
      for item in item_or_items:
        assert isinstance(item, self._list_item_type)
        self.Append(item)
    else:
      assert isinstance(item_or_items, self._list_item_type)
      self.Append(item_or_items)

  # Support iteration. For everything else, users should just access |items|
  # directly. (We intentionally do NOT supply |__len__()| or |__nonzero__()|, so
  # |bool(NodeListBase())| is true.)
  def __iter__(self):
    return self.items.__iter__()

  def __eq__(self, other):
    return super(NodeListBase, self).__eq__(other) and \
           self.items == other.items

  # Implement this so that on failure, we get slightly more sensible output.
  def __repr__(self):
    return self.__class__.__name__ + "([" + \
           ", ".join([repr(elem) for elem in self.items]) + "])"

  def Insert(self, item):
    """Inserts item at the front of the list."""

    assert isinstance(item, self._list_item_type)
    self.items.insert(0, item)
    self._UpdateFilenameAndLineno()

  def Append(self, item):
    """Appends item to the end of the list."""

    assert isinstance(item, self._list_item_type)
    self.items.append(item)
    self._UpdateFilenameAndLineno()

  def _UpdateFilenameAndLineno(self):
    if self.items:
      self.filename = self.items[0].filename
      self.lineno = self.items[0].lineno


class Definition(NodeBase):
  """Represents a definition of anything that has a global name (e.g., enums,
  enum values, consts, structs, struct fields, interfaces). (This does not
  include parameter definitions.) This class is meant to be subclassed."""

  def __init__(self, name, **kwargs):
    assert isinstance(name, str)
    NodeBase.__init__(self, **kwargs)
    self.name = name


################################################################################


class Attribute(NodeBase):
  """Represents an attribute."""

  def __init__(self, key, value, **kwargs):
    assert isinstance(key, str)
    super(Attribute, self).__init__(**kwargs)
    self.key = key
    self.value = value

  def __eq__(self, other):
    return super(Attribute, self).__eq__(other) and \
           self.key == other.key and \
           self.value == other.value


class AttributeList(NodeListBase):
  """Represents a list attributes."""

  _list_item_type = Attribute


class Const(Definition):
  """Represents a const definition."""

  def __init__(self, name, typename, value, **kwargs):
    # The typename is currently passed through as a string.
    assert isinstance(typename, str)
    # The value is either a literal (currently passed through as a string) or a
    # "wrapped identifier".
    assert isinstance(value, str) or isinstance(value, tuple)
    super(Const, self).__init__(name, **kwargs)
    self.typename = typename
    self.value = value

  def __eq__(self, other):
    return super(Const, self).__eq__(other) and \
           self.typename == other.typename and \
           self.value == other.value


class Enum(Definition):
  """Represents an enum definition."""

  def __init__(self, name, attribute_list, enum_value_list, **kwargs):
    assert attribute_list is None or isinstance(attribute_list, AttributeList)
    assert isinstance(enum_value_list, EnumValueList)
    super(Enum, self).__init__(name, **kwargs)
    self.attribute_list = attribute_list
    self.enum_value_list = enum_value_list

  def __eq__(self, other):
    return super(Enum, self).__eq__(other) and \
           self.attribute_list == other.attribute_list and \
           self.enum_value_list == other.enum_value_list


class EnumValue(Definition):
  """Represents a definition of an enum value."""

  def __init__(self, name, attribute_list, value, **kwargs):
    # The optional value is either an int (which is current a string) or a
    # "wrapped identifier".
    assert attribute_list is None or isinstance(attribute_list, AttributeList)
    assert value is None or isinstance(value, (str, tuple))
    super(EnumValue, self).__init__(name, **kwargs)
    self.attribute_list = attribute_list
    self.value = value

  def __eq__(self, other):
    return super(EnumValue, self).__eq__(other) and \
           self.attribute_list == other.attribute_list and \
           self.value == other.value


class EnumValueList(NodeListBase):
  """Represents a list of enum value definitions (i.e., the "body" of an enum
  definition)."""

  _list_item_type = EnumValue


class Import(NodeBase):
  """Represents an import statement."""

  def __init__(self, import_filename, **kwargs):
    assert isinstance(import_filename, str)
    super(Import, self).__init__(**kwargs)
    self.import_filename = import_filename

  def __eq__(self, other):
    return super(Import, self).__eq__(other) and \
           self.import_filename == other.import_filename


class ImportList(NodeListBase):
  """Represents a list (i.e., sequence) of import statements."""

  _list_item_type = Import


class Interface(Definition):
  """Represents an interface definition."""

  def __init__(self, name, attribute_list, body, **kwargs):
    assert attribute_list is None or isinstance(attribute_list, AttributeList)
    assert isinstance(body, InterfaceBody)
    super(Interface, self).__init__(name, **kwargs)
    self.attribute_list = attribute_list
    self.body = body

  def __eq__(self, other):
    return super(Interface, self).__eq__(other) and \
           self.attribute_list == other.attribute_list and \
           self.body == other.body


class Method(Definition):
  """Represents a method definition."""

  def __init__(self, name, attribute_list, ordinal, parameter_list,
               response_parameter_list, **kwargs):
    assert attribute_list is None or isinstance(attribute_list, AttributeList)
    assert ordinal is None or isinstance(ordinal, Ordinal)
    assert isinstance(parameter_list, ParameterList)
    assert response_parameter_list is None or \
           isinstance(response_parameter_list, ParameterList)
    super(Method, self).__init__(name, **kwargs)
    self.attribute_list = attribute_list
    self.ordinal = ordinal
    self.parameter_list = parameter_list
    self.response_parameter_list = response_parameter_list

  def __eq__(self, other):
    return super(Method, self).__eq__(other) and \
           self.attribute_list == other.attribute_list and \
           self.ordinal == other.ordinal and \
           self.parameter_list == other.parameter_list and \
           self.response_parameter_list == other.response_parameter_list


# This needs to be declared after |Method|.
class InterfaceBody(NodeListBase):
  """Represents the body of (i.e., list of definitions inside) an interface."""

  _list_item_type = (Const, Enum, Method)


class Module(NodeBase):
  """Represents a module statement."""

  def __init__(self, name, attribute_list, **kwargs):
    # |name| is either none or a "wrapped identifier".
    assert name is None or isinstance(name, tuple)
    assert attribute_list is None or isinstance(attribute_list, AttributeList)
    super(Module, self).__init__(**kwargs)
    self.name = name
    self.attribute_list = attribute_list

  def __eq__(self, other):
    return super(Module, self).__eq__(other) and \
           self.name == other.name and \
           self.attribute_list == other.attribute_list


class Mojom(NodeBase):
  """Represents an entire .mojom file. (This is the root node.)"""

  def __init__(self, module, import_list, definition_list, **kwargs):
    assert module is None or isinstance(module, Module)
    assert isinstance(import_list, ImportList)
    assert isinstance(definition_list, list)
    super(Mojom, self).__init__(**kwargs)
    self.module = module
    self.import_list = import_list
    self.definition_list = definition_list

  def __eq__(self, other):
    return super(Mojom, self).__eq__(other) and \
           self.module == other.module and \
           self.import_list == other.import_list and \
           self.definition_list == other.definition_list

  def __repr__(self):
    return "%s(%r, %r, %r)" % (self.__class__.__name__, self.module,
                               self.import_list, self.definition_list)


class Ordinal(NodeBase):
  """Represents an ordinal value labeling, e.g., a struct field."""

  def __init__(self, value, **kwargs):
    assert isinstance(value, int)
    super(Ordinal, self).__init__(**kwargs)
    self.value = value

  def __eq__(self, other):
    return super(Ordinal, self).__eq__(other) and \
           self.value == other.value


class Parameter(NodeBase):
  """Represents a method request or response parameter."""

  def __init__(self, name, attribute_list, ordinal, typename, **kwargs):
    assert isinstance(name, str)
    assert attribute_list is None or isinstance(attribute_list, AttributeList)
    assert ordinal is None or isinstance(ordinal, Ordinal)
    assert isinstance(typename, str)
    super(Parameter, self).__init__(**kwargs)
    self.name = name
    self.attribute_list = attribute_list
    self.ordinal = ordinal
    self.typename = typename

  def __eq__(self, other):
    return super(Parameter, self).__eq__(other) and \
           self.name == other.name and \
           self.attribute_list == other.attribute_list and \
           self.ordinal == other.ordinal and \
           self.typename == other.typename


class ParameterList(NodeListBase):
  """Represents a list of (method request or response) parameters."""

  _list_item_type = Parameter


class Struct(Definition):
  """Represents a struct definition."""

  def __init__(self, name, attribute_list, body, **kwargs):
    assert attribute_list is None or isinstance(attribute_list, AttributeList)
    assert isinstance(body, StructBody)
    super(Struct, self).__init__(name, **kwargs)
    self.attribute_list = attribute_list
    self.body = body

  def __eq__(self, other):
    return super(Struct, self).__eq__(other) and \
           self.attribute_list == other.attribute_list and \
           self.body == other.body


class StructField(Definition):
  """Represents a struct field definition."""

  def __init__(self, name, attribute_list, ordinal, typename, default_value,
               **kwargs):
    assert isinstance(name, str)
    assert attribute_list is None or isinstance(attribute_list, AttributeList)
    assert ordinal is None or isinstance(ordinal, Ordinal)
    assert isinstance(typename, str)
    # The optional default value is currently either a value as a string or a
    # "wrapped identifier".
    assert default_value is None or isinstance(default_value, (str, tuple))
    super(StructField, self).__init__(name, **kwargs)
    self.attribute_list = attribute_list
    self.ordinal = ordinal
    self.typename = typename
    self.default_value = default_value

  def __eq__(self, other):
    return super(StructField, self).__eq__(other) and \
           self.attribute_list == other.attribute_list and \
           self.ordinal == other.ordinal and \
           self.typename == other.typename and \
           self.default_value == other.default_value


# This needs to be declared after |StructField|.
class StructBody(NodeListBase):
  """Represents the body of (i.e., list of definitions inside) a struct."""

  _list_item_type = (Const, Enum, StructField)


class Union(Definition):
  """Represents a union definition."""

  def __init__(self, name, attribute_list, body, **kwargs):
    assert attribute_list is None or isinstance(attribute_list, AttributeList)
    assert isinstance(body, UnionBody)
    super(Union, self).__init__(name, **kwargs)
    self.attribute_list = attribute_list
    self.body = body

  def __eq__(self, other):
    return super(Union, self).__eq__(other) and \
           self.attribute_list == other.attribute_list and \
           self.body == other.body


class UnionField(Definition):

  def __init__(self, name, attribute_list, ordinal, typename, **kwargs):
    assert isinstance(name, str)
    assert attribute_list is None or isinstance(attribute_list, AttributeList)
    assert ordinal is None or isinstance(ordinal, Ordinal)
    assert isinstance(typename, str)
    super(UnionField, self).__init__(name, **kwargs)
    self.attribute_list = attribute_list
    self.ordinal = ordinal
    self.typename = typename

  def __eq__(self, other):
    return super(UnionField, self).__eq__(other) and \
           self.attribute_list == other.attribute_list and \
           self.ordinal == other.ordinal and \
           self.typename == other.typename


class UnionBody(NodeListBase):

  _list_item_type = UnionField
