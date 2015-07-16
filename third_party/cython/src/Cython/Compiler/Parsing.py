# cython: auto_cpdef=True, infer_types=True, language_level=3, py2_import=True
#
#   Parser
#

# This should be done automatically
import cython
cython.declare(Nodes=object, ExprNodes=object, EncodedString=object,
               BytesLiteral=object, StringEncoding=object,
               FileSourceDescriptor=object, lookup_unicodechar=object,
               Future=object, Options=object, error=object, warning=object,
               Builtin=object, ModuleNode=object, Utils=object,
               re=object, _unicode=object, _bytes=object)

import re
from unicodedata import lookup as lookup_unicodechar

from Cython.Compiler.Scanning import PyrexScanner, FileSourceDescriptor
import Nodes
import ExprNodes
import Builtin
import StringEncoding
from StringEncoding import EncodedString, BytesLiteral, _unicode, _bytes
from ModuleNode import ModuleNode
from Errors import error, warning
from Cython import Utils
import Future
import Options

class Ctx(object):
    #  Parsing context
    level = 'other'
    visibility = 'private'
    cdef_flag = 0
    typedef_flag = 0
    api = 0
    overridable = 0
    nogil = 0
    namespace = None
    templates = None
    allow_struct_enum_decorator = False

    def __init__(self, **kwds):
        self.__dict__.update(kwds)

    def __call__(self, **kwds):
        ctx = Ctx()
        d = ctx.__dict__
        d.update(self.__dict__)
        d.update(kwds)
        return ctx

def p_ident(s, message = "Expected an identifier"):
    if s.sy == 'IDENT':
        name = s.systring
        s.next()
        return name
    else:
        s.error(message)

def p_ident_list(s):
    names = []
    while s.sy == 'IDENT':
        names.append(s.systring)
        s.next()
        if s.sy != ',':
            break
        s.next()
    return names

#------------------------------------------
#
#   Expressions
#
#------------------------------------------

def p_binop_operator(s):
    pos = s.position()
    op = s.sy
    s.next()
    return op, pos

def p_binop_expr(s, ops, p_sub_expr):
    n1 = p_sub_expr(s)
    while s.sy in ops:
        op, pos = p_binop_operator(s)
        n2 = p_sub_expr(s)
        n1 = ExprNodes.binop_node(pos, op, n1, n2)
        if op == '/':
            if Future.division in s.context.future_directives:
                n1.truedivision = True
            else:
                n1.truedivision = None # unknown
    return n1

#lambdef: 'lambda' [varargslist] ':' test

def p_lambdef(s, allow_conditional=True):
    # s.sy == 'lambda'
    pos = s.position()
    s.next()
    if s.sy == ':':
        args = []
        star_arg = starstar_arg = None
    else:
        args, star_arg, starstar_arg = p_varargslist(
            s, terminator=':', annotated=False)
    s.expect(':')
    if allow_conditional:
        expr = p_test(s)
    else:
        expr = p_test_nocond(s)
    return ExprNodes.LambdaNode(
        pos, args = args,
        star_arg = star_arg, starstar_arg = starstar_arg,
        result_expr = expr)

#lambdef_nocond: 'lambda' [varargslist] ':' test_nocond

def p_lambdef_nocond(s):
    return p_lambdef(s, allow_conditional=False)

#test: or_test ['if' or_test 'else' test] | lambdef

def p_test(s):
    if s.sy == 'lambda':
        return p_lambdef(s)
    pos = s.position()
    expr = p_or_test(s)
    if s.sy == 'if':
        s.next()
        test = p_or_test(s)
        s.expect('else')
        other = p_test(s)
        return ExprNodes.CondExprNode(pos, test=test, true_val=expr, false_val=other)
    else:
        return expr

#test_nocond: or_test | lambdef_nocond

def p_test_nocond(s):
    if s.sy == 'lambda':
        return p_lambdef_nocond(s)
    else:
        return p_or_test(s)

#or_test: and_test ('or' and_test)*

def p_or_test(s):
    return p_rassoc_binop_expr(s, ('or',), p_and_test)

def p_rassoc_binop_expr(s, ops, p_subexpr):
    n1 = p_subexpr(s)
    if s.sy in ops:
        pos = s.position()
        op = s.sy
        s.next()
        n2 = p_rassoc_binop_expr(s, ops, p_subexpr)
        n1 = ExprNodes.binop_node(pos, op, n1, n2)
    return n1

#and_test: not_test ('and' not_test)*

def p_and_test(s):
    #return p_binop_expr(s, ('and',), p_not_test)
    return p_rassoc_binop_expr(s, ('and',), p_not_test)

#not_test: 'not' not_test | comparison

def p_not_test(s):
    if s.sy == 'not':
        pos = s.position()
        s.next()
        return ExprNodes.NotNode(pos, operand = p_not_test(s))
    else:
        return p_comparison(s)

#comparison: expr (comp_op expr)*
#comp_op: '<'|'>'|'=='|'>='|'<='|'<>'|'!='|'in'|'not' 'in'|'is'|'is' 'not'

def p_comparison(s):
    n1 = p_starred_expr(s)
    if s.sy in comparison_ops:
        pos = s.position()
        op = p_cmp_op(s)
        n2 = p_starred_expr(s)
        n1 = ExprNodes.PrimaryCmpNode(pos,
            operator = op, operand1 = n1, operand2 = n2)
        if s.sy in comparison_ops:
            n1.cascade = p_cascaded_cmp(s)
    return n1

def p_test_or_starred_expr(s):
    if s.sy == '*':
        return p_starred_expr(s)
    else:
        return p_test(s)

def p_starred_expr(s):
    pos = s.position()
    if s.sy == '*':
        starred = True
        s.next()
    else:
        starred = False
    expr = p_bit_expr(s)
    if starred:
        expr = ExprNodes.StarredTargetNode(pos, expr)
    return expr

def p_cascaded_cmp(s):
    pos = s.position()
    op = p_cmp_op(s)
    n2 = p_starred_expr(s)
    result = ExprNodes.CascadedCmpNode(pos,
        operator = op, operand2 = n2)
    if s.sy in comparison_ops:
        result.cascade = p_cascaded_cmp(s)
    return result

def p_cmp_op(s):
    if s.sy == 'not':
        s.next()
        s.expect('in')
        op = 'not_in'
    elif s.sy == 'is':
        s.next()
        if s.sy == 'not':
            s.next()
            op = 'is_not'
        else:
            op = 'is'
    else:
        op = s.sy
        s.next()
    if op == '<>':
        op = '!='
    return op

comparison_ops = cython.declare(set, set([
    '<', '>', '==', '>=', '<=', '<>', '!=',
    'in', 'is', 'not'
]))

#expr: xor_expr ('|' xor_expr)*

def p_bit_expr(s):
    return p_binop_expr(s, ('|',), p_xor_expr)

#xor_expr: and_expr ('^' and_expr)*

def p_xor_expr(s):
    return p_binop_expr(s, ('^',), p_and_expr)

#and_expr: shift_expr ('&' shift_expr)*

def p_and_expr(s):
    return p_binop_expr(s, ('&',), p_shift_expr)

#shift_expr: arith_expr (('<<'|'>>') arith_expr)*

def p_shift_expr(s):
    return p_binop_expr(s, ('<<', '>>'), p_arith_expr)

#arith_expr: term (('+'|'-') term)*

def p_arith_expr(s):
    return p_binop_expr(s, ('+', '-'), p_term)

#term: factor (('*'|'/'|'%') factor)*

def p_term(s):
    return p_binop_expr(s, ('*', '/', '%', '//'), p_factor)

#factor: ('+'|'-'|'~'|'&'|typecast|sizeof) factor | power

def p_factor(s):
    # little indirection for C-ification purposes
    return _p_factor(s)

def _p_factor(s):
    sy = s.sy
    if sy in ('+', '-', '~'):
        op = s.sy
        pos = s.position()
        s.next()
        return ExprNodes.unop_node(pos, op, p_factor(s))
    elif not s.in_python_file:
        if sy == '&':
            pos = s.position()
            s.next()
            arg = p_factor(s)
            return ExprNodes.AmpersandNode(pos, operand = arg)
        elif sy == "<":
            return p_typecast(s)
        elif sy == 'IDENT' and s.systring == "sizeof":
            return p_sizeof(s)
    return p_power(s)

def p_typecast(s):
    # s.sy == "<"
    pos = s.position()
    s.next()
    base_type = p_c_base_type(s)
    is_memslice = isinstance(base_type, Nodes.MemoryViewSliceTypeNode)
    is_template = isinstance(base_type, Nodes.TemplatedTypeNode)
    is_const = isinstance(base_type, Nodes.CConstTypeNode)
    if (not is_memslice and not is_template and not is_const
        and base_type.name is None):
        s.error("Unknown type")
    declarator = p_c_declarator(s, empty = 1)
    if s.sy == '?':
        s.next()
        typecheck = 1
    else:
        typecheck = 0
    s.expect(">")
    operand = p_factor(s)
    if is_memslice:
        return ExprNodes.CythonArrayNode(pos, base_type_node=base_type,
                                         operand=operand)

    return ExprNodes.TypecastNode(pos,
        base_type = base_type,
        declarator = declarator,
        operand = operand,
        typecheck = typecheck)

def p_sizeof(s):
    # s.sy == ident "sizeof"
    pos = s.position()
    s.next()
    s.expect('(')
    # Here we decide if we are looking at an expression or type
    # If it is actually a type, but parsable as an expression,
    # we treat it as an expression here.
    if looking_at_expr(s):
        operand = p_test(s)
        node = ExprNodes.SizeofVarNode(pos, operand = operand)
    else:
        base_type = p_c_base_type(s)
        declarator = p_c_declarator(s, empty = 1)
        node = ExprNodes.SizeofTypeNode(pos,
            base_type = base_type, declarator = declarator)
    s.expect(')')
    return node

def p_yield_expression(s):
    # s.sy == "yield"
    pos = s.position()
    s.next()
    is_yield_from = False
    if s.sy == 'from':
        is_yield_from = True
        s.next()
    if s.sy != ')' and s.sy not in statement_terminators:
        arg = p_testlist(s)
    else:
        if is_yield_from:
            s.error("'yield from' requires a source argument",
                    pos=pos, fatal=False)
        arg = None
    if is_yield_from:
        return ExprNodes.YieldFromExprNode(pos, arg=arg)
    else:
        return ExprNodes.YieldExprNode(pos, arg=arg)

def p_yield_statement(s):
    # s.sy == "yield"
    yield_expr = p_yield_expression(s)
    return Nodes.ExprStatNode(yield_expr.pos, expr=yield_expr)

#power: atom trailer* ('**' factor)*

def p_power(s):
    if s.systring == 'new' and s.peek()[0] == 'IDENT':
        return p_new_expr(s)
    n1 = p_atom(s)
    while s.sy in ('(', '[', '.'):
        n1 = p_trailer(s, n1)
    if s.sy == '**':
        pos = s.position()
        s.next()
        n2 = p_factor(s)
        n1 = ExprNodes.binop_node(pos, '**', n1, n2)
    return n1

def p_new_expr(s):
    # s.systring == 'new'.
    pos = s.position()
    s.next()
    cppclass = p_c_base_type(s)
    return p_call(s, ExprNodes.NewExprNode(pos, cppclass = cppclass))

#trailer: '(' [arglist] ')' | '[' subscriptlist ']' | '.' NAME

def p_trailer(s, node1):
    pos = s.position()
    if s.sy == '(':
        return p_call(s, node1)
    elif s.sy == '[':
        return p_index(s, node1)
    else: # s.sy == '.'
        s.next()
        name = EncodedString( p_ident(s) )
        return ExprNodes.AttributeNode(pos,
            obj = node1, attribute = name)

# arglist:  argument (',' argument)* [',']
# argument: [test '='] test       # Really [keyword '='] test

def p_call_parse_args(s, allow_genexp = True):
    # s.sy == '('
    pos = s.position()
    s.next()
    positional_args = []
    keyword_args = []
    star_arg = None
    starstar_arg = None
    while s.sy not in ('**', ')'):
        if s.sy == '*':
            if star_arg:
                s.error("only one star-arg parameter allowed",
                        pos=s.position())
            s.next()
            star_arg = p_test(s)
        else:
            arg = p_test(s)
            if s.sy == '=':
                s.next()
                if not arg.is_name:
                    s.error("Expected an identifier before '='",
                            pos=arg.pos)
                encoded_name = EncodedString(arg.name)
                keyword = ExprNodes.IdentifierStringNode(
                    arg.pos, value=encoded_name)
                arg = p_test(s)
                keyword_args.append((keyword, arg))
            else:
                if keyword_args:
                    s.error("Non-keyword arg following keyword arg",
                            pos=arg.pos)
                if star_arg:
                    s.error("Non-keyword arg following star-arg",
                            pos=arg.pos)
                positional_args.append(arg)
        if s.sy != ',':
            break
        s.next()

    if s.sy == 'for':
        if len(positional_args) == 1 and not star_arg:
            positional_args = [ p_genexp(s, positional_args[0]) ]
    elif s.sy == '**':
        s.next()
        starstar_arg = p_test(s)
        if s.sy == ',':
            s.next()
    s.expect(')')
    return positional_args, keyword_args, star_arg, starstar_arg

def p_call_build_packed_args(pos, positional_args, keyword_args,
                             star_arg, starstar_arg):
    arg_tuple = None
    keyword_dict = None
    if positional_args or not star_arg:
        arg_tuple = ExprNodes.TupleNode(pos,
            args = positional_args)
    if star_arg:
        star_arg_tuple = ExprNodes.AsTupleNode(pos, arg = star_arg)
        if arg_tuple:
            arg_tuple = ExprNodes.binop_node(pos,
                operator = '+', operand1 = arg_tuple,
                operand2 = star_arg_tuple)
        else:
            arg_tuple = star_arg_tuple
    if keyword_args or starstar_arg:
        keyword_args = [ExprNodes.DictItemNode(pos=key.pos, key=key, value=value)
                          for key, value in keyword_args]
        if starstar_arg:
            keyword_dict = ExprNodes.KeywordArgsNode(
                pos,
                starstar_arg = starstar_arg,
                keyword_args = keyword_args)
        else:
            keyword_dict = ExprNodes.DictNode(
                pos, key_value_pairs = keyword_args)
    return arg_tuple, keyword_dict

def p_call(s, function):
    # s.sy == '('
    pos = s.position()

    positional_args, keyword_args, star_arg, starstar_arg = \
                     p_call_parse_args(s)

    if not (keyword_args or star_arg or starstar_arg):
        return ExprNodes.SimpleCallNode(pos,
            function = function,
            args = positional_args)
    else:
        arg_tuple, keyword_dict = p_call_build_packed_args(
            pos, positional_args, keyword_args, star_arg, starstar_arg)
        return ExprNodes.GeneralCallNode(pos,
            function = function,
            positional_args = arg_tuple,
            keyword_args = keyword_dict)

#lambdef: 'lambda' [varargslist] ':' test

#subscriptlist: subscript (',' subscript)* [',']

def p_index(s, base):
    # s.sy == '['
    pos = s.position()
    s.next()
    subscripts, is_single_value = p_subscript_list(s)
    if is_single_value and len(subscripts[0]) == 2:
        start, stop = subscripts[0]
        result = ExprNodes.SliceIndexNode(pos,
            base = base, start = start, stop = stop)
    else:
        indexes = make_slice_nodes(pos, subscripts)
        if is_single_value:
            index = indexes[0]
        else:
            index = ExprNodes.TupleNode(pos, args = indexes)
        result = ExprNodes.IndexNode(pos,
            base = base, index = index)
    s.expect(']')
    return result

def p_subscript_list(s):
    is_single_value = True
    items = [p_subscript(s)]
    while s.sy == ',':
        is_single_value = False
        s.next()
        if s.sy == ']':
            break
        items.append(p_subscript(s))
    return items, is_single_value

#subscript: '.' '.' '.' | test | [test] ':' [test] [':' [test]]

def p_subscript(s):
    # Parse a subscript and return a list of
    # 1, 2 or 3 ExprNodes, depending on how
    # many slice elements were encountered.
    pos = s.position()
    start = p_slice_element(s, (':',))
    if s.sy != ':':
        return [start]
    s.next()
    stop = p_slice_element(s, (':', ',', ']'))
    if s.sy != ':':
        return [start, stop]
    s.next()
    step = p_slice_element(s, (':', ',', ']'))
    return [start, stop, step]

def p_slice_element(s, follow_set):
    # Simple expression which may be missing iff
    # it is followed by something in follow_set.
    if s.sy not in follow_set:
        return p_test(s)
    else:
        return None

def expect_ellipsis(s):
    s.expect('.')
    s.expect('.')
    s.expect('.')

def make_slice_nodes(pos, subscripts):
    # Convert a list of subscripts as returned
    # by p_subscript_list into a list of ExprNodes,
    # creating SliceNodes for elements with 2 or
    # more components.
    result = []
    for subscript in subscripts:
        if len(subscript) == 1:
            result.append(subscript[0])
        else:
            result.append(make_slice_node(pos, *subscript))
    return result

def make_slice_node(pos, start, stop = None, step = None):
    if not start:
        start = ExprNodes.NoneNode(pos)
    if not stop:
        stop = ExprNodes.NoneNode(pos)
    if not step:
        step = ExprNodes.NoneNode(pos)
    return ExprNodes.SliceNode(pos,
        start = start, stop = stop, step = step)

#atom: '(' [yield_expr|testlist_comp] ')' | '[' [listmaker] ']' | '{' [dict_or_set_maker] '}' | '`' testlist '`' | NAME | NUMBER | STRING+

def p_atom(s):
    pos = s.position()
    sy = s.sy
    if sy == '(':
        s.next()
        if s.sy == ')':
            result = ExprNodes.TupleNode(pos, args = [])
        elif s.sy == 'yield':
            result = p_yield_expression(s)
        else:
            result = p_testlist_comp(s)
        s.expect(')')
        return result
    elif sy == '[':
        return p_list_maker(s)
    elif sy == '{':
        return p_dict_or_set_maker(s)
    elif sy == '`':
        return p_backquote_expr(s)
    elif sy == '.':
        expect_ellipsis(s)
        return ExprNodes.EllipsisNode(pos)
    elif sy == 'INT':
        return p_int_literal(s)
    elif sy == 'FLOAT':
        value = s.systring
        s.next()
        return ExprNodes.FloatNode(pos, value = value)
    elif sy == 'IMAG':
        value = s.systring[:-1]
        s.next()
        return ExprNodes.ImagNode(pos, value = value)
    elif sy == 'BEGIN_STRING':
        kind, bytes_value, unicode_value = p_cat_string_literal(s)
        if kind == 'c':
            return ExprNodes.CharNode(pos, value = bytes_value)
        elif kind == 'u':
            return ExprNodes.UnicodeNode(pos, value = unicode_value, bytes_value = bytes_value)
        elif kind == 'b':
            return ExprNodes.BytesNode(pos, value = bytes_value)
        else:
            return ExprNodes.StringNode(pos, value = bytes_value, unicode_value = unicode_value)
    elif sy == 'IDENT':
        name = EncodedString( s.systring )
        s.next()
        if name == "None":
            return ExprNodes.NoneNode(pos)
        elif name == "True":
            return ExprNodes.BoolNode(pos, value=True)
        elif name == "False":
            return ExprNodes.BoolNode(pos, value=False)
        elif name == "NULL" and not s.in_python_file:
            return ExprNodes.NullNode(pos)
        else:
            return p_name(s, name)
    else:
        s.error("Expected an identifier or literal")

def p_int_literal(s):
    pos = s.position()
    value = s.systring
    s.next()
    unsigned = ""
    longness = ""
    while value[-1] in u"UuLl":
        if value[-1] in u"Ll":
            longness += "L"
        else:
            unsigned += "U"
        value = value[:-1]
    # '3L' is ambiguous in Py2 but not in Py3.  '3U' and '3LL' are
    # illegal in Py2 Python files.  All suffixes are illegal in Py3
    # Python files.
    is_c_literal = None
    if unsigned:
        is_c_literal = True
    elif longness:
        if longness == 'LL' or s.context.language_level >= 3:
            is_c_literal = True
    if s.in_python_file:
        if is_c_literal:
            error(pos, "illegal integer literal syntax in Python source file")
        is_c_literal = False
    return ExprNodes.IntNode(pos,
                             is_c_literal = is_c_literal,
                             value = value,
                             unsigned = unsigned,
                             longness = longness)


def p_name(s, name):
    pos = s.position()
    if not s.compile_time_expr and name in s.compile_time_env:
        value = s.compile_time_env.lookup_here(name)
        node = wrap_compile_time_constant(pos, value)
        if node is not None:
            return node
    return ExprNodes.NameNode(pos, name=name)


def wrap_compile_time_constant(pos, value):
    rep = repr(value)
    if value is None:
        return ExprNodes.NoneNode(pos)
    elif value is Ellipsis:
        return ExprNodes.EllipsisNode(pos)
    elif isinstance(value, bool):
        return ExprNodes.BoolNode(pos, value=value)
    elif isinstance(value, int):
        return ExprNodes.IntNode(pos, value=rep)
    elif isinstance(value, long):
        return ExprNodes.IntNode(pos, value=rep, longness="L")
    elif isinstance(value, float):
        return ExprNodes.FloatNode(pos, value=rep)
    elif isinstance(value, _unicode):
        return ExprNodes.UnicodeNode(pos, value=EncodedString(value))
    elif isinstance(value, _bytes):
        return ExprNodes.BytesNode(pos, value=BytesLiteral(value))
    elif isinstance(value, tuple):
        args = [wrap_compile_time_constant(pos, arg)
                for arg in value]
        if None not in args:
            return ExprNodes.TupleNode(pos, args=args)
        else:
            # error already reported
            return None
    error(pos, "Invalid type for compile-time constant: %r (type %s)"
               % (value, value.__class__.__name__))
    return None


def p_cat_string_literal(s):
    # A sequence of one or more adjacent string literals.
    # Returns (kind, bytes_value, unicode_value)
    # where kind in ('b', 'c', 'u', '')
    kind, bytes_value, unicode_value = p_string_literal(s)
    if kind == 'c' or s.sy != 'BEGIN_STRING':
        return kind, bytes_value, unicode_value
    bstrings, ustrings = [bytes_value], [unicode_value]
    bytes_value = unicode_value = None
    while s.sy == 'BEGIN_STRING':
        pos = s.position()
        next_kind, next_bytes_value, next_unicode_value = p_string_literal(s)
        if next_kind == 'c':
            error(pos, "Cannot concatenate char literal with another string or char literal")
        elif next_kind != kind:
            error(pos, "Cannot mix string literals of different types, expected %s'', got %s''" %
                  (kind, next_kind))
        else:
            bstrings.append(next_bytes_value)
            ustrings.append(next_unicode_value)
    # join and rewrap the partial literals
    if kind in ('b', 'c', '') or kind == 'u' and None not in bstrings:
        # Py3 enforced unicode literals are parsed as bytes/unicode combination
        bytes_value = BytesLiteral( StringEncoding.join_bytes(bstrings) )
        bytes_value.encoding = s.source_encoding
    if kind in ('u', ''):
        unicode_value = EncodedString( u''.join([ u for u in ustrings if u is not None ]) )
    return kind, bytes_value, unicode_value

def p_opt_string_literal(s, required_type='u'):
    if s.sy == 'BEGIN_STRING':
        kind, bytes_value, unicode_value = p_string_literal(s, required_type)
        if required_type == 'u':
            return unicode_value
        elif required_type == 'b':
            return bytes_value
        else:
            s.error("internal parser configuration error")
    else:
        return None

def check_for_non_ascii_characters(string):
    for c in string:
        if c >= u'\x80':
            return True
    return False

def p_string_literal(s, kind_override=None):
    # A single string or char literal.  Returns (kind, bvalue, uvalue)
    # where kind in ('b', 'c', 'u', '').  The 'bvalue' is the source
    # code byte sequence of the string literal, 'uvalue' is the
    # decoded Unicode string.  Either of the two may be None depending
    # on the 'kind' of string, only unprefixed strings have both
    # representations.

    # s.sy == 'BEGIN_STRING'
    pos = s.position()
    is_raw = False
    is_python3_source = s.context.language_level >= 3
    has_non_ASCII_literal_characters = False
    kind = s.systring[:1].lower()
    if kind == 'r':
        # Py3 allows both 'br' and 'rb' as prefix
        if s.systring[1:2].lower() == 'b':
            kind = 'b'
        else:
            kind = ''
        is_raw = True
    elif kind in 'ub':
        is_raw = s.systring[1:2].lower() == 'r'
    elif kind != 'c':
        kind = ''
    if kind == '' and kind_override is None and Future.unicode_literals in s.context.future_directives:
        chars = StringEncoding.StrLiteralBuilder(s.source_encoding)
        kind = 'u'
    else:
        if kind_override is not None and kind_override in 'ub':
            kind = kind_override
        if kind == 'u':
            chars = StringEncoding.UnicodeLiteralBuilder()
        elif kind == '':
            chars = StringEncoding.StrLiteralBuilder(s.source_encoding)
        else:
            chars = StringEncoding.BytesLiteralBuilder(s.source_encoding)

    while 1:
        s.next()
        sy = s.sy
        systr = s.systring
        #print "p_string_literal: sy =", sy, repr(s.systring) ###
        if sy == 'CHARS':
            chars.append(systr)
            if is_python3_source and not has_non_ASCII_literal_characters and check_for_non_ascii_characters(systr):
                has_non_ASCII_literal_characters = True
        elif sy == 'ESCAPE':
            if is_raw:
                chars.append(systr)
                if is_python3_source and not has_non_ASCII_literal_characters \
                       and check_for_non_ascii_characters(systr):
                    has_non_ASCII_literal_characters = True
            else:
                c = systr[1]
                if c in u"01234567":
                    chars.append_charval( int(systr[1:], 8) )
                elif c in u"'\"\\":
                    chars.append(c)
                elif c in u"abfnrtv":
                    chars.append(
                        StringEncoding.char_from_escape_sequence(systr))
                elif c == u'\n':
                    pass
                elif c == u'x':   # \xXX
                    if len(systr) == 4:
                        chars.append_charval( int(systr[2:], 16) )
                    else:
                        s.error("Invalid hex escape '%s'" % systr,
                                fatal=False)
                elif c in u'NUu' and kind in ('u', ''):   # \uxxxx, \Uxxxxxxxx, \N{...}
                    chrval = -1
                    if c == u'N':
                        try:
                            chrval = ord(lookup_unicodechar(systr[3:-1]))
                        except KeyError:
                            s.error("Unknown Unicode character name %s" %
                                    repr(systr[3:-1]).lstrip('u'))
                    elif len(systr) in (6,10):
                        chrval = int(systr[2:], 16)
                        if chrval > 1114111: # sys.maxunicode:
                            s.error("Invalid unicode escape '%s'" % systr)
                            chrval = -1
                    else:
                        s.error("Invalid unicode escape '%s'" % systr,
                                fatal=False)
                    if chrval >= 0:
                        chars.append_uescape(chrval, systr)
                else:
                    chars.append(u'\\' + systr[1:])
                    if is_python3_source and not has_non_ASCII_literal_characters \
                           and check_for_non_ascii_characters(systr):
                        has_non_ASCII_literal_characters = True
        elif sy == 'NEWLINE':
            chars.append(u'\n')
        elif sy == 'END_STRING':
            break
        elif sy == 'EOF':
            s.error("Unclosed string literal", pos=pos)
        else:
            s.error("Unexpected token %r:%r in string literal" %
                    (sy, s.systring))

    if kind == 'c':
        unicode_value = None
        bytes_value = chars.getchar()
        if len(bytes_value) != 1:
            error(pos, u"invalid character literal: %r" % bytes_value)
    else:
        bytes_value, unicode_value = chars.getstrings()
        if is_python3_source and has_non_ASCII_literal_characters:
            # Python 3 forbids literal non-ASCII characters in byte strings
            if kind != 'u':
                s.error("bytes can only contain ASCII literal characters.",
                        pos=pos, fatal=False)
            bytes_value = None
    s.next()
    return (kind, bytes_value, unicode_value)

# list_display      ::=      "[" [listmaker] "]"
# listmaker     ::=     expression ( comp_for | ( "," expression )* [","] )
# comp_iter     ::=     comp_for | comp_if
# comp_for     ::=     "for" expression_list "in" testlist [comp_iter]
# comp_if     ::=     "if" test [comp_iter]

def p_list_maker(s):
    # s.sy == '['
    pos = s.position()
    s.next()
    if s.sy == ']':
        s.expect(']')
        return ExprNodes.ListNode(pos, args = [])
    expr = p_test(s)
    if s.sy == 'for':
        append = ExprNodes.ComprehensionAppendNode(pos, expr=expr)
        loop = p_comp_for(s, append)
        s.expect(']')
        return ExprNodes.ComprehensionNode(
            pos, loop=loop, append=append, type = Builtin.list_type,
            # list comprehensions leak their loop variable in Py2
            has_local_scope = s.context.language_level >= 3)
    else:
        if s.sy == ',':
            s.next()
            exprs = p_simple_expr_list(s, expr)
        else:
            exprs = [expr]
        s.expect(']')
        return ExprNodes.ListNode(pos, args = exprs)

def p_comp_iter(s, body):
    if s.sy == 'for':
        return p_comp_for(s, body)
    elif s.sy == 'if':
        return p_comp_if(s, body)
    else:
        # insert the 'append' operation into the loop
        return body

def p_comp_for(s, body):
    # s.sy == 'for'
    pos = s.position()
    s.next()
    kw = p_for_bounds(s, allow_testlist=False)
    kw.update(else_clause = None, body = p_comp_iter(s, body))
    return Nodes.ForStatNode(pos, **kw)

def p_comp_if(s, body):
    # s.sy == 'if'
    pos = s.position()
    s.next()
    test = p_test_nocond(s)
    return Nodes.IfStatNode(pos,
        if_clauses = [Nodes.IfClauseNode(pos, condition = test,
                                         body = p_comp_iter(s, body))],
        else_clause = None )

#dictmaker: test ':' test (',' test ':' test)* [',']

def p_dict_or_set_maker(s):
    # s.sy == '{'
    pos = s.position()
    s.next()
    if s.sy == '}':
        s.next()
        return ExprNodes.DictNode(pos, key_value_pairs = [])
    item = p_test(s)
    if s.sy == ',' or s.sy == '}':
        # set literal
        values = [item]
        while s.sy == ',':
            s.next()
            if s.sy == '}':
                break
            values.append( p_test(s) )
        s.expect('}')
        return ExprNodes.SetNode(pos, args=values)
    elif s.sy == 'for':
        # set comprehension
        append = ExprNodes.ComprehensionAppendNode(
            item.pos, expr=item)
        loop = p_comp_for(s, append)
        s.expect('}')
        return ExprNodes.ComprehensionNode(
            pos, loop=loop, append=append, type=Builtin.set_type)
    elif s.sy == ':':
        # dict literal or comprehension
        key = item
        s.next()
        value = p_test(s)
        if s.sy == 'for':
            # dict comprehension
            append = ExprNodes.DictComprehensionAppendNode(
                item.pos, key_expr=key, value_expr=value)
            loop = p_comp_for(s, append)
            s.expect('}')
            return ExprNodes.ComprehensionNode(
                pos, loop=loop, append=append, type=Builtin.dict_type)
        else:
            # dict literal
            items = [ExprNodes.DictItemNode(key.pos, key=key, value=value)]
            while s.sy == ',':
                s.next()
                if s.sy == '}':
                    break
                key = p_test(s)
                s.expect(':')
                value = p_test(s)
                items.append(
                    ExprNodes.DictItemNode(key.pos, key=key, value=value))
            s.expect('}')
            return ExprNodes.DictNode(pos, key_value_pairs=items)
    else:
        # raise an error
        s.expect('}')
    return ExprNodes.DictNode(pos, key_value_pairs = [])

# NOTE: no longer in Py3 :)
def p_backquote_expr(s):
    # s.sy == '`'
    pos = s.position()
    s.next()
    args = [p_test(s)]
    while s.sy == ',':
        s.next()
        args.append(p_test(s))
    s.expect('`')
    if len(args) == 1:
        arg = args[0]
    else:
        arg = ExprNodes.TupleNode(pos, args = args)
    return ExprNodes.BackquoteNode(pos, arg = arg)

def p_simple_expr_list(s, expr=None):
    exprs = expr is not None and [expr] or []
    while s.sy not in expr_terminators:
        exprs.append( p_test(s) )
        if s.sy != ',':
            break
        s.next()
    return exprs

def p_test_or_starred_expr_list(s, expr=None):
    exprs = expr is not None and [expr] or []
    while s.sy not in expr_terminators:
        exprs.append( p_test_or_starred_expr(s) )
        if s.sy != ',':
            break
        s.next()
    return exprs


#testlist: test (',' test)* [',']

def p_testlist(s):
    pos = s.position()
    expr = p_test(s)
    if s.sy == ',':
        s.next()
        exprs = p_simple_expr_list(s, expr)
        return ExprNodes.TupleNode(pos, args = exprs)
    else:
        return expr

# testlist_star_expr: (test|star_expr) ( comp_for | (',' (test|star_expr))* [','] )

def p_testlist_star_expr(s):
    pos = s.position()
    expr = p_test_or_starred_expr(s)
    if s.sy == ',':
        s.next()
        exprs = p_test_or_starred_expr_list(s, expr)
        return ExprNodes.TupleNode(pos, args = exprs)
    else:
        return expr

# testlist_comp: (test|star_expr) ( comp_for | (',' (test|star_expr))* [','] )

def p_testlist_comp(s):
    pos = s.position()
    expr = p_test_or_starred_expr(s)
    if s.sy == ',':
        s.next()
        exprs = p_test_or_starred_expr_list(s, expr)
        return ExprNodes.TupleNode(pos, args = exprs)
    elif s.sy == 'for':
        return p_genexp(s, expr)
    else:
        return expr

def p_genexp(s, expr):
    # s.sy == 'for'
    loop = p_comp_for(s, Nodes.ExprStatNode(
        expr.pos, expr = ExprNodes.YieldExprNode(expr.pos, arg=expr)))
    return ExprNodes.GeneratorExpressionNode(expr.pos, loop=loop)

expr_terminators = cython.declare(set, set([
    ')', ']', '}', ':', '=', 'NEWLINE']))

#-------------------------------------------------------
#
#   Statements
#
#-------------------------------------------------------

def p_global_statement(s):
    # assume s.sy == 'global'
    pos = s.position()
    s.next()
    names = p_ident_list(s)
    return Nodes.GlobalNode(pos, names = names)

def p_nonlocal_statement(s):
    pos = s.position()
    s.next()
    names = p_ident_list(s)
    return Nodes.NonlocalNode(pos, names = names)

def p_expression_or_assignment(s):
    expr_list = [p_testlist_star_expr(s)]
    if s.sy == '=' and expr_list[0].is_starred:
        # This is a common enough error to make when learning Cython to let
        # it fail as early as possible and give a very clear error message.
        s.error("a starred assignment target must be in a list or tuple"
                " - maybe you meant to use an index assignment: var[0] = ...",
                pos=expr_list[0].pos)
    while s.sy == '=':
        s.next()
        if s.sy == 'yield':
            expr = p_yield_expression(s)
        else:
            expr = p_testlist_star_expr(s)
        expr_list.append(expr)
    if len(expr_list) == 1:
        if re.match(r"([+*/\%^\&|-]|<<|>>|\*\*|//)=", s.sy):
            lhs = expr_list[0]
            if isinstance(lhs, ExprNodes.SliceIndexNode):
                # implementation requires IndexNode
                lhs = ExprNodes.IndexNode(
                    lhs.pos,
                    base=lhs.base,
                    index=make_slice_node(lhs.pos, lhs.start, lhs.stop))
            elif not isinstance(lhs, (ExprNodes.AttributeNode, ExprNodes.IndexNode, ExprNodes.NameNode) ):
                error(lhs.pos, "Illegal operand for inplace operation.")
            operator = s.sy[:-1]
            s.next()
            if s.sy == 'yield':
                rhs = p_yield_expression(s)
            else:
                rhs = p_testlist(s)
            return Nodes.InPlaceAssignmentNode(lhs.pos, operator = operator, lhs = lhs, rhs = rhs)
        expr = expr_list[0]
        return Nodes.ExprStatNode(expr.pos, expr=expr)

    rhs = expr_list[-1]
    if len(expr_list) == 2:
        return Nodes.SingleAssignmentNode(rhs.pos,
            lhs = expr_list[0], rhs = rhs)
    else:
        return Nodes.CascadedAssignmentNode(rhs.pos,
            lhs_list = expr_list[:-1], rhs = rhs)

def p_print_statement(s):
    # s.sy == 'print'
    pos = s.position()
    ends_with_comma = 0
    s.next()
    if s.sy == '>>':
        s.next()
        stream = p_test(s)
        if s.sy == ',':
            s.next()
            ends_with_comma = s.sy in ('NEWLINE', 'EOF')
    else:
        stream = None
    args = []
    if s.sy not in ('NEWLINE', 'EOF'):
        args.append(p_test(s))
        while s.sy == ',':
            s.next()
            if s.sy in ('NEWLINE', 'EOF'):
                ends_with_comma = 1
                break
            args.append(p_test(s))
    arg_tuple = ExprNodes.TupleNode(pos, args = args)
    return Nodes.PrintStatNode(pos,
        arg_tuple = arg_tuple, stream = stream,
        append_newline = not ends_with_comma)

def p_exec_statement(s):
    # s.sy == 'exec'
    pos = s.position()
    s.next()
    code = p_bit_expr(s)
    if isinstance(code, ExprNodes.TupleNode):
        # Py3 compatibility syntax
        tuple_variant = True
        args = code.args
        if len(args) not in (2, 3):
            s.error("expected tuple of length 2 or 3, got length %d" % len(args),
                    pos=pos, fatal=False)
            args = [code]
    else:
        tuple_variant = False
        args = [code]
    if s.sy == 'in':
        if tuple_variant:
            s.error("tuple variant of exec does not support additional 'in' arguments",
                    fatal=False)
        s.next()
        args.append(p_test(s))
        if s.sy == ',':
            s.next()
            args.append(p_test(s))
    return Nodes.ExecStatNode(pos, args=args)

def p_del_statement(s):
    # s.sy == 'del'
    pos = s.position()
    s.next()
    # FIXME: 'exprlist' in Python
    args = p_simple_expr_list(s)
    return Nodes.DelStatNode(pos, args = args)

def p_pass_statement(s, with_newline = 0):
    pos = s.position()
    s.expect('pass')
    if with_newline:
        s.expect_newline("Expected a newline")
    return Nodes.PassStatNode(pos)

def p_break_statement(s):
    # s.sy == 'break'
    pos = s.position()
    s.next()
    return Nodes.BreakStatNode(pos)

def p_continue_statement(s):
    # s.sy == 'continue'
    pos = s.position()
    s.next()
    return Nodes.ContinueStatNode(pos)

def p_return_statement(s):
    # s.sy == 'return'
    pos = s.position()
    s.next()
    if s.sy not in statement_terminators:
        value = p_testlist(s)
    else:
        value = None
    return Nodes.ReturnStatNode(pos, value = value)

def p_raise_statement(s):
    # s.sy == 'raise'
    pos = s.position()
    s.next()
    exc_type = None
    exc_value = None
    exc_tb = None
    cause = None
    if s.sy not in statement_terminators:
        exc_type = p_test(s)
        if s.sy == ',':
            s.next()
            exc_value = p_test(s)
            if s.sy == ',':
                s.next()
                exc_tb = p_test(s)
        elif s.sy == 'from':
            s.next()
            cause = p_test(s)
    if exc_type or exc_value or exc_tb:
        return Nodes.RaiseStatNode(pos,
            exc_type = exc_type,
            exc_value = exc_value,
            exc_tb = exc_tb,
            cause = cause)
    else:
        return Nodes.ReraiseStatNode(pos)

def p_import_statement(s):
    # s.sy in ('import', 'cimport')
    pos = s.position()
    kind = s.sy
    s.next()
    items = [p_dotted_name(s, as_allowed = 1)]
    while s.sy == ',':
        s.next()
        items.append(p_dotted_name(s, as_allowed = 1))
    stats = []
    for pos, target_name, dotted_name, as_name in items:
        dotted_name = EncodedString(dotted_name)
        if kind == 'cimport':
            stat = Nodes.CImportStatNode(pos,
                module_name = dotted_name,
                as_name = as_name)
        else:
            if as_name and "." in dotted_name:
                name_list = ExprNodes.ListNode(pos, args = [
                        ExprNodes.IdentifierStringNode(pos, value = EncodedString("*"))])
            else:
                name_list = None
            stat = Nodes.SingleAssignmentNode(pos,
                lhs = ExprNodes.NameNode(pos,
                    name = as_name or target_name),
                rhs = ExprNodes.ImportNode(pos,
                    module_name = ExprNodes.IdentifierStringNode(
                        pos, value = dotted_name),
                    level = None,
                    name_list = name_list))
        stats.append(stat)
    return Nodes.StatListNode(pos, stats = stats)

def p_from_import_statement(s, first_statement = 0):
    # s.sy == 'from'
    pos = s.position()
    s.next()
    if s.sy == '.':
        # count relative import level
        level = 0
        while s.sy == '.':
            level += 1
            s.next()
        if s.sy == 'cimport':
            s.error("Relative cimport is not supported yet")
    else:
        level = None
    if level is not None and s.sy == 'import':
        # we are dealing with "from .. import foo, bar"
        dotted_name_pos, dotted_name = s.position(), ''
    elif level is not None and s.sy == 'cimport':
        # "from .. cimport"
        s.error("Relative cimport is not supported yet")
    else:
        (dotted_name_pos, _, dotted_name, _) = \
            p_dotted_name(s, as_allowed = 0)
    if s.sy in ('import', 'cimport'):
        kind = s.sy
        s.next()
    else:
        s.error("Expected 'import' or 'cimport'")

    is_cimport = kind == 'cimport'
    is_parenthesized = False
    if s.sy == '*':
        imported_names = [(s.position(), "*", None, None)]
        s.next()
    else:
        if s.sy == '(':
            is_parenthesized = True
            s.next()
        imported_names = [p_imported_name(s, is_cimport)]
    while s.sy == ',':
        s.next()
        if is_parenthesized and s.sy == ')':
            break
        imported_names.append(p_imported_name(s, is_cimport))
    if is_parenthesized:
        s.expect(')')
    dotted_name = EncodedString(dotted_name)
    if dotted_name == '__future__':
        if not first_statement:
            s.error("from __future__ imports must occur at the beginning of the file")
        elif level is not None:
            s.error("invalid syntax")
        else:
            for (name_pos, name, as_name, kind) in imported_names:
                if name == "braces":
                    s.error("not a chance", name_pos)
                    break
                try:
                    directive = getattr(Future, name)
                except AttributeError:
                    s.error("future feature %s is not defined" % name, name_pos)
                    break
                s.context.future_directives.add(directive)
        return Nodes.PassStatNode(pos)
    elif kind == 'cimport':
        return Nodes.FromCImportStatNode(pos,
            module_name = dotted_name,
            imported_names = imported_names)
    else:
        imported_name_strings = []
        items = []
        for (name_pos, name, as_name, kind) in imported_names:
            encoded_name = EncodedString(name)
            imported_name_strings.append(
                ExprNodes.IdentifierStringNode(name_pos, value = encoded_name))
            items.append(
                (name,
                 ExprNodes.NameNode(name_pos,
                                    name = as_name or name)))
        import_list = ExprNodes.ListNode(
            imported_names[0][0], args = imported_name_strings)
        dotted_name = EncodedString(dotted_name)
        return Nodes.FromImportStatNode(pos,
            module = ExprNodes.ImportNode(dotted_name_pos,
                module_name = ExprNodes.IdentifierStringNode(pos, value = dotted_name),
                level = level,
                name_list = import_list),
            items = items)

imported_name_kinds = cython.declare(
    set, set(['class', 'struct', 'union']))

def p_imported_name(s, is_cimport):
    pos = s.position()
    kind = None
    if is_cimport and s.systring in imported_name_kinds:
        kind = s.systring
        s.next()
    name = p_ident(s)
    as_name = p_as_name(s)
    return (pos, name, as_name, kind)

def p_dotted_name(s, as_allowed):
    pos = s.position()
    target_name = p_ident(s)
    as_name = None
    names = [target_name]
    while s.sy == '.':
        s.next()
        names.append(p_ident(s))
    if as_allowed:
        as_name = p_as_name(s)
    return (pos, target_name, u'.'.join(names), as_name)

def p_as_name(s):
    if s.sy == 'IDENT' and s.systring == 'as':
        s.next()
        return p_ident(s)
    else:
        return None

def p_assert_statement(s):
    # s.sy == 'assert'
    pos = s.position()
    s.next()
    cond = p_test(s)
    if s.sy == ',':
        s.next()
        value = p_test(s)
    else:
        value = None
    return Nodes.AssertStatNode(pos, cond = cond, value = value)

statement_terminators = cython.declare(set, set([';', 'NEWLINE', 'EOF']))

def p_if_statement(s):
    # s.sy == 'if'
    pos = s.position()
    s.next()
    if_clauses = [p_if_clause(s)]
    while s.sy == 'elif':
        s.next()
        if_clauses.append(p_if_clause(s))
    else_clause = p_else_clause(s)
    return Nodes.IfStatNode(pos,
        if_clauses = if_clauses, else_clause = else_clause)

def p_if_clause(s):
    pos = s.position()
    test = p_test(s)
    body = p_suite(s)
    return Nodes.IfClauseNode(pos,
        condition = test, body = body)

def p_else_clause(s):
    if s.sy == 'else':
        s.next()
        return p_suite(s)
    else:
        return None

def p_while_statement(s):
    # s.sy == 'while'
    pos = s.position()
    s.next()
    test = p_test(s)
    body = p_suite(s)
    else_clause = p_else_clause(s)
    return Nodes.WhileStatNode(pos,
        condition = test, body = body,
        else_clause = else_clause)

def p_for_statement(s):
    # s.sy == 'for'
    pos = s.position()
    s.next()
    kw = p_for_bounds(s, allow_testlist=True)
    body = p_suite(s)
    else_clause = p_else_clause(s)
    kw.update(body = body, else_clause = else_clause)
    return Nodes.ForStatNode(pos, **kw)

def p_for_bounds(s, allow_testlist=True):
    target = p_for_target(s)
    if s.sy == 'in':
        s.next()
        iterator = p_for_iterator(s, allow_testlist)
        return dict( target = target, iterator = iterator )
    elif not s.in_python_file:
        if s.sy == 'from':
            s.next()
            bound1 = p_bit_expr(s)
        else:
            # Support shorter "for a <= x < b" syntax
            bound1, target = target, None
        rel1 = p_for_from_relation(s)
        name2_pos = s.position()
        name2 = p_ident(s)
        rel2_pos = s.position()
        rel2 = p_for_from_relation(s)
        bound2 = p_bit_expr(s)
        step = p_for_from_step(s)
        if target is None:
            target = ExprNodes.NameNode(name2_pos, name = name2)
        else:
            if not target.is_name:
                error(target.pos,
                    "Target of for-from statement must be a variable name")
            elif name2 != target.name:
                error(name2_pos,
                    "Variable name in for-from range does not match target")
        if rel1[0] != rel2[0]:
            error(rel2_pos,
                "Relation directions in for-from do not match")
        return dict(target = target,
                    bound1 = bound1,
                    relation1 = rel1,
                    relation2 = rel2,
                    bound2 = bound2,
                    step = step,
                    )
    else:
        s.expect('in')
        return {}

def p_for_from_relation(s):
    if s.sy in inequality_relations:
        op = s.sy
        s.next()
        return op
    else:
        s.error("Expected one of '<', '<=', '>' '>='")

def p_for_from_step(s):
    if s.sy == 'IDENT' and s.systring == 'by':
        s.next()
        step = p_bit_expr(s)
        return step
    else:
        return None

inequality_relations = cython.declare(set, set(['<', '<=', '>', '>=']))

def p_target(s, terminator):
    pos = s.position()
    expr = p_starred_expr(s)
    if s.sy == ',':
        s.next()
        exprs = [expr]
        while s.sy != terminator:
            exprs.append(p_starred_expr(s))
            if s.sy != ',':
                break
            s.next()
        return ExprNodes.TupleNode(pos, args = exprs)
    else:
        return expr

def p_for_target(s):
    return p_target(s, 'in')

def p_for_iterator(s, allow_testlist=True):
    pos = s.position()
    if allow_testlist:
        expr = p_testlist(s)
    else:
        expr = p_or_test(s)
    return ExprNodes.IteratorNode(pos, sequence = expr)

def p_try_statement(s):
    # s.sy == 'try'
    pos = s.position()
    s.next()
    body = p_suite(s)
    except_clauses = []
    else_clause = None
    if s.sy in ('except', 'else'):
        while s.sy == 'except':
            except_clauses.append(p_except_clause(s))
        if s.sy == 'else':
            s.next()
            else_clause = p_suite(s)
        body = Nodes.TryExceptStatNode(pos,
            body = body, except_clauses = except_clauses,
            else_clause = else_clause)
        if s.sy != 'finally':
            return body
        # try-except-finally is equivalent to nested try-except/try-finally
    if s.sy == 'finally':
        s.next()
        finally_clause = p_suite(s)
        return Nodes.TryFinallyStatNode(pos,
            body = body, finally_clause = finally_clause)
    else:
        s.error("Expected 'except' or 'finally'")

def p_except_clause(s):
    # s.sy == 'except'
    pos = s.position()
    s.next()
    exc_type = None
    exc_value = None
    is_except_as = False
    if s.sy != ':':
        exc_type = p_test(s)
        # normalise into list of single exception tests
        if isinstance(exc_type, ExprNodes.TupleNode):
            exc_type = exc_type.args
        else:
            exc_type = [exc_type]
        if s.sy == ',' or (s.sy == 'IDENT' and s.systring == 'as'
                           and s.context.language_level == 2):
            s.next()
            exc_value = p_test(s)
        elif s.sy == 'IDENT' and s.systring == 'as':
            # Py3 syntax requires a name here
            s.next()
            pos2 = s.position()
            name = p_ident(s)
            exc_value = ExprNodes.NameNode(pos2, name = name)
            is_except_as = True
    body = p_suite(s)
    return Nodes.ExceptClauseNode(pos,
        pattern = exc_type, target = exc_value,
        body = body, is_except_as=is_except_as)

def p_include_statement(s, ctx):
    pos = s.position()
    s.next() # 'include'
    unicode_include_file_name = p_string_literal(s, 'u')[2]
    s.expect_newline("Syntax error in include statement")
    if s.compile_time_eval:
        include_file_name = unicode_include_file_name
        include_file_path = s.context.find_include_file(include_file_name, pos)
        if include_file_path:
            s.included_files.append(include_file_name)
            f = Utils.open_source_file(include_file_path, mode="rU")
            source_desc = FileSourceDescriptor(include_file_path)
            s2 = PyrexScanner(f, source_desc, s, source_encoding=f.encoding, parse_comments=s.parse_comments)
            try:
                tree = p_statement_list(s2, ctx)
            finally:
                f.close()
            return tree
        else:
            return None
    else:
        return Nodes.PassStatNode(pos)

def p_with_statement(s):
    s.next() # 'with'
    if s.systring == 'template' and not s.in_python_file:
        node = p_with_template(s)
    else:
        node = p_with_items(s)
    return node

def p_with_items(s):
    pos = s.position()
    if not s.in_python_file and s.sy == 'IDENT' and s.systring in ('nogil', 'gil'):
        state = s.systring
        s.next()
        if s.sy == ',':
            s.next()
            body = p_with_items(s)
        else:
            body = p_suite(s)
        return Nodes.GILStatNode(pos, state = state, body = body)
    else:
        manager = p_test(s)
        target = None
        if s.sy == 'IDENT' and s.systring == 'as':
            s.next()
            target = p_starred_expr(s)
        if s.sy == ',':
            s.next()
            body = p_with_items(s)
        else:
            body = p_suite(s)
    return Nodes.WithStatNode(pos, manager = manager,
                              target = target, body = body)

def p_with_template(s):
    pos = s.position()
    templates = []
    s.next()
    s.expect('[')
    templates.append(s.systring)
    s.next()
    while s.systring == ',':
        s.next()
        templates.append(s.systring)
        s.next()
    s.expect(']')
    if s.sy == ':':
        s.next()
        s.expect_newline("Syntax error in template function declaration")
        s.expect_indent()
        body_ctx = Ctx()
        body_ctx.templates = templates
        func_or_var = p_c_func_or_var_declaration(s, pos, body_ctx)
        s.expect_dedent()
        return func_or_var
    else:
        error(pos, "Syntax error in template function declaration")

def p_simple_statement(s, first_statement = 0):
    #print "p_simple_statement:", s.sy, s.systring ###
    if s.sy == 'global':
        node = p_global_statement(s)
    elif s.sy == 'nonlocal':
        node = p_nonlocal_statement(s)
    elif s.sy == 'print':
        node = p_print_statement(s)
    elif s.sy == 'exec':
        node = p_exec_statement(s)
    elif s.sy == 'del':
        node = p_del_statement(s)
    elif s.sy == 'break':
        node = p_break_statement(s)
    elif s.sy == 'continue':
        node = p_continue_statement(s)
    elif s.sy == 'return':
        node = p_return_statement(s)
    elif s.sy == 'raise':
        node = p_raise_statement(s)
    elif s.sy in ('import', 'cimport'):
        node = p_import_statement(s)
    elif s.sy == 'from':
        node = p_from_import_statement(s, first_statement = first_statement)
    elif s.sy == 'yield':
        node = p_yield_statement(s)
    elif s.sy == 'assert':
        node = p_assert_statement(s)
    elif s.sy == 'pass':
        node = p_pass_statement(s)
    else:
        node = p_expression_or_assignment(s)
    return node

def p_simple_statement_list(s, ctx, first_statement = 0):
    # Parse a series of simple statements on one line
    # separated by semicolons.
    stat = p_simple_statement(s, first_statement = first_statement)
    pos = stat.pos
    stats = []
    if not isinstance(stat, Nodes.PassStatNode):
        stats.append(stat)
    while s.sy == ';':
        #print "p_simple_statement_list: maybe more to follow" ###
        s.next()
        if s.sy in ('NEWLINE', 'EOF'):
            break
        stat = p_simple_statement(s, first_statement = first_statement)
        if isinstance(stat, Nodes.PassStatNode):
            continue
        stats.append(stat)
        first_statement = False

    if not stats:
        stat = Nodes.PassStatNode(pos)
    elif len(stats) == 1:
        stat = stats[0]
    else:
        stat = Nodes.StatListNode(pos, stats = stats)
    s.expect_newline("Syntax error in simple statement list")
    return stat

def p_compile_time_expr(s):
    old = s.compile_time_expr
    s.compile_time_expr = 1
    expr = p_testlist(s)
    s.compile_time_expr = old
    return expr

def p_DEF_statement(s):
    pos = s.position()
    denv = s.compile_time_env
    s.next() # 'DEF'
    name = p_ident(s)
    s.expect('=')
    expr = p_compile_time_expr(s)
    value = expr.compile_time_value(denv)
    #print "p_DEF_statement: %s = %r" % (name, value) ###
    denv.declare(name, value)
    s.expect_newline()
    return Nodes.PassStatNode(pos)

def p_IF_statement(s, ctx):
    pos = s.position()
    saved_eval = s.compile_time_eval
    current_eval = saved_eval
    denv = s.compile_time_env
    result = None
    while 1:
        s.next() # 'IF' or 'ELIF'
        expr = p_compile_time_expr(s)
        s.compile_time_eval = current_eval and bool(expr.compile_time_value(denv))
        body = p_suite(s, ctx)
        if s.compile_time_eval:
            result = body
            current_eval = 0
        if s.sy != 'ELIF':
            break
    if s.sy == 'ELSE':
        s.next()
        s.compile_time_eval = current_eval
        body = p_suite(s, ctx)
        if current_eval:
            result = body
    if not result:
        result = Nodes.PassStatNode(pos)
    s.compile_time_eval = saved_eval
    return result

def p_statement(s, ctx, first_statement = 0):
    cdef_flag = ctx.cdef_flag
    decorators = None
    if s.sy == 'ctypedef':
        if ctx.level not in ('module', 'module_pxd'):
            s.error("ctypedef statement not allowed here")
        #if ctx.api:
        #    error(s.position(), "'api' not allowed with 'ctypedef'")
        return p_ctypedef_statement(s, ctx)
    elif s.sy == 'DEF':
        return p_DEF_statement(s)
    elif s.sy == 'IF':
        return p_IF_statement(s, ctx)
    elif s.sy == 'DECORATOR':
        if ctx.level not in ('module', 'class', 'c_class', 'function', 'property', 'module_pxd', 'c_class_pxd', 'other'):
            s.error('decorator not allowed here')
        s.level = ctx.level
        decorators = p_decorators(s)
        bad_toks =  'def', 'cdef', 'cpdef', 'class'
        if not ctx.allow_struct_enum_decorator and s.sy not in bad_toks:
            s.error("Decorators can only be followed by functions or classes")
    elif s.sy == 'pass' and cdef_flag:
        # empty cdef block
        return p_pass_statement(s, with_newline = 1)

    overridable = 0
    if s.sy == 'cdef':
        cdef_flag = 1
        s.next()
    elif s.sy == 'cpdef':
        cdef_flag = 1
        overridable = 1
        s.next()
    if cdef_flag:
        if ctx.level not in ('module', 'module_pxd', 'function', 'c_class', 'c_class_pxd'):
            s.error('cdef statement not allowed here')
        s.level = ctx.level
        node = p_cdef_statement(s, ctx(overridable = overridable))
        if decorators is not None:
            tup = Nodes.CFuncDefNode, Nodes.CVarDefNode, Nodes.CClassDefNode
            if ctx.allow_struct_enum_decorator:
                tup += Nodes.CStructOrUnionDefNode, Nodes.CEnumDefNode
            if not isinstance(node, tup):
                s.error("Decorators can only be followed by functions or classes")
            node.decorators = decorators
        return node
    else:
        if ctx.api:
            s.error("'api' not allowed with this statement", fatal=False)
        elif s.sy == 'def':
            # def statements aren't allowed in pxd files, except
            # as part of a cdef class
            if ('pxd' in ctx.level) and (ctx.level != 'c_class_pxd'):
                s.error('def statement not allowed here')
            s.level = ctx.level
            return p_def_statement(s, decorators)
        elif s.sy == 'class':
            if ctx.level not in ('module', 'function', 'class', 'other'):
                s.error("class definition not allowed here")
            return p_class_statement(s, decorators)
        elif s.sy == 'include':
            if ctx.level not in ('module', 'module_pxd'):
                s.error("include statement not allowed here")
            return p_include_statement(s, ctx)
        elif ctx.level == 'c_class' and s.sy == 'IDENT' and s.systring == 'property':
            return p_property_decl(s)
        elif s.sy == 'pass' and ctx.level != 'property':
            return p_pass_statement(s, with_newline=True)
        else:
            if ctx.level in ('c_class_pxd', 'property'):
                node = p_ignorable_statement(s)
                if node is not None:
                    return node
                s.error("Executable statement not allowed here")
            if s.sy == 'if':
                return p_if_statement(s)
            elif s.sy == 'while':
                return p_while_statement(s)
            elif s.sy == 'for':
                return p_for_statement(s)
            elif s.sy == 'try':
                return p_try_statement(s)
            elif s.sy == 'with':
                return p_with_statement(s)
            else:
                return p_simple_statement_list(
                    s, ctx, first_statement = first_statement)

def p_statement_list(s, ctx, first_statement = 0):
    # Parse a series of statements separated by newlines.
    pos = s.position()
    stats = []
    while s.sy not in ('DEDENT', 'EOF'):
        stat = p_statement(s, ctx, first_statement = first_statement)
        if isinstance(stat, Nodes.PassStatNode):
            continue
        stats.append(stat)
        first_statement = False
    if not stats:
        return Nodes.PassStatNode(pos)
    elif len(stats) == 1:
        return stats[0]
    else:
        return Nodes.StatListNode(pos, stats = stats)


def p_suite(s, ctx=Ctx()):
    return p_suite_with_docstring(s, ctx, with_doc_only=False)[1]


def p_suite_with_docstring(s, ctx, with_doc_only=False):
    s.expect(':')
    doc = None
    if s.sy == 'NEWLINE':
        s.next()
        s.expect_indent()
        if with_doc_only:
            doc = p_doc_string(s)
        body = p_statement_list(s, ctx)
        s.expect_dedent()
    else:
        if ctx.api:
            s.error("'api' not allowed with this statement", fatal=False)
        if ctx.level in ('module', 'class', 'function', 'other'):
            body = p_simple_statement_list(s, ctx)
        else:
            body = p_pass_statement(s)
            s.expect_newline("Syntax error in declarations")
    if not with_doc_only:
        doc, body = _extract_docstring(body)
    return doc, body


def p_positional_and_keyword_args(s, end_sy_set, templates = None):
    """
    Parses positional and keyword arguments. end_sy_set
    should contain any s.sy that terminate the argument list.
    Argument expansion (* and **) are not allowed.

    Returns: (positional_args, keyword_args)
    """
    positional_args = []
    keyword_args = []
    pos_idx = 0

    while s.sy not in end_sy_set:
        if s.sy == '*' or s.sy == '**':
            s.error('Argument expansion not allowed here.', fatal=False)

        parsed_type = False
        if s.sy == 'IDENT' and s.peek()[0] == '=':
            ident = s.systring
            s.next() # s.sy is '='
            s.next()
            if looking_at_expr(s):
                arg = p_test(s)
            else:
                base_type = p_c_base_type(s, templates = templates)
                declarator = p_c_declarator(s, empty = 1)
                arg = Nodes.CComplexBaseTypeNode(base_type.pos,
                    base_type = base_type, declarator = declarator)
                parsed_type = True
            keyword_node = ExprNodes.IdentifierStringNode(
                arg.pos, value = EncodedString(ident))
            keyword_args.append((keyword_node, arg))
            was_keyword = True

        else:
            if looking_at_expr(s):
                arg = p_test(s)
            else:
                base_type = p_c_base_type(s, templates = templates)
                declarator = p_c_declarator(s, empty = 1)
                arg = Nodes.CComplexBaseTypeNode(base_type.pos,
                    base_type = base_type, declarator = declarator)
                parsed_type = True
            positional_args.append(arg)
            pos_idx += 1
            if len(keyword_args) > 0:
                s.error("Non-keyword arg following keyword arg",
                        pos=arg.pos)

        if s.sy != ',':
            if s.sy not in end_sy_set:
                if parsed_type:
                    s.error("Unmatched %s" % " or ".join(end_sy_set))
            break
        s.next()
    return positional_args, keyword_args

def p_c_base_type(s, self_flag = 0, nonempty = 0, templates = None):
    # If self_flag is true, this is the base type for the
    # self argument of a C method of an extension type.
    if s.sy == '(':
        return p_c_complex_base_type(s, templates = templates)
    else:
        return p_c_simple_base_type(s, self_flag, nonempty = nonempty, templates = templates)

def p_calling_convention(s):
    if s.sy == 'IDENT' and s.systring in calling_convention_words:
        result = s.systring
        s.next()
        return result
    else:
        return ""

calling_convention_words = cython.declare(
    set, set(["__stdcall", "__cdecl", "__fastcall"]))

def p_c_complex_base_type(s, templates = None):
    # s.sy == '('
    pos = s.position()
    s.next()
    base_type = p_c_base_type(s, templates = templates)
    declarator = p_c_declarator(s, empty = 1)
    s.expect(')')
    type_node = Nodes.CComplexBaseTypeNode(pos,
            base_type = base_type, declarator = declarator)
    if s.sy == '[':
        if is_memoryviewslice_access(s):
            type_node = p_memoryviewslice_access(s, type_node)
        else:
            type_node = p_buffer_or_template(s, type_node, templates)
    return type_node


def p_c_simple_base_type(s, self_flag, nonempty, templates = None):
    #print "p_c_simple_base_type: self_flag =", self_flag, nonempty
    is_basic = 0
    signed = 1
    longness = 0
    complex = 0
    module_path = []
    pos = s.position()
    if not s.sy == 'IDENT':
        error(pos, "Expected an identifier, found '%s'" % s.sy)
    if s.systring == 'const':
        s.next()
        base_type = p_c_base_type(s,
            self_flag = self_flag, nonempty = nonempty, templates = templates)
        return Nodes.CConstTypeNode(pos, base_type = base_type)
    if looking_at_base_type(s):
        #print "p_c_simple_base_type: looking_at_base_type at", s.position()
        is_basic = 1
        if s.sy == 'IDENT' and s.systring in special_basic_c_types:
            signed, longness = special_basic_c_types[s.systring]
            name = s.systring
            s.next()
        else:
            signed, longness = p_sign_and_longness(s)
            if s.sy == 'IDENT' and s.systring in basic_c_type_names:
                name = s.systring
                s.next()
            else:
                name = 'int'  # long [int], short [int], long [int] complex, etc.
        if s.sy == 'IDENT' and s.systring == 'complex':
            complex = 1
            s.next()
    elif looking_at_dotted_name(s):
        #print "p_c_simple_base_type: looking_at_type_name at", s.position()
        name = s.systring
        s.next()
        while s.sy == '.':
            module_path.append(name)
            s.next()
            name = p_ident(s)
    else:
        name = s.systring
        s.next()
        if nonempty and s.sy != 'IDENT':
            # Make sure this is not a declaration of a variable or function.
            if s.sy == '(':
                s.next()
                if (s.sy == '*' or s.sy == '**' or s.sy == '&'
                        or (s.sy == 'IDENT' and s.systring in calling_convention_words)):
                    s.put_back('(', '(')
                else:
                    s.put_back('(', '(')
                    s.put_back('IDENT', name)
                    name = None
            elif s.sy not in ('*', '**', '[', '&'):
                s.put_back('IDENT', name)
                name = None

    type_node = Nodes.CSimpleBaseTypeNode(pos,
        name = name, module_path = module_path,
        is_basic_c_type = is_basic, signed = signed,
        complex = complex, longness = longness,
        is_self_arg = self_flag, templates = templates)

    #    declarations here.
    if s.sy == '[':
        if is_memoryviewslice_access(s):
            type_node = p_memoryviewslice_access(s, type_node)
        else:
            type_node = p_buffer_or_template(s, type_node, templates)

    if s.sy == '.':
        s.next()
        name = p_ident(s)
        type_node = Nodes.CNestedBaseTypeNode(pos, base_type = type_node, name = name)

    return type_node

def p_buffer_or_template(s, base_type_node, templates):
    # s.sy == '['
    pos = s.position()
    s.next()
    # Note that buffer_positional_options_count=1, so the only positional argument is dtype.
    # For templated types, all parameters are types.
    positional_args, keyword_args = (
        p_positional_and_keyword_args(s, (']',), templates)
    )
    s.expect(']')

    if s.sy == '[':
        base_type_node = p_buffer_or_template(s, base_type_node, templates)

    keyword_dict = ExprNodes.DictNode(pos,
        key_value_pairs = [
            ExprNodes.DictItemNode(pos=key.pos, key=key, value=value)
            for key, value in keyword_args
        ])
    result = Nodes.TemplatedTypeNode(pos,
        positional_args = positional_args,
        keyword_args = keyword_dict,
        base_type_node = base_type_node)
    return result

def p_bracketed_base_type(s, base_type_node, nonempty, empty):
    # s.sy == '['
    if empty and not nonempty:
        # sizeof-like thing.  Only anonymous C arrays allowed (int[SIZE]).
        return base_type_node
    elif not empty and nonempty:
        # declaration of either memoryview slice or buffer.
        if is_memoryviewslice_access(s):
            return p_memoryviewslice_access(s, base_type_node)
        else:
            return p_buffer_or_template(s, base_type_node, None)
            # return p_buffer_access(s, base_type_node)
    elif not empty and not nonempty:
        # only anonymous C arrays and memoryview slice arrays here.  We
        # disallow buffer declarations for now, due to ambiguity with anonymous
        # C arrays.
        if is_memoryviewslice_access(s):
            return p_memoryviewslice_access(s, base_type_node)
        else:
            return base_type_node

def is_memoryviewslice_access(s):
    # s.sy == '['
    # a memoryview slice declaration is distinguishable from a buffer access
    # declaration by the first entry in the bracketed list.  The buffer will
    # not have an unnested colon in the first entry; the memoryview slice will.
    saved = [(s.sy, s.systring)]
    s.next()
    retval = False
    if s.systring == ':':
        retval = True
    elif s.sy == 'INT':
        saved.append((s.sy, s.systring))
        s.next()
        if s.sy == ':':
            retval = True

    for sv in saved[::-1]:
        s.put_back(*sv)

    return retval

def p_memoryviewslice_access(s, base_type_node):
    # s.sy == '['
    pos = s.position()
    s.next()
    subscripts, _ = p_subscript_list(s)
    # make sure each entry in subscripts is a slice
    for subscript in subscripts:
        if len(subscript) < 2:
            s.error("An axis specification in memoryview declaration does not have a ':'.")
    s.expect(']')
    indexes = make_slice_nodes(pos, subscripts)
    result = Nodes.MemoryViewSliceTypeNode(pos,
            base_type_node = base_type_node,
            axes = indexes)
    return result

def looking_at_name(s):
    return s.sy == 'IDENT' and not s.systring in calling_convention_words

def looking_at_expr(s):
    if s.systring in base_type_start_words:
        return False
    elif s.sy == 'IDENT':
        is_type = False
        name = s.systring
        dotted_path = []
        s.next()

        while s.sy == '.':
            s.next()
            dotted_path.append(s.systring)
            s.expect('IDENT')

        saved = s.sy, s.systring
        if s.sy == 'IDENT':
            is_type = True
        elif s.sy == '*' or s.sy == '**':
            s.next()
            is_type = s.sy in (')', ']')
            s.put_back(*saved)
        elif s.sy == '(':
            s.next()
            is_type = s.sy == '*'
            s.put_back(*saved)
        elif s.sy == '[':
            s.next()
            is_type = s.sy == ']'
            s.put_back(*saved)

        dotted_path.reverse()
        for p in dotted_path:
            s.put_back('IDENT', p)
            s.put_back('.', '.')

        s.put_back('IDENT', name)
        return not is_type and saved[0]
    else:
        return True

def looking_at_base_type(s):
    #print "looking_at_base_type?", s.sy, s.systring, s.position()
    return s.sy == 'IDENT' and s.systring in base_type_start_words

def looking_at_dotted_name(s):
    if s.sy == 'IDENT':
        name = s.systring
        s.next()
        result = s.sy == '.'
        s.put_back('IDENT', name)
        return result
    else:
        return 0

def looking_at_call(s):
    "See if we're looking at a.b.c("
    # Don't mess up the original position, so save and restore it.
    # Unfortunately there's no good way to handle this, as a subsequent call
    # to next() will not advance the position until it reads a new token.
    position = s.start_line, s.start_col
    result = looking_at_expr(s) == u'('
    if not result:
        s.start_line, s.start_col = position
    return result

basic_c_type_names = cython.declare(
    set, set(["void", "char", "int", "float", "double", "bint"]))

special_basic_c_types = cython.declare(dict, {
    # name : (signed, longness)
    "Py_UNICODE" : (0, 0),
    "Py_UCS4"    : (0, 0),
    "Py_ssize_t" : (2, 0),
    "ssize_t"    : (2, 0),
    "size_t"     : (0, 0),
    "ptrdiff_t"  : (2, 0),
})

sign_and_longness_words = cython.declare(
    set, set(["short", "long", "signed", "unsigned"]))

base_type_start_words = cython.declare(
    set,
    basic_c_type_names
    | sign_and_longness_words
    | set(special_basic_c_types))

struct_enum_union = cython.declare(
    set, set(["struct", "union", "enum", "packed"]))

def p_sign_and_longness(s):
    signed = 1
    longness = 0
    while s.sy == 'IDENT' and s.systring in sign_and_longness_words:
        if s.systring == 'unsigned':
            signed = 0
        elif s.systring == 'signed':
            signed = 2
        elif s.systring == 'short':
            longness = -1
        elif s.systring == 'long':
            longness += 1
        s.next()
    return signed, longness

def p_opt_cname(s):
    literal = p_opt_string_literal(s, 'u')
    if literal is not None:
        cname = EncodedString(literal)
        cname.encoding = s.source_encoding
    else:
        cname = None
    return cname

def p_c_declarator(s, ctx = Ctx(), empty = 0, is_type = 0, cmethod_flag = 0,
                   assignable = 0, nonempty = 0,
                   calling_convention_allowed = 0):
    # If empty is true, the declarator must be empty. If nonempty is true,
    # the declarator must be nonempty. Otherwise we don't care.
    # If cmethod_flag is true, then if this declarator declares
    # a function, it's a C method of an extension type.
    pos = s.position()
    if s.sy == '(':
        s.next()
        if s.sy == ')' or looking_at_name(s):
            base = Nodes.CNameDeclaratorNode(pos, name = EncodedString(u""), cname = None)
            result = p_c_func_declarator(s, pos, ctx, base, cmethod_flag)
        else:
            result = p_c_declarator(s, ctx, empty = empty, is_type = is_type,
                                    cmethod_flag = cmethod_flag,
                                    nonempty = nonempty,
                                    calling_convention_allowed = 1)
            s.expect(')')
    else:
        result = p_c_simple_declarator(s, ctx, empty, is_type, cmethod_flag,
                                       assignable, nonempty)
    if not calling_convention_allowed and result.calling_convention and s.sy != '(':
        error(s.position(), "%s on something that is not a function"
            % result.calling_convention)
    while s.sy in ('[', '('):
        pos = s.position()
        if s.sy == '[':
            result = p_c_array_declarator(s, result)
        else: # sy == '('
            s.next()
            result = p_c_func_declarator(s, pos, ctx, result, cmethod_flag)
        cmethod_flag = 0
    return result

def p_c_array_declarator(s, base):
    pos = s.position()
    s.next() # '['
    if s.sy != ']':
        dim = p_testlist(s)
    else:
        dim = None
    s.expect(']')
    return Nodes.CArrayDeclaratorNode(pos, base = base, dimension = dim)

def p_c_func_declarator(s, pos, ctx, base, cmethod_flag):
    #  Opening paren has already been skipped
    args = p_c_arg_list(s, ctx, cmethod_flag = cmethod_flag,
                        nonempty_declarators = 0)
    ellipsis = p_optional_ellipsis(s)
    s.expect(')')
    nogil = p_nogil(s)
    exc_val, exc_check = p_exception_value_clause(s)
    with_gil = p_with_gil(s)
    return Nodes.CFuncDeclaratorNode(pos,
        base = base, args = args, has_varargs = ellipsis,
        exception_value = exc_val, exception_check = exc_check,
        nogil = nogil or ctx.nogil or with_gil, with_gil = with_gil)

supported_overloaded_operators = cython.declare(set, set([
    '+', '-', '*', '/', '%',
    '++', '--', '~', '|', '&', '^', '<<', '>>', ',',
    '==', '!=', '>=', '>', '<=', '<',
    '[]', '()', '!',
]))

def p_c_simple_declarator(s, ctx, empty, is_type, cmethod_flag,
                          assignable, nonempty):
    pos = s.position()
    calling_convention = p_calling_convention(s)
    if s.sy == '*':
        s.next()
        if s.systring == 'const':
            const_pos = s.position()
            s.next()
            const_base = p_c_declarator(s, ctx, empty = empty,
                                       is_type = is_type,
                                       cmethod_flag = cmethod_flag,
                                       assignable = assignable,
                                       nonempty = nonempty)
            base = Nodes.CConstDeclaratorNode(const_pos, base = const_base)
        else:
            base = p_c_declarator(s, ctx, empty = empty, is_type = is_type,
                                  cmethod_flag = cmethod_flag,
                                  assignable = assignable, nonempty = nonempty)
        result = Nodes.CPtrDeclaratorNode(pos,
            base = base)
    elif s.sy == '**': # scanner returns this as a single token
        s.next()
        base = p_c_declarator(s, ctx, empty = empty, is_type = is_type,
                              cmethod_flag = cmethod_flag,
                              assignable = assignable, nonempty = nonempty)
        result = Nodes.CPtrDeclaratorNode(pos,
            base = Nodes.CPtrDeclaratorNode(pos,
                base = base))
    elif s.sy == '&':
        s.next()
        base = p_c_declarator(s, ctx, empty = empty, is_type = is_type,
                              cmethod_flag = cmethod_flag,
                              assignable = assignable, nonempty = nonempty)
        result = Nodes.CReferenceDeclaratorNode(pos, base = base)
    else:
        rhs = None
        if s.sy == 'IDENT':
            name = EncodedString(s.systring)
            if empty:
                error(s.position(), "Declarator should be empty")
            s.next()
            cname = p_opt_cname(s)
            if name != 'operator' and s.sy == '=' and assignable:
                s.next()
                rhs = p_test(s)
        else:
            if nonempty:
                error(s.position(), "Empty declarator")
            name = ""
            cname = None
        if cname is None and ctx.namespace is not None and nonempty:
            cname = ctx.namespace + "::" + name
        if name == 'operator' and ctx.visibility == 'extern' and nonempty:
            op = s.sy
            if [1 for c in op if c in '+-*/<=>!%&|([^~,']:
                s.next()
                # Handle diphthong operators.
                if op == '(':
                    s.expect(')')
                    op = '()'
                elif op == '[':
                    s.expect(']')
                    op = '[]'
                elif op in ('-', '+', '|', '&') and s.sy == op:
                    op *= 2       # ++, --, ...
                    s.next()
                elif s.sy == '=':
                    op += s.sy    # +=, -=, ...
                    s.next()
                if op not in supported_overloaded_operators:
                    s.error("Overloading operator '%s' not yet supported." % op,
                            fatal=False)
                name += op
        result = Nodes.CNameDeclaratorNode(pos,
            name = name, cname = cname, default = rhs)
    result.calling_convention = calling_convention
    return result

def p_nogil(s):
    if s.sy == 'IDENT' and s.systring == 'nogil':
        s.next()
        return 1
    else:
        return 0

def p_with_gil(s):
    if s.sy == 'with':
        s.next()
        s.expect_keyword('gil')
        return 1
    else:
        return 0

def p_exception_value_clause(s):
    exc_val = None
    exc_check = 0
    if s.sy == 'except':
        s.next()
        if s.sy == '*':
            exc_check = 1
            s.next()
        elif s.sy == '+':
            exc_check = '+'
            s.next()
            if s.sy == 'IDENT':
                name = s.systring
                s.next()
                exc_val = p_name(s, name)
        else:
            if s.sy == '?':
                exc_check = 1
                s.next()
            exc_val = p_test(s)
    return exc_val, exc_check

c_arg_list_terminators = cython.declare(set, set(['*', '**', '.', ')']))

def p_c_arg_list(s, ctx = Ctx(), in_pyfunc = 0, cmethod_flag = 0,
                 nonempty_declarators = 0, kw_only = 0, annotated = 1):
    #  Comma-separated list of C argument declarations, possibly empty.
    #  May have a trailing comma.
    args = []
    is_self_arg = cmethod_flag
    while s.sy not in c_arg_list_terminators:
        args.append(p_c_arg_decl(s, ctx, in_pyfunc, is_self_arg,
            nonempty = nonempty_declarators, kw_only = kw_only,
            annotated = annotated))
        if s.sy != ',':
            break
        s.next()
        is_self_arg = 0
    return args

def p_optional_ellipsis(s):
    if s.sy == '.':
        expect_ellipsis(s)
        return 1
    else:
        return 0

def p_c_arg_decl(s, ctx, in_pyfunc, cmethod_flag = 0, nonempty = 0,
                 kw_only = 0, annotated = 1):
    pos = s.position()
    not_none = or_none = 0
    default = None
    annotation = None
    if s.in_python_file:
        # empty type declaration
        base_type = Nodes.CSimpleBaseTypeNode(pos,
            name = None, module_path = [],
            is_basic_c_type = 0, signed = 0,
            complex = 0, longness = 0,
            is_self_arg = cmethod_flag, templates = None)
    else:
        base_type = p_c_base_type(s, cmethod_flag, nonempty = nonempty)
    declarator = p_c_declarator(s, ctx, nonempty = nonempty)
    if s.sy in ('not', 'or') and not s.in_python_file:
        kind = s.sy
        s.next()
        if s.sy == 'IDENT' and s.systring == 'None':
            s.next()
        else:
            s.error("Expected 'None'")
        if not in_pyfunc:
            error(pos, "'%s None' only allowed in Python functions" % kind)
        or_none = kind == 'or'
        not_none = kind == 'not'
    if annotated and s.sy == ':':
        s.next()
        annotation = p_test(s)
    if s.sy == '=':
        s.next()
        if 'pxd' in ctx.level:
            if s.sy not in ['*', '?']:
                error(pos, "default values cannot be specified in pxd files, use ? or *")
            default = ExprNodes.BoolNode(1)
            s.next()
        else:
            default = p_test(s)
    return Nodes.CArgDeclNode(pos,
        base_type = base_type,
        declarator = declarator,
        not_none = not_none,
        or_none = or_none,
        default = default,
        annotation = annotation,
        kw_only = kw_only)

def p_api(s):
    if s.sy == 'IDENT' and s.systring == 'api':
        s.next()
        return 1
    else:
        return 0

def p_cdef_statement(s, ctx):
    pos = s.position()
    ctx.visibility = p_visibility(s, ctx.visibility)
    ctx.api = ctx.api or p_api(s)
    if ctx.api:
        if ctx.visibility not in ('private', 'public'):
            error(pos, "Cannot combine 'api' with '%s'" % ctx.visibility)
    if (ctx.visibility == 'extern') and s.sy == 'from':
        return p_cdef_extern_block(s, pos, ctx)
    elif s.sy == 'import':
        s.next()
        return p_cdef_extern_block(s, pos, ctx)
    elif p_nogil(s):
        ctx.nogil = 1
        if ctx.overridable:
            error(pos, "cdef blocks cannot be declared cpdef")
        return p_cdef_block(s, ctx)
    elif s.sy == ':':
        if ctx.overridable:
            error(pos, "cdef blocks cannot be declared cpdef")
        return p_cdef_block(s, ctx)
    elif s.sy == 'class':
        if ctx.level not in ('module', 'module_pxd'):
            error(pos, "Extension type definition not allowed here")
        if ctx.overridable:
            error(pos, "Extension types cannot be declared cpdef")
        return p_c_class_definition(s, pos, ctx)
    elif s.sy == 'IDENT' and s.systring == 'cppclass':
        return p_cpp_class_definition(s, pos, ctx)
    elif s.sy == 'IDENT' and s.systring in struct_enum_union:
        if ctx.level not in ('module', 'module_pxd'):
            error(pos, "C struct/union/enum definition not allowed here")
        if ctx.overridable:
            error(pos, "C struct/union/enum cannot be declared cpdef")
        return p_struct_enum(s, pos, ctx)
    elif s.sy == 'IDENT' and s.systring == 'fused':
        return p_fused_definition(s, pos, ctx)
    else:
        return p_c_func_or_var_declaration(s, pos, ctx)

def p_cdef_block(s, ctx):
    return p_suite(s, ctx(cdef_flag = 1))

def p_cdef_extern_block(s, pos, ctx):
    if ctx.overridable:
        error(pos, "cdef extern blocks cannot be declared cpdef")
    include_file = None
    s.expect('from')
    if s.sy == '*':
        s.next()
    else:
        include_file = p_string_literal(s, 'u')[2]
    ctx = ctx(cdef_flag = 1, visibility = 'extern')
    if s.systring == "namespace":
        s.next()
        ctx.namespace = p_string_literal(s, 'u')[2]
    if p_nogil(s):
        ctx.nogil = 1
    body = p_suite(s, ctx)
    return Nodes.CDefExternNode(pos,
        include_file = include_file,
        body = body,
        namespace = ctx.namespace)

def p_c_enum_definition(s, pos, ctx):
    # s.sy == ident 'enum'
    s.next()
    if s.sy == 'IDENT':
        name = s.systring
        s.next()
        cname = p_opt_cname(s)
        if cname is None and ctx.namespace is not None:
            cname = ctx.namespace + "::" + name
    else:
        name = None
        cname = None
    items = None
    s.expect(':')
    items = []
    if s.sy != 'NEWLINE':
        p_c_enum_line(s, ctx, items)
    else:
        s.next() # 'NEWLINE'
        s.expect_indent()
        while s.sy not in ('DEDENT', 'EOF'):
            p_c_enum_line(s, ctx, items)
        s.expect_dedent()
    return Nodes.CEnumDefNode(
        pos, name = name, cname = cname, items = items,
        typedef_flag = ctx.typedef_flag, visibility = ctx.visibility,
        api = ctx.api, in_pxd = ctx.level == 'module_pxd')

def p_c_enum_line(s, ctx, items):
    if s.sy != 'pass':
        p_c_enum_item(s, ctx, items)
        while s.sy == ',':
            s.next()
            if s.sy in ('NEWLINE', 'EOF'):
                break
            p_c_enum_item(s, ctx, items)
    else:
        s.next()
    s.expect_newline("Syntax error in enum item list")

def p_c_enum_item(s, ctx, items):
    pos = s.position()
    name = p_ident(s)
    cname = p_opt_cname(s)
    if cname is None and ctx.namespace is not None:
        cname = ctx.namespace + "::" + name
    value = None
    if s.sy == '=':
        s.next()
        value = p_test(s)
    items.append(Nodes.CEnumDefItemNode(pos,
        name = name, cname = cname, value = value))

def p_c_struct_or_union_definition(s, pos, ctx):
    packed = False
    if s.systring == 'packed':
        packed = True
        s.next()
        if s.sy != 'IDENT' or s.systring != 'struct':
            s.expected('struct')
    # s.sy == ident 'struct' or 'union'
    kind = s.systring
    s.next()
    name = p_ident(s)
    cname = p_opt_cname(s)
    if cname is None and ctx.namespace is not None:
        cname = ctx.namespace + "::" + name
    attributes = None
    if s.sy == ':':
        s.next()
        s.expect('NEWLINE')
        s.expect_indent()
        attributes = []
        body_ctx = Ctx()
        while s.sy != 'DEDENT':
            if s.sy != 'pass':
                attributes.append(
                    p_c_func_or_var_declaration(s, s.position(), body_ctx))
            else:
                s.next()
                s.expect_newline("Expected a newline")
        s.expect_dedent()
    else:
        s.expect_newline("Syntax error in struct or union definition")
    return Nodes.CStructOrUnionDefNode(pos,
        name = name, cname = cname, kind = kind, attributes = attributes,
        typedef_flag = ctx.typedef_flag, visibility = ctx.visibility,
        api = ctx.api, in_pxd = ctx.level == 'module_pxd', packed = packed)

def p_fused_definition(s, pos, ctx):
    """
    c(type)def fused my_fused_type:
        ...
    """
    # s.systring == 'fused'

    if ctx.level not in ('module', 'module_pxd'):
        error(pos, "Fused type definition not allowed here")

    s.next()
    name = p_ident(s)

    s.expect(":")
    s.expect_newline()
    s.expect_indent()

    types = []
    while s.sy != 'DEDENT':
        if s.sy != 'pass':
            #types.append(p_c_declarator(s))
            types.append(p_c_base_type(s)) #, nonempty=1))
        else:
            s.next()

        s.expect_newline()

    s.expect_dedent()

    if not types:
        error(pos, "Need at least one type")

    return Nodes.FusedTypeNode(pos, name=name, types=types)

def p_struct_enum(s, pos, ctx):
    if s.systring == 'enum':
        return p_c_enum_definition(s, pos, ctx)
    else:
        return p_c_struct_or_union_definition(s, pos, ctx)

def p_visibility(s, prev_visibility):
    pos = s.position()
    visibility = prev_visibility
    if s.sy == 'IDENT' and s.systring in ('extern', 'public', 'readonly'):
        visibility = s.systring
        if prev_visibility != 'private' and visibility != prev_visibility:
            s.error("Conflicting visibility options '%s' and '%s'"
                % (prev_visibility, visibility), fatal=False)
        s.next()
    return visibility

def p_c_modifiers(s):
    if s.sy == 'IDENT' and s.systring in ('inline',):
        modifier = s.systring
        s.next()
        return [modifier] + p_c_modifiers(s)
    return []

def p_c_func_or_var_declaration(s, pos, ctx):
    cmethod_flag = ctx.level in ('c_class', 'c_class_pxd')
    modifiers = p_c_modifiers(s)
    base_type = p_c_base_type(s, nonempty = 1, templates = ctx.templates)
    declarator = p_c_declarator(s, ctx, cmethod_flag = cmethod_flag,
                                assignable = 1, nonempty = 1)
    declarator.overridable = ctx.overridable
    if s.sy == 'IDENT' and s.systring == 'const' and ctx.level == 'cpp_class':
        s.next()
        is_const_method = 1
    else:
        is_const_method = 0
    if s.sy == ':':
        if ctx.level not in ('module', 'c_class', 'module_pxd', 'c_class_pxd', 'cpp_class') and not ctx.templates:
            s.error("C function definition not allowed here")
        doc, suite = p_suite_with_docstring(s, Ctx(level='function'))
        result = Nodes.CFuncDefNode(pos,
            visibility = ctx.visibility,
            base_type = base_type,
            declarator = declarator,
            body = suite,
            doc = doc,
            modifiers = modifiers,
            api = ctx.api,
            overridable = ctx.overridable,
            is_const_method = is_const_method)
    else:
        #if api:
        #    s.error("'api' not allowed with variable declaration")
        if is_const_method:
            declarator.is_const_method = is_const_method
        declarators = [declarator]
        while s.sy == ',':
            s.next()
            if s.sy == 'NEWLINE':
                break
            declarator = p_c_declarator(s, ctx, cmethod_flag = cmethod_flag,
                                        assignable = 1, nonempty = 1)
            declarators.append(declarator)
        doc_line = s.start_line + 1
        s.expect_newline("Syntax error in C variable declaration")
        if ctx.level in ('c_class', 'c_class_pxd') and s.start_line == doc_line:
            doc = p_doc_string(s)
        else:
            doc = None
        result = Nodes.CVarDefNode(pos,
            visibility = ctx.visibility,
            base_type = base_type,
            declarators = declarators,
            in_pxd = ctx.level in ('module_pxd', 'c_class_pxd'),
            doc = doc,
            api = ctx.api,
            modifiers = modifiers,
            overridable = ctx.overridable)
    return result

def p_ctypedef_statement(s, ctx):
    # s.sy == 'ctypedef'
    pos = s.position()
    s.next()
    visibility = p_visibility(s, ctx.visibility)
    api = p_api(s)
    ctx = ctx(typedef_flag = 1, visibility = visibility)
    if api:
        ctx.api = 1
    if s.sy == 'class':
        return p_c_class_definition(s, pos, ctx)
    elif s.sy == 'IDENT' and s.systring in struct_enum_union:
        return p_struct_enum(s, pos, ctx)
    elif s.sy == 'IDENT' and s.systring == 'fused':
        return p_fused_definition(s, pos, ctx)
    else:
        base_type = p_c_base_type(s, nonempty = 1)
        declarator = p_c_declarator(s, ctx, is_type = 1, nonempty = 1)
        s.expect_newline("Syntax error in ctypedef statement")
        return Nodes.CTypeDefNode(
            pos, base_type = base_type,
            declarator = declarator,
            visibility = visibility, api = api,
            in_pxd = ctx.level == 'module_pxd')

def p_decorators(s):
    decorators = []
    while s.sy == 'DECORATOR':
        pos = s.position()
        s.next()
        decstring = p_dotted_name(s, as_allowed=0)[2]
        names = decstring.split('.')
        decorator = ExprNodes.NameNode(pos, name=EncodedString(names[0]))
        for name in names[1:]:
            decorator = ExprNodes.AttributeNode(pos,
                                           attribute=EncodedString(name),
                                           obj=decorator)
        if s.sy == '(':
            decorator = p_call(s, decorator)
        decorators.append(Nodes.DecoratorNode(pos, decorator=decorator))
        s.expect_newline("Expected a newline after decorator")
    return decorators

def p_def_statement(s, decorators=None):
    # s.sy == 'def'
    pos = s.position()
    s.next()
    name = EncodedString( p_ident(s) )
    s.expect('(')
    args, star_arg, starstar_arg = p_varargslist(s, terminator=')')
    s.expect(')')
    if p_nogil(s):
        error(pos, "Python function cannot be declared nogil")
    return_type_annotation = None
    if s.sy == '->':
        s.next()
        return_type_annotation = p_test(s)
    doc, body = p_suite_with_docstring(s, Ctx(level='function'))
    return Nodes.DefNode(pos, name = name, args = args,
        star_arg = star_arg, starstar_arg = starstar_arg,
        doc = doc, body = body, decorators = decorators,
        return_type_annotation = return_type_annotation)

def p_varargslist(s, terminator=')', annotated=1):
    args = p_c_arg_list(s, in_pyfunc = 1, nonempty_declarators = 1,
                        annotated = annotated)
    star_arg = None
    starstar_arg = None
    if s.sy == '*':
        s.next()
        if s.sy == 'IDENT':
            star_arg = p_py_arg_decl(s, annotated=annotated)
        if s.sy == ',':
            s.next()
            args.extend(p_c_arg_list(s, in_pyfunc = 1,
                nonempty_declarators = 1, kw_only = 1, annotated = annotated))
        elif s.sy != terminator:
            s.error("Syntax error in Python function argument list")
    if s.sy == '**':
        s.next()
        starstar_arg = p_py_arg_decl(s, annotated=annotated)
    return (args, star_arg, starstar_arg)

def p_py_arg_decl(s, annotated = 1):
    pos = s.position()
    name = p_ident(s)
    annotation = None
    if annotated and s.sy == ':':
        s.next()
        annotation = p_test(s)
    return Nodes.PyArgDeclNode(pos, name = name, annotation = annotation)

def p_class_statement(s, decorators):
    # s.sy == 'class'
    pos = s.position()
    s.next()
    class_name = EncodedString( p_ident(s) )
    class_name.encoding = s.source_encoding
    arg_tuple = None
    keyword_dict = None
    starstar_arg = None
    if s.sy == '(':
        positional_args, keyword_args, star_arg, starstar_arg = \
                            p_call_parse_args(s, allow_genexp = False)
        arg_tuple, keyword_dict = p_call_build_packed_args(
            pos, positional_args, keyword_args, star_arg, None)
    if arg_tuple is None:
        # XXX: empty arg_tuple
        arg_tuple = ExprNodes.TupleNode(pos, args=[])
    doc, body = p_suite_with_docstring(s, Ctx(level='class'))
    return Nodes.PyClassDefNode(
        pos, name=class_name,
        bases=arg_tuple,
        keyword_args=keyword_dict,
        starstar_arg=starstar_arg,
        doc=doc, body=body, decorators=decorators,
        force_py3_semantics=s.context.language_level >= 3)

def p_c_class_definition(s, pos,  ctx):
    # s.sy == 'class'
    s.next()
    module_path = []
    class_name = p_ident(s)
    while s.sy == '.':
        s.next()
        module_path.append(class_name)
        class_name = p_ident(s)
    if module_path and ctx.visibility != 'extern':
        error(pos, "Qualified class name only allowed for 'extern' C class")
    if module_path and s.sy == 'IDENT' and s.systring == 'as':
        s.next()
        as_name = p_ident(s)
    else:
        as_name = class_name
    objstruct_name = None
    typeobj_name = None
    base_class_module = None
    base_class_name = None
    if s.sy == '(':
        s.next()
        base_class_path = [p_ident(s)]
        while s.sy == '.':
            s.next()
            base_class_path.append(p_ident(s))
        if s.sy == ',':
            s.error("C class may only have one base class", fatal=False)
        s.expect(')')
        base_class_module = ".".join(base_class_path[:-1])
        base_class_name = base_class_path[-1]
    if s.sy == '[':
        if ctx.visibility not in ('public', 'extern') and not ctx.api:
            error(s.position(), "Name options only allowed for 'public', 'api', or 'extern' C class")
        objstruct_name, typeobj_name = p_c_class_options(s)
    if s.sy == ':':
        if ctx.level == 'module_pxd':
            body_level = 'c_class_pxd'
        else:
            body_level = 'c_class'
        doc, body = p_suite_with_docstring(s, Ctx(level=body_level))
    else:
        s.expect_newline("Syntax error in C class definition")
        doc = None
        body = None
    if ctx.visibility == 'extern':
        if not module_path:
            error(pos, "Module name required for 'extern' C class")
        if typeobj_name:
            error(pos, "Type object name specification not allowed for 'extern' C class")
    elif ctx.visibility == 'public':
        if not objstruct_name:
            error(pos, "Object struct name specification required for 'public' C class")
        if not typeobj_name:
            error(pos, "Type object name specification required for 'public' C class")
    elif ctx.visibility == 'private':
        if ctx.api:
            if not objstruct_name:
                error(pos, "Object struct name specification required for 'api' C class")
            if not typeobj_name:
                error(pos, "Type object name specification required for 'api' C class")
    else:
        error(pos, "Invalid class visibility '%s'" % ctx.visibility)
    return Nodes.CClassDefNode(pos,
        visibility = ctx.visibility,
        typedef_flag = ctx.typedef_flag,
        api = ctx.api,
        module_name = ".".join(module_path),
        class_name = class_name,
        as_name = as_name,
        base_class_module = base_class_module,
        base_class_name = base_class_name,
        objstruct_name = objstruct_name,
        typeobj_name = typeobj_name,
        in_pxd = ctx.level == 'module_pxd',
        doc = doc,
        body = body)

def p_c_class_options(s):
    objstruct_name = None
    typeobj_name = None
    s.expect('[')
    while 1:
        if s.sy != 'IDENT':
            break
        if s.systring == 'object':
            s.next()
            objstruct_name = p_ident(s)
        elif s.systring == 'type':
            s.next()
            typeobj_name = p_ident(s)
        if s.sy != ',':
            break
        s.next()
    s.expect(']', "Expected 'object' or 'type'")
    return objstruct_name, typeobj_name


def p_property_decl(s):
    pos = s.position()
    s.next()  # 'property'
    name = p_ident(s)
    doc, body = p_suite_with_docstring(
        s, Ctx(level='property'), with_doc_only=True)
    return Nodes.PropertyNode(pos, name=name, doc=doc, body=body)


def p_ignorable_statement(s):
    """
    Parses any kind of ignorable statement that is allowed in .pxd files.
    """
    if s.sy == 'BEGIN_STRING':
        pos = s.position()
        string_node = p_atom(s)
        if s.sy != 'EOF':
            s.expect_newline("Syntax error in string")
        return Nodes.ExprStatNode(pos, expr=string_node)
    return None


def p_doc_string(s):
    if s.sy == 'BEGIN_STRING':
        pos = s.position()
        kind, bytes_result, unicode_result = p_cat_string_literal(s)
        if s.sy != 'EOF':
            s.expect_newline("Syntax error in doc string")
        if kind in ('u', ''):
            return unicode_result
        warning(pos, "Python 3 requires docstrings to be unicode strings")
        return bytes_result
    else:
        return None


def _extract_docstring(node):
    """
    Extract a docstring from a statement or from the first statement
    in a list.  Remove the statement if found.  Return a tuple
    (plain-docstring or None, node).
    """
    doc_node = None
    if node is None:
        pass
    elif isinstance(node, Nodes.ExprStatNode):
        if node.expr.is_string_literal:
            doc_node = node.expr
            node = Nodes.StatListNode(node.pos, stats=[])
    elif isinstance(node, Nodes.StatListNode) and node.stats:
        stats = node.stats
        if isinstance(stats[0], Nodes.ExprStatNode):
            if stats[0].expr.is_string_literal:
                doc_node = stats[0].expr
                del stats[0]

    if doc_node is None:
        doc = None
    elif isinstance(doc_node, ExprNodes.BytesNode):
        warning(node.pos,
                "Python 3 requires docstrings to be unicode strings")
        doc = doc_node.value
    elif isinstance(doc_node, ExprNodes.StringNode):
        doc = doc_node.unicode_value
        if doc is None:
            doc = doc_node.value
    else:
        doc = doc_node.value
    return doc, node


def p_code(s, level=None, ctx=Ctx):
    body = p_statement_list(s, ctx(level = level), first_statement = 1)
    if s.sy != 'EOF':
        s.error("Syntax error in statement [%s,%s]" % (
            repr(s.sy), repr(s.systring)))
    return body

_match_compiler_directive_comment = cython.declare(object, re.compile(
    r"^#\s*cython\s*:\s*((\w|[.])+\s*=.*)$").match)

def p_compiler_directive_comments(s):
    result = {}
    while s.sy == 'commentline':
        m = _match_compiler_directive_comment(s.systring)
        if m:
            directives = m.group(1).strip()
            try:
                result.update(Options.parse_directive_list(
                    directives, ignore_unknown=True))
            except ValueError, e:
                s.error(e.args[0], fatal=False)
        s.next()
    return result

def p_module(s, pxd, full_module_name, ctx=Ctx):
    pos = s.position()

    directive_comments = p_compiler_directive_comments(s)
    s.parse_comments = False

    if 'language_level' in directive_comments:
        s.context.set_language_level(directive_comments['language_level'])

    doc = p_doc_string(s)
    if pxd:
        level = 'module_pxd'
    else:
        level = 'module'

    body = p_statement_list(s, ctx(level=level), first_statement = 1)
    if s.sy != 'EOF':
        s.error("Syntax error in statement [%s,%s]" % (
            repr(s.sy), repr(s.systring)))
    return ModuleNode(pos, doc = doc, body = body,
                      full_module_name = full_module_name,
                      directive_comments = directive_comments)

def p_cpp_class_definition(s, pos,  ctx):
    # s.sy == 'cppclass'
    s.next()
    module_path = []
    class_name = p_ident(s)
    cname = p_opt_cname(s)
    if cname is None and ctx.namespace is not None:
        cname = ctx.namespace + "::" + class_name
    if s.sy == '.':
        error(pos, "Qualified class name not allowed C++ class")
    if s.sy == '[':
        s.next()
        templates = [p_ident(s)]
        while s.sy == ',':
            s.next()
            templates.append(p_ident(s))
        s.expect(']')
    else:
        templates = None
    if s.sy == '(':
        s.next()
        base_classes = [p_c_base_type(s, templates = templates)]
        while s.sy == ',':
            s.next()
            base_classes.append(p_c_base_type(s, templates = templates))
        s.expect(')')
    else:
        base_classes = []
    if s.sy == '[':
        error(s.position(), "Name options not allowed for C++ class")
    nogil = p_nogil(s)
    if s.sy == ':':
        s.next()
        s.expect('NEWLINE')
        s.expect_indent()
        attributes = []
        body_ctx = Ctx(visibility = ctx.visibility, level='cpp_class', nogil=nogil or ctx.nogil)
        body_ctx.templates = templates
        while s.sy != 'DEDENT':
            if s.systring == 'cppclass':
                attributes.append(
                    p_cpp_class_definition(s, s.position(), body_ctx))
            elif s.sy != 'pass':
                attributes.append(
                    p_c_func_or_var_declaration(s, s.position(), body_ctx))
            else:
                s.next()
                s.expect_newline("Expected a newline")
        s.expect_dedent()
    else:
        attributes = None
        s.expect_newline("Syntax error in C++ class definition")
    return Nodes.CppClassNode(pos,
        name = class_name,
        cname = cname,
        base_classes = base_classes,
        visibility = ctx.visibility,
        in_pxd = ctx.level == 'module_pxd',
        attributes = attributes,
        templates = templates)



#----------------------------------------------
#
#   Debugging
#
#----------------------------------------------

def print_parse_tree(f, node, level, key = None):
    from types import ListType, TupleType
    from Nodes import Node
    ind = "  " * level
    if node:
        f.write(ind)
        if key:
            f.write("%s: " % key)
        t = type(node)
        if t is tuple:
            f.write("(%s @ %s\n" % (node[0], node[1]))
            for i in xrange(2, len(node)):
                print_parse_tree(f, node[i], level+1)
            f.write("%s)\n" % ind)
            return
        elif isinstance(node, Node):
            try:
                tag = node.tag
            except AttributeError:
                tag = node.__class__.__name__
            f.write("%s @ %s\n" % (tag, node.pos))
            for name, value in node.__dict__.items():
                if name != 'tag' and name != 'pos':
                    print_parse_tree(f, value, level+1, name)
            return
        elif t is list:
            f.write("[\n")
            for i in xrange(len(node)):
                print_parse_tree(f, node[i], level+1)
            f.write("%s]\n" % ind)
            return
    f.write("%s%s\n" % (ind, node))
