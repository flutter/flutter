#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import sys

import idl_definitions
from idl_types import IdlType, IdlUnionType, IdlArrayOrSequenceType

from compute_interfaces_info_overall import interfaces_info


new_asts = {}


_operation_suffix_map = {
  '__getter__': "Getter",
  '__setter__': "Setter",
  '__delete__': "Deleter",
}

class IDLNode(object):
  """Base class for all IDL elements.
  IDLNode may contain various child nodes, and have properties. Examples
  of IDLNode are interfaces, interface members, function arguments,
  etc.
  """

  def __init__(self, ast):
    """Initializes an IDLNode from a PegParser AST output."""
    self.id = self._find_first(ast, 'Id') if ast is not None else None


  def __repr__(self):
    """Generates string of the form <class id extra extra ... 0x12345678>."""
    extras = self._extra_repr()
    if isinstance(extras, list):
      extras = ' '.join([str(e) for e in extras])
    try:
      if self.id:
        return '<%s %s 0x%x>' % (
            type(self).__name__,
            ('%s %s' % (self.id, extras)).strip(),
            hash(self))
      return '<%s %s 0x%x>' % (
          type(self).__name__,
          extras,
          hash(self))
    except Exception, e:
      return "can't convert to string: %s" % e

  def _extra_repr(self):
    """Returns string of extra info for __repr__()."""
    return ''

  def __cmp__(self, other):
    """Override default compare operation.
    IDLNodes are equal if all their properties are equal."""
    if other is None or not isinstance(other, IDLNode):
      return 1
    return self.__dict__.__cmp__(other.__dict__)

  def reset_id(self, newId):
    """Reset the id of the Node.  This is typically done during a normalization
    phase (e.g., "DOMWindow" -> "Window")."""
    self.id = newId

  def all(self, type_filter=None):
    """Returns a list containing this node and all it child nodes
    (recursive).

    Args:
      type_filter -- can be used to limit the results to a specific
        node type (e.g. IDLOperation).
    """
    res = []
    if type_filter is None or isinstance(self, type_filter):
      res.append(self)
    for v in self._all_subnodes():
      if isinstance(v, IDLNode):
        res.extend(v.all(type_filter))
      elif isinstance(v, list):
        for item in v:
          if isinstance(item, IDLNode):
            res.extend(item.all(type_filter))
    return res

  def _all_subnodes(self):
    """Accessor used by all() to find subnodes."""
    return self.__dict__.values()

  def to_dict(self):
    """Converts the IDLNode and its children into a dictionary.
    This method is useful mostly for debugging and pretty printing.
    """
    res = {}
    for (k, v) in self.__dict__.items():
      if v == None or v == False or v == [] or v == {}:
        # Skip empty/false members.
        continue
      elif isinstance(v, IDLDictNode) and not len(v):
        # Skip empty dict sub-nodes.
        continue
      elif isinstance(v, list):
        # Convert lists:
        new_v = []
        for sub_node in v:
          if isinstance(sub_node, IDLNode):
            # Convert sub-node:
            new_v.append(sub_node.to_dict())
          else:
            new_v.append(sub_node)
        v = new_v
      elif isinstance(v, IDLNode):
        # Convert sub-node:
        v = v.to_dict()
      res[k] = v
    return res

  def _find_all(self, ast, label, max_results=sys.maxint):
    """Searches the AST for tuples with a given label. The PegParser
    output is composed of lists and tuples, where the tuple 1st argument
    is a label. If ast root is a list, will search recursively inside each
    member in the list.

    Args:
      ast -- the AST to search.
      label -- the label to look for.
      res -- results are put into this list.
      max_results -- maximum number of results.
    """
    res = []
    if max_results <= 0:
      return res

    if isinstance(ast, list):
      for childAst in ast:
        if childAst and \
           not(isinstance(childAst, dict)) and \
           not(isinstance(childAst, str)) and \
           not(isinstance(childAst, tuple)) and \
           childAst.__module__ == "idl_definitions":
          field_name = self._convert_label_to_field(label)
          if hasattr(childAst, field_name):
            field_value = getattr(childAst, field_name)
            # It's an IdlType we need the string name of the type.
            if field_name == 'idl_type':
              field_value =  getattr(field_value, 'base_type')
            res.append(field_value)
        else:
          sub_res = self._find_all(childAst, label,
                       max_results - len(res))
          res.extend(sub_res)
    elif isinstance(ast, tuple):
      (nodeLabel, value) = ast
      if nodeLabel == label:
        res.append(value)
    # TODO(terry): Seems bogus to check for so many things probably better to just
    #              pass in blink_compile and drive it off from that...
    elif (ast and not(isinstance(ast, dict)) and
          not(isinstance(ast, str)) and
          (ast.__module__ == "idl_definitions" or ast.__module__ == "idl_types")):
      field_name = self._convert_label_to_field(label)
      if hasattr(ast, field_name):
        field_value = getattr(ast, field_name)
        if field_value:
          if label == 'Interface' or label == 'Enum':
            for key in field_value:
              value = field_value[key]
              res.append(value)
          elif isinstance(field_value, list):
            for item in field_value:
              res.append(item)
          elif label == 'ParentInterface' or label == 'InterfaceType':
            # Fetch the AST for the parent interface.
            parent_idlnode = new_asts[field_value]
            res.append(parent_idlnode.interfaces[field_value])
          else:
            res.append(field_value)

    return res

  def _find_first(self, ast, label):
    """Convenience method for _find_all(..., max_results=1).
    Returns a single element instead of a list, or None if nothing
    is found."""
    res = self._find_all(ast, label, max_results=1)
    if len(res):
      return res[0]
    return None

  def _has(self, ast, label):
    """Returns true if an element with the given label is
    in the AST by searching for it."""
    return len(self._find_all(ast, label, max_results=1)) == 1

  # Mapping from original AST tuple names to new AST field names idl_definitions.Idl*.
  def _convert_label_to_field(self, label):
    label_field = {
      # Keys old AST names, Values Blink IdlInterface names.
      'ParentInterface': 'parent',
      'Id': 'name',
      'Interface': 'interfaces',
      'Callback': 'is_callback',
      'Partial': 'is_partial',
      'Operation': 'operations',
      'Attribute': 'attributes',
      'Const': 'constants',
      'Type': 'idl_type',
      'ExtAttrs':  'extended_attributes',
      'Special': 'specials',
      'ReturnType': 'idl_type',
      'Argument': 'arguments',
      'InterfaceType': 'name',
      'ConstExpr': 'value',
      'Static': 'is_static',
      'ReadOnly': 'is_read_only',
      'Optional': 'is_optional',
      'Nullable': 'is_nullable',
      'Enum': 'enumerations',
      'Annotation': '',         # TODO(terry): Ignore annotation used for database cache.
      'TypeDef': '',            # typedef in an IDL are already resolved.
    }
    result = label_field.get(label)
    if result != '' and not(result):
      print 'FATAL ERROR: AST mapping name not found %s.' % label
    return result if result else ''

  def _convert_all(self, ast, label, idlnode_ctor):
    """Converts AST elements into IDLNode elements.
    Uses _find_all to find elements with a given label and converts
    them into IDLNodes with a given constructor.
    Returns:
      A list of the converted nodes.
    Args:
      ast -- the ast element to start a search at.
      label -- the element label to look for.
      idlnode_ctor -- a constructor function of one of the IDLNode
        sub-classes.
    """
    res = []
    found = self._find_all(ast, label)
    if not found:
      return res
    if not isinstance(found, list):
      raise RuntimeError("Expected list but %s found" % type(found))
    for childAst in found:
      converted = idlnode_ctor(childAst)
      res.append(converted)
    return res

  def _convert_first(self, ast, label, idlnode_ctor):
    """Like _convert_all, but only converts the first found results."""
    childAst = self._find_first(ast, label)
    if not childAst:
      return None
    return idlnode_ctor(childAst)

  def _convert_ext_attrs(self, ast):
    """Helper method for uniform conversion of extended attributes."""
    self.ext_attrs = IDLExtAttrs(ast)

  def _convert_annotations(self, ast):
    """Helper method for uniform conversion of annotations."""
    self.annotations = IDLAnnotations(ast)


class IDLDictNode(IDLNode):
  """Base class for dictionary-like IDL nodes such as extended attributes
  and annotations. The base class implements various dict interfaces."""

  def __init__(self, ast):
    IDLNode.__init__(self, None)
    if ast is not None and isinstance(ast, dict):
      self.__map = ast
    else:
      self.__map = {}

  def __len__(self):
    return len(self.__map)

  def __getitem__(self, key):
    return self.__map[key]

  def __setitem__(self, key, value):
    self.__map[key] = value

  def __delitem__(self, key):
    del self.__map[key]

  def __contains__(self, key):
    return key in self.__map

  def __iter__(self):
    return self.__map.__iter__()

  def get(self, key, default=None):
    return self.__map.get(key, default)

  def setdefault(self, key, value=None):
    return self.__map.setdefault(key, value)

  def items(self):
    return self.__map.items()

  def keys(self):
    return self.__map.keys()

  def values(self):
    return self.__map.values()

  def clear(self):
    self.__map = {}

  def to_dict(self):
    """Overrides the default IDLNode.to_dict behavior.
    The IDLDictNode members are copied into a new dictionary, and
    IDLNode members are recursively converted into dicts as well.
    """
    res = {}
    for (k, v) in self.__map.items():
      if isinstance(v, IDLNode):
        v = v.to_dict()
      res[k] = v
    return res

  def _all_subnodes(self):
    # Usually an IDLDictNode does not contain further IDLNodes.
    return []


class IDLFile(IDLNode):
  """IDLFile is the top-level node in each IDL file. It may contain interfaces."""

  DART_IDL = 'dart.idl'

  def __init__(self, ast, filename=None):
    IDLNode.__init__(self, ast)
    self.filename = filename

    filename_basename = os.path.basename(filename)

    self.interfaces = self._convert_all(ast, 'Interface', IDLInterface)

    is_blink = not(isinstance(ast, list)) and ast.__module__ == 'idl_definitions'

    if is_blink:
      # implements is handled by the interface merging step (see the function
      # merge_interface_dependencies).
      for interface in self.interfaces:
        blink_interface = ast.interfaces.get(interface.id)
        if filename_basename == self.DART_IDL:
          # Special handling for dart.idl we need to remember the interface,
          # since we could have many (not one interface / file). Then build up
          # the IDLImplementsStatement for any implements in dart.idl.
          interface_info = interfaces_info['__dart_idl___'];

          self.implementsStatements = []

          implement_pairs = interface_info['implement_pairs']
          for implement_pair in implement_pairs:
            interface_name = implement_pair[0]
            implemented_name = implement_pair[1]

            implementor = new_asts[interface_name].interfaces.get(interface_name)
            implement_statement = self._createImplementsStatement(implementor,
                                                                  implemented_name)

            self.implementsStatements.append(implement_statement)
        else:
          interface_info = interfaces_info[interface.id]

          implements = interface_info['implements_interfaces']
          if not(blink_interface.is_partial) and len(implements) > 0:
            implementor = new_asts[interface.id].interfaces.get(interface.id)

            self.implementsStatements = []

            # TODO(terry): Need to handle more than one implements.
            for implemented_name in implements:
              implement_statement = self._createImplementsStatement(implementor,
                                                                    implemented_name)
              self.implementsStatements.append(implement_statement)
          else:
            self.implementsStatements = []
    else:
      self.implementsStatements = self._convert_all(ast, 'ImplStmt',
        IDLImplementsStatement)

    # No reason to handle typedef they're already aliased in Blink's AST.
    self.typeDefs = [] if is_blink else self._convert_all(ast, 'TypeDef', IDLTypeDef)

    self.enums = self._convert_all(ast, 'Enum', IDLEnum)

  def _createImplementsStatement(self, implementor, implemented_name):
    implemented = new_asts[implemented_name].interfaces.get(implemented_name)

    implement_statement = IDLImplementsStatement(implemented)

    implement_statement.implementor = IDLType(implementor)
    implement_statement.implemented = IDLType(implemented)

    return implement_statement


class IDLModule(IDLNode):
  """IDLModule has an id, and may contain interfaces, type defs and
  implements statements."""
  def __init__(self, ast):
    IDLNode.__init__(self, ast)
    self._convert_ext_attrs(ast)
    self._convert_annotations(ast)
    self.interfaces = self._convert_all(ast, 'Interface', IDLInterface)

    is_blink = ast.__module__ == 'idl_definitions'

    # No reason to handle typedef they're already aliased in Blink's AST.
    self.typeDefs = [] if is_blink else self._convert_all(ast, 'TypeDef', IDLTypeDef)

    self.enums = self._convert_all(ast, 'Enum', IDLNode)

    if is_blink:
      # implements is handled by the interface merging step (see the function
      # merge_interface_dependencies).
      for interface in self.interfaces:
        interface_info = interfaces_info[interface.id]
        # TODO(terry): Same handling for implementsStatements as in IDLFile?
        self.implementsStatements = interface_info['implements_interfaces']
    else:
      self.implementsStatements = self._convert_all(ast, 'ImplStmt',
        IDLImplementsStatement)


class IDLExtAttrs(IDLDictNode):
  """IDLExtAttrs is an IDLDictNode that stores IDL Extended Attributes.
  Modules, interfaces, members and arguments can all own IDLExtAttrs."""
  def __init__(self, ast=None):
    IDLDictNode.__init__(self, None)
    if not ast:
      return
    if not(isinstance(ast, list)) and ast.__module__ == "idl_definitions":
      # Pull out extended attributes from Blink AST.
      for name, value in ast.extended_attributes.items():
        # TODO(terry): Handle constructors...
        if name == 'NamedConstructor' or name == 'Constructor':
          for constructor in ast.constructors:
            if constructor.name == 'NamedConstructor':
              constructor_name = ast.extended_attributes['NamedConstructor']
            else:
              constructor_name = None
            func_value = IDLExtAttrFunctionValue(constructor_name, constructor.arguments, True)
            if name == 'Constructor':
              self.setdefault('Constructor', []).append(func_value)
            else:
              self[name] = func_value
        else:
          self[name] = value
    else:
      ext_attrs_ast = self._find_first(ast, 'ExtAttrs')
      if not ext_attrs_ast:
        return
      for ext_attr in self._find_all(ext_attrs_ast, 'ExtAttr'):
        name = self._find_first(ext_attr, 'Id')
        value = self._find_first(ext_attr, 'ExtAttrValue')

        if name == 'Constructor':
          # There might be multiple constructor attributes, collect them
          # as a list.  Represent plain Constructor attribute
          # (without any signature) as None.
          assert value is None
          func_value = None
          ctor_args = self._find_first(ext_attr, 'ExtAttrArgList')
          if ctor_args:
            func_value = IDLExtAttrFunctionValue(None, ctor_args)
          self.setdefault('Constructor', []).append(func_value)
          continue

        func_value = self._find_first(value, 'ExtAttrFunctionValue')
        if func_value:
          # E.g. NamedConstructor=Audio(optional DOMString src)
          self[name] = IDLExtAttrFunctionValue(
              func_value,
              self._find_first(func_value, 'ExtAttrArgList'))
          continue

        self[name] = value

  def _all_subnodes(self):
    # Extended attributes may contain IDLNodes, e.g. IDLExtAttrFunctionValue
    return self.values()


class IDLExtAttrFunctionValue(IDLNode):
  """IDLExtAttrFunctionValue."""
  def __init__(self, func_value_ast, arg_list_ast, is_blink=False):
    IDLNode.__init__(self, func_value_ast)
    if is_blink:
      # Blink path
      self.id = func_value_ast   # func_value_ast is the function name for Blink.
      self.arguments = []
      for argument in arg_list_ast:
        self.arguments.append(IDLArgument(argument))
    else:
      self.arguments = self._convert_all(arg_list_ast, 'Argument', IDLArgument)


class IDLType(IDLNode):
  """IDLType is used to describe constants, attributes and operations'
  return and input types. IDLType matches AST labels such as ScopedName,
  StringType, VoidType, IntegerType, etc."""

  def __init__(self, ast):
    IDLNode.__init__(self, ast)

    self.nullable = self._has(ast, 'Nullable')
    # Search for a 'ScopedName' or any label ending with 'Type'.
    if isinstance(ast, list):
      self.id = self._find_first(ast, 'ScopedName')
      if not self.id:
        # FIXME: use regexp search instead
        def findType(ast):
          for label, childAst in ast:
            if label.endswith('Type'):
              type = self._label_to_type(label, ast)
              if type != 'sequence':
                return type
              type_ast = self._find_first(childAst, 'Type')
              if not type_ast:
                return type
              return 'sequence<%s>' % findType(type_ast)
          raise Exception('No type declaration found in %s' % ast)
        self.id = findType(ast)
      # TODO(terry): Remove array_modifiers id has [] appended, keep for old
      #              parsing.
      array_modifiers = self._find_first(ast, 'ArrayModifiers')
      if array_modifiers:
        self.id += array_modifiers
    elif isinstance(ast, tuple):
      (label, value) = ast
      if label == 'ScopedName':
        self.id = value
      else:
        self.id = self._label_to_type(label, ast)
    elif isinstance(ast, str):
      self.id = ast
    # New blink handling.
    elif ast.__module__ == "idl_types":
      if isinstance(ast, IdlType) or isinstance(ast, IdlArrayOrSequenceType):
        type_name = str(ast)

        # TODO(terry): For now don't handle unrestricted types see
        #              https://code.google.com/p/chromium/issues/detail?id=354298
        type_name = type_name.replace('unrestricted ', '', 1);

        # TODO(terry): Handled ScalarValueString as a DOMString.
        type_name = type_name.replace('ScalarValueString', 'DOMString', 1)

        self.id = type_name
      else:
        # IdlUnionType
        if ast.is_union_type:
          print 'WARNING type %s is union mapped to \'any\'' % self.id
        # TODO(terry): For union types use any otherwise type is unionType is
        #              not found and is removed during merging.
        self.id = 'any'
        # TODO(terry): Any union type e.g. 'type1 or type2 or type2',
        #                            'typedef (Type1 or Type2) UnionType'
        # Is a problem we need to extend IDLType and IDLTypeDef to handle more
        # than one type.
        #
        # Also for typedef's e.g.,
        #                 typedef (Type1 or Type2) UnionType
        # should consider synthesizing a new interface (e.g., UnionType) that's
        # both Type1 and Type2.
    if not self.id:
      print '>>>> __module__ %s' % ast.__module__
      raise SyntaxError('Could not parse type %s' % (ast))

  def _label_to_type(self, label, ast):
    if label == 'LongLongType':
      label = 'long long'
    elif label.endswith('Type'):
      # Omit 'Type' suffix and lowercase the rest.
      label = '%s%s' % (label[0].lower(), label[1:-4])

    # Add unsigned qualifier.
    if self._has(ast, 'Unsigned'):
      label = 'unsigned %s' % label
    return label


class IDLEnum(IDLNode):
  """IDLNode for 'enum [id] { [string]+ }'"""
  def __init__(self, ast):
    IDLNode.__init__(self, ast)
    self._convert_annotations(ast)
    if not(isinstance(ast, list)) and ast.__module__ == "idl_definitions":
      # Blink AST
      self.values = ast.values
    else:
      self.values = self._find_all(ast, 'StringLiteral')

    # TODO(terry): Need to handle emitting of enums for dart:html


class IDLTypeDef(IDLNode):
  """IDLNode for 'typedef [type] [id]' declarations."""
  def __init__(self, ast):
    IDLNode.__init__(self, ast)
    self._convert_annotations(ast)
    self.type = self._convert_first(ast, 'Type', IDLType)


class IDLInterface(IDLNode):
  """IDLInterface node contains operations, attributes, constants,
  as well as parent references."""

  def __init__(self, ast):
    IDLNode.__init__(self, ast)
    self._convert_ext_attrs(ast)
    self._convert_annotations(ast)

    self.parents = self._convert_all(ast, 'ParentInterface',
      IDLParentInterface)

    javascript_interface_name = self.ext_attrs.get('InterfaceName', self.id)
    self.javascript_binding_name = javascript_interface_name
    self.doc_js_name = javascript_interface_name

    if not (self._find_first(ast, 'Callback') is None):
      self.ext_attrs['Callback'] = None
    if not (self._find_first(ast, 'Partial') is None):
      self.is_supplemental = True
      self.ext_attrs['DartSupplemental'] = None

    self.operations = self._convert_all(ast, 'Operation',
      lambda ast: IDLOperation(ast, self.doc_js_name))
    self.attributes = self._convert_all(ast, 'Attribute',
      lambda ast: IDLAttribute(ast, self.doc_js_name))
    self.constants = self._convert_all(ast, 'Const',
      lambda ast: IDLConstant(ast, self.doc_js_name))
    self.is_supplemental = 'DartSupplemental' in self.ext_attrs
    self.is_no_interface_object = 'NoInterfaceObject' in self.ext_attrs


  def reset_id(self, new_id):
    """Reset the id of the Interface and corresponding the JS names."""
    if self.id != new_id:
      self.id = new_id
      self.doc_js_name = new_id
      self.javascript_binding_name = new_id
      for member in self.operations:
        member.doc_js_interface_name = new_id
      for member in self.attributes:
        member.doc_js_interface_name = new_id
      for member in self.constants:
        member.doc_js_interface_name = new_id

  def has_attribute(self, candidate):
    for attribute in self.attributes:
      if (attribute.id == candidate.id and
          attribute.is_read_only == candidate.is_read_only):
        return True
    return False


class IDLParentInterface(IDLNode):
  """This IDLNode specialization is for 'Interface Child : Parent {}'
  declarations."""
  def __init__(self, ast):
    IDLNode.__init__(self, ast)
    self._convert_annotations(ast)
    self.type = self._convert_first(ast, 'InterfaceType', IDLType)


class IDLMember(IDLNode):
  """A base class for constants, attributes and operations."""

  def __init__(self, ast, doc_js_interface_name):
    IDLNode.__init__(self, ast)

    self.type = self._convert_first(ast, 'Type', IDLType)
    self._convert_ext_attrs(ast)
    self._convert_annotations(ast)
    self.doc_js_interface_name = doc_js_interface_name
    self.is_static = self._has(ast, 'Static')


class IDLOperation(IDLMember):
  """IDLNode specialization for 'type name(args)' declarations."""
  def __init__(self, ast, doc_js_interface_name):
    IDLMember.__init__(self, ast, doc_js_interface_name)

    self.type = self._convert_first(ast, 'ReturnType', IDLType)
    self.arguments = self._convert_all(ast, 'Argument', IDLArgument)
    self.specials = self._find_all(ast, 'Special')
    # Special case: there are getters of the form
    # getter <ReturnType>(args).  For now force the name to be __getter__,
    # but it should be operator[] later.
    if self.id is None:
      if self.specials == ['getter']:
        if self.ext_attrs.get('Custom') == 'PropertyQuery':
          # Handling __propertyQuery__ the extended attribute is:
          # [Custom=PropertyQuery] getter boolean (DOMString name);
          self.id = '__propertyQuery__'
        else:
          self.id = '__getter__'
      elif self.specials == ['setter']:
        self.id = '__setter__'
        # Special case: if it's a setter, ignore 'declared' return type
        self.type = IDLType([('VoidType', None)])
      elif self.specials == ['deleter']:
        self.id = '__delete__'
      else:
        raise Exception('Cannot handle %s: operation has no id' % ast)

      if len(self.arguments) >= 1 and (self.id in _operation_suffix_map) and not self.ext_attrs.get('ImplementedAs'):
        arg = self.arguments[0]
        operation_category = 'Named' if arg.type.id == 'DOMString' else 'Indexed'
        self.ext_attrs.setdefault('ImplementedAs', 'anonymous%s%s' % (operation_category, _operation_suffix_map[self.id]))

  def _extra_repr(self):
    return [self.arguments]

  def SameSignatureAs(self, operation):
    if self.type != operation.type:
      return False
    return [a.type for a in self.arguments] == [a.type for a in operation.arguments]

class IDLAttribute(IDLMember):
  """IDLNode specialization for 'attribute type name' declarations."""
  def __init__(self, ast, doc_js_interface_name):
    IDLMember.__init__(self, ast, doc_js_interface_name)
    self.is_read_only = self._has(ast, 'ReadOnly')
    # There are various ways to define exceptions for attributes:

  def _extra_repr(self):
    extra = []
    if self.is_read_only: extra.append('readonly')
    return extra


class IDLConstant(IDLMember):
  """IDLNode specialization for 'const type name = value' declarations."""
  def __init__(self, ast, doc_js_interface_name):
    IDLMember.__init__(self, ast, doc_js_interface_name)
    self.value = self._find_first(ast, 'ConstExpr')


class IDLArgument(IDLNode):
  """IDLNode specialization for operation arguments."""
  def __init__(self, ast):
    IDLNode.__init__(self, ast)

    self.default_value = None
    self.default_value_is_null = False
    # Handle the 'argType arg = default'. IDL syntax changed from
    # [default=NullString].
    if not isinstance(ast, list):
      if isinstance(ast.default_value, idl_definitions.IdlLiteral) and ast.default_value:
        self.default_value = ast.default_value.value
        self.default_value_is_null = ast.default_value.is_null
      elif 'Default' in ast.extended_attributes:
        # Work around [Default=Undefined] for arguments - only look in the model's
        # default_value
        self.default_value = ast.extended_attributes.get('Default')
        self.default_value_is_null = False

    self.type = self._convert_first(ast, 'Type', IDLType)
    self.optional = self._has(ast, 'Optional')
    self._convert_ext_attrs(ast)
    # TODO(vsm): Recover this from the type instead.
    if 'Callback' in self.type.id:
      self.ext_attrs['Callback'] = None

  def __repr__(self):
    return '<IDLArgument(type = %s, id = %s)>' % (self.type, self.id)


class IDLImplementsStatement(IDLNode):
  """IDLNode specialization for 'IMPLEMENTOR implements IMPLEMENTED' declarations."""
  def __init__(self, ast):
    IDLNode.__init__(self, ast)
    if isinstance(ast, list) or ast.__module__ != 'idl_definitions':
      self.implementor = self._convert_first(ast, 'ImplStmtImplementor', IDLType)
      self.implemented = self._convert_first(ast, 'ImplStmtImplemented', IDLType)


class IDLAnnotations(IDLDictNode):
  """IDLDictNode specialization for a list of FremontCut annotations."""
  def __init__(self, ast=None):
    IDLDictNode.__init__(self, ast)
    self.id = None
    if not ast:
      return
    for annotation in self._find_all(ast, 'Annotation'):
      name = self._find_first(annotation, 'Id')
      value = IDLAnnotation(annotation)
      self[name] = value


class IDLAnnotation(IDLDictNode):
  """IDLDictNode specialization for one annotation."""
  def __init__(self, ast=None):
    IDLDictNode.__init__(self, ast)
    self.id = None
    if not ast:
      return
    for arg in self._find_all(ast, 'AnnotationArg'):
      name = self._find_first(arg, 'Id')
      value = self._find_first(arg, 'AnnotationArgValue')
      self[name] = value
