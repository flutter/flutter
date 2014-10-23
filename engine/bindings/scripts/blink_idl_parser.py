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

"""Parser for Blink IDL.

The parser uses the PLY (Python Lex-Yacc) library to build a set of parsing
rules which understand the Blink dialect of Web IDL.
It derives from a standard Web IDL parser, overriding rules where Blink IDL
differs syntactically or semantically from the base parser, or where the base
parser diverges from the Web IDL standard.

Web IDL:
    http://www.w3.org/TR/WebIDL/
Web IDL Grammar:
    http://www.w3.org/TR/WebIDL/#idl-grammar
PLY:
    http://www.dabeaz.com/ply/

Design doc:
http://www.chromium.org/developers/design-documents/idl-compiler#TOC-Front-end
"""

# Disable check for line length and Member as Function due to how grammar rules
# are defined with PLY
#
# pylint: disable=R0201
# pylint: disable=C0301
#
# Disable attribute validation, as lint can't import parent class to check
# pylint: disable=E1101

import os.path
import sys

# PLY is in Chromium src/third_party/ply
module_path, module_name = os.path.split(__file__)
third_party = os.path.join(module_path, os.pardir, os.pardir, os.pardir, os.pardir, 'third_party')
# Insert at front to override system libraries, and after path[0] == script dir
sys.path.insert(1, third_party)
from ply import yacc

# Base parser is in Chromium src/tools/idl_parser
tools_dir = os.path.join(module_path, os.pardir, os.pardir, os.pardir, os.pardir, 'tools')
sys.path.append(tools_dir)
from idl_parser.idl_parser import IDLParser, ListFromConcat
from idl_parser.idl_parser import ParseFile as parse_file

from blink_idl_lexer import BlinkIDLLexer
import blink_idl_lexer


# Explicitly set starting symbol to rule defined only in base parser.
# BEWARE that the starting symbol should NOT be defined in both the base parser
# and the derived one, as otherwise which is used depends on which line number
# is lower, which is fragile. Instead, either use one in base parser or
# create a new symbol, so that this is unambiguous.
# FIXME: unfortunately, this doesn't work in PLY 3.4, so need to duplicate the
# rule below.
STARTING_SYMBOL = 'Definitions'

# We ignore comments (and hence don't need 'Top') but base parser preserves them
# FIXME: Upstream: comments should be removed in base parser
REMOVED_RULES = ['Top',  # [0]
                 'Comments',  # [0.1]
                 'CommentsRest',  # [0.2]
                ]

# Remove rules from base class
# FIXME: add a class method upstream: @classmethod IDLParser._RemoveRules
for rule in REMOVED_RULES:
    production_name = 'p_' + rule
    delattr(IDLParser, production_name)


class BlinkIDLParser(IDLParser):
    # [1]
    # FIXME: Need to duplicate rule for starting symbol here, with line number
    # *lower* than in the base parser (idl_parser.py).
    # This is a bug in PLY: it determines starting symbol by lowest line number.
    # This can be overridden by the 'start' parameter, but as of PLY 3.4 this
    # doesn't work correctly.
    def p_Definitions(self, p):
        """Definitions : ExtendedAttributeList Definition Definitions
                       | """
        if len(p) > 1:
            p[2].AddChildren(p[1])
            p[0] = ListFromConcat(p[2], p[3])

    # Below are grammar rules used by yacc, given by functions named p_<RULE>.
    # * The docstring is the production rule in BNF (grammar).
    # * The body is the yacc action (semantics).
    #
    # The PLY framework builds the actual low-level parser by introspecting this
    # parser object, selecting all attributes named p_<RULE> as grammar rules.
    # It extracts the docstrings and uses them as the production rules, building
    # the table of a LALR parser, and uses the body of the functions as actions.
    #
    # Reference:
    # http://www.dabeaz.com/ply/ply.html#ply_nn23
    #
    # Review of yacc:
    # Yacc parses a token stream, internally producing a Concrete Syntax Tree
    # (CST), where each node corresponds to a production rule in the grammar.
    # At each node, it runs an action, which is usually "produce a node in the
    # Abstract Syntax Tree (AST)" or "ignore this node" (for nodes in the CST
    # that aren't included in the AST, since only needed for parsing).
    #
    # The rules use pseudo-variables; in PLY syntax:
    # p[0] is the left side: assign return value to p[0] instead of returning,
    # p[1] ... p[n] are the right side: the values can be accessed, and they
    # can be modified.
    # (In yacc these are $$ and $1 ... $n.)
    #
    # The rules can look cryptic at first, but there are a few standard
    # transforms from the CST to AST. With these in mind, the actions should
    # be reasonably legible.
    #
    # * Ignore production
    #   Discard this branch. Primarily used when one alternative is empty.
    #
    #   Sample code:
    #   if len(p) > 1:
    #       p[0] = ...
    #   # Note no assignment if len(p) == 1
    #
    # * Eliminate singleton production
    #   Discard this node in the CST, pass the next level down up the tree.
    #   Used to ignore productions only necessary for parsing, but not needed
    #   in the AST.
    #
    #   Sample code:
    #   p[0] = p[1]
    #
    # * Build node
    #   The key type of rule. In this parser, produces object of class IDLNode.
    #   There are several helper functions:
    #   * BuildProduction: actually builds an IDLNode, based on a production.
    #   * BuildAttribute: builds an IDLAttribute, which is a temporary
    #                     object to hold a name-value pair, which is then
    #                     set as a Property of the IDLNode when the IDLNode
    #                     is built.
    #   * BuildNamed: Same as BuildProduction, and sets the 'NAME' property.
    #   * BuildTrue: BuildAttribute with value True, for flags.
    #   See base idl_parser.py for definitions and more examples of use.
    #
    #   Sample code:
    #   # Build node of type NodeType, with value p[1], and children.
    #   p[0] = self.BuildProduction('NodeType', p, 1, children)
    #
    #   # Build named node of type NodeType, with name and value p[1].
    #   # (children optional)
    #   p[0] = self.BuildNamed('NodeType', p, 1)
    #
    #   # Make a list
    #   # Used if one node has several children.
    #   children = ListFromConcat(p[2], p[3])
    #   p[0] = self.BuildProduction('NodeType', p, 1, children)
    #
    #   # Also used to collapse the right-associative tree
    #   # produced by parsing a list back into a single list.
    #   """Foos : Foo Foos
    #           |"""
    #   if len(p) > 1:
    #       p[0] = ListFromConcat(p[1], p[2])
    #
    #   # Add children.
    #   # Primarily used to add attributes, produced via BuildTrue.
    #   # p_StaticAttribute
    #   """StaticAttribute : STATIC Attribute"""
    #   p[2].AddChildren(self.BuildTrue('STATIC'))
    #   p[0] = p[2]
    #
    # Numbering scheme for the rules is:
    # [1] for Web IDL spec (or additions in base parser)
    #     These should all be upstreamed to the base parser.
    # [b1] for Blink IDL changes (overrides Web IDL)
    # [b1.1] for Blink IDL additions, auxiliary rules for [b1]
    # Numbers are as per Candidate Recommendation 19 April 2012:
    # http://www.w3.org/TR/2012/CR-WebIDL-20120419/

    # [3] Override action, since we distinguish callbacks
    # FIXME: Upstream
    def p_CallbackOrInterface(self, p):
        """CallbackOrInterface : CALLBACK CallbackRestOrInterface
                               | Interface"""
        if len(p) > 2:
            p[2].AddChildren(self.BuildTrue('CALLBACK'))
            p[0] = p[2]
        else:
            p[0] = p[1]

    # [b27] Add strings, more 'Literal' productions
    # 'Literal's needed because integers and strings are both internally strings
    def p_ConstValue(self, p):
        """ConstValue : BooleanLiteral
                      | FloatLiteral
                      | IntegerLiteral
                      | StringLiteral
                      | null"""
        # Standard is (no 'string', fewer 'Literal's):
        # ConstValue : BooleanLiteral
        #            | FloatLiteral
        #            | integer
        #            | NULL
        p[0] = p[1]

    # [b27.1]
    def p_IntegerLiteral(self, p):
        """IntegerLiteral : integer"""
        p[0] = ListFromConcat(self.BuildAttribute('TYPE', 'integer'),
                              self.BuildAttribute('NAME', p[1]))

    # [b27.2]
    def p_StringLiteral(self, p):
        """StringLiteral : string"""
        p[0] = ListFromConcat(self.BuildAttribute('TYPE', 'DOMString'),
                              self.BuildAttribute('NAME', p[1]))

    # [b47]
    def p_ExceptionMember(self, p):
        """ExceptionMember : Const
                           | ExceptionField
                           | Attribute
                           | ExceptionOperation"""
        # Standard is (no Attribute, no ExceptionOperation):
        # ExceptionMember : Const
        #                 | ExceptionField
        # FIXME: In DOMException.idl, Attributes should be changed to
        # ExceptionFields, and Attribute removed from this rule.
        p[0] = p[1]

    # [b47.1]
    def p_ExceptionOperation(self, p):
        """ExceptionOperation : Type identifier '(' ')' ';'"""
        # Needed to handle one case in DOMException.idl:
        # // Override in a Mozilla compatible format
        # [NotEnumerable] DOMString toString();
        # Limited form of Operation to prevent others from being added.
        # FIXME: Should be a stringifier instead.
        p[0] = self.BuildNamed('ExceptionOperation', p, 2, p[1])

    # Extended attributes
    # [b49] Override base parser: remove comment field, since comments stripped
    # FIXME: Upstream
    def p_ExtendedAttributeList(self, p):
        """ExtendedAttributeList : '[' ExtendedAttribute ExtendedAttributes ']'
                                 | '[' ']'
                                 | """
        if len(p) > 3:
            items = ListFromConcat(p[2], p[3])
            p[0] = self.BuildProduction('ExtAttributes', p, 1, items)

    # [b50] Allow optional trailing comma
    # Blink-only, marked as WONTFIX in Web IDL spec:
    # https://www.w3.org/Bugs/Public/show_bug.cgi?id=22156
    def p_ExtendedAttributes(self, p):
        """ExtendedAttributes : ',' ExtendedAttribute ExtendedAttributes
                              | ','
                              |"""
        if len(p) > 3:
            p[0] = ListFromConcat(p[2], p[3])

    # [b51] Add ExtendedAttributeStringLiteral and ExtendedAttributeStringLiteralList
    def p_ExtendedAttribute(self, p):
        """ExtendedAttribute : ExtendedAttributeNoArgs
                             | ExtendedAttributeArgList
                             | ExtendedAttributeIdent
                             | ExtendedAttributeIdentList
                             | ExtendedAttributeNamedArgList
                             | ExtendedAttributeStringLiteral
                             | ExtendedAttributeStringLiteralList"""
        p[0] = p[1]

    # [59]
    # FIXME: Upstream UnionType
    def p_UnionType(self, p):
        """UnionType : '(' UnionMemberType OR UnionMemberType UnionMemberTypes ')'"""
        members = ListFromConcat(p[2], p[4], p[5])
        p[0] = self.BuildProduction('UnionType', p, 1, members)

    # [60]
    def p_UnionMemberType(self, p):
        """UnionMemberType : NonAnyType
                           | UnionType TypeSuffix
                           | ANY '[' ']' TypeSuffix"""
        if len(p) == 2:
            p[0] = self.BuildProduction('Type', p, 1, p[1])
        elif len(p) == 3:
            p[0] = self.BuildProduction('Type', p, 1, ListFromConcat(p[1], p[2]))
        else:
            any_node = ListFromConcat(self.BuildProduction('Any', p, 1), p[4])
            p[0] = self.BuildProduction('Type', p, 1, any_node)

    # [61]
    def p_UnionMemberTypes(self, p):
        """UnionMemberTypes : OR UnionMemberType UnionMemberTypes
                            |"""
        if len(p) > 2:
            p[0] = ListFromConcat(p[2], p[3])

    # [70] Override base parser to remove non-standard sized array
    # FIXME: Upstream
    def p_TypeSuffix(self, p):
        """TypeSuffix : '[' ']' TypeSuffix
                      | '?' TypeSuffixStartingWithArray
                      |"""
        if len(p) == 4:
            p[0] = self.BuildProduction('Array', p, 1, p[3])
        elif len(p) == 3:
            p[0] = ListFromConcat(self.BuildTrue('NULLABLE'), p[2])

    # Blink extension: Add support for string literal Extended Attribute values
    def p_ExtendedAttributeStringLiteral(self, p):
        """ExtendedAttributeStringLiteral : identifier '=' StringLiteral """
        def unwrap_string(ls):
            """Reach in and grab the string literal's "NAME"."""
            return ls[1].value

        value = self.BuildAttribute('VALUE', unwrap_string(p[3]))
        p[0] = self.BuildNamed('ExtAttribute', p, 1, value)

    # Blink extension: Add support for compound Extended Attribute values over string literals ("A","B")
    def p_ExtendedAttributeStringLiteralList(self, p):
        """ExtendedAttributeStringLiteralList : identifier '=' '(' StringLiteralList ')' """
        value = self.BuildAttribute('VALUE', p[4])
        p[0] = self.BuildNamed('ExtAttribute', p, 1, value)

    # Blink extension: one or more string literals. The values aren't propagated as literals,
    # but their by their value only.
    def p_StringLiteralList(self, p):
        """StringLiteralList : StringLiteral ',' StringLiteralList
                             | StringLiteral"""
        def unwrap_string(ls):
            """Reach in and grab the string literal's "NAME"."""
            return ls[1].value

        if len(p) > 3:
            p[0] = ListFromConcat(unwrap_string(p[1]), p[3])
        else:
            p[0] = ListFromConcat(unwrap_string(p[1]))

    def __init__(self,
                 # common parameters
                 debug=False,
                 # local parameters
                 rewrite_tables=False,
                 # idl_parser parameters
                 lexer=None, verbose=False, mute_error=False,
                 # yacc parameters
                 outputdir='', optimize=True, write_tables=False,
                 picklefile=None):
        if debug:
            # Turn off optimization and caching, and write out tables,
            # to help debugging
            optimize = False
            outputdir = None
            picklefile = None
            write_tables = True
        if outputdir:
            picklefile = picklefile or os.path.join(outputdir, 'parsetab.pickle')
            if rewrite_tables:
                try:
                    os.unlink(picklefile)
                except OSError:
                    pass

        lexer = lexer or BlinkIDLLexer(debug=debug,
                                       outputdir=outputdir,
                                       optimize=optimize)
        self.lexer = lexer
        self.tokens = lexer.KnownTokens()
        # Using SLR (instead of LALR) generates the table faster,
        # but produces the same output. This is ok b/c Web IDL (and Blink IDL)
        # is an SLR grammar (as is often the case for simple LL(1) grammars).
        #
        # Optimized mode substantially decreases startup time (by disabling
        # error checking), and also allows use of Python's optimized mode.
        # See: Using Python's Optimized Mode
        # http://www.dabeaz.com/ply/ply.html#ply_nn38
        #
        # |picklefile| allows simpler importing than |tabmodule| (parsetab.py),
        # as we don't need to modify sys.path; virtually identical speed.
        # See: CHANGES, Version 3.2
        # http://ply.googlecode.com/svn/trunk/CHANGES
        self.yaccobj = yacc.yacc(module=self,
                                 start=STARTING_SYMBOL,
                                 method='SLR',
                                 debug=debug,
                                 optimize=optimize,
                                 write_tables=write_tables,
                                 picklefile=picklefile)
        self.parse_debug = debug
        self.verbose = verbose
        self.mute_error = mute_error
        self._parse_errors = 0
        self._parse_warnings = 0
        self._last_error_msg = None
        self._last_error_lineno = 0
        self._last_error_pos = 0


################################################################################

def main(argv):
    # If file itself executed, cache lex/parse tables
    try:
        outputdir = argv[1]
    except IndexError as err:
        print 'Usage: %s OUTPUT_DIR' % argv[0]
        return 1
    blink_idl_lexer.main(argv)
    # Important: rewrite_tables=True causes the cache file to be deleted if it
    # exists, thus making sure that PLY doesn't load it instead of regenerating
    # the parse table.
    parser = BlinkIDLParser(outputdir=outputdir, rewrite_tables=True)


if __name__ == '__main__':
    sys.exit(main(sys.argv))
