# Copyright (C) 2013 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""Lexer for Blink IDL.

The lexer uses the PLY (Python Lex-Yacc) library to build a tokenizer which
understands the Blink dialect of Web IDL and produces a token stream suitable
for the Blink IDL parser.

Blink IDL is identical to Web IDL at the token level, but the base lexer
does not discard comments. We need to override (and not include comments in
the token stream), as otherwise comments must be explicitly included in the
phrase grammar of the parser.

FIXME: Change base lexer to discard comments, and simply used the base
lexer, eliminating this separate lexer.

Web IDL:
    http://www.w3.org/TR/WebIDL/
Web IDL Grammar:
    http://www.w3.org/TR/WebIDL/#idl-grammar
PLY:
    http://www.dabeaz.com/ply/

Design doc:
http://www.chromium.org/developers/design-documents/idl-compiler#TOC-Front-end
"""

# Disable attribute validation, as lint can't import parent class to check
# pylint: disable=E1101

import os.path
import sys

# PLY is in Chromium src/third_party/ply
module_path, module_name = os.path.split(__file__)
third_party = os.path.join(module_path, os.pardir, os.pardir, os.pardir, os.pardir)
# Insert at front to override system libraries, and after path[0] == script dir
sys.path.insert(1, third_party)
from ply import lex

# Base lexer is in Chromium src/tools/idl_parser
tools_dir = os.path.join(third_party, os.pardir, 'tools')
sys.path.append(tools_dir)
from idl_parser.idl_lexer import IDLLexer

LEXTAB = 'lextab'
REMOVE_TOKENS = ['COMMENT']


class BlinkIDLLexer(IDLLexer):
    # ignore comments
    def t_COMMENT(self, t):
        r'(/\*(.|\n)*?\*/)|(//.*(\n[ \t]*//.*)*)'
        self.AddLines(t.value.count('\n'))

    # Analogs to _AddToken/_AddTokens in base lexer
    # Needed to remove COMMENT token, since comments ignored
    def _RemoveToken(self, token):
        if token in self.tokens:
            self.tokens.remove(token)

    def _RemoveTokens(self, tokens):
        for token in tokens:
            self._RemoveToken(token)

    def __init__(self, debug=False, optimize=True, outputdir=None,
                 rewrite_tables=False):
        if debug:
            # Turn off optimization and caching to help debugging
            optimize = False
            outputdir = None
        if outputdir:
            # Need outputdir in path because lex imports the cached lex table
            # as a Python module
            sys.path.append(outputdir)

            if rewrite_tables:
                tablefile_root = os.path.join(outputdir, LEXTAB)
                # Also remove the .pyc/.pyo files, or they'll be used even if
                # the .py file doesn't exist.
                for ext in ('.py', '.pyc', '.pyo'):
                    try:
                        os.unlink(tablefile_root + ext)
                    except OSError:
                        pass

        IDLLexer.__init__(self)
        # Overrides to parent class
        self._RemoveTokens(REMOVE_TOKENS)
        # Optimized mode substantially decreases startup time (by disabling
        # error checking), and also allows use of Python's optimized mode.
        # See: Optimized Mode
        # http://www.dabeaz.com/ply/ply.html#ply_nn15
        self._lexobj = lex.lex(object=self,
                               debug=debug,
                               optimize=optimize,
                               lextab=LEXTAB,
                               outputdir=outputdir)


################################################################################

def main(argv):
    # If file itself executed, build and cache lex table
    try:
        outputdir = argv[1]
    except IndexError as err:
        print 'Usage: %s OUTPUT_DIR' % argv[0]
        return 1
    # Important: rewrite_tables=True causes the cache file to be deleted if it
    # exists, thus making sure that PLY doesn't load it instead of regenerating
    # the parse table.
    lexer = BlinkIDLLexer(outputdir=outputdir, rewrite_tables=True)


if __name__ == '__main__':
    sys.exit(main(sys.argv))
