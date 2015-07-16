#!/usr/bin/env python
# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

""" Lexer for PPAPI IDL

The lexer uses the PLY library to build a tokenizer which understands both
WebIDL and Pepper tokens.

WebIDL, and WebIDL regular expressions can be found at:
   http://www.w3.org/TR/2012/CR-WebIDL-20120419/
PLY can be found at:
   http://www.dabeaz.com/ply/
"""

from idl_lexer import IDLLexer


#
# IDL PPAPI Lexer
#
class IDLPPAPILexer(IDLLexer):
  # Token definitions
  #
  # These need to be methods for lexer construction, despite not using self.
  # pylint: disable=R0201

  # Special multi-character operators
  def t_LSHIFT(self, t):
    r'<<'
    return t

  def t_RSHIFT(self, t):
    r'>>'
    return t

  def t_INLINE(self, t):
    r'\#inline (.|\n)*?\#endinl.*'
    self.AddLines(t.value.count('\n'))
    return t

  # Return a "preprocessor" inline block
  def __init__(self):
    IDLLexer.__init__(self)
    self._AddTokens(['INLINE', 'LSHIFT', 'RSHIFT'])
    self._AddKeywords(['label', 'struct'])

    # Add number types
    self._AddKeywords(['char', 'int8_t', 'int16_t', 'int32_t', 'int64_t'])
    self._AddKeywords(['uint8_t', 'uint16_t', 'uint32_t', 'uint64_t'])
    self._AddKeywords(['double_t', 'float_t'])

    # Add handle types
    self._AddKeywords(['handle_t', 'PP_FileHandle'])

    # Add pointer types (void*, char*, const char*, const void*)
    self._AddKeywords(['mem_t', 'str_t', 'cstr_t', 'interface_t'])

    # Remove JS types
    self._DelKeywords(['boolean', 'byte', 'ByteString', 'Date', 'DOMString',
                       'double', 'float', 'long', 'object', 'octet', 'Promise',
                       'RegExp', 'short', 'unsigned'])


# If run by itself, attempt to build the lexer
if __name__ == '__main__':
  lexer = IDLPPAPILexer()
  lexer.Tokenize(open('test_parser/inline_ppapi.idl').read())
  for tok in lexer.GetTokens():
    print '\n' + str(tok)
