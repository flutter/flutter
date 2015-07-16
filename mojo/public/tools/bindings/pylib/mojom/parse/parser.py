# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Generates a syntax tree from a Mojo IDL file."""

import imp
import os.path
import sys

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
  imp.find_module("ply")
except ImportError:
  sys.path.append(os.path.join(_GetDirAbove("public"), "public/third_party"))
from ply import lex
from ply import yacc

from ..error import Error
from . import ast
from .lexer import Lexer


_MAX_ORDINAL_VALUE = 0xffffffff
_MAX_ARRAY_SIZE = 0xffffffff


class ParseError(Error):
  """Class for errors from the parser."""

  def __init__(self, filename, message, lineno=None, snippet=None):
    Error.__init__(self, filename, message, lineno=lineno,
                   addenda=([snippet] if snippet else None))


# We have methods which look like they could be functions:
# pylint: disable=R0201
class Parser(object):

  def __init__(self, lexer, source, filename):
    self.tokens = lexer.tokens
    self.source = source
    self.filename = filename

  # Names of functions
  #
  # In general, we name functions after the left-hand-side of the rule(s) that
  # they handle. E.g., |p_foo_bar| for a rule |foo_bar : ...|.
  #
  # There may be multiple functions handling rules for the same left-hand-side;
  # then we name the functions |p_foo_bar_N| (for left-hand-side |foo_bar|),
  # where N is a number (numbered starting from 1). Note that using multiple
  # functions is actually more efficient than having single functions handle
  # multiple rules (and, e.g., distinguishing them by examining |len(p)|).
  #
  # It's also possible to have a function handling multiple rules with different
  # left-hand-sides. We do not do this.
  #
  # See http://www.dabeaz.com/ply/ply.html#ply_nn25 for more details.

  # TODO(vtl): Get rid of the braces in the module "statement". (Consider
  # renaming "module" -> "package".) Then we'll be able to have a single rule
  # for root (by making module "optional").
  def p_root_1(self, p):
    """root : """
    p[0] = ast.Mojom(None, ast.ImportList(), [])

  def p_root_2(self, p):
    """root : root module"""
    if p[1].module is not None:
      raise ParseError(self.filename,
                       "Multiple \"module\" statements not allowed:",
                       p[2].lineno, snippet=self._GetSnippet(p[2].lineno))
    if p[1].import_list.items or p[1].definition_list:
      raise ParseError(
          self.filename,
          "\"module\" statements must precede imports and definitions:",
          p[2].lineno, snippet=self._GetSnippet(p[2].lineno))
    p[0] = p[1]
    p[0].module = p[2]

  def p_root_3(self, p):
    """root : root import"""
    if p[1].definition_list:
      raise ParseError(self.filename,
                       "\"import\" statements must precede definitions:",
                       p[2].lineno, snippet=self._GetSnippet(p[2].lineno))
    p[0] = p[1]
    p[0].import_list.Append(p[2])

  def p_root_4(self, p):
    """root : root definition"""
    p[0] = p[1]
    p[0].definition_list.append(p[2])

  def p_import(self, p):
    """import : IMPORT STRING_LITERAL SEMI"""
    # 'eval' the literal to strip the quotes.
    # TODO(vtl): This eval is dubious. We should unquote/unescape ourselves.
    p[0] = ast.Import(eval(p[2]), filename=self.filename, lineno=p.lineno(2))

  def p_module(self, p):
    """module : attribute_section MODULE identifier_wrapped SEMI"""
    p[0] = ast.Module(p[3], p[1], filename=self.filename, lineno=p.lineno(2))

  def p_definition(self, p):
    """definition : struct
                  | union
                  | interface
                  | enum
                  | const"""
    p[0] = p[1]

  def p_attribute_section_1(self, p):
    """attribute_section : """
    p[0] = None

  def p_attribute_section_2(self, p):
    """attribute_section : LBRACKET attribute_list RBRACKET"""
    p[0] = p[2]

  def p_attribute_list_1(self, p):
    """attribute_list : """
    p[0] = ast.AttributeList()

  def p_attribute_list_2(self, p):
    """attribute_list : nonempty_attribute_list"""
    p[0] = p[1]

  def p_nonempty_attribute_list_1(self, p):
    """nonempty_attribute_list : attribute"""
    p[0] = ast.AttributeList(p[1])

  def p_nonempty_attribute_list_2(self, p):
    """nonempty_attribute_list : nonempty_attribute_list COMMA attribute"""
    p[0] = p[1]
    p[0].Append(p[3])

  def p_attribute(self, p):
    """attribute : NAME EQUALS evaled_literal
                 | NAME EQUALS NAME"""
    p[0] = ast.Attribute(p[1], p[3], filename=self.filename, lineno=p.lineno(1))

  def p_evaled_literal(self, p):
    """evaled_literal : literal"""
    # 'eval' the literal to strip the quotes.
    p[0] = eval(p[1])

  def p_struct(self, p):
    """struct : attribute_section STRUCT NAME LBRACE struct_body RBRACE SEMI"""
    p[0] = ast.Struct(p[3], p[1], p[5])

  def p_struct_body_1(self, p):
    """struct_body : """
    p[0] = ast.StructBody()

  def p_struct_body_2(self, p):
    """struct_body : struct_body const
                   | struct_body enum
                   | struct_body struct_field"""
    p[0] = p[1]
    p[0].Append(p[2])

  def p_struct_field(self, p):
    """struct_field : attribute_section typename NAME ordinal default SEMI"""
    p[0] = ast.StructField(p[3], p[1], p[4], p[2], p[5])

  def p_union(self, p):
    """union : attribute_section UNION NAME LBRACE union_body RBRACE SEMI"""
    p[0] = ast.Union(p[3], p[1], p[5])

  def p_union_body_1(self, p):
    """union_body : """
    p[0] = ast.UnionBody()

  def p_union_body_2(self, p):
    """union_body : union_body union_field"""
    p[0] = p[1]
    p[1].Append(p[2])

  def p_union_field(self, p):
    """union_field : attribute_section typename NAME ordinal SEMI"""
    p[0] = ast.UnionField(p[3], p[1], p[4], p[2])

  def p_default_1(self, p):
    """default : """
    p[0] = None

  def p_default_2(self, p):
    """default : EQUALS constant"""
    p[0] = p[2]

  def p_interface(self, p):
    """interface : attribute_section INTERFACE NAME LBRACE interface_body \
                       RBRACE SEMI"""
    p[0] = ast.Interface(p[3], p[1], p[5])

  def p_interface_body_1(self, p):
    """interface_body : """
    p[0] = ast.InterfaceBody()

  def p_interface_body_2(self, p):
    """interface_body : interface_body const
                      | interface_body enum
                      | interface_body method"""
    p[0] = p[1]
    p[0].Append(p[2])

  def p_response_1(self, p):
    """response : """
    p[0] = None

  def p_response_2(self, p):
    """response : RESPONSE LPAREN parameter_list RPAREN"""
    p[0] = p[3]

  def p_method(self, p):
    """method : attribute_section NAME ordinal LPAREN parameter_list RPAREN \
                    response SEMI"""
    p[0] = ast.Method(p[2], p[1], p[3], p[5], p[7])

  def p_parameter_list_1(self, p):
    """parameter_list : """
    p[0] = ast.ParameterList()

  def p_parameter_list_2(self, p):
    """parameter_list : nonempty_parameter_list"""
    p[0] = p[1]

  def p_nonempty_parameter_list_1(self, p):
    """nonempty_parameter_list : parameter"""
    p[0] = ast.ParameterList(p[1])

  def p_nonempty_parameter_list_2(self, p):
    """nonempty_parameter_list : nonempty_parameter_list COMMA parameter"""
    p[0] = p[1]
    p[0].Append(p[3])

  def p_parameter(self, p):
    """parameter : attribute_section typename NAME ordinal"""
    p[0] = ast.Parameter(p[3], p[1], p[4], p[2],
                         filename=self.filename, lineno=p.lineno(3))

  def p_typename(self, p):
    """typename : nonnullable_typename QSTN
                | nonnullable_typename"""
    if len(p) == 2:
      p[0] = p[1]
    else:
      p[0] = p[1] + "?"

  def p_nonnullable_typename(self, p):
    """nonnullable_typename : basictypename
                            | array
                            | fixed_array
                            | associative_array
                            | interfacerequest"""
    p[0] = p[1]

  def p_basictypename(self, p):
    """basictypename : identifier
                     | handletype"""
    p[0] = p[1]

  def p_handletype(self, p):
    """handletype : HANDLE
                  | HANDLE LANGLE NAME RANGLE"""
    if len(p) == 2:
      p[0] = p[1]
    else:
      if p[3] not in ('data_pipe_consumer',
                      'data_pipe_producer',
                      'message_pipe',
                      'shared_buffer'):
        # Note: We don't enable tracking of line numbers for everything, so we
        # can't use |p.lineno(3)|.
        raise ParseError(self.filename, "Invalid handle type %r:" % p[3],
                         lineno=p.lineno(1),
                         snippet=self._GetSnippet(p.lineno(1)))
      p[0] = "handle<" + p[3] + ">"

  def p_array(self, p):
    """array : ARRAY LANGLE typename RANGLE"""
    p[0] = p[3] + "[]"

  def p_fixed_array(self, p):
    """fixed_array : ARRAY LANGLE typename COMMA INT_CONST_DEC RANGLE"""
    value = int(p[5])
    if value == 0 or value > _MAX_ARRAY_SIZE:
      raise ParseError(self.filename, "Fixed array size %d invalid:" % value,
                       lineno=p.lineno(5),
                       snippet=self._GetSnippet(p.lineno(5)))
    p[0] = p[3] + "[" + p[5] + "]"

  def p_associative_array(self, p):
    """associative_array : MAP LANGLE identifier COMMA typename RANGLE"""
    p[0] = p[5] + "{" + p[3] + "}"

  def p_interfacerequest(self, p):
    """interfacerequest : identifier AMP"""
    p[0] = p[1] + "&"

  def p_ordinal_1(self, p):
    """ordinal : """
    p[0] = None

  def p_ordinal_2(self, p):
    """ordinal : ORDINAL"""
    value = int(p[1][1:])
    if value > _MAX_ORDINAL_VALUE:
      raise ParseError(self.filename, "Ordinal value %d too large:" % value,
                       lineno=p.lineno(1),
                       snippet=self._GetSnippet(p.lineno(1)))
    p[0] = ast.Ordinal(value, filename=self.filename, lineno=p.lineno(1))

  def p_enum(self, p):
    """enum : attribute_section ENUM NAME LBRACE nonempty_enum_value_list \
                  RBRACE SEMI
            | attribute_section ENUM NAME LBRACE nonempty_enum_value_list \
                  COMMA RBRACE SEMI"""
    p[0] = ast.Enum(p[3], p[1], p[5], filename=self.filename,
                    lineno=p.lineno(2))

  def p_nonempty_enum_value_list_1(self, p):
    """nonempty_enum_value_list : enum_value"""
    p[0] = ast.EnumValueList(p[1])

  def p_nonempty_enum_value_list_2(self, p):
    """nonempty_enum_value_list : nonempty_enum_value_list COMMA enum_value"""
    p[0] = p[1]
    p[0].Append(p[3])

  def p_enum_value(self, p):
    """enum_value : attribute_section NAME
                  | attribute_section NAME EQUALS int
                  | attribute_section NAME EQUALS identifier_wrapped"""
    p[0] = ast.EnumValue(p[2], p[1], p[4] if len(p) == 5 else None,
                         filename=self.filename, lineno=p.lineno(2))

  def p_const(self, p):
    """const : CONST typename NAME EQUALS constant SEMI"""
    p[0] = ast.Const(p[3], p[2], p[5])

  def p_constant(self, p):
    """constant : literal
                | identifier_wrapped"""
    p[0] = p[1]

  def p_identifier_wrapped(self, p):
    """identifier_wrapped : identifier"""
    p[0] = ('IDENTIFIER', p[1])

  # TODO(vtl): Make this produce a "wrapped" identifier (probably as an
  # |ast.Identifier|, to be added) and get rid of identifier_wrapped.
  def p_identifier(self, p):
    """identifier : NAME
                  | NAME DOT identifier"""
    p[0] = ''.join(p[1:])

  def p_literal(self, p):
    """literal : int
               | float
               | TRUE
               | FALSE
               | DEFAULT
               | STRING_LITERAL"""
    p[0] = p[1]

  def p_int(self, p):
    """int : int_const
           | PLUS int_const
           | MINUS int_const"""
    p[0] = ''.join(p[1:])

  def p_int_const(self, p):
    """int_const : INT_CONST_DEC
                 | INT_CONST_HEX"""
    p[0] = p[1]

  def p_float(self, p):
    """float : FLOAT_CONST
             | PLUS FLOAT_CONST
             | MINUS FLOAT_CONST"""
    p[0] = ''.join(p[1:])

  def p_error(self, e):
    if e is None:
      # Unexpected EOF.
      # TODO(vtl): Can we figure out what's missing?
      raise ParseError(self.filename, "Unexpected end of file")

    raise ParseError(self.filename, "Unexpected %r:" % e.value, lineno=e.lineno,
                     snippet=self._GetSnippet(e.lineno))

  def _GetSnippet(self, lineno):
    return self.source.split('\n')[lineno - 1]


def Parse(source, filename):
  lexer = Lexer(filename)
  parser = Parser(lexer, source, filename)

  lex.lex(object=lexer)
  yacc.yacc(module=parser, debug=0, write_tables=0)

  tree = yacc.parse(source)
  return tree
