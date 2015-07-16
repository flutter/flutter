"""
This module deals with interpreting the parse tree as Python
would have done, in the compiler.

For now this only covers parse tree to value conversion of
compile-time values.
"""

from Nodes import *
from ExprNodes import *
from Errors import CompileError


class EmptyScope(object):
    def lookup(self, name):
        return None

empty_scope = EmptyScope()

def interpret_compiletime_options(optlist, optdict, type_env=None, type_args=()):
    """
    Tries to interpret a list of compile time option nodes.
    The result will be a tuple (optlist, optdict) but where
    all expression nodes have been interpreted. The result is
    in the form of tuples (value, pos).

    optlist is a list of nodes, while optdict is a DictNode (the
    result optdict is a dict)

    If type_env is set, all type nodes will be analysed and the resulting
    type set. Otherwise only interpretateable ExprNodes
    are allowed, other nodes raises errors.

    A CompileError will be raised if there are problems.
    """

    def interpret(node, ix):
        if ix in type_args:
            if type_env:
                type = node.analyse_as_type(type_env)
                if not type:
                    raise CompileError(node.pos, "Invalid type.")
                return (type, node.pos)
            else:
                raise CompileError(node.pos, "Type not allowed here.")
        else:
            if (sys.version_info[0] >=3 and
                isinstance(node, StringNode) and
                node.unicode_value is not None):
                return (node.unicode_value, node.pos)
            return (node.compile_time_value(empty_scope), node.pos)

    if optlist:
        optlist = [interpret(x, ix) for ix, x in enumerate(optlist)]
    if optdict:
        assert isinstance(optdict, DictNode)
        new_optdict = {}
        for item in optdict.key_value_pairs:
            new_key, dummy = interpret(item.key, None)
            new_optdict[new_key] = interpret(item.value, item.key.value)
        optdict = new_optdict
    return (optlist, new_optdict)
